#!/bin/bash
set -e

echo "=========================================================="
echo " Starting Pharmacy Management System inside Docker"
echo "=========================================================="

# Set virtual display
export DISPLAY=:99

echo "[1/4] Starting Xvfb virtual display (:99)..."
Xvfb :99 -screen 0 1280x800x24 &
XVFB_PID=$!
sleep 1

echo "[2/4] Starting Fluxbox window manager..."
fluxbox &
FLUXBOX_PID=$!

echo "[3/4] Starting x11vnc server (port 5900)..."
x11vnc -display :99 -forever -nopw -shared -rfbport 5900 -quiet &
VNC_PID=$!

echo "[4/4] Starting noVNC web interface on port 6080..."
websockify --web /usr/share/novnc 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

echo "=========================================================="
echo " GUI ready! Open in your browser: http://localhost:6080"
echo "=========================================================="

cleanup() {
    echo "Stopping background processes..."
    kill $WEBSOCKIFY_PID $VNC_PID $FLUXBOX_PID $XVFB_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

echo "Starting Spring Boot Application..."
java -jar /app/app.jar "$@" &
JAVA_PID=$!

# Wait for the main Java process
wait $JAVA_PID

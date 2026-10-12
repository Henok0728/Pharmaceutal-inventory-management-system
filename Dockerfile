# Stage 1: Build the Spring Boot application using Maven
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /build

# Pre-fetch Maven dependencies for layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -B || true

# Copy source code and build executable jar
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime environment with virtual display & noVNC web client
FROM eclipse-temurin:17-jre-jammy

ENV DEBIAN_FRONTEND=noninteractive

# Install Xvfb, fluxbox, x11vnc, noVNC, websockify, and required desktop fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    fluxbox \
    x11vnc \
    novnc \
    websockify \
    net-tools \
    procps \
    libfreetype6 \
    fontconfig \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

WORKDIR /app

# Copy the built jar from the builder stage
COPY --from=builder /build/target/*.jar /app/app.jar

# Copy entrypoint script and ensure Unix line endings + execute permissions
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && chmod +x /app/docker-entrypoint.sh

# Expose noVNC web interface (6080) and native VNC server (5900)
EXPOSE 6080 5900

ENTRYPOINT ["/app/docker-entrypoint.sh"]

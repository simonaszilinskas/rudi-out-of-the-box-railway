FROM ubuntu:22.04

# Install required packages and Docker
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    supervisor && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the entire repository
COPY . .

# Create supervisor configuration
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:dockerd]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/usr/bin/dockerd' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'priority=1' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:compose]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=sh -c "while ! docker info > /dev/null 2>&1; do sleep 1; done && docker compose -f docker-compose-magnolia.yml -f docker-compose-rudi.yml -f docker-compose-dataverse.yml -f docker-compose-network.yml --profile \"*\" up"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'priority=2' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'startsecs=0' >> /etc/supervisor/conf.d/supervisord.conf

# Create startup script with verification
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'mkdir -p /var/run/docker' >> /start.sh && \
    echo 'if [ -x "$(command -v dockerd)" ]; then' >> /start.sh && \
    echo '    echo "Docker daemon found at $(command -v dockerd)"' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '    echo "Docker daemon not found"' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'if [ -x "$(command -v docker)" ]; then' >> /start.sh && \
    echo '    echo "Docker client found at $(command -v docker)"' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '    echo "Docker client not found"' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' >> /start.sh && \
    chmod +x /start.sh

# Set environment variables
ENV DOCKER_HOST="unix:///var/run/docker.sock"
ENV DOCKER_BUILDKIT=1
ENV COMPOSE_DOCKER_CLI_BUILD=1

# Start supervisord
CMD ["/start.sh"]

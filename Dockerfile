FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    uidmap \
    dbus-user-session \
    fuse-overlayfs \
    curl \
    git \
    iptables \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Create rootless user
RUN useradd -m -u 1000 rootless && \
    mkdir -p /home/rootless/.local/bin && \
    chown -R rootless:rootless /home/rootless

# Switch to rootless user for Docker installation
USER rootless
WORKDIR /home/rootless

# Install Docker
RUN curl -fsSL https://get.docker.com/rootless | sh && \
    echo 'export PATH=/home/rootless/bin:$PATH' >> /home/rootless/.bashrc && \
    echo 'export DOCKER_HOST=unix:///run/user/1000/docker.sock' >> /home/rootless/.bashrc

# Switch back to root for remaining setup
USER root
WORKDIR /app

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Copy the entire repository
COPY . .
RUN chown -R rootless:rootless /app

# Create supervisor configuration
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:dockerd]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/home/rootless/bin/dockerd-rootless.sh' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=rootless' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=HOME="/home/rootless",USER="rootless",PATH="/home/rootless/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",XDG_RUNTIME_DIR="/run/user/1000"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:compose]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/usr/local/bin/docker-compose -f docker-compose-magnolia.yml -f docker-compose-rudi.yml -f docker-compose-dataverse.yml -f docker-compose-network.yml --profile "*" up' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=rootless' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=HOME="/home/rootless",USER="rootless",PATH="/home/rootless/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",DOCKER_HOST="unix:///run/user/1000/docker.sock",XDG_RUNTIME_DIR="/run/user/1000"' >> /etc/supervisor/conf.d/supervisord.conf

# Create necessary directories
RUN mkdir -p /run/user/1000 && \
    chown -R rootless:rootless /run/user/1000

# Set environment variables
ENV DOCKER_HOST="unix:///run/user/1000/docker.sock"
ENV XDG_RUNTIME_DIR="/run/user/1000"
ENV PATH="/home/rootless/bin:${PATH}"

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'mkdir -p /run/user/1000' >> /start.sh && \
    echo 'chown -R rootless:rootless /run/user/1000' >> /start.sh && \
    echo 'exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' >> /start.sh && \
    chmod +x /start.sh

# Start supervisord
CMD ["/start.sh"]

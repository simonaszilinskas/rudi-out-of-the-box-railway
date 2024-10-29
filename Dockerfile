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

# Install Docker
RUN curl -fsSL https://get.docker.com/rootless | sh

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

WORKDIR /app

# Copy the entire repository
COPY . .

# Create supervisor configuration
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:dockerd]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/home/rootless/.local/bin/dockerd-rootless.sh' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=rootless' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=HOME="/home/rootless",USER="rootless",PATH="/home/rootless/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:compose]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/usr/local/bin/docker-compose -f docker-compose-magnolia.yml -f docker-compose-rudi.yml -f docker-compose-dataverse.yml -f docker-compose-network.yml --profile "*" up' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=rootless' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=HOME="/home/rootless",USER="rootless",PATH="/home/rootless/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",DOCKER_HOST="unix:///run/user/1000/docker.sock"' >> /etc/supervisor/conf.d/supervisord.conf

# Create rootless user
RUN useradd -m -u 1000 rootless && \
    mkdir -p /home/rootless/.local/bin && \
    chown -R rootless:rootless /app /home/rootless

# Set environment variables
ENV DOCKER_HOST="unix:///run/user/1000/docker.sock"
ENV XDG_RUNTIME_DIR="/run/user/1000"
ENV PATH="/home/rootless/.local/bin:${PATH}"

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

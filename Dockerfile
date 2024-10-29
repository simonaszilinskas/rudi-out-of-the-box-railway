FROM docker:24.0-dind

# Install required dependencies and Docker Compose
RUN apk add --no-cache \
    bash \
    git \
    curl \
    docker-compose

WORKDIR /app

# Copy the entire repository
COPY . .

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start the docker daemon' >> /entrypoint.sh && \
    echo 'dockerd &' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Wait for docker daemon to be ready' >> /entrypoint.sh && \
    echo 'while ! docker info > /dev/null 2>&1; do' >> /entrypoint.sh && \
    echo '  echo "Waiting for docker daemon..."' >> /entrypoint.sh && \
    echo '  sleep 1' >> /entrypoint.sh && \
    echo 'done' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start docker-compose' >> /entrypoint.sh && \
    echo 'exec docker-compose -f docker-compose-magnolia.yml -f docker-compose-rudi.yml -f docker-compose-dataverse.yml -f docker-compose-network.yml --profile "*" up' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENV DOCKER_TLS_CERTDIR=""
ENV DOCKER_HOST="unix:///var/run/docker.sock"

# Start command
ENTRYPOINT ["/entrypoint.sh"]

FROM docker:20.10-dind

# Install required packages
RUN apk add --no-cache \
    docker-compose \
    bash \
    git

WORKDIR /app

# Copy all necessary files
COPY . .

# Set environment variables
ENV DOCKER_HOST=unix:///var/run/docker.sock
ENV COMPOSE_DOCKER_CLI_BUILD=1
ENV DOCKER_BUILDKIT=1

# Start script
CMD ["docker-compose", "-f", "docker-compose-magnolia.yml", "-f", "docker-compose-rudi.yml", "-f", "docker-compose-dataverse.yml", "-f", "docker-compose-network.yml", "--profile", "*", "up"]

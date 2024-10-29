FROM docker/compose:1.29.2

# Install required dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl \
    docker-cli

WORKDIR /app

# Copy the entire repository
COPY . .

# Make sure all scripts are executable
RUN chmod +x /usr/local/bin/docker-compose

# Set environment variables
ENV COMPOSE_DOCKER_CLI_BUILD=1
ENV DOCKER_BUILDKIT=1

# Start command
CMD ["docker-compose", "-f", "docker-compose-magnolia.yml", "-f", "docker-compose-rudi.yml", "-f", "docker-compose-dataverse.yml", "-f", "docker-compose-network.yml", "--profile", "*", "up"]

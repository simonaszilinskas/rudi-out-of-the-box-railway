FROM docker:23-cli

# Install Docker Compose V2
COPY --from=docker/compose:latest /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

# Install required dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl && \
    mkdir -p /usr/local/lib/docker/cli-plugins

WORKDIR /app

# Copy the entire repository
COPY . .

# Set environment variables
ENV COMPOSE_DOCKER_CLI_BUILD=1
ENV DOCKER_BUILDKIT=1

# Make sure compose plugin is executable
RUN chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Start command using Docker Compose V2
CMD ["docker", "compose", "-f", "docker-compose-magnolia.yml", "-f", "docker-compose-rudi.yml", "-f", "docker-compose-dataverse.yml", "-f", "docker-compose-network.yml", "--profile", "*", "up"]

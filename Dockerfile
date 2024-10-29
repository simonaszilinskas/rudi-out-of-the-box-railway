FROM docker:23-cli

# Install required dependencies and Docker Compose
RUN apk add --no-cache \
    bash \
    git \
    curl && \
    curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

WORKDIR /app

# Copy the entire repository
COPY . .

# Set environment variables
ENV COMPOSE_DOCKER_CLI_BUILD=1
ENV DOCKER_BUILDKIT=1
ENV PATH="/usr/local/bin:${PATH}"

# Start command using Docker Compose
CMD ["/usr/local/bin/docker-compose", "-f", "docker-compose-magnolia.yml", "-f", "docker-compose-rudi.yml", "-f", "docker-compose-dataverse.yml", "-f", "docker-compose-network.yml", "--profile", "*", "up"]

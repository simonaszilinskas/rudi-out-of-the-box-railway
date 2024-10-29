FROM docker:20.10-dind

WORKDIR /app

COPY . .

ENV DOCKER_HOST=unix:///var/run/docker.sock
ENV COMPOSE_DOCKER_CLI_BUILD=1
ENV DOCKER_BUILDKIT=1

CMD ["sh", "-c", "docker compose -f docker-compose-magnolia.yml -f docker-compose-rudi.yml -f docker-compose-dataverse.yml -f docker-compose-network.yml --profile '*' up"]

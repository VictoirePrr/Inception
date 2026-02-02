NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: help all up build down restart logs clean fclean ps

help:
	@echo "$(NAME) - Docker infrastructure for 42 Inception project"
	@echo ""
	@echo "Available targets:"
	@echo "  make up           - Build and start all containers"
	@echo "  make build        - Build images without starting"
	@echo "  make down         - Stop and remove containers"
	@echo "  make restart      - Restart all containers"
	@echo "  make logs         - Show container logs"
	@echo "  make ps           - Show running containers"
	@echo "  make clean        - Stop containers and remove volumes"
	@echo "  make fclean       - Full clean: remove images, containers, volumes, networks"
	@echo "  make help         - Show this help message"
	@echo "  make database     - Open a mysql shell as root inside the mariadb container"

all: up

up:
	@echo "Starting $(NAME) containers..."
	docker compose -f $(COMPOSE_FILE) -p $(NAME) up --build -d
	@echo "✓ Containers started"
	@echo "Access WordPress at: https://localhost (accept self-signed certificate)"

build:
	@echo "Building $(NAME) images..."
	docker compose -f $(COMPOSE_FILE) -p $(NAME) build
	@echo "✓ Images built"

down:
	@echo "Stopping $(NAME) containers..."
	docker compose -f $(COMPOSE_FILE) -p $(NAME) down
	@echo "✓ Containers stopped"

restart:
	@echo "Restarting $(NAME) containers..."
	docker compose -f $(COMPOSE_FILE) -p $(NAME) restart
	@echo "✓ Containers restarted"

logs:
	docker compose -f $(COMPOSE_FILE) -p $(NAME) logs -f

ps:
	docker compose -f $(COMPOSE_FILE) -p $(NAME) ps


.PHONY: database
database:
	@echo "Opening a mysql shell as root inside the mariadb container..."
	@docker compose -f $(COMPOSE_FILE) -p $(NAME) exec mariadb bash -lc "mysql -uroot -p"

clean: down
	@echo "Removing volumes..."
	docker compose -f $(COMPOSE_FILE) -p $(NAME) down -v
	@echo "✓ Volumes removed"

fclean: clean
	@echo "Removing all $(NAME) images..."
	docker rmi inception-mariadb inception-wordpress inception-nginx 2>/dev/null || true
	@echo "Removing dangling images..."
	docker image prune -f
	@echo "✓ Full cleanup complete"

.DEFAULT_GOAL := help




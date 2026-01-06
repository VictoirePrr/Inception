NAME = inception

all: up

up:
	@echo "Starting Inception containers..."
	docker compose -f srcs/docker-compose.yml -p $(NAME) up --build -d

down:
	@echo "Stopping Inception containers..."
	docker compose -f srcs/docker-compose.yml -p $(NAME) down




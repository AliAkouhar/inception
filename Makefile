COMPOSE_FILE = src/docker-compose.yml
DATA_DIR = /home/aakouhar/data

all: up

up: build
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@docker compose -f $(COMPOSE_FILE) up -d

build:
	@docker compose -f $(COMPOSE_FILE) build

down:
	@docker compose -f $(COMPOSE_FILE) down

clean: down
	@docker compose -f $(COMPOSE_FILE) down -v
	@docker system prune -af

fclean: clean
	@sudo rm -rf $(DATA_DIR)
	@docker system prune -af --volumes

re: fclean all

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

status:
	@docker compose -f $(COMPOSE_FILE) ps

.PHONY: all up build down clean fclean re logs status
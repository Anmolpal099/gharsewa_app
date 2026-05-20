# Gharsewa Backend - Docker Commands

# Start all containers
up:
	docker-compose up -d

# Stop all containers
down:
	docker-compose down

# Build containers
build:
	docker-compose build

# View logs
logs:
	docker-compose logs -f

# SSH into app container
shell:
	docker-compose exec app bash

# Run artisan commands
artisan:
	docker-compose exec app php artisan $(cmd)

# Run migrations
migrate:
	docker-compose exec app php artisan migrate

# Run seeders
seed:
	docker-compose exec app php artisan db:seed

# Fresh migration with seed
fresh:
	docker-compose exec app php artisan migrate:fresh --seed

# Install composer dependencies
composer:
	docker-compose exec app composer install

# Clear all caches
clear:
	docker-compose exec app php artisan optimize:clear

# Initialize Laravel project (first time setup)
init:
	docker-compose up -d
	docker-compose exec app bash setup.sh

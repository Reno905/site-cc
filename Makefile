# Case Platform Makefile

.PHONY: help install start stop restart build logs clean test lint

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Environment setup
install: ## Install and setup the project
	@echo "Installing Case Platform..."
	@cp backend/.env.example backend/.env || true
	@cp websocket/.env.example websocket/.env || true
	@cp frontend/.env.example frontend/.env || true
	@echo "Environment files created. Please configure them before starting."

# Docker commands
start: ## Start all services
	@echo "Starting Case Platform services..."
	@docker-compose up -d

start-dev: ## Start development services with hot reload
	@echo "Starting Case Platform in development mode..."
	@docker-compose --profile dev up -d

stop: ## Stop all services
	@echo "Stopping Case Platform services..."
	@docker-compose down

restart: ## Restart all services
	@echo "Restarting Case Platform services..."
	@docker-compose restart

build: ## Build all Docker images
	@echo "Building Case Platform images..."
	@docker-compose build --no-cache

rebuild: ## Rebuild and restart all services
	@echo "Rebuilding Case Platform..."
	@docker-compose down
	@docker-compose build --no-cache
	@docker-compose up -d

# Backend commands
backend-install: ## Install backend dependencies
	@echo "Installing backend dependencies..."
	@docker-compose exec php composer install

backend-setup: ## Setup Laravel backend
	@echo "Setting up Laravel backend..."
	@docker-compose exec php php artisan key:generate
	@docker-compose exec php php artisan migrate
	@docker-compose exec php php artisan db:seed
	@docker-compose exec php php artisan voyager:install
	@docker-compose exec php php artisan storage:link

backend-shell: ## Access backend shell
	@docker-compose exec php bash

backend-artisan: ## Run artisan command (usage: make backend-artisan cmd="migrate")
	@docker-compose exec php php artisan $(cmd)

backend-test: ## Run backend tests
	@docker-compose exec php vendor/bin/phpunit

backend-lint: ## Run backend linting
	@docker-compose exec php vendor/bin/pint

# Frontend commands
frontend-install: ## Install frontend dependencies
	@echo "Installing frontend dependencies..."
	@docker-compose exec frontend npm install

frontend-build: ## Build frontend for production
	@echo "Building frontend..."
	@docker-compose exec frontend npm run build

frontend-shell: ## Access frontend shell
	@docker-compose exec frontend sh

frontend-test: ## Run frontend tests
	@docker-compose exec frontend npm test

frontend-lint: ## Run frontend linting
	@docker-compose exec frontend npm run lint

# WebSocket commands
websocket-install: ## Install WebSocket dependencies
	@echo "Installing WebSocket dependencies..."
	@docker-compose exec websocket npm install

websocket-shell: ## Access WebSocket shell
	@docker-compose exec websocket sh

websocket-test: ## Run WebSocket tests
	@docker-compose exec websocket npm test

websocket-lint: ## Run WebSocket linting
	@docker-compose exec websocket npm run lint

# Database commands
db-migrate: ## Run database migrations
	@docker-compose exec php php artisan migrate

db-seed: ## Seed database with test data
	@docker-compose exec php php artisan db:seed

db-fresh: ## Fresh database with migrations and seeds
	@docker-compose exec php php artisan migrate:fresh --seed

db-backup: ## Backup database
	@echo "Creating database backup..."
	@docker-compose exec mysql mysqldump -u case_user -pcase_password case_platform > backup_$(shell date +%Y%m%d_%H%M%S).sql

db-restore: ## Restore database from backup (usage: make db-restore file=backup.sql)
	@echo "Restoring database from $(file)..."
	@docker-compose exec -T mysql mysql -u case_user -pcase_password case_platform < $(file)

# Logs and monitoring
logs: ## Show all services logs
	@docker-compose logs -f

logs-backend: ## Show backend logs
	@docker-compose logs -f php

logs-frontend: ## Show frontend logs
	@docker-compose logs -f frontend

logs-websocket: ## Show WebSocket logs
	@docker-compose logs -f websocket

logs-nginx: ## Show Nginx logs
	@docker-compose logs -f nginx

logs-mysql: ## Show MySQL logs
	@docker-compose logs -f mysql

logs-redis: ## Show Redis logs
	@docker-compose logs -f redis

# Testing
test: backend-test frontend-test websocket-test ## Run all tests

test-coverage: ## Run tests with coverage
	@docker-compose exec php vendor/bin/phpunit --coverage-html coverage

# Linting
lint: backend-lint frontend-lint websocket-lint ## Run all linting

# Cache and optimization
cache-clear: ## Clear all caches
	@docker-compose exec php php artisan cache:clear
	@docker-compose exec php php artisan config:clear
	@docker-compose exec php php artisan route:clear
	@docker-compose exec php php artisan view:clear

cache-optimize: ## Optimize for production
	@docker-compose exec php php artisan config:cache
	@docker-compose exec php php artisan route:cache
	@docker-compose exec php php artisan view:cache

# Maintenance
clean: ## Clean up containers and volumes
	@echo "Cleaning up..."
	@docker-compose down -v
	@docker system prune -f

clean-all: ## Clean up everything including images
	@echo "Cleaning up everything..."
	@docker-compose down -v --rmi all
	@docker system prune -a -f

# Production deployment
deploy-prod: ## Deploy to production
	@echo "Deploying to production..."
	@git pull origin main
	@docker-compose -f docker-compose.prod.yml down
	@docker-compose -f docker-compose.prod.yml build
	@docker-compose -f docker-compose.prod.yml up -d
	@make cache-optimize

# Health checks
health: ## Check service health
	@echo "Checking service health..."
	@docker-compose ps
	@curl -f http://localhost/health || echo "Backend health check failed"
	@curl -f http://localhost:3001/health || echo "WebSocket health check failed"

# Security
security-scan: ## Run security scans
	@echo "Running security scans..."
	@docker-compose exec php composer audit
	@docker-compose exec frontend npm audit
	@docker-compose exec websocket npm audit

# Monitoring
monitor: ## Show system resource usage
	@echo "System resource usage:"
	@docker stats --no-stream

# Quick development setup
dev-setup: install start-dev backend-install backend-setup frontend-install ## Quick development setup

# Full reset (be careful!)
reset: clean install start backend-setup ## Full project reset
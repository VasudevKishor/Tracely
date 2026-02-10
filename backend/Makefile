.PHONY: help build run test clean docker-up docker-down migrate setup

# Variables
APP_NAME=tracely-backend
MAIN_FILE=main.go

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Set up development environment
	@echo "Setting up development environment..."
	@cp .env.example .env
	@echo "Installing dependencies..."
	@go mod download
	@echo "Creating database..."
	@createdb tracely_dev || true
	@echo "Setup complete! Edit .env file with your configuration."

build: ## Build the application
	@echo "Building $(APP_NAME)..."
	@go build -o bin/$(APP_NAME) $(MAIN_FILE)

run: ## Run the application
	@echo "Running $(APP_NAME)..."
	@go run $(MAIN_FILE)

dev: ## Run with hot reload (requires air)
	@echo "Running in development mode with hot reload..."
	@air

# Testing
.PHONY: test test-unit test-integration test-coverage

test: test-unit

test-unit:
	@echo "Running unit tests..."
	go test ./... -v -short

test-integration:
	@echo "Running integration tests..."
	go test ./... -v -tags=integration

test-coverage:
	@echo "Running tests with coverage..."
	go test ./... -coverprofile=coverage.out
	go tool cover -func=coverage.out

test-html-coverage:
	@echo "Generating HTML coverage report..."
	go test ./... -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html
	@echo "Open coverage.html in your browser"

test-services:
	@echo "Testing services..."
	go test ./services -v

test-handlers:
	@echo "Testing handlers..."
	go test ./handlers -v

test-models:
	@echo "Testing models..."
	go test ./models -v

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@rm -rf bin/
	@rm -f coverage.out coverage.html

docker-build: ## Build Docker image
	@echo "Building Docker image..."
	@docker build -t $(APP_NAME):latest .

docker-up: ## Start Docker containers
	@echo "Starting Docker containers..."
	@docker-compose up -d

docker-down: ## Stop Docker containers
	@echo "Stopping Docker containers..."
	@docker-compose down

docker-logs: ## View Docker logs
	@docker-compose logs -f backend

docker-restart: docker-down docker-up ## Restart Docker containers

migrate: ## Run database migrations
	@echo "Running database migrations..."
	@go run $(MAIN_FILE) migrate

fmt: ## Format code
	@echo "Formatting code..."
	@go fmt ./...

lint: ## Run linter
	@echo "Running linter..."
	@golangci-lint run

install-tools: ## Install development tools
	@echo "Installing development tools..."
	@go install github.com/cosmtrek/air@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

deps: ## Download dependencies
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy

deps-update: ## Update dependencies
	@echo "Updating dependencies..."
	@go get -u ./...
	@go mod tidy

psql: ## Connect to PostgreSQL database
	@psql tracely_dev

db-reset: ## Reset database (WARNING: destroys all data)
	@echo "Resetting database..."
	@dropdb tracely_dev || true
	@createdb tracely_dev
	@echo "Database reset complete."

prod-build: ## Build for production
	@echo "Building for production..."
	@CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o bin/$(APP_NAME) $(MAIN_FILE)

all: clean build ## Clean and build

.DEFAULT_GOAL := help

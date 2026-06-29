.PHONY: build run test clean migrate-up migrate-down docker-build docker-up docker-down lint swagger

# Variables
APP_NAME=pos-golang
BUILD_DIR=./bin
MAIN_FILE=./cmd/api/main.go

# Build
build:
	go build -o $(BUILD_DIR)/$(APP_NAME) $(MAIN_FILE)

# Run
run:
	go run $(MAIN_FILE)

# Test
test:
	go test -v ./...

test-coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html

# Lint
lint:
	golangci-lint run ./...

# Docker
docker-build:
	docker build -t $(APP_NAME) .

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

# Migration
migrate-up:
	go run ./cmd/migrate/main.go up

migrate-down:
	go run ./cmd/migrate/main.go down

# Swagger
swagger:
	swag init -g $(MAIN_FILE) -o ./docs

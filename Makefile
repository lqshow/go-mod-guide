SHELL := /bin/bash

BUILD_IMAGE := golang:alpine
REGISTRY := docker.io/lqshow
IMAGE_NAME := $(REGISTRY)/go-mod-guide
VERSION := $(shell git rev-parse --short HEAD)

all: build

.PHONY: version
version:
	@echo $(VERSION)

.PHONY: check
check: format vet lint

.PHONY: format
format:
	@echo "go fmt"
	@go fmt ./...
	@echo "ok"

.PHONY: vet
vet:
	@echo "go vet"
	@go vet ./...
	@echo "ok"

.PHONY: lint
lint:
	@echo "golint"
	@golint ./...
	@echo "ok"

.PHONY: build
build: check
	@mkdir -p ./bin
	@CGO_ENABLED=0 GOARCH=amd64 go build -a -installsuffix cgo -o ./bin/server .
	@echo "ok"

.PHONY: run
run:
	@bin/server

.PHONY: build-image
build-image:
	@docker build -t $(IMAGE_NAME):$(VERSION) -f Dockerfile --build-arg BUILD_IMAGE=$(BUILD_IMAGE) .

.PHONY: run-container
run-container:
	@docker run -it --rm  -p 3000:1323 $(IMAGE_NAME):$(VERSION)

.PHONY: clean
clean:
	@rm -rf ./bin
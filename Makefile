#========================================================================
# Copyright Universidade Federal do Espirito Santo (Ufes)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#========================================================================

SHELL := /bin/sh

DOCKER ?= docker
COMPOSE ?= $(DOCKER) compose

# Registry/image settings used by tag/push targets.
REGISTRY ?= ghcr.io
IMAGE_NAMESPACE ?= joaofazolo/boca-docker
IMAGE_TAG ?= 1.2.2

# Stack settings used by swarm targets.
STACK_NAME ?= boca-stack

# Super-linter settings.
LINTER_IMAGE ?= ghcr.io/super-linter/super-linter:latest

.PHONY: help \
        docker-images docker-containers \
        up-prod down-prod \
        build-dev up-dev down-dev \
        stack-deploy stack-services stack-rm \
        login-ghcr tag-images push-images \
        lint

help:
	@echo "Available targets:"
	@echo "  make docker-images      - docker image ls"
	@echo "  make docker-containers  - docker container ls -a"
	@echo "  make up-prod            - docker compose up (prod override)"
	@echo "  make down-prod          - docker compose down (prod override)"
	@echo "  make build-dev          - build boca-base, boca-web and boca-jail images"
	@echo "  make up-dev             - docker compose up (dev override)"
	@echo "  make down-dev           - docker compose down (dev override)"
	@echo "  make stack-deploy       - deploy stack in Docker Swarm"
	@echo "  make stack-services     - list services from deployed stack"
	@echo "  make stack-rm           - remove stack from Docker Swarm"
	@echo "  make login-ghcr         - docker login ghcr.io"
	@echo "  make tag-images         - tag local images for registry publish"
	@echo "  make push-images        - push tagged images to registry"
	@echo "  make lint               - run Super-Linter"
	@echo ""
	@echo "Configurable vars:"
	@echo "  REGISTRY=$(REGISTRY)"
	@echo "  IMAGE_NAMESPACE=$(IMAGE_NAMESPACE)"
	@echo "  IMAGE_TAG=$(IMAGE_TAG)"
	@echo "  STACK_NAME=$(STACK_NAME)"

docker-images:
	$(DOCKER) image ls

docker-containers:
	$(DOCKER) container ls -a

up-prod:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml up -d

down-prod:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml down

build-dev:
	$(DOCKER) build -t boca-base . -f docker/dev/base/Dockerfile
	$(DOCKER) build -t boca-web . -f docker/dev/web/Dockerfile
	$(DOCKER) build -t boca-jail . -f docker/dev/jail/Dockerfile

up-dev:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml up -d

down-dev:
	$(COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml down

stack-deploy:
	$(DOCKER) stack deploy --compose-file docker-compose.yml -c docker-compose.prod.yml $(STACK_NAME)

stack-services:
	$(DOCKER) stack services $(STACK_NAME)

stack-rm:
	$(DOCKER) stack rm $(STACK_NAME)

login-ghcr:
	$(DOCKER) login $(REGISTRY)

tag-images:
	$(DOCKER) tag boca-web $(REGISTRY)/$(IMAGE_NAMESPACE)/boca-web:$(IMAGE_TAG)
	$(DOCKER) tag boca-jail $(REGISTRY)/$(IMAGE_NAMESPACE)/boca-jail:$(IMAGE_TAG)

push-images:
	$(DOCKER) push $(REGISTRY)/$(IMAGE_NAMESPACE)/boca-web:$(IMAGE_TAG)
	$(DOCKER) push $(REGISTRY)/$(IMAGE_NAMESPACE)/boca-jail:$(IMAGE_TAG)

lint:
	$(DOCKER) run --rm \
		-e ACTIONS_RUNNER_DEBUG=true \
		-e RUN_LOCAL=true \
		--env-file .github/super-linter.env \
		-v "$$PWD":/tmp/lint \
		$(LINTER_IMAGE)

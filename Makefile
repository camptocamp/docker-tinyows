DOCKER_TAG ?= latest
TINYOWS_BRANCH ?= main
DOCKER_IMAGE = camptocamp/tinyows
export DOCKER_BUILDKIT = 1
ROOT = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
GID = $(shell id -g)
UID = $(shell id -u)

#Get the docker version (must use the same version for acceptance tests)
DOCKER_VERSION_ACTUAL = $(shell docker version --format '{{.Server.Version}}')
ifeq ($(DOCKER_VERSION_ACTUAL),)
DOCKER_VERSION = 1.12.0
else
DOCKER_VERSION = $(DOCKER_VERSION_ACTUAL)
endif

DOCKER_COMPOSE_VERSION = 1.29.2

all: acceptance

.PHONY: pull
pull:
	for image in `find -name Dockerfile | xargs grep --no-filename ^FROM | awk '{print $$2}'`; do docker pull $$image; done


.PHONY: build
build:
	docker build --tag=$(DOCKER_IMAGE):$(DOCKER_TAG) --build-arg=TINYOWS_BRANCH=$(TINYOWS_BRANCH) .

.PHONY: build_acceptance_config
build_acceptance_config:
	docker build --tag=$(DOCKER_IMAGE)_acceptance_config:$(DOCKER_TAG) acceptance_tests/config

.PHONY: build_acceptance
build_acceptance: build_acceptance_config
	@echo "Docker version: $(DOCKER_VERSION)"
	@echo "Docker-compose version: $(DOCKER_COMPOSE_VERSION)"
	docker build --build-arg DOCKER_VERSION="$(DOCKER_VERSION)" --build-arg DOCKER_COMPOSE_VERSION="$(DOCKER_COMPOSE_VERSION)" -t $(DOCKER_IMAGE)_acceptance:$(DOCKER_TAG) acceptance_tests

.PHONY: acceptance
acceptance: build_acceptance build
	mkdir -p acceptance_tests/junitxml && touch acceptance_tests/junitxml/results.xml
	docker run --rm -e DOCKER_TAG=$(DOCKER_TAG) -v /var/run/docker.sock:/var/run/docker.sock -v $(ROOT)/acceptance_tests/junitxml:/tmp/junitxml $(DOCKER_IMAGE)_acceptance:$(DOCKER_TAG)

.PHONY: clean
clean:
	rm -rf acceptance_tests/junitxml/ server/build server/target
	(cd src && git clean -xf) || true

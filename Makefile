GIT_PROJECT ?= $(shell GIT_PROJECT=$$(git remote get-url origin); GIT_PROJECT=$${GIT_PROJECT%/*}; GIT_PROJECT=$${GIT_PROJECT\#\#*/};echo $$GIT_PROJECT)
GIT_REPO_NAME ?= $(shell XX=$$(git remote get-url origin); XX=$${XX\#\#*/};echo $${XX%%.git*})
TARGET_PLATFORM ?= rhel7
DOCKER_TARGET_REGISTRY ?= harbor.transmit.im/oak/
DOCKER_SOURCE_REGISTRY ?= harbor.transmit.im/dockers/
BUILD_NUMBER ?= 1
GIT_LAST_COMMIT_ID ?= $(shell git rev-parse --short HEAD)
GIT_CURRENT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
DOCKER_TARGET_IMAGE_TAG ?= $(BUILD_NUMBER)-$(subst /,-,$(GIT_CURRENT_BRANCH))-$(GIT_LAST_COMMIT_ID)
DOCKER_TARGET_IMAGE_NAME ?= $(GIT_PROJECT)-$(GIT_REPO_NAME)

DOCKER_TARGET_IMAGE ?= $(DOCKER_TARGET_REGISTRY)$(DOCKER_TARGET_IMAGE_NAME):$(DOCKER_TARGET_IMAGE_TAG)
DOCKER_BUILD_WORKSPACE_SUBDIR ?= .
DOCKER_BUILD_WORKSPACE_DIR ?= $(shell realpath "$(shell git rev-parse --show-toplevel)/$(DOCKER_BUILD_WORKSPACE_SUBDIR)")
NODEJS_SOURCE ?= https://nodejs.org/dist/v12.13.0/node-v12.13.0-linux-x64.tar.gz

NODEJS_SOURCE_FILE ?= $(lastword $(subst /, ,$(NODEJS_SOURCE)))

.PHONY: test docker-build all clean build docker-clean help $(DOCKER_BUILD_WORKSPACE_DIR)-clean docker-push

all: docker-build


help:
	$(info $ DIALOG Build-o-matic usage:)
	$(info $ 	make test 		- Run app unit tests in $$TARGET_PLATFORM docker image)
	$(info $ 	make docker-build	- Build app inside docker and build docker image of $$TARGET_PLATFORM)
	$(info $ 	make build		- Build app in project root dir. No docker used)
	$(info $ 				  Image name controlled by envs: $$DOCKER_TARGET_REGISTRY$$DOCKER_TARGET_IMAGE_NAME:$$DOCKER_TARGET_IMAGE_TAG)
	$(info $ 	make clean		- Clean build and node_modules dirs, run docker-clean)
	$(info $ 	make docker-clean	- Remove target docker image and any leftover docker networks)
	$(info $ 	make .npmrc		- Generate .npmrc from NPM_SOURCE_REEGISTRY and NPM_SOURCE_REGISTRY_TOKEN env vars)


build: build/$(NODEJS_SOURCE_FILE)

build/$(NODEJS_SOURCE_FILE):
	@mkdir -p build
	cd build && curl $(NODEJS_SOURCE) -OL


docker-build: build
ifeq "$(shell docker images -q $(DOCKER_TARGET_IMAGE))" ""
	@echo \*\*\* [$@] Compiling code and building docker image
	docker build -f Dockerfile.$(TARGET_PLATFORM) -t $(DOCKER_TARGET_IMAGE) "$(DOCKER_BUILD_WORKSPACE_DIR)"
	@echo \*\*\* [$@] Docker image $(DOCKER_TARGET_IMAGE) built successfully
else
	@echo \*\*\* [$@] Docker image $(DOCKER_TARGET_IMAGE) is already built. Run "make docker-clean" to wipe it
endif

clean: docker-clean
	@echo \*\*\* [$@] Not implemented

test:
	@echo \*\*\* [$@] Not implemented


docker-push:
	docker push $(DOCKER_TARGET_IMAGE)
	
docker-clean:
ifneq "$(shell docker images -q $(DOCKER_TARGET_IMAGE))" ""
	@echo \*\*\* [$@] Removing built image
	docker rmi -f $(DOCKER_TARGET_IMAGE)
endif

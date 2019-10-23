GIT_PROJECT ?= $(shell GIT_PROJECT=$$(git remote get-url origin); GIT_PROJECT=$${GIT_PROJECT%/*}; GIT_PROJECT=$${GIT_PROJECT\#\#*/};echo $$GIT_PROJECT)
GIT_REPO_NAME ?= $(shell XX=$$(git remote get-url origin); XX=$${XX\#\#*/};echo $${XX%%.git*})
TARGET_PLATFORM ?= rhel7
DOCKER_TARGET_REGISTRY ?= harbor.transmit.im/oak/
DOCKER_SOURCE_REGISTRY ?= 10.36.131.149:5000
BUILD_NUMBER ?= 1
GIT_LAST_COMMIT_ID ?= $(shell git rev-parse --short HEAD)
GIT_CURRENT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
DOCKER_TARGET_IMAGE_TAG ?= $(BUILD_NUMBER)-$(subst /,-,$(GIT_CURRENT_BRANCH))-$(GIT_LAST_COMMIT_ID)
DOCKER_TARGET_IMAGE_NAME ?= $(GIT_PROJECT)-$(GIT_REPO_NAME)

DOCKER_TARGET_IMAGE ?= $(DOCKER_TARGET_REGISTRY)$(DOCKER_TARGET_IMAGE_NAME):$(DOCKER_TARGET_IMAGE_TAG)
DOCKER_BUILD_WORKSPACE_SUBDIR ?= .
DOCKER_BUILD_WORKSPACE_DIR ?= $(shell realpath "$(shell git rev-parse --show-toplevel)/$(DOCKER_BUILD_WORKSPACE_SUBDIR)")

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


docker-build:
ifeq "$(shell docker images -q $(DOCKER_TARGET_IMAGE))" ""
	@echo \*\*\* [$@] Compiling code and building docker image
	docker build -f Dockerfile.$(TARGET_PLATFORM) -t $(DOCKER_TARGET_IMAGE) $(DOCKER_BUILD_WORKSPACE_DIR)
	@echo \*\*\* [$@] Docker image $(DOCKER_TARGET_IMAGE) built successfully
else
	@echo \*\*\* [$@] Docker image $(DOCKER_TARGET_IMAGE) is already built. Run "make docker-clean" to wipe it
endif

build:
	@echo \*\*\* [$@] Not implemented

clean: docker-clean
	@echo \*\*\* [$@] Not implemented


docker-push:
	docker push $(DOCKER_TARGET_IMAGE)
	
docker-clean:
ifneq "$(shell docker images -q $(DOCKER_TARGET_IMAGE))" ""
	@echo \*\*\* [$@] Removing built image
	docker rmi -f $(DOCKER_TARGET_IMAGE)
endif

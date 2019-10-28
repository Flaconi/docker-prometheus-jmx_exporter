ifneq (,)
.error This Makefile requires GNU Make.
endif

.PHONY: help build rebuild tag test pull push login

CURRENT_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

DIR = .
FILE = Dockerfile
IMAGE = flaconi/prometheus-jmx-exporter
TAG = latest

ARG_GOMPLATE_VERSION = v3.3.1


help:
	@echo "build       Build the image (TAG is optional)"
	@echo "rebuild     Rebuild the image without cache (TAG is optional)"
	@echo "test        Test the image"

build:
	docker build --build-arg GOMPLATE_VERSION=$(ARG_GOMPLATE_VERSION) -t $(IMAGE):$(TAG) -f $(DIR)/$(FILE) $(DIR)

rebuild: pull
	docker build --build-arg GOMPLATE_VERSION=$(ARG_GOMPLATE_VERSION) --no-cache -t $(IMAGE):$(TAG) -f $(DIR)/$(FILE) $(DIR)


test:
	echo "Not yet implemented"

pull:
	@grep -E '^\s*FROM' Dockerfile \
		| sed -e 's/^FROM//g' -e 's/[[:space:]][[:space:]]*as[[:space:]][[:space:]]*.*$$//g' \
		| sed -e 's/$${GOMPLATE_VERSION}/$(ARG_GOMPLATE_VERSION)/g' \
		| xargs -n1 docker pull

login:
	yes | docker login --username $(USER) --password $(PASS)

tag:
	docker tag $(IMAGE):$(TAG) $(IMAGE):$(NEW_TAG)

push:
	docker push $(IMAGE):$(TAG)

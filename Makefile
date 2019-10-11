ifneq (,)
.error This Makefile requires GNU Make.
endif

.PHONY: help build rebuild tag test pull push login

CURRENT_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

DIR = .
FILE = Dockerfile
IMAGE = flaconi/prometheus-jmx-exporter
TAG = latest

help:
	@echo "build       Build the image (TAG is optional)"
	@echo "rebuild     Rebuild the image without cache (TAG is optional)"
	@echo "test        Test the image"

build:
	docker build -t $(IMAGE):$(TAG) -f $(DIR)/$(FILE) $(DIR)

rebuild: pull
	docker build --no-cache -t $(IMAGE):$(TAG) -f $(DIR)/$(FILE) $(DIR)

test:
	echo "Not yet implemented"

pull:
	@grep -E '^\s*FROM' Dockerfile \
		| sed -e 's/^FROM//g' -e 's/[[:space:]]*as[[:space:]]*.*$$//g' \
		| xargs -n1 docker pull;

login:
	yes | docker login --username $(USER) --password $(PASS)

tag:
	docker tag $(IMAGE):$(TAG) $(IMAGE):$(NEW_TAG)

push:
	docker push $(IMAGE):$(TAG)

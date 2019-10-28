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


define JMX_RULES
- pattern : kafka.cluster<type=(.+), name=(.+), topic=(.+), partition=(.+)><>Value
  name: kafka_cluster_$$1_$$2
  labels:
    topic: "$$3"
    partition: "$$4"
endef
export JMX_RULES
test:
	@docker stop jmx-exporter 2>/dev/null || true
	@echo "--------------------------------------------------------------------------------"
	@echo "Starting container"
	@echo "--------------------------------------------------------------------------------"
	docker run -d --rm $$(tty -s && echo "-it" || echo) \
		--name jmx-exporter \
		-e JMX_HOST=localhost \
		-e JMX_PORT=10991 \
		-e JMX_RULES \
		-p 1992:10990 \
		$(IMAGE)
	@sleep 5
	@echo "--------------------------------------------------------------------------------"
	@echo "Scraping metrics"
	@echo "--------------------------------------------------------------------------------"
	@if ! curl -sS localhost:1992; then \
		echo "--------------------------------------------------------------------------------"; \
		echo "Docker logs"; \
		echo "--------------------------------------------------------------------------------"; \
		docker logs jmx-exporter || true; \
		docker stop jmx-exporter 2>/dev/null || true; \
		false; \
	else \
		echo "--------------------------------------------------------------------------------"; \
		echo "Docker logs"; \
		echo "--------------------------------------------------------------------------------"; \
		docker logs jmx-exporter || true; \
		docker stop jmx-exporter 2>/dev/null || true; \
	fi

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

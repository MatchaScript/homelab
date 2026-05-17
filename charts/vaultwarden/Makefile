# vaultwarden chart test entry point.
# Local and CI runs both drive the same Make targets so behaviour cannot drift.

KIND_CLUSTER       ?= vaultwarden-test
KIND_NODE_IMAGE    ?= kindest/node:v1.34.3

CHAINSAW_VERSION   ?= v0.2.14

CHART_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TEST_DIR  := $(CHART_DIR)/test
REPO_ROOT := $(abspath $(CHART_DIR)/../..)

export CHART_DIR TEST_DIR REPO_ROOT
export KIND_NODE_IMAGE

.PHONY: help test test-up test-down test-fresh lint template

help:
	@echo "Targets:"
	@echo "  make test          - kind up + chainsaw test (full cycle, leaves cluster on failure)"
	@echo "  make test-up       - kind create only"
	@echo "  make test-down     - kind delete"
	@echo "  make test-fresh    - test-down + test"
	@echo "  make lint          - helm lint + helm template smoke checks"

test: test-up
	chainsaw test --config $(TEST_DIR)/chainsaw.yaml $(TEST_DIR)
	@echo "All tests passed; tearing the cluster down."
	$(MAKE) test-down

test-up:
	@if ! kind get clusters 2>/dev/null | grep -qx $(KIND_CLUSTER); then \
	  kind create cluster --name $(KIND_CLUSTER) --image $(KIND_NODE_IMAGE); \
	fi

test-down:
	@if kind get clusters 2>/dev/null | grep -qx $(KIND_CLUSTER); then \
	  kind delete cluster --name $(KIND_CLUSTER); \
	fi

test-fresh: test-down test

lint:
	helm lint $(CHART_DIR) --values $(CHART_DIR)/ci/test-values.yaml
	helm template lint-default $(CHART_DIR) >/dev/null
	helm template lint-ci $(CHART_DIR) \
	  --values $(CHART_DIR)/ci/test-values.yaml >/dev/null
	helm template lint-test $(CHART_DIR) \
	  --values $(TEST_DIR)/01-default/vaultwarden-values.yaml >/dev/null

template:
	helm template smoke $(CHART_DIR) \
	  --values $(CHART_DIR)/ci/test-values.yaml

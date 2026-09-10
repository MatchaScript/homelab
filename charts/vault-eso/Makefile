# vault-eso chart test entry point.
# Local and CI runs both go through `prereqs-install.sh` so behaviour cannot drift.

KIND_CLUSTER       ?= vault-eso-test
KIND_NODE_IMAGE    ?= kindest/node:v1.34.3

ESO_VERSION        ?= 0.20.4
VAULT_VERSION      ?= 0.31.0
CHAINSAW_VERSION   ?= v0.2.14

CHART_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TEST_DIR  := $(CHART_DIR)/test
REPO_ROOT := $(abspath $(CHART_DIR)/../..)

export CHART_DIR TEST_DIR REPO_ROOT
export KIND_NODE_IMAGE
export ESO_VERSION VAULT_VERSION

.PHONY: help test test-up test-down test-fresh prereqs lint template

help:
	@echo "Targets:"
	@echo "  make test          - kind up + prereqs + chainsaw test (full cycle, leaves cluster on failure)"
	@echo "  make test-up       - kind create + prereqs install only"
	@echo "  make test-down     - kind delete"
	@echo "  make test-fresh    - test-down + test"
	@echo "  make prereqs       - re-run prereqs-install.sh against the current cluster"
	@echo "  make lint          - helm lint + helm template smoke checks"

test: test-up
	chainsaw test --config $(TEST_DIR)/chainsaw.yaml $(TEST_DIR)
	@echo "All tests passed; tearing the cluster down."
	$(MAKE) test-down

test-up:
	@if ! kind get clusters 2>/dev/null | grep -qx $(KIND_CLUSTER); then \
	  kind create cluster --name $(KIND_CLUSTER) --image $(KIND_NODE_IMAGE); \
	fi
	$(MAKE) prereqs

test-down:
	@if kind get clusters 2>/dev/null | grep -qx $(KIND_CLUSTER); then \
	  kind delete cluster --name $(KIND_CLUSTER); \
	fi

test-fresh: test-down test

prereqs:
	$(TEST_DIR)/support/prereqs-install.sh

lint:
	helm lint $(CHART_DIR) --values $(CHART_DIR)/ci/test-values.yaml
	helm template lint-auth $(CHART_DIR) \
	  --values $(TEST_DIR)/01-auth-only/vault-eso-values.yaml >/dev/null
	helm template lint-roundtrip $(CHART_DIR) \
	  --values $(TEST_DIR)/02-secret-roundtrip/vault-eso-values.yaml >/dev/null
	helm template lint-templates $(CHART_DIR) \
	  --values $(TEST_DIR)/03-template-variants/vault-eso-values.yaml >/dev/null

template:
	helm template smoke $(CHART_DIR) \
	  --values $(TEST_DIR)/01-auth-only/vault-eso-values.yaml

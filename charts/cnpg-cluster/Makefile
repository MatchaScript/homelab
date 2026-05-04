# cnpg-cluster chart test entry point.
# Local and CI runs both go through `prereqs-install.sh` so behaviour cannot drift.

KIND_CLUSTER       ?= cnpg-cluster-test
KIND_NODE_IMAGE    ?= kindest/node:v1.34.3

CERT_MANAGER_VERSION   ?= v1.20.2
CNPG_VERSION           ?= 0.28.0
PLUGIN_BARMAN_VERSION  ?= 0.6.0
PROM_CRDS_VERSION      ?= 28.0.1
MINIO_OPERATOR_VERSION ?= 7.1.1
MINIO_TENANT_VERSION   ?= 7.1.1
CHAINSAW_VERSION       ?= v0.2.14

CHART_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TEST_DIR  := $(CHART_DIR)/test

export CHART_DIR TEST_DIR
export KIND_NODE_IMAGE
export CERT_MANAGER_VERSION CNPG_VERSION PLUGIN_BARMAN_VERSION
export PROM_CRDS_VERSION MINIO_OPERATOR_VERSION MINIO_TENANT_VERSION

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
	helm lint $(CHART_DIR)
	helm template lint-standalone $(CHART_DIR) \
	  --values $(TEST_DIR)/01-standalone-backup-restore/01-cluster.yaml >/dev/null
	helm template lint-replica $(CHART_DIR) \
	  --values $(TEST_DIR)/02-replica-from-objectstore/02-replica.yaml >/dev/null
	helm template lint-scheduled $(CHART_DIR) \
	  --values $(TEST_DIR)/03-scheduled-backup/01-cluster.yaml >/dev/null

template:
	helm template smoke $(CHART_DIR) \
	  --values $(TEST_DIR)/01-standalone-backup-restore/01-cluster.yaml

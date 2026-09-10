# ceph-multisite chart test entry point.
#
# This chart only renders three Rook CRs (CephObjectRealm,
# CephObjectZoneGroup, CephObjectZone). End-to-end reconciliation requires a
# real Rook Ceph cluster with OSDs, which is outside what kind in CI can
# host cheaply, so testing here is limited to `helm lint` and
# `helm template` against several values variants.

CHART_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CI_DIR    := $(CHART_DIR)/ci

.PHONY: help lint template

help:
	@echo "Targets:"
	@echo "  make lint     - helm lint + helm template across ci/ values variants"
	@echo "  make template - render each ci/ variant to stdout for inspection"

lint:
	helm lint $(CHART_DIR) --values $(CI_DIR)/test-values-new-realm.yaml
	helm lint $(CHART_DIR) --values $(CI_DIR)/test-values-pull-realm.yaml
	helm lint $(CHART_DIR) --values $(CI_DIR)/test-values-erasure-coded.yaml
	helm template lint-new-realm $(CHART_DIR) \
	  --values $(CI_DIR)/test-values-new-realm.yaml >/dev/null
	helm template lint-pull-realm $(CHART_DIR) \
	  --values $(CI_DIR)/test-values-pull-realm.yaml >/dev/null
	helm template lint-erasure-coded $(CHART_DIR) \
	  --values $(CI_DIR)/test-values-erasure-coded.yaml >/dev/null

template:
	@for v in $(CI_DIR)/test-values-*.yaml; do \
	  echo "==== $$v ===="; \
	  helm template smoke $(CHART_DIR) --values $$v; \
	done

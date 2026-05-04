#!/usr/bin/env bash
# Idempotently install everything the powerdns chart tests depend on:
#   1. cert-manager           (prereq for CNPG operator)
#   2. CloudNativePG operator (provides the Cluster CRD that backs powerdns)
#
# The powerdns chart itself no longer provisions a database, but the tests
# stand up a CNPG cluster via the in-tree charts/cnpg-cluster chart so that
# the schema ConfigMap → initdb integration is exercised end-to-end.
set -euo pipefail

CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.20.2}"
CNPG_VERSION="${CNPG_VERSION:-0.28.0}"

echo "==> Adding/updating Helm repos"
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo add cnpg https://cloudnative-pg.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null

echo "==> Installing cert-manager ${CERT_MANAGER_VERSION}"
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version "${CERT_MANAGER_VERSION}" \
  --set crds.enabled=true \
  --wait --timeout 5m

echo "==> Installing CloudNativePG operator ${CNPG_VERSION}"
helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system --create-namespace \
  --version "${CNPG_VERSION}" \
  --wait --timeout 5m

echo "==> Waiting for the CNPG Cluster CRD to be Established"
kubectl wait --for=condition=Established crd/clusters.postgresql.cnpg.io --timeout=2m

echo "==> Prereqs installed"

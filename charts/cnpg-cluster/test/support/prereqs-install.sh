#!/usr/bin/env bash
# Idempotently install everything the cnpg-cluster chart tests depend on,
# in dependency order:
#   1. cert-manager           (prereq for the barman-cloud plugin)
#   2. CloudNativePG operator
#   3. plugin-barman-cloud    (provides the ObjectStore CRD)
#   4. Prometheus operator CRDs (so PodMonitor / PrometheusRule render+install)
#   5. MinIO operator + tenant (S3 backend for tests)
set -euo pipefail

CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.20.2}"
CNPG_VERSION="${CNPG_VERSION:-0.28.0}"
PLUGIN_BARMAN_VERSION="${PLUGIN_BARMAN_VERSION:-0.6.0}"
PROM_CRDS_VERSION="${PROM_CRDS_VERSION:-28.0.1}"
MINIO_OPERATOR_VERSION="${MINIO_OPERATOR_VERSION:-7.1.1}"
MINIO_TENANT_VERSION="${MINIO_TENANT_VERSION:-7.1.1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Adding/updating Helm repos"
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo add cnpg https://cloudnative-pg.github.io/charts >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add minio-operator https://operator.min.io >/dev/null 2>&1 || true
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

echo "==> Installing plugin-barman-cloud ${PLUGIN_BARMAN_VERSION}"
helm upgrade --install plugin-barman-cloud cnpg/plugin-barman-cloud \
  --namespace cnpg-system \
  --version "${PLUGIN_BARMAN_VERSION}" \
  --wait --timeout 5m

echo "==> Installing Prometheus operator CRDs ${PROM_CRDS_VERSION}"
helm upgrade --install prometheus-crds prometheus-community/prometheus-operator-crds \
  --namespace monitoring --create-namespace \
  --version "${PROM_CRDS_VERSION}"

echo "==> Installing MinIO operator ${MINIO_OPERATOR_VERSION}"
helm upgrade --install operator minio-operator/operator \
  --namespace minio-system --create-namespace \
  --version "${MINIO_OPERATOR_VERSION}" \
  --wait --timeout 5m

echo "==> Installing MinIO tenant ${MINIO_TENANT_VERSION}"
helm upgrade --install tenant minio-operator/tenant \
  --namespace minio --create-namespace \
  --version "${MINIO_TENANT_VERSION}" \
  --values "${SCRIPT_DIR}/minio-tenant.yaml" \
  --wait --timeout 5m

echo "==> Waiting for the barman-cloud ObjectStore CRD to be Established"
kubectl wait --for=condition=Established crd/objectstores.barmancloud.cnpg.io --timeout=2m

echo "==> Prereqs installed"

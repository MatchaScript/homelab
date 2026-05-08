#!/usr/bin/env bash
# Idempotently install everything the keycloak chart tests depend on:
#   1. cert-manager           (prereq for CNPG operator)
#   2. CloudNativePG operator (provides the Cluster CRD that backs keycloak)
#   3. ingress-nginx          (validates the public/admin host split in the chart's Ingress)
#
# The keycloak chart itself does not provision a database; the tests stand up a
# CNPG cluster via the in-tree charts/cnpg-cluster chart.
set -euo pipefail

CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.20.2}"
CNPG_VERSION="${CNPG_VERSION:-0.28.0}"
INGRESS_NGINX_VERSION="${INGRESS_NGINX_VERSION:-4.13.3}"

echo "==> Adding/updating Helm repos"
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo add cnpg https://cloudnative-pg.github.io/charts >/dev/null 2>&1 || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
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

echo "==> Installing ingress-nginx ${INGRESS_NGINX_VERSION}"
# Use ClusterIP so in-cluster Jobs can curl the controller directly with Host headers.
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version "${INGRESS_NGINX_VERSION}" \
  --set controller.service.type=ClusterIP \
  --set controller.admissionWebhooks.enabled=false \
  --wait --timeout 5m

echo "==> Waiting for the CNPG Cluster CRD to be Established"
kubectl wait --for=condition=Established crd/clusters.postgresql.cnpg.io --timeout=2m

echo "==> Prereqs installed"

#!/usr/bin/env bash
# Idempotently install everything the vault-eso chart tests depend on:
#   1. external-secrets operator (provides SecretStore / ExternalSecret CRDs)
#   2. Vault in dev mode        (provides a KV-v2 backend at `secret/`
#                                 with the Kubernetes auth method enabled)
#
# Vault dev mode is intentional: the operator-side wiring (SecretStore,
# ServiceAccount, ExternalSecret) is what this chart owns and what we want
# to exercise. Vault HA / KMS unseal / production OIDC issuer wiring are
# out of scope; documented in the chart README.
set -euo pipefail

ESO_VERSION="${ESO_VERSION:-0.20.4}"
VAULT_VERSION="${VAULT_VERSION:-0.31.0}"
VAULT_NAMESPACE="${VAULT_NAMESPACE:-vault}"
VAULT_DEV_ROOT_TOKEN="${VAULT_DEV_ROOT_TOKEN:-root}"

echo "==> Adding/updating Helm repos"
helm repo add external-secrets https://charts.external-secrets.io >/dev/null 2>&1 || true
helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
helm repo update >/dev/null

echo "==> Installing external-secrets operator ${ESO_VERSION}"
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --version "${ESO_VERSION}" \
  --set installCRDs=true \
  --wait --timeout 5m

echo "==> Installing Vault (dev mode) ${VAULT_VERSION}"
helm upgrade --install vault hashicorp/vault \
  --namespace "${VAULT_NAMESPACE}" --create-namespace \
  --version "${VAULT_VERSION}" \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=${VAULT_DEV_ROOT_TOKEN}" \
  --set "injector.enabled=false" \
  --wait --timeout 5m

echo "==> Waiting for Vault pod to be Ready"
# The Vault StatefulSet uses updateStrategy: OnDelete, so `rollout status` is unavailable.
# Wait for pod readiness directly (covers fresh installs and re-runs).
kubectl -n "${VAULT_NAMESPACE}" wait --for=condition=Ready pod/vault-0 --timeout=2m

echo "==> Waiting for ESO CRDs to be Established"
for crd in \
    secretstores.external-secrets.io \
    clustersecretstores.external-secrets.io \
    externalsecrets.external-secrets.io ; do
  kubectl wait --for=condition=Established "crd/${crd}" --timeout=2m
done

echo "==> Configuring Vault: enable KV-v2 at secret/ + Kubernetes auth"
KUBE_HOST="https://kubernetes.default.svc"
KUBE_CA_B64="$(kubectl -n "${VAULT_NAMESPACE}" get secret \
  -o jsonpath='{.items[?(@.type=="kubernetes.io/service-account-token")].data.ca\.crt}' \
  | head -c 100000)"

# Fall back: read it from the in-cluster CA path mounted into the vault pod.
kubectl -n "${VAULT_NAMESPACE}" exec statefulset/vault -- sh -eu -c "
  export VAULT_TOKEN='${VAULT_DEV_ROOT_TOKEN}'
  export VAULT_ADDR='http://127.0.0.1:8200'

  # KV v2 is enabled by default in dev mode at secret/, so 'enable' may 409.
  vault secrets enable -version=2 -path=secret kv 2>/dev/null || true

  vault auth enable kubernetes 2>/dev/null || true

  vault write auth/kubernetes/config \
    kubernetes_host='${KUBE_HOST}' \
    disable_iss_validation=true

  # Broad read policy used by all tests; each test scopes its own role.
  vault policy write vault-eso-test - <<'POLICY'
path \"secret/data/*\" { capabilities = [\"read\"] }
path \"secret/metadata/*\" { capabilities = [\"read\"] }
POLICY
"

echo "==> Prereqs installed"

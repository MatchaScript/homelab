#!/usr/bin/env bash
# Create the S3 credentials Secret consumed by the cnpg-cluster chart.
# Mirrors the shape of an OBC-generated Secret:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#
# Usage: s3-secret.sh <namespace> <secret-name>
set -euo pipefail

NS="${1:?namespace required}"
NAME="${2:?secret name required}"

# Static MinIO credentials matching test/support/minio-tenant.yaml.
ACCESS_KEY="${MINIO_ACCESS_KEY:-minio}"
SECRET_KEY="${MINIO_SECRET_KEY:-minio123}"

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "${NS}" create secret generic "${NAME}" \
  --from-literal=AWS_ACCESS_KEY_ID="${ACCESS_KEY}" \
  --from-literal=AWS_SECRET_ACCESS_KEY="${SECRET_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

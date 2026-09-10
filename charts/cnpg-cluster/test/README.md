# cnpg-cluster Chart Tests

End-to-end tests for the `cnpg-cluster` Helm chart, driven by
[kyverno/chainsaw][chainsaw] against a local [kind][kind] cluster.

[chainsaw]: https://kyverno.github.io/chainsaw/
[kind]: https://kind.sigs.k8s.io/

## Prerequisites

- `kind`, `kubectl`, `helm`, `chainsaw` on PATH.
- Docker (or another container runtime kind supports).
- ~6 GB free RAM. The CNPG cluster + MinIO + operators add up.

## Layout

```
test/
├── chainsaw.yaml                       # Global chainsaw config
├── support/                            # Shared install scripts and values
│   ├── minio-tenant.yaml
│   ├── prereqs-install.sh
│   └── s3-secret.sh
├── 01-standalone-backup-restore/       # Backup → restore (backup CR + ObjectStore CR)
├── 02-replica-from-objectstore/        # Replica cluster from existing ObjectStore
└── 03-scheduled-backup/                # ScheduledBackup with immediate=true
```

## Running

From the chart directory (`homelab/charts/cnpg-cluster/`):

```bash
make test          # full cycle: kind up, prereqs, chainsaw, kind down on success
make test-up       # spin up kind + prereqs, leave it running
make test-down     # delete the kind cluster
make test-fresh    # test-down then test
make lint          # helm lint + helm template smoke checks
```

On test failure the kind cluster is **not** deleted, so you can inspect:

```bash
kubectl --context kind-cnpg-cluster-test get clusters.postgresql.cnpg.io -A
kubectl --context kind-cnpg-cluster-test logs -n cnpg-system deploy/cnpg-cloudnative-pg
```

Once you are done debugging, run `make test-down`.

## Pinned versions

The Makefile and `support/prereqs-install.sh` pin every dependency by
chart/image version. Bump the variables in lockstep.

## What is **not** tested here

This suite is intentionally narrower than the upstream chart's chainsaw
suite. See the design doc for the full rationale:
[`docs/superpowers/specs/2026-05-03-cnpg-cluster-chart-tests-design.md`](../../../docs/superpowers/specs/2026-05-03-cnpg-cluster-chart-tests-design.md).

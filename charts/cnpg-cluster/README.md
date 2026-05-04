# cnpg-cluster

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Opinionated Helm chart that deploys a [CloudNativePG][cnpg] `Cluster` wired
to the [`barman-cloud` plugin][barman-plugin] for WAL archiving and
backups via an `ObjectStore` custom resource.

This chart is **not** intended for general consumption — it tracks the
needs of the [`fjord` homelab cluster][fjord-readme] and intentionally
exposes a narrower surface than the upstream chart it was forked from.

[cnpg]: https://cloudnative-pg.io/
[barman-plugin]: https://github.com/cloudnative-pg/plugin-barman-cloud
[fjord-readme]: ../../README.md

## Fork notice

This chart is forked from the
[`cluster` chart in cloudnative-pg/charts][upstream] at the **v0.6.0**
fork point and is distributed under the Apache License 2.0. See
[`LICENSE`](./LICENSE) for the full license text and [`NOTICE`](./NOTICE)
for the attribution and a summary of homelab-specific modifications.

[upstream]: https://github.com/cloudnative-pg/charts/tree/main/charts/cluster

## Scope

Compared to upstream, this fork:

- Targets the **barman-cloud CNPG plugin** + an `ObjectStore` CR for
  archiving/backups/recovery, instead of the in-cluster
  `spec.backup.barmanObjectStore` block.
- Supports the **`postgresql` cluster type only** (PostGIS and
  TimescaleDB image/extension wiring removed).
- Supports **S3-compatible** object storage only (Azure Blob and GCS
  provider blocks removed).
- Expects backup credentials to be **provisioned out-of-band** (e.g. by
  an OBC / external secret) and referenced by name. The chart does not
  generate credential secrets.
- Does **not** ship: `recovery.method: import`, `ImageCatalog` /
  `ClusterImageCatalog` integration, managed `Database` CRs, the CNPG
  Console StatefulSet, or `helm test` hooks.

If you need any of the above, use the upstream chart directly.

## Prerequisites

- A Kubernetes cluster with the **CloudNativePG operator** installed
  (this chart does not install the operator).
- The **`barman-cloud` CNPG plugin** installed in the same cluster, so
  that `barmancloud.cnpg.io/v1` `ObjectStore` resources and the
  `barman-cloud.cloudnative-pg.io` `Cluster.spec.plugins` entry are
  reconciled.
- A pre-existing **S3 credential `Secret`** in the target namespace
  containing `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` keys, when
  `backups.enabled` is `true`. The default secret name is
  `<release>-cnpg-cluster-backup`; override with
  `backups.s3CredentialsSecret`.

## Installation

This chart lives in-tree at `homelab/charts/cnpg-cluster` and is not
published to a Helm repository. Install it directly from the path:

```console
helm upgrade --install <release> \
  --namespace <namespace> \
  --create-namespace \
  --values values.yaml \
  ./homelab/charts/cnpg-cluster
```

In the `fjord` cluster the chart is consumed via ArgoCD, with
per-instance overrides under `clusters/japan-east-fjord-1a/<app>/`.

## Values

The values schema is a trimmed subset of the upstream chart. Refer to
[`values.yaml`](./values.yaml) for the authoritative list and inline
documentation. Highlights specific to this fork:

| Key | Description |
| --- | --- |
| `backups.enabled` | Generates the `ObjectStore` CR and wires the `barman-cloud` plugin into the `Cluster` spec. |
| `backups.objectStoreName` | Overrides the generated `ObjectStore` name (default: `<fullname>-backup`). |
| `backups.s3CredentialsSecret` | Name of the existing `Secret` holding S3 credentials (default: `<fullname>-backup`). |
| `backups.destinationPath` | S3 destination URL passed through to the `ObjectStore`. |
| `backups.endpointURL` / `backups.endpointCA` | Endpoint overrides for S3-compatible providers (e.g. Ceph RGW, MinIO). |
| `backups.retentionPolicy` | Set on the `ObjectStore`, not on the `Cluster`. |
| `recovery.method: object_store` | Requires `recovery.objectStoreName` referencing an existing `ObjectStore` CR. |
| `replica.origin.objectStore.name` | For replica clusters: name of the source `ObjectStore` CR. |
| `cluster.imageName` | Plain image override; `imageCatalogRef` is not supported. |

## Generated resources

When rendered, the chart produces:

- A `postgresql.cnpg.io/v1` `Cluster`, with the `barman-cloud` plugin
  declared in `spec.plugins` (`isWALArchiver: true`) when backups are
  enabled.
- A `barmancloud.cnpg.io/v1` `ObjectStore` (when `backups.enabled`).
- Zero or more `postgresql.cnpg.io/v1` `ScheduledBackup` resources,
  always using `method: plugin` and the `barman-cloud` plugin
  configuration.
- Optional `Pooler`, `PodMonitor` and `PrometheusRule` resources
  matching the upstream behaviour.

## Tests

End-to-end tests live in [`test/`](./test/) and run on a local kind
cluster via chainsaw. From this directory:

```console
make test          # full cycle (kind up, prereqs, chainsaw, kind down)
make test-up       # just kind + prereqs
make test-down     # delete the kind cluster
make lint          # helm lint + helm template smoke checks
```

The same suite runs in CI on PRs touching this chart — see
[`.github/workflows/test-cnpg-cluster.yml`](../../.github/workflows/test-cnpg-cluster.yml).

## License

Apache License 2.0. See [`LICENSE`](./LICENSE) and [`NOTICE`](./NOTICE).

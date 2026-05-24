# mixins

Pre-built, kustomize-ready Grafana dashboards and Prometheus rules
sourced from the upstream
[kubernetes-mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin)
and [ceph-mixin](https://github.com/ceph/ceph/tree/main/monitoring/ceph-mixin)
projects.

Generated artefacts (`base/<mixin>/`) are committed so consumers can
`kustomize build` directly — no jsonnet, no in-cluster CMP plugin
required.

## Layout

| Path | Purpose |
|---|---|
| `jsonnetfile.json` / `jsonnetfile.lock.json` | jsonnet-bundler dependency pinning |
| `lib/<mixin>.libsonnet`, `lib/<mixin>_config.libsonnet` | per-mixin wrapper + `_config` overrides |
| `lib/prometheusrule.libsonnet` | wraps raw rule groups into `PrometheusRule` CRs (one per group) |
| `lib/dashboards_<mixin>.jsonnet`, `lib/prometheusrules.jsonnet` | jsonnet entry points |
| `lib/raw_alerts.jsonnet`, `lib/raw_rules.jsonnet` | entries used only for promtool validation |
| `scripts/generate.sh`, `Makefile` | regenerate `base/<mixin>/` from `lib/` + vendored upstream |
| `base/<mixin>/` | generated, committed — each is a standalone kustomize base |

Currently bundled mixins: **kubernetes**, **ceph** (dashboards only —
Rook ships an equivalent PrometheusRule, see _Assumptions_ below).

## Consuming

Reference a base from your own kustomization (mount this repo as a
submodule, or use kustomize remote refs):

```yaml
# your-repo/clusters/<your-cluster>/mixins/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: monitoring
resources:
  - <path-to>/mixins/base/kubernetes
  - <path-to>/mixins/base/ceph     # drop this line on Ceph-free clusters
labels:
  - pairs:
      grafana_dashboard: "1"        # Grafana sidecar discovery label
      cluster: <your-cluster>
    includeSelectors: false
```

For Grafana, the sidecar must be configured to honour the
`grafana_folder` annotation that each ConfigMap carries:

```yaml
sidecar:
  dashboards:
    folderAnnotation: grafana_folder
    provider:
      foldersFromFilesStructure: true
```

`PrometheusRule` CRs require a rule-evaluating component (Prometheus or
ThanosRuler) configured to pick them up from the destination namespace.

## Assumptions baked into `lib/`

These defaults reflect a typical kube-prometheus-stack + Cilium
deployment. Tune `lib/<mixin>_config.libsonnet` (and the filter lists
in `lib/<mixin>.libsonnet`) for your environment, then `make generate`.

### kubernetes

- Cluster label is `cluster` (Prometheus / Alloy `external_labels`).
- Scrape job labels follow kube-prometheus-stack ServiceMonitor
  defaults (`job=kubelet`, `job=kube-state-metrics`,
  `job=node-exporter`, `job=apiserver`, `job=kube-scheduler`,
  `job=kube-controller-manager`, `job=coredns`).
- etcd is scraped at `job=kube-etcd` (kubeadm-style).
- kube-proxy is assumed replaced by another component — the proxy
  dashboard and the `kubernetes-system-kube-proxy` rule group are
  filtered out.
- No Windows nodes — Windows dashboards are filtered out.
- Grafana datasource is named `Prometheus`.

### ceph

- Cluster label is `cluster`.
- **Alerts and rules are intentionally not generated.** The Rook
  Operator ships `prometheus-ceph-rules` containing nearly the same
  alert set (vendored from ceph-mixin); duplicating leads to double
  evaluation. This base provides dashboards only.
- NVMeoF and SMB gateway dashboards are filtered out.

## Regenerating

Required tooling on `PATH`:

- [`jb`](https://github.com/jsonnet-bundler/jsonnet-bundler)
- [`jsonnet`](https://github.com/google/go-jsonnet) and `jsonnetfmt`
- [`promtool`](https://prometheus.io/download/)

Then:

```sh
make generate          # render artefacts into base/<mixin>/
make check             # generate + fail if base/ diff is non-empty (CI gate)
make update            # jb update (bump upstream pin)
```

## Adding a mixin

1. `jb install github.com/<owner>/<repo>/<path>@<rev>` (or edit
   `jsonnetfile.json` + `make update`).
2. Create `lib/<mixin>.libsonnet` (entry returning `{ grafanaDashboards,
   prometheusRuleCRs? }`) and `lib/<mixin>_config.libsonnet`.
3. Create `lib/dashboards_<mixin>.jsonnet`.
4. Append a tuple to the `MIXINS` array in `scripts/generate.sh`:
   `name:GrafanaFolder:lib/dashboards_<mixin>.jsonnet:[lib/rules.jsonnet|""]`.
5. `make generate` emits a fresh `base/<mixin>/` tree.

## License

Generated artefacts inherit the licenses of their upstream sources
(see `vendor/<dep>/LICENSE` after `jb install`). Wrapper code in this
directory is provided under the repository's root `LICENSE`.

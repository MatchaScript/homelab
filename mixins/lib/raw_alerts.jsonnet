// Single YAML doc with kubernetes-mixin alerts in promtool-friendly form
// (top-level `groups:`). Used by `make generate` to validate via promtool
// before wrapping into CRs. Ceph alerts come from Rook, not generated here.
std.manifestYamlDoc((import 'kubernetes.libsonnet').prometheusAlerts)

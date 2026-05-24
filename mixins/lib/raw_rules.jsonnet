// Single YAML doc with kubernetes-mixin recording rules in promtool-friendly form.
std.manifestYamlDoc((import 'kubernetes.libsonnet').prometheusRules)

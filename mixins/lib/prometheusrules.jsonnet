// Produces one YAML document per PrometheusRule CR.
// Use with `jsonnet -S -m <outdir>`.
// Only kubernetes-mixin emits rules; ceph rules come from the Rook chart.
local k = import 'kubernetes.libsonnet';

{
  [name]: std.manifestYamlDoc(k.prometheusRuleCRs[name], quote_keys=false)
  for name in std.objectFields(k.prometheusRuleCRs)
}

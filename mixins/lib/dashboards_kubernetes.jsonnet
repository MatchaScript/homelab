local k = import 'kubernetes.libsonnet';

{
  [name]: k.grafanaDashboards[name]
  for name in std.objectFields(k.grafanaDashboards)
}

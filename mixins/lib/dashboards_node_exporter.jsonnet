local n = import 'node_exporter.libsonnet';

{
  [name]: n.grafanaDashboards[name]
  for name in std.objectFields(n.grafanaDashboards)
}

local c = import 'ceph.libsonnet';

{
  [name]: c.grafanaDashboards[name]
  for name in std.objectFields(c.grafanaDashboards)
}

local cephMixin = import 'ceph-mixin/mixin.libsonnet';
local config = import 'ceph_config.libsonnet';

local mixin = cephMixin { _config+:: config };

// Drop dashboards we don't use:
//   - nvmeof / smb: not deployed here
//   - node-exporter: ceph ships its own variant that would collide with the
//     stock node-exporter dashboard managed elsewhere
local excludeDashboards = [
  'ceph-nvmeof.json',
  'ceph-nvmeof-performance.json',
  'smb-overview.json',
  'node-exporter.json',
];

local filterDashboards(d) = {
  [k]: d[k]
  for k in std.objectFields(d)
  if !std.member(excludeDashboards, k)
};

{
  // Dashboards only. Alerts/rules are provided by the Rook chart and
  // would otherwise duplicate (79/81 overlap with the upstream mixin).
  grafanaDashboards: filterDashboards(mixin.grafanaDashboards),
}

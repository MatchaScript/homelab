local nodeMixin = import 'node-mixin/mixin.libsonnet';
local config = import 'node_exporter_config.libsonnet';

local mixin = nodeMixin { _config+:: config };

// Drop dashboards for platforms we don't run:
//   - darwin / aix: every node is Linux (incl. Asahi on Apple silicon).
local excludeDashboards = [
  'nodes-darwin.json',
  'nodes-aix.json',
];

local filterDashboards(d) = {
  [k]: d[k]
  for k in std.objectFields(d)
  if !std.member(excludeDashboards, k)
};

{
  // Dashboards only. The node-exporter alerts and recording rules are
  // provided by kube-prometheus-stack defaultRules (nodeExporterAlerting /
  // nodeExporterRecording / network groups); generating them here would
  // double-evaluate. The USE Method dashboards rely on those same recording
  // rules (instance:node_*), which the defaultRules supply.
  grafanaDashboards: filterDashboards(mixin.grafanaDashboards),
}

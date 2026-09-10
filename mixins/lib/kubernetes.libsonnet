local kubernetes = import 'kubernetes-mixin/mixin.libsonnet';
local config = import 'kubernetes_config.libsonnet';
local wrap = import 'prometheusrule.libsonnet';

local mixin = kubernetes { _config+:: config };

// Drop output that the default config excludes:
//   - kube-proxy: assumes Cilium (or another kube-proxy replacement)
//   - Windows: assumes a Linux-only cluster
// Adjust these lists in your fork if your environment differs.
local excludeDashboards = [
  'proxy.json',
  'k8s-resources-windows-cluster.json',
  'k8s-resources-windows-namespace.json',
  'k8s-resources-windows-pod.json',
  'k8s-windows-cluster-rsrc-use.json',
  'k8s-windows-node-rsrc-use.json',
];

local excludeGroups = [
  'kubernetes-system-kube-proxy',
];

local filterDashboards(d) = {
  [k]: d[k]
  for k in std.objectFields(d)
  if !std.member(excludeDashboards, k)
};

local filterGroups(groups) = [
  g
  for g in groups
  if !std.member(excludeGroups, g.name)
];

// Also filter individual alerts in remaining groups by name.
local excludeAlerts = ['KubeProxyDown'];
local filterAlerts(groups) = [
  g {
    rules: [r for r in g.rules if !std.objectHas(r, 'alert') || !std.member(excludeAlerts, r.alert)],
  }
  for g in groups
];

local alertGroups = filterAlerts(filterGroups(mixin.prometheusAlerts.groups));
local ruleGroups = filterGroups(mixin.prometheusRules.groups);

{
  grafanaDashboards: filterDashboards(mixin.grafanaDashboards),
  prometheusAlerts: { groups: alertGroups },
  prometheusRules: { groups: ruleGroups },
  prometheusRuleCRs: wrap.fromGroups(
    'kubernetes-mixin',
    alertGroups + ruleGroups,
  ),
}

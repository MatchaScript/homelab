// Overrides for ceph-mixin's _config.
// We only consume dashboards from ceph-mixin (alerts come from the Rook
// chart's prometheus-ceph-rules), so this is minimal — selectors etc.
// only matter for the dashboard query strings.
{
  clusterLabel: 'cluster',
  showMultiCluster: true,
  dashboardTags: ['ceph-mixin'],
}

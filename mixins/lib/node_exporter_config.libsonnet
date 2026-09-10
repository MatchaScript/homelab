// Overrides for node-mixin's _config.
// See https://github.com/prometheus/node_exporter/blob/master/docs/node-mixin/config.libsonnet
// for the full set of knobs (selectors, thresholds, multi-cluster support).
//
// Only dashboard-affecting knobs are set here: this base ships dashboards
// only (see node_exporter.libsonnet), so the alert/recording thresholds are
// left at their upstream defaults.
{
  clusterLabel: 'cluster',
  showMultiCluster: true,

  // node-exporter scrape job. The prometheus-node-exporter ServiceMonitor
  // here sets jobLabel=node-exporter; the upstream mixin default is `node`.
  nodeExporterSelector: 'job="node-exporter"',
}

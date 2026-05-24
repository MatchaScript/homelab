// Overrides for kubernetes-mixin's _config.
// See https://github.com/kubernetes-monitoring/kubernetes-mixin/blob/master/config.libsonnet
// for the full set of knobs.
{
  clusterLabel: 'cluster',
  datasourceName: 'Prometheus',
  showMultiCluster: true,
  dashboardTags: ['kubernetes-mixin'],

  grafanaK8s+:: {
    dashboardNamePrefix: 'Kubernetes / ',
    refresh: '30s',
  },

  // Scrape job labels — these match the defaults produced by
  // kube-prometheus-stack ServiceMonitors (and Grafana Alloy's
  // prometheus.operator.servicemonitors that consumes them).
  // Tune for your scrape setup if you don't use kube-prometheus-stack.
  cadvisorSelector: 'job="kubelet", metrics_path="/metrics/cadvisor"',
  kubeletSelector: 'job="kubelet", metrics_path="/metrics"',
  kubeStateMetricsSelector: 'job="kube-state-metrics"',
  nodeExporterSelector: 'job="node-exporter"',
  kubeSchedulerSelector: 'job="kube-scheduler"',
  kubeControllerManagerSelector: 'job="kube-controller-manager"',
  kubeApiserverSelector: 'job="apiserver"',
  coreDNSSelector: 'job="coredns"',
  // kubeadm-style etcd scrape commonly produces job=kube-etcd;
  // the upstream mixin default is `etcd`. Adjust to your scrape config.
  kubeEtcdSelector: 'job="kube-etcd"',
}

// Wrap raw Prometheus rule groups into one PrometheusRule CR per group.
// Keeps diffs and silences scoped to single rule groups.
local sanitize(name) =
  std.asciiLower(
    std.join('-', std.split(std.strReplace(std.strReplace(name, '_', '-'), '.', '-'), ' '))
  );

{
  fromGroups(prefix, groups)::
    {
      [prefix + '-' + sanitize(group.name) + '.yaml']: {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'PrometheusRule',
        metadata: {
          name: prefix + '-' + sanitize(group.name),
          labels: {
            'app.kubernetes.io/part-of': prefix,
            'app.kubernetes.io/managed-by': 'argocd',
          },
        },
        spec: {
          groups: [group],
        },
      }
      for group in groups
    },
}

{{/*
Common labels for vault-eso resources
*/}}
{{- define "vault-eso.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Release.Name }}
helm.sh/chart: vault-eso
{{- end -}}

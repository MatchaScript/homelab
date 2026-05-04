{{/*
Common labels.
*/}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — kept as `app: keycloak` to match historical Deployment
selectors so the Deployment can be upgraded in place (selectors are immutable).
*/}}
{{- define "keycloak.selectorLabels" -}}
app: keycloak
{{- end }}

{{- define "keycloak.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}

{{/*
Strip the scheme from a URL, returning the host portion.
*/}}
{{- define "keycloak.hostOnly" -}}
{{- $url := . -}}
{{- if hasPrefix "https://" $url -}}{{ trimPrefix "https://" $url }}
{{- else if hasPrefix "http://" $url -}}{{ trimPrefix "http://" $url }}
{{- else -}}{{ $url }}
{{- end -}}
{{- end -}}

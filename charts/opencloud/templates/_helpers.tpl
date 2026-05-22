{{/*
Expand the name of the chart.
*/}}
{{- define "opencloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
*/}}
{{- define "opencloud.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "opencloud.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}

{{- define "opencloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opencloud.labels" -}}
helm.sh/chart: {{ include "opencloud.chart" . }}
{{ include "opencloud.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "opencloud.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opencloud.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Image reference. Combines repository, tag (defaulted to chart appVersion),
and an optional digest pin. Keeping tag and digest separate keeps Renovate's
helm-values manager from splicing the digest into an empty tag and producing
an invalid reference.
*/}}
{{- define "opencloud.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- if .Values.image.digest -}}
{{- printf "%s:%s@%s" .Values.image.repository $tag .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end }}

{{/*
NATS endpoint used in env wiring. External when enabled, otherwise the
in-process registry on 127.0.0.1:9233.
*/}}
{{- define "opencloud.natsEndpoint" -}}
{{- if .Values.nats.external.enabled -}}
{{- required "nats.external.endpoint is required when nats.external.enabled=true" .Values.nats.external.endpoint -}}
{{- else -}}
127.0.0.1:9233
{{- end -}}
{{- end }}

{{/*
Comma-joined OC_EXCLUDE_RUN_SERVICES. Always appends nats when external NATS
is enabled (in-process NATS would otherwise fight the external one).
*/}}
{{- define "opencloud.excludeServices" -}}
{{- $exclude := .Values.excludeServices | default (list) -}}
{{- if .Values.nats.external.enabled -}}
{{- $exclude = append $exclude "nats" -}}
{{- end -}}
{{- join "," $exclude -}}
{{- end }}

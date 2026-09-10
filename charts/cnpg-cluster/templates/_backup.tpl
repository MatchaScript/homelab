{{/*
Plugin entry on the Cluster spec, wiring barman-cloud.cloudnative-pg.io.

Emitted in two cases:

  1. Standalone clusters with backups.enabled: true — the plugin
     archives WAL to the locally-generated ObjectStore.

  2. Recovery clusters with recovery.objectStoreName set — CNPG requires
     the plugin to be declared on the recovery cluster too, otherwise
     restoration falls back to the inline barman path and errors with
     "ObjectStoreConfiguration invalid: no credentials defined". This
     applies to both recovery.method: object_store (where
     objectStoreName is also used by externalClusters) and
     recovery.method: backup (where it points at the same ObjectStore
     the referenced Backup was written to). The recovery instance is a
     read-only consumer, so isWALArchiver is false.
*/}}
{{- define "cluster.plugins" -}}
{{- if .Values.backups.enabled }}
plugins:
- name: barman-cloud.cloudnative-pg.io
  enabled: true
  isWALArchiver: true
  parameters:
    barmanObjectName: {{ include "cluster.objectStoreName" . }}
{{- else if and (eq .Values.mode "recovery") .Values.recovery.objectStoreName }}
plugins:
- name: barman-cloud.cloudnative-pg.io
  enabled: true
  isWALArchiver: false
  parameters:
    barmanObjectName: {{ .Values.recovery.objectStoreName }}
{{- end }}
{{- end }}

{{- define "cluster.externalClusters" -}}
{{- if eq .Values.mode "standalone" }}
{{- else }}
externalClusters:
{{- if eq .Values.mode "recovery" }}
  {{- if eq .Values.recovery.method "pg_basebackup" }}
  - name: pgBaseBackupSource
     {{- include "cluster.externalSourceCluster" .Values.recovery.pgBaseBackup.source | nindent 4 }}
  {{- else if eq .Values.recovery.method "object_store" }}
  - name: objectStoreRecoveryCluster
    plugin:
      name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: {{ required "recovery.objectStoreName is required for object_store recovery" .Values.recovery.objectStoreName }}
        {{- with .Values.recovery.clusterName }}
        serverName: {{ . }}
        {{- end }}
  {{- else if eq .Values.recovery.method "backup" }}
  # Backup-CR recovery still needs an externalCluster with the plugin reference;
  # CNPG's plugin recovery hook only fires when bootstrap.recovery.source is set
  # (see plugin-barman-cloud config.go:getRecoverySourcePlugin). The plugin then
  # uses this entry to know where to read WAL/base from.
  - name: backupRecoverySource
    plugin:
      name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: {{ required "recovery.objectStoreName is required for backup recovery (the source ObjectStore)" .Values.recovery.objectStoreName }}
        {{- with .Values.recovery.clusterName }}
        serverName: {{ . }}
        {{- end }}
  {{- end }}
{{- else if eq .Values.mode "replica" }}
  - name: originCluster
  {{- if .Values.replica.origin.objectStore.name }}
    plugin:
      name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: {{ .Values.replica.origin.objectStore.name }}
        {{- with .Values.replica.origin.objectStore.clusterName }}
        serverName: {{ . }}
        {{- end }}
  {{- else if .Values.replica.origin.pg_basebackup.host }}
    {{- include "cluster.externalSourceCluster" .Values.replica.origin.pg_basebackup | nindent 4 }}
  {{- end }}
{{- else }}
  {{ fail "Invalid cluster mode!" }}
{{- end }}
{{- end }}
{{ end }}

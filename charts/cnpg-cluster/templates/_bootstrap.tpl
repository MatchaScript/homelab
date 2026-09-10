{{- define "cluster.bootstrap" -}}
bootstrap:
{{- if eq .Values.mode "standalone" }}
  initdb:
    {{- with .Values.cluster.initdb }}
        {{- with (omit . "postInitApplicationSQL" "owner") }}
            {{- . | toYaml | nindent 4 }}
        {{- end }}
    {{- end }}
    {{- if .Values.cluster.initdb.owner }}
    owner: {{ tpl .Values.cluster.initdb.owner . }}
    {{- end }}
    {{- with .Values.cluster.initdb.postInitApplicationSQL }}
    postInitApplicationSQL:
      {{- range . }}
        {{- printf "- %s" . | nindent 6 }}
      {{- end }}
    {{- end }}
{{- else if eq .Values.mode "recovery" -}}
  {{- if eq .Values.recovery.method "pg_basebackup" }}
  pg_basebackup:
    source: pgBaseBackupSource
    {{ with .Values.recovery.pgBaseBackup.database }}
    database: {{ . }}
    {{- end }}
    {{ with .Values.recovery.pgBaseBackup.owner }}
    owner: {{ . }}
    {{- end }}
    {{ with .Values.recovery.pgBaseBackup.secretName }}
    secret:
      name: {{ . }}
    {{- end }}
  {{- else }}
  recovery:
    {{- with .Values.recovery.pitrTarget.time }}
    recoveryTarget:
      targetTime: {{ . }}
    {{- end }}
    {{ with .Values.recovery.database }}
    database: {{ . }}
    {{- end }}
    {{ with .Values.recovery.owner }}
    owner: {{ . }}
    {{- end }}
    {{- if eq .Values.recovery.method "backup" }}
    backup:
      name: {{ .Values.recovery.backupName }}
    # Required so the plugin's recovery hook fires; without source, CNPG falls
    # back to the in-tree barman path which our fork doesn't render the inline
    # config for. The matching externalCluster is in _external_clusters.tpl.
    source: backupRecoverySource
    {{- else if eq .Values.recovery.method "object_store" }}
    source: objectStoreRecoveryCluster
    {{- end }}
  {{- end }}
{{- else if eq .Values.mode "replica" }}
  {{- if eq .Values.replica.bootstrap.source "pg_basebackup" }}
  pg_basebackup:
    source: originCluster
    {{ with .Values.replica.bootstrap.database }}
    database: {{ . }}
    {{- end }}
    {{ with .Values.replica.bootstrap.owner }}
    owner: {{ . }}
    {{- end }}
    {{ with .Values.replica.bootstrap.secret }}
    secret:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- else if eq .Values.replica.bootstrap.source "object_store" }}
  recovery:
    source: originCluster
    {{ with .Values.replica.bootstrap.database }}
    database: {{ . }}
    {{- end }}
    {{ with .Values.replica.bootstrap.owner }}
    owner: {{ . }}
    {{- end }}
    {{ with .Values.replica.bootstrap.secret }}
    secret:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- else }}
    {{ fail "Invalid replica bootstrap mode!" }}
  {{- end }}
{{- else }}
  {{ fail "Invalid cluster mode!" }}
{{- end }}
{{- if eq .Values.mode "replica" }}
replica:
  enabled: true
  source: originCluster
  {{ with .Values.replica.self }}
  self: {{ . }}
  {{- end }}
  {{ with .Values.replica.primary }}
  primary: {{ . }}
  {{- end }}
  {{ with .Values.replica.promotionToken }}
  promotionToken: {{ . }}
  {{- end }}
  {{ with .Values.replica.minApplyDelay }}
  minApplyDelay: {{ . }}
  {{- end }}
{{- end }}
{{- end }}

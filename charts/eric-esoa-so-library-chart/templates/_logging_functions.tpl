{{/*
Define the log streaming method (DR-470222-030)
*/}}
{{- define "eric-esoa-so-library-chart.streamingMethod" -}}
  {{- $streamingMethod := "indirect" -}}
  {{- if .Values.log -}}
    {{- if .Values.log.streamingMethod -}}
      {{- $streamingMethod = .Values.log.streamingMethod | toString -}}
    {{- end -}}
  {{- end -}}
  {{- if (.Values.global) -}}
    {{- if  .Values.global.log -}}
      {{- if  .Values.global.log.streamingMethod -}}
        {{- $streamingMethod = .Values.global.log.streamingMethod | toString -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- print $streamingMethod -}}
{{- end -}}


{{/*
Define the logging-format-json method (DR-470222-030)
*/}}
{{- define "eric-esoa-so-library-chart.loggingFormatJsonMethodEnabled" -}}
{{- if  .Values.logging -}}
  {{- if  .Values.logging.format -}}
    {{- .Values.logging.format.json | toString -}}
  {{- else -}}
    {{- "false" -}}
  {{- end -}}
{{- else -}}
  {{- "false" -}}
{{- end -}}
{{- end -}}


{{/*
Define logback-config-file value (DR-470222-030)
*/}}
{{- define "eric-esoa-so-library-chart.logbackConfigFileValue" -}}
{{- $streamingMethod := (include "eric-esoa-so-library-chart.streamingMethod" .) -}}
  {{- if eq $streamingMethod "direct" }}
    - name: LOGBACK_CONFIG_FILE
    {{- if eq (include "eric-esoa-so-library-chart.loggingFormatJsonMethodEnabled" .) "true" }}
      value: "classpath:logback-json.xml"
    {{- else }}
      value: "classpath:logback-http.xml"
    {{- end }}
  {{- else if eq $streamingMethod "indirect" }}
    - name: LOGBACK_CONFIG_FILE
    {{- if eq (include "eric-esoa-so-library-chart.loggingFormatJsonMethodEnabled" .) "true" }}
      value: "classpath:logback-json.xml"
    {{- else }}
      value: "classpath:logback-plain-text.xml"
    {{- end }}
  {{- else }}
    - name: LOGBACK_CONFIG_FILE
    {{- if eq (include "eric-esoa-so-library-chart.loggingFormatJsonMethodEnabled" .) "true" }}
      value: "classpath:logback-json.xml"
    {{- else }}
      value: "classpath:logback-plain-text.xml"
    {{- end }}
  {{- end }}
{{- end }}


{{/*
Define logging environment variables  (DR-470222-030)
*/}}
{{- define "eric-esoa-so-library-chart.loggingEnvVariables" -}}
{{- $streamingMethod := (include "eric-esoa-so-library-chart.streamingMethod" .) -}}
{{- if or (eq "direct" $streamingMethod) (eq "indirect" $streamingMethod) (eq "dual" $streamingMethod) }}
{{- include "eric-esoa-so-library-chart.logbackConfigFileValue" .| indent 0 }}
  {{- if eq $streamingMethod "direct" }}
    - name: LOGSTASH_DESTINATION
      value: eric-log-transformer
    - name: LOGSTASH_PORT
      value: "9080"
  {{- end }}
{{- else }}
{{- fail ".log.streamingMethod unknown" }}
{{- end }}
{{- include "eric-esoa-so-library-chart.loggingEnvParams" .| indent 4 }}
{{- end -}}


{{/*
Merge logging format related environment variables.
*/}}
{{- define "eric-esoa-so-library-chart.loggingEnvParams" }}
- name: POD_NAME
  valueFrom: { fieldRef: { fieldPath: metadata.name } }
- name: POD_UID
  valueFrom: { fieldRef: { fieldPath: metadata.uid } }
- name: CONTAINER_NAME
  value: {{ include "eric-esoa-so-library-chart.name" . | quote }}
- name: NODE_NAME
  valueFrom: { fieldRef: { fieldPath: spec.nodeName } }
- name: NAMESPACE
  valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
{{- end }}
{{/*
Create a ConfigMap to store security configuration
*/}}
{{- define "eric-esoa-so-library-chart.truststoreConfigMap" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "eric-esoa-so-library-chart.name" . }}-truststore-configmap
  labels:
  {{- include "eric-esoa-so-library-chart.labels" .| nindent 4 }}
  annotations:
  {{- include "eric-esoa-so-library-chart.annotations" .| nindent 4 }}
  {{- include "eric-esoa-so-library-chart.truststore-configmap-data" .| nindent 0}}
{{- end }}
{{- end }}

{{/*
This function is to generate common data for SIP TLS security configuration
*/}}
{{- define "eric-esoa-so-library-chart.truststore-configmap-data" -}}
data:
    truststore.yaml: |
      security:
        truststore:
{{ toYaml .Values.security.truststore | indent 10 }}
{{- end }}
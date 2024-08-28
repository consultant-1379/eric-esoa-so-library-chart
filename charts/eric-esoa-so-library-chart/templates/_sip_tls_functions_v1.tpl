
{{/*
SIP/TLS Common Environment variables
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-env-variables.v1" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- name: SECURITY_TLS_ENABLED
  value: {{ .Values.global.security.tls.enabled | quote }}
- name: TLS_CERT_DIRECTORY
  value: {{ .Values.security.keystore.tlsCertDirectory | quote }}
- name: TLS_CERT_FILE
  value: {{ .Values.security.keystore.tlsCertFile | quote }}
- name: TLS_KEY_FILE
  value: {{ .Values.security.keystore.tlsKeyFile | quote }}
- name: CERT_RENEW_RETRY_DELAY
  value: {{ .Values.security.renewCertRetry.delay | quote }}
- name: CERT_RENEW_RETRY_COUNT
  value: {{ .Values.security.renewCertRetry.times | quote }}
{{- end }}
{{- end }}

{{/*
SIP/TLS Volumes
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-volumes.v1" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
{{- range $values := .Values.security.truststore.certificates }}
- name: {{ $values.secretName }}
  secret:
    defaultMode: 420
    optional: true
    secretName: {{ $values.secretName | quote}}
{{- end }}
- name: keystore
  secret:
    defaultMode: 420
    optional: true
    secretName: {{ .Values.security.keystore.keyStoreSecretName | quote }}
- name: truststore-configmap
  configMap:
    defaultMode: 420
    optional: true
    name: {{ template "eric-esoa-so-library-chart.name" . }}-truststore-configmap
{{- end }}
{{- end }}


{{/*
SIP/TLS Volume Mounts
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-volume-mounts.v1" -}}
{{-  $caCertDirectory := .Values.security.truststore.caCertDirectory -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- mountPath: {{ .Values.security.keystore.tlsCertDirectory | quote }}
  name: keystore
{{- range $values := .Values.security.truststore.certificates }}
- mountPath:  {{ $caCertDirectory }}{{ $values.secretName }}
  name: {{ $values.secretName }}
{{- end }}
- mountPath: {{ .Values.security.config.mountPath | quote }}
  name: truststore-configmap
{{- end }}
{{- end }}

{{/*
Create an InternalCertificate
*/}}
{{- define "eric-esoa-so-library-chart.internalcertificate.v1" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
apiVersion: siptls.sec.ericsson.com/v1
kind: InternalCertificate
metadata:
  name: {{ include "eric-esoa-so-library-chart.name" . }}-int-cert
  labels:
  {{- include "eric-esoa-so-library-chart.labels" .| nindent 4 }}
  annotations:
  {{- include "eric-esoa-so-library-chart.annotations" .| nindent 4 }}
  {{- include "eric-esoa-so-library-chart.sip-tls-internal-cert-spec.v1" .| nindent 0}}
{{- end }}
{{- end }}

{{/*
This function is to generate common spec for SIP TLS internal certificates
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-internal-cert-spec.v1" -}}
spec:
  kubernetes:
    generatedSecretName: {{ .Chart.Name | printf "%s-int-cert" }}
    certificateName: "tls.crt"
    privateKeyName: "tls.key"
    secretType: tls
  certificate:
    subject:
      cn: {{ .Chart.Name }}
    subjectAlternativeName:
      dns:
        - localhost
    extendedKeyUsage:
      tlsClientAuth: true
      tlsServerAuth: true
{{- end }}

{{/*
SIP/TLS Common Environment variables
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-env-variables" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- name: SECURITY_TLS_ENABLED
  value: {{ .Values.global.security.tls.enabled | quote }}
- name: CA_CERT_DIRECTORY
  value: {{ .Values.security.truststore.caCertDirectory | quote }}
- name: CA_CERT_FILE
  value: {{ .Values.security.truststore.caCertFile | quote }}
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
SIP/TLS Alarm Environment variables
*/}}
{{- define "eric-esoa-so-library-chart.alarm-env-variables" -}}
{{ include "eric-esoa-so-library-chart.alarm-scheme-and-port" . }}
- name: ALARM_API_ADDRESS
  value: {{ .Values.security.systemMonitoring.faultManagement.address | default "eric-fh-alarm-handler" | quote }}
- name: ALARM_API_PATH
  value: {{ .Values.security.systemMonitoring.faultManagement.apiPath | default "alarm-handler/v1/fault-indications" | quote }}
- name: ALARM_EXPIRATION_PERIOD
  value: {{ .Values.security.systemMonitoring.expiration | default "600" | quote }}
- name: ALARM_RETRY_COUNT
  value: {{ .Values.security.systemMonitoring.faultManagement.retry | default "3" | quote }}
- name: ALARM_DELAY
  value: {{ .Values.security.systemMonitoring.faultManagement.delay | default "5000" | quote }}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- name: ALARM_TLS_CERT_DIRECTORY
  value: {{ .Values.security.systemMonitoring.keystore.tlsCertDirectory | quote }}
- name: ALARM_TLS_CERT_FILE
  value: {{ .Values.security.systemMonitoring.keystore.tlsCertFile | quote }}
- name: ALARM_TLS_KEY_FILE
  value: {{ .Values.security.systemMonitoring.keystore.tlsKeyFile | quote }}
{{- end }}
{{- end }}


{{/*
Alarm Environment variables
*/}}
{{- define "eric-esoa-so-library-chart.alarm-scheme-and-port" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- name: ALARM_API_SCHEME
  value: "https"
- name: ALARM_API_PORT
  value: "6006"
{{- else }}
- name: ALARM_API_SCHEME
  value: "http"
- name: ALARM_API_PORT
  value: "6005"
{{- end }}
{{- end }}


{{/*
SIP/TLS Volumes
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-volumes" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- name: ca-cert
  secret:
    defaultMode: 420
    optional: true
    secretName: {{ .Values.security.truststore.caCertSecretName | quote }}
- name: keystore
  secret:
    defaultMode: 420
    optional: true
    secretName: {{ .Values.security.keystore.keyStoreSecretName | quote }}
{{- end }}
{{- end }}

{{/*
SIP/TLS Alarm Volumes
*/}}
{{- define "eric-esoa-so-library-chart.alarm-volumes" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- name: alarmkeystore
  secret:
    defaultMode: 420
    optional: true
    secretName: {{ .Values.security.systemMonitoring.keystore.alarmKeyStoreSecretName | quote }}
{{- end }}
{{- end }}


{{/*
SIP/TLS Volume Mounts
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-volume-mounts" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- mountPath: {{ .Values.security.keystore.tlsCertDirectory | quote }}
  name: keystore
- mountPath: {{ .Values.security.truststore.caCertDirectory | quote }}
  name: ca-cert
{{- end }}
{{- end }}

{{/*
SIP/TLS Alarm Volume Mounts
*/}}
{{- define "eric-esoa-so-library-chart.alarm-volume-mounts" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
- mountPath: {{ .Values.security.systemMonitoring.keystore.tlsCertDirectory | quote }}
  name: alarmkeystore
{{- end }}
{{- end }}


{{/*
Create an InternalCertificate
*/}}
{{- define "eric-esoa-so-library-chart.internalcertificate" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
apiVersion: siptls.sec.ericsson.com/v1
kind: InternalCertificate
metadata:
  name: {{ include "eric-esoa-so-library-chart.name" . }}-int-cert
  labels:
  {{- include "eric-esoa-so-library-chart.labels" .| nindent 4 }}
  annotations:
  {{- include "eric-esoa-so-library-chart.annotations" .| nindent 4 }}
  {{- include "eric-esoa-so-library-chart.sip-tls-internal-cert-spec" .| nindent 0}}
{{- end }}
{{- end }}

{{/*
This function is to generate common spec for SIP TLS internal certificates
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-internal-cert-spec" -}}
spec:
  kubernetes:
    generatedSecretName: {{ .Chart.Name | printf "%s-int-cert" }}
    certificateName: "tls.crt"
    privateKeyName: "tls.key"
    secretType: tls
  certificate:
    subject:
      cn: {{ .Chart.Name }}
    extendedKeyUsage:
      tlsClientAuth: true
      tlsServerAuth: true
{{- end }}

{{/*
Create an InternalCertificate for Alarm Handler Communication
*/}}
{{- define "eric-esoa-so-library-chart.alarminternalcertificate" -}}
{{- if eq (include "eric-esoa-so-library-chart.global-security-tls-enabled" .) "true" }}
apiVersion: siptls.sec.ericsson.com/v1
kind: InternalCertificate
metadata:
  name: {{ include "eric-esoa-so-library-chart.name" . }}-alarm-handler-int-cert
  labels:
  {{- include "eric-esoa-so-library-chart.labels" .| nindent 4 }}
  annotations:
  {{- include "eric-esoa-so-library-chart.annotations" .| nindent 4 }}
{{- include "eric-esoa-so-library-chart.sip-tls-alarm-internal-cert-spec" .| nindent 0}}
{{- end }}
{{- end }}

{{/*
This function is to generate common spec for SIP TLS alarm internal certificates
*/}}
{{- define "eric-esoa-so-library-chart.sip-tls-alarm-internal-cert-spec" -}}
spec:
  kubernetes:
    generatedSecretName: {{ .Chart.Name | printf "%s-alarm-handler-int-cert" }}
    certificateName: "tls.crt"
    privateKeyName: "tls.key"
    secretType: tls
  certificate:
    subject:
      cn: {{ .Chart.Name }}
    issuer:
      reference: eric-fh-alarm-handler-fi-server-client-ca
    extendedKeyUsage:
      tlsClientAuth: true
      tlsServerAuth: true
{{- end }}
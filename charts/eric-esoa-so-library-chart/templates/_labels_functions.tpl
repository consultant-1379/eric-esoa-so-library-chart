{{/*
Merge kubernetes-io-info, user-defined labels, and app and chart labels into a single set
of metadata labels.
*/}}
{{- define "eric-esoa-so-library-chart.labels" -}}
  {{- $kubernetesIoInfo := include "eric-esoa-so-library-chart.kubernetes-io-info" . | fromYaml -}}
  {{- $config := include "eric-esoa-so-library-chart.config-labels" . | fromYaml -}}
  {{- $appAndChartLabels := include "eric-esoa-so-library-chart.app-and-chart-labels" . | fromYaml -}}
  {{- include "eric-esoa-so-library-chart.mergeLabels" (dict "location" .Template.Name "sources" (list $kubernetesIoInfo $config $appAndChartLabels)) | trim }}
  {{- $streamingMethod := (include "eric-esoa-so-library-chart.streamingMethod" .) -}}
  {{- if eq $streamingMethod "direct" }}
    {{- include "eric-esoa-so-library-chart.directStreamingLabel" (dict "location" .Template.Name "sources" (list $kubernetesIoInfo $config $appAndChartLabels)) | nindent 0 }}
  {{- end -}}
{{- end -}}

{{/*
Create Ericsson product app.kubernetes.io info
*/}}
{{- define "eric-esoa-so-library-chart.kubernetes-io-info" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "eric-esoa-so-library-chart.chart" . }}
{{- end -}}

{{/*
Create user-defined labels
*/}}
{{ define "eric-esoa-so-library-chart.config-labels" }}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-esoa-so-library-chart.mergeLabels" (dict "location" .Template.Name "sources" (list $global $service)) }}
{{- end }}

{{/*
Create app and chart metadata labels
*/}}
{{- define "eric-esoa-so-library-chart.app-and-chart-labels" -}}
app: {{ template "eric-esoa-so-library-chart.name" . }}
chart: {{ template "eric-esoa-so-library-chart.chart" . }}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-esoa-so-library-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-esoa-so-library-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
Wrapper functions to set the contexts
*/ -}}
{{- define "eric-esoa-so-library-chart.mergeLabels" -}}
  {{- include "eric-esoa-so-library-chart.aggregatedMerge" (dict "context" "labels" "location" .location "sources" .sources) }}
{{- end -}}

{{/*
Define the label needed for reaching eric-log-transformer (DR-D470222-030)
*/}}
{{- define "eric-esoa-so-library-chart.directStreamingLabel" -}}
  logger-communication-type: "direct"
{{- end -}}

{{/*
Create label for BSS BAM GUI Aggregator
*/}}
{{- define "eric-esoa-so-library-chart.bamPartofLabel" -}}
ui.ericsson.com/part-of: bss-oam-gui
{{- end -}}
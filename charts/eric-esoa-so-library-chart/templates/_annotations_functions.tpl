{{/*
Merge eric-product-info, user-defined annotations, and Prometheus annotations into a single set
of metadata annotations.
*/}}
{{- define "eric-esoa-so-library-chart.annotations" -}}
  {{- $productInfo := include "eric-esoa-so-library-chart.helm-annotations" . | fromYaml -}}
  {{- $config := include "eric-esoa-so-library-chart.config-annotations" . | fromYaml -}}
  {{- $prometheus := include "eric-esoa-so-library-chart.prometheus" . | fromYaml -}}
  {{- include "eric-esoa-so-library-chart.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $config $prometheus)) | trim }}
{{- end -}}

{{/*
Create Ericsson Product Info
*/}}
{{- define "eric-esoa-so-library-chart.helm-annotations" -}}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end}}

{{/*
Create a user defined annotation
*/}}
{{- define "eric-esoa-so-library-chart.config-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-esoa-so-library-chart.mergeAnnotations" (dict "location" .Template.Name "sources" (list $global $service))}}
{{- end }}

{{/*
Create prometheus info
*/}}
{{- define "eric-esoa-so-library-chart.prometheus" -}}
prometheus.io/path: "{{ .Values.prometheus.path }}"
prometheus.io/port: "{{ .Values.port.http }}"
prometheus.io/scrape: "{{ .Values.prometheus.scrape }}"
{{- end -}}

{{- /*
Wrapper functions to set the contexts
*/ -}}
{{- define "eric-esoa-so-library-chart.mergeAnnotations" -}}
  {{- include "eric-esoa-so-library-chart.aggregatedMerge" (dict "context" "annotations" "location" .location "sources" .sources) }}
{{- end -}}

{{/*
Create Annotation for BSS BAM GUI Aggregator
*/}}
{{- define "eric-esoa-so-library-chart.bamDiscoveryAnnotation" -}}
ui.ericsson.com/discovery-services: eric-bss-gui-aggregator
ui.ericsson.com/proxy: {{ .Values.portal.proxyValue }}
{{- end -}}
{{/*
adding TopologySpreadConstraints
*/}}
{{- define "eric-esoa-so-library-chart.topologySpreadConstraints" }}
{{- range $values := .Values.topologySpreadConstraints }}
- topologyKey: {{ $values.topologyKey }}
  maxSkew: {{ $values.maxSkew | default 1 }}
  whenUnsatisfiable: {{ $values.whenUnsatisfiable | default "ScheduleAnyway" }}
{{- if $values.nodeAffinityPolicy }}
  nodeAffinityPolicy: {{ $values.nodeAffinityPolicy }}
{{- end }}
{{- if $values.nodeTaintsPolicy }}
  nodeTaintsPolicy: {{ $values.nodeTaintsPolicy }}
{{- end }}
{{- if $values.minDomains }}
  minDomains: {{ $values.minDomains }}
{{- end }}
{{- if $values.matchLabelKeys }}
  matchLabelKeys: {{ $values.matchLabelKeys }}
{{- end }}
  labelSelector:
    matchLabels:
      app: {{ template "eric-esoa-so-library-chart.name" $ }}
{{- end }}
{{- end }}

{{/*
POD Antiaffinity type (soft/hard)
*/}}

{{- define "eric-esoa-so-library-chart.pod-anti-affinity-type" -}}
{{- $podantiaffinity := "soft" }}
{{- if .Values.affinity -}}
  {{- $podantiaffinity = .Values.affinity.podAntiAffinity }}
{{- end -}}
{{- if eq $podantiaffinity "hard" }}
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app.kubernetes.io/name
        operator: In
        values:
        - {{ template "eric-esoa-so-library-chart.name" . }}
    topologyKey: {{ .Values.affinity.topologyKey }}
 {{- else if eq $podantiaffinity "soft" -}}
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - {{ template "eric-esoa-so-library-chart.name" .}}
      topologyKey: {{ .Values.affinity.topologyKey }}
 {{- end }}
{{- end }}


{{/*
This helps to define replicas during deployment
*/}}
{{- define "eric-esoa-so-library-chart.replicas" -}}
{{- $replicas := 1 -}}

{{ if .Values.replicaCount }}
  {{- $replicas = .Values.replicaCount -}}
{{- end -}}

{{- if eq (.Values.replicaCount | int) 0 -}}
  {{- $replicas = .Values.replicaCount -}}
{{- end -}}

{{- print $replicas -}}
{{- end -}}


{{/*
DR-D1120-080 Define terminationGracePeriodSeconds
*/}}
{{- define "eric-esoa-so-library-chart.terminationGracePeriodSeconds" -}}
{{- $terminationGracePeriodSeconds := 30 -}}
{{- if gt (int (index .Values "terminationGracePeriodSeconds" )) 0 }}
  {{- $terminationGracePeriodSeconds = int (index .Values "terminationGracePeriodSeconds" ) -}}
{{- end }}
{{- print $terminationGracePeriodSeconds -}}
{{- end -}}

{/*
 create resource requests and limits
*/}}
{{- define "eric-esoa-so-library-chart.resourceRequestsAndLimits" -}}
requests:
{{- if (index .Values "resources" .resourceName "requests" "ephemeral-storage") }}
  ephemeral-storage: {{ (index .Values "resources" .resourceName "requests" "ephemeral-storage" | quote) }}
{{- end }}
{{- if (index .Values "resources" .resourceName "requests" "memory") }}
  memory: {{ (index .Values "resources" .resourceName "requests" "memory" | quote) }}
{{- end }}
{{- if (index .Values "resources" .resourceName "requests" "cpu") }}
  cpu: {{ (index .Values "resources" .resourceName "requests" "cpu" | quote) }}
{{- end }}
limits:
{{- if (index .Values "resources" .resourceName "limits" "ephemeral-storage") }}
  ephemeral-storage: {{ (index .Values "resources" .resourceName "limits" "ephemeral-storage" | quote) }}
{{- end }}
{{- if (index .Values "resources" .resourceName "limits" "memory") }}
  memory: {{ (index .Values "resources" .resourceName "limits" "memory" | quote) }}
{{- end }}
{{- if (index .Values "resources" .resourceName "limits" "cpu") }}
  cpu: {{ (index .Values "resources" .resourceName "limits" "cpu" | quote) }}
{{- end }}
{{- end -}}

{/*
DR-D1120-060-AD, DR-D1120-061-AD, DR-D1120-067-AD - create tolerations
*/}}
{{- define "eric-esoa-so-library-chart.tolerations" -}}
{{- range $values := .Values.tolerations }}
- key: {{ $values.key }}
  operator: {{ $values.operator }}
  {{- if $values.value }}
  value: {{ $values.value }}
  {{- end }}
  effect: {{ $values.effect }}
  tolerationSeconds: {{ $values.tolerationSeconds }}
{{- end }}
{{- end -}}
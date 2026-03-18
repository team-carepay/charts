{{/*
Expand the name of the chart.
*/}}
{{- define "karpenter-nodes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Derive the Karpenter node IAM role from the cluster name.
*/}}
{{- define "karpenter-nodes.nodeRole" -}}
{{- printf "%s-eks-auto" .Values.clusterName }}
{{- end }}

{{/*
Derive the Karpenter discovery tag value from the cluster name.
*/}}
{{- define "karpenter-nodes.discoveryTag" -}}
{{- .Values.clusterName }}
{{- end }}

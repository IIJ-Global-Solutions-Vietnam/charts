{{/*
Expand the name of the chart.
*/}}
{{- define "namespace-admission-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "namespace-admission-controller.mutating.name" -}}
{{- $defaultName := printf "mutating-%s" .Chart.Name }}
{{- default $defaultName .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "namespace-admission-controller.validating.name" -}}
{{- $defaultName := printf "validating-%s" .Chart.Name }}
{{- default $defaultName .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "namespace-admission-controller.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "namespace-admission-controller.mutating.fullname" -}}
{{- $defaultName := printf "mutating-%s" .Chart.Name }}
{{- $name := default $defaultName .Values.mutatingController.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "namespace-admission-controller.validating.fullname" -}}
{{- $defaultName := printf "validating-%s" .Chart.Name }}
{{- $name := default $defaultName .Values.validatingController.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create service name for admission service from chart name or apply override.
*/}}
{{- define "namespace-admission-controller.mutating.service.name" -}}
{{- default (include "namespace-admission-controller.mutating.fullname" .) .Values.mutatingController.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "namespace-admission-controller.validating.service.name" -}}
{{- default (include "namespace-admission-controller.validating.fullname" .) .Values.validatingController.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "namespace-admission-controller.mutating.service.fullname" -}}
{{- default ( printf "%s.%s.svc" (include "namespace-admission-controller.mutating.service.name" .) .Release.Namespace ) -}}
{{- end -}}

{{- define "namespace-admission-controller.validating.service.fullname" -}}
{{- default ( printf "%s.%s.svc" (include "namespace-admission-controller.validating.service.name" .) .Release.Namespace ) -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "namespace-admission-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "namespace-admission-controller.labels" -}}
helm.sh/chart: {{ include "namespace-admission-controller.chart" . }}
{{ include "namespace-admission-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "namespace-admission-controller.mutating.labels" -}}
helm.sh/chart: {{ include "namespace-admission-controller.chart" . }}
{{ include "namespace-admission-controller.mutating.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "namespace-admission-controller.validating.labels" -}}
helm.sh/chart: {{ include "namespace-admission-controller.chart" . }}
{{ include "namespace-admission-controller.validating.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "namespace-admission-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "namespace-admission-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "namespace-admission-controller.mutating.selectorLabels" -}}
app.kubernetes.io/name: {{ include "namespace-admission-controller.name" . }}
app.kubernetes.io/type: {{ include "namespace-admission-controller.mutating.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "namespace-admission-controller.validating.selectorLabels" -}}
app.kubernetes.io/name: {{ include "namespace-admission-controller.name" . }}
app.kubernetes.io/type: {{ include "namespace-admission-controller.validating.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use
*/}}
{{- define "namespace-admission-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "namespace-admission-controller.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate certificates for admission-controller webhooks
*/}}
{{- define "admission-controller.mutating.gen-certs" -}}
{{- $expiration := (.Values.admissionCA.expiration | int) -}}
{{- if (or (empty .Values.admissionCA.cert) (empty .Values.admissionCA.key)) -}}
{{- $ca :=  genCA "admission-controller-ca" $expiration -}}
{{- template "admission-controller.mutating.gen-client-tls" (dict "RootScope" . "CA" $ca) -}}
{{- else -}}
{{- $ca :=  buildCustomCert (.Values.admissionCA.cert | b64enc) (.Values.admissionCA.key | b64enc) -}}
{{- template "admission-controller.mutating.gen-client-tls" (dict "RootScope" . "CA" $ca) -}}
{{- end -}}
{{- end -}}

{{/*
Generate client key and cert from CA
*/}}
{{- define "admission-controller.mutating.gen-client-tls" -}}
{{- $cn := include "namespace-admission-controller.mutating.service.name" . -}}
{{- $altName1 := printf "%s.%s" $cn .Release.Namespace }}
{{- $altName2 := printf "%s.%s.svc" $cn .Release.Namespace }}
{{- $expiration := (.RootScope.Values.admissionCA.expiration | int) -}}
{{- $cert := genSignedCert $cn nil list( $altName1 $altName2) $expiration .CA }}
{{- $clientCA := .CA.Cert | b64enc }}
{{- $clientCert := default $cert.Cert .RootScope.Values.admissionSecret.cert | b64enc }}
{{- $clientKey := default $cert.Key .RootScope.Values.admissionSecret.key | b64enc }}
caCert: {{ $clientCA }}
clientCert: {{ $clientCert }}
clientKey: {{ $clientKey }}
{{- end -}}

{{/*
Generate certificates for admission-controller webhooks
*/}}
{{- define "admission-controller.validating.gen-certs" -}}
{{- $expiration := (.Values.admissionCA.expiration | int) -}}
{{- if (or (empty .Values.admissionCA.cert) (empty .Values.admissionCA.key)) -}}
{{- $ca :=  genCA "admission-controller-ca" $expiration -}}
{{- template "admission-controller.validating.gen-client-tls" (dict "RootScope" . "CA" $ca) -}}
{{- else -}}
{{- $ca :=  buildCustomCert (.Values.admissionCA.cert | b64enc) (.Values.admissionCA.key | b64enc) -}}
{{- template "admission-controller.validating.gen-client-tls" (dict "RootScope" . "CA" $ca) -}}
{{- end -}}
{{- end -}}

{{/*
Generate client key and cert from CA
*/}}
{{- define "admission-controller.validating.gen-client-tls" -}}
{{- $altNames := list ( include "namespace-admission-controller.validating.service.fullname" .RootScope) ( include "namespace-admission-controller.validating.service.name" .RootScope)   -}}
{{- $expiration := (.RootScope.Values.admissionCA.expiration | int) -}}
{{- $cert := genSignedCert ( include "namespace-admission-controller.validating.service.fullname" .RootScope) nil $altNames $expiration .CA -}}
{{- $clientCA := .CA.Cert | b64enc -}}
{{- $clientCert := default $cert.Cert .RootScope.Values.admissionSecret.cert | b64enc -}}
{{- $clientKey := default $cert.Key .RootScope.Values.admissionSecret.key | b64enc -}}
caCert: {{ $clientCA }}
clientCert: {{ $clientCert }}
clientKey: {{ $clientKey }}
{{- end -}}


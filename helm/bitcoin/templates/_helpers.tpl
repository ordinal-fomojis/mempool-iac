{{/* Port of RPC connections for the bitcoin node. */}}
{{- define "bitcoin.rpcPort" -}}
{{- if .chain | eq "main" -}}
{{ 8332 }}
{{- else if .chain | eq "test" -}}
{{ 18332 }}
{{- else if .chain | eq "signet" -}}
{{ 38332 }}
{{- else if .chain | eq "testnet4" -}}
{{ 48332 }}
{{- else -}}
{{ fail "Invalid chain name" }}
{{- end -}}
{{- end -}}

{{/* Network to be used in mempool config. */}}
{{- define "bitcoin.mempoolNetwork" -}}
{{- if .chain | eq "main" -}}
{{ "mainnet" }}
{{- else if .chain | eq "test" -}}
{{ "testnet" }}
{{- else if .chain | eq "signet" -}}
{{ "signet" }}
{{- else if .chain | eq "testnet4" -}}
{{ "testnet" }}
{{- else -}}
{{ fail "Invalid chain name" }}
{{- end -}}
{{- end -}}

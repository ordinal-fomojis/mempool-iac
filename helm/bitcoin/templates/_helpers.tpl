{{/* Port of RPC connections for the bitcoin node. */}}
{{- define "bitcoin.rpcPort" -}}
{{- if .chain | eq "main" -}}
8332
{{- else if .chain | eq "test" -}}
18332
{{- else if .chain | eq "signet" -}}
38332
{{- else if .chain | eq "testnet4" -}}
48332
{{- else -}}
{{ fail "Invalid chain name" }}
{{- end -}}
{{- end -}}

{{/* Network to be used in mempool config. */}}
{{- define "bitcoin.mempoolNetwork" -}}
{{- if .chain | eq "main" -}}
mainnet
{{- else if .chain | eq "test" -}}
testnet
{{- else if .chain | eq "signet" -}}
signet
{{- else if .chain | eq "testnet4" -}}
testnet
{{- else -}}
{{ fail "Invalid chain name" }}
{{- end -}}
{{- end -}}

{{/* Create chain specific name */}}
{{- define "bitcoin.name" -}}
{{- if .chain | eq "main" -}}
{{ .name }}
{{- else if .chain | eq "test" -}}
testnet3-{{ .name }}
{{- else if .chain | eq "signet" -}}
signet-{{ .name }}
{{- else if .chain | eq "testnet4" -}}
testnet-{{ .name }}
{{- else -}}
{{ fail "Invalid chain name" }}
{{- end -}}
{{- end -}}

{{/* Create chain specific url */}}
{{- define "bitcoin.url" -}}
{{- if .chain | eq "main" -}}
{{ .url }}
{{- else if .chain | eq "test" -}}
testnet3.{{ .url }}
{{- else if .chain | eq "signet" -}}
signet.{{ .url }}
{{- else if .chain | eq "testnet4" -}}
testnet.{{ .url }}
{{- else -}}
{{ fail "Invalid chain name" }}
{{- end -}}
{{- end -}}

{{/* Bitcoin Service Name */}}
{{- define "bitcoin.bitcoinServiceName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "bitcoin-service") -}}
{{- end -}}

{{/* Bitcoin Statefulset Name */}}
{{- define "bitcoin.bitcoinStatefulsetName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "bitcoin") -}}
{{- end -}}

{{/* Mempool Service Name */}}
{{- define "bitcoin.mempoolServiceName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "mempool-service") -}}
{{- end -}}

{{/* Mempool Statefulset Name */}}
{{- define "bitcoin.mempoolStatefulsetName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "mempool") -}}
{{- end -}}

{{/* Mempool Config Name */}}
{{- define "bitcoin.mempoolConfigName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "mempool-config") -}}
{{- end -}}

{{/* DB Config Name */}}
{{- define "bitcoin.dbConfigName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "db-config") -}}
{{- end -}}

{{/* Bitcoin Ingress Name */}}
{{- define "bitcoin.bitcoinIngressName" -}}
{{- include "bitcoin.name" (dict "chain" .chain "name" "bitcoin-ingress") -}}
{{- end -}}

{{/* Mempool URL */}}
{{- define "bitcoin.mempoolUrl" -}}
{{- include "bitcoin.url" (dict "chain" .chain "url" "mempool.generatord.io") -}}
{{- end -}}

{{/* Bitcoin URL */}}
{{- define "bitcoin.bitcoinUrl" -}}
{{- include "bitcoin.url" (dict "chain" .chain "url" "bitcoin.generatord.io") -}}
{{- end -}}
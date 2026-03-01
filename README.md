# mempool-iac

Infrastructure-as-code for running a self-hosted [mempool.space](https://mempool.space) instance on Azure Kubernetes Service (AKS). This deploys Bitcoin Core nodes alongside the Mempool backend API, fronted by an NGINX ingress with TLS and basic auth.

The API exposes both Bitcoin RPC and Mempool endpoints. The setup is designed to be production-ready, with persistent storage, health checks, and secure access.

## What this sets up

Each environment (prod / nonprod) gets its own isolated AKS cluster with:

- **Bitcoin Core nodes** -- built from source (v28.0) via a custom Docker image, running as StatefulSets with persistent storage for blockchain data. A readiness probe ensures pods aren't marked ready until the initial block download finishes.
- **Mempool backend** -- the `mempool/backend` container, paired with a MariaDB sidecar in the same pod. Connects to the Bitcoin node over RPC for block and transaction data.
- **NGINX Ingress Controller** -- handles TLS termination (via cert-manager / Let's Encrypt) and basic auth. Routes traffic to Bitcoin RPC and Mempool API endpoints using path-based routing.
- **Multi-chain support** -- testnet and mainnet are independently toggleable. Each enabled chain gets its own complete set of StatefulSets, Services, and ConfigMaps with chain-prefixed names.

The rough architecture looks like this:

```
Internet
  |
  |  HTTPS (Let's Encrypt)
  v
+----------------------------------------------+
|         NGINX Ingress Controller             |
|  (basic auth on all routes)                  |
|                                              |
|  /             -> bitcoin-service (mainnet)  |
|  /testnet4     -> testnet-bitcoin-service    |
|  /mempool      -> mempool-service (mainnet)  |
|  /mempool/testnet4 -> testnet-mempool-service|
+---------------------+-----------+------------+
                      |           |
              +-------v---+   +---v------------------+
              | Bitcoin    |   | Mempool StatefulSet  |
              | StatefulSet|   |  +---------+-------+ |
              |            |<--+  | mempool | maria | |
              | (bitcoind) | RPC  | backend | db    | |
              |            |   |  +----+----+---+---+ |
              | PVC: chain |   |       | localhost |   |
              |   data     |   |       +----------+   |
              +------------+   | PVC: db   PVC: cache |
                               +-----------+----------+
```

## Prerequisites

Everything runs through GitHub Actions, so there's nothing to install locally. The workflows authenticate to Azure via OIDC (workload identity federation), so the following secrets need to be configured in the repository:

- `AZURE_CLIENT_ID` -- service principal / app registration client ID
- `AZURE_SUBSCRIPTION_ID` -- target Azure subscription
- `AZURE_TENANT_ID` -- Azure AD tenant
- `API_PASSWORD` -- password for the basic auth layer on the ingress
- `VERCEL_TOKEN` -- API token for Vercel DNS management

The repo uses GitHub environments (`prod` and `nonprod`) to scope these secrets per environment.

## Repository layout

```
.github/workflows/   GitHub Actions workflow definitions
terraform/           Terraform config for AKS, ACR, resource groups, and passwords
helm/bitcoin/        Helm chart for the full stack (Bitcoin, Mempool, MariaDB, Ingress)
docker/bitcoin/      Dockerfile that builds Bitcoin Core v28.0 from source
dns/                 TypeScript script to point a Vercel-managed domain at the cluster IP
local/               Helper scripts (used by the workflows)
```

## Deployment

All deployment is handled via three GitHub Actions workflows, each triggered manually through the Actions tab. Every workflow takes an environment input (`prod` or `nonprod`) to select the target.

### 1. Deploy IaC (`deploy-iac.yaml`)

Provisions the Azure infrastructure -- resource group, AKS cluster, container registry, and generated passwords.

This workflow has two jobs:

1. **Terraform Plan** -- runs on every PR and on manual dispatch. Produces a plan, uploads it as an artifact, and posts a summary to the workflow run.
2. **Terraform Apply** -- only runs when the plan detects changes. For prod, it creates a GitHub issue requesting manual approval before applying. Nonprod applies automatically on the main branch.

Terraform state is stored per-environment in an Azure Storage Account backend (`fomojisterraform`), keyed as `terraform-prod.tfstate` / `terraform-nonprod.tfstate`.

### 2. Build Bitcoin (`build-bitcoin.yaml`)

Builds the custom Bitcoin Core v28.0 Docker image from `docker/bitcoin/Dockerfile` and pushes it to the Azure Container Registry. The image is tagged with the commit SHA. Runs on an ARM64 runner and uses GitHub Actions cache for Docker layer caching.

Trigger this whenever the Dockerfile changes or you want to pick up a new Bitcoin Core version.

### 3. Deploy Application (`deploy-application.yaml`)

Deploys the full application stack to the AKS cluster. This is the main workflow you'll run after infrastructure and the Bitcoin image are in place. It does the following:

1. Reads Terraform outputs (cluster name, resource group, ACR name, passwords).
2. Connects to the AKS cluster via `kubelogin`.
3. Installs cert-manager for TLS certificate provisioning.
4. Runs `helm upgrade --install` with all passwords, the latest Bitcoin image tag from ACR, and environment-specific settings (prod enables mainnet; nonprod is testnet only).
5. Waits briefly for the load balancer to come up, then runs the DNS setup script to create or update an A record in Vercel pointing at the cluster's external IP.

### Typical order of operations

For a fresh deployment from scratch:

1. Run **Deploy IaC** to create the Azure resources.
2. Run **Build Bitcoin** to build and push the Docker image.
3. Run **Deploy Application** to deploy everything to the cluster.

## Environments

| Environment | Resource Group   | VM Size             | Chains enabled       |
|-------------|------------------|---------------------|----------------------|
| nonprod     | mempool-nonprod  | Standard_D2ps_v6    | testnet4             |
| prod        | mempool-prod     | Standard_D8ps_v6    | testnet4 + mainnet   |

Terraform state is stored remotely in an Azure Storage Account (`fomojisterraform` in the `iac` resource group), with separate state files per environment.

## Helm values

The default `values.yaml` has passwords and hostname set to `null` -- these are injected at deploy time by the Deploy Application workflow via Helm `--set` flags. You shouldn't need to edit `values.yaml` directly for normal deployments.

Key settings you might want to tweak:

- `chains.<chain>.bitcoinStorage` -- PVC size for blockchain data
- `chains.<chain>.bitcoinNodeReplicas` / `mempoolReplicas` -- replica counts
- `chains.<chain>.dbSize` / `cacheSize` -- PVC sizes for MariaDB and Mempool cache
- `chains.<chain>.spawnProcs` -- number of Mempool worker processes

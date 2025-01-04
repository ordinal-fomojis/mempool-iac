if [ -z "$1" ]; then
  echo "Usage: $0 <prod|nonprod>"
  exit 1
fi

export ARM_SUBSCRIPTION_ID=cc174810-b2c5-4ca2-8397-0c701e8a2b96
cd terraform
terraform init -backend-config="key=terraform-$1.tfstate" -reconfigure
rg_name=$(terraform output -raw rg_name)
cluster_name=$(terraform output -raw kube_cluster_name)
az aks get-credentials --resource-group $rg_name --name $cluster_name
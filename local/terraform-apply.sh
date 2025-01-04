if [ -z "$1" ]; then
  echo "Usage: $0 <prod|nonprod>"
  exit 1
fi

cd terraform
export ARM_SUBSCRIPTION_ID=cc174810-b2c5-4ca2-8397-0c701e8a2b96
terraform init -backend-config="key=terraform-$1.tfstate" -reconfigure
terraform apply -var-file="$1.tfvars" -auto-approve
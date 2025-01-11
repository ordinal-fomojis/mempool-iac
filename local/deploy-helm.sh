if [ -z "$1" ]; then
  echo "Usage: $0 <prod|nonprod>"
  exit 1
fi

if [ "$1" == "prod" ]; then
  mainnet=true
  SUB_DOMAIN="bitcoin"
else
  mainnet=false
  SUB_DOMAIN="nonprod.bitcoin"
fi

DOMAIN="generatord.io"
export ARM_SUBSCRIPTION_ID=cc174810-b2c5-4ca2-8397-0c701e8a2b96
cd terraform
terraform init -backend-config="key=terraform-$1.tfstate" -reconfigure

acr_name=$(terraform output -raw acr_name)
image_tag=$(az acr repository show-tags --n $acr_name --repository bitcoin \
  --orderby time_desc --top 1 --output tsv)
passwords=$(terraform output -json passwords)
helm upgrade --install bitcoin ../helm/bitcoin \
  --set acrName=$acr_name \
  --set bitcoinImageTag=$image_tag \
  --set chains.mainnet.enabled=$mainnet \
  --set chains.testnet.rpcPassword="$(echo $passwords | jq -r '."testnet-rpc"')" \
  --set chains.mainnet.rpcPassword="$(echo $passwords | jq -r '."mainnet-rpc"')" \
  --set chains.testnet.dbPassword="$(echo $passwords | jq -r '."testnet-db"')" \
  --set chains.mainnet.dbPassword="$(echo $passwords | jq -r '."mainnet-db"')" \
  --set chains.testnet.dbRootPassword="$(echo $passwords | jq -r '."testnet-db-root"')" \
  --set chains.mainnet.dbRootPassword="$(echo $passwords | jq -r '."mainnet-db-root"')" \
  --set hostname=$SUB_DOMAIN.$DOMAIN
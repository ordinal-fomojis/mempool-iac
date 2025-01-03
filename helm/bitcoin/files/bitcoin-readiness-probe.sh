info=$(bitcoin-cli -rpcuser=$1 -rpcpassword=$2 -chain=$3 -rpcwait getblockchaininfo)
ibd=$(echo $info | jq -r '.initialblockdownload')
if [ "$ibd" == "true" ]; then
  exit 1
fi

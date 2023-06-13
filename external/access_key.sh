#!/usr/bin/env bash 


region="$1"

path=$(which outline-vpn)
path="${path//bin/lib}"
path=$(echo $path/outline-vpn/terraform.tfstate.d/"$region"/)

apiUrl=$(jq ".ApiUrl" "$path"/outline.json | sed 's/\"//g')


accessKey=$(curl --insecure -sX POST "$apiUrl"/access-keys | jq '.accessUrl' | sed 's/\"//g')
jq -n --arg accessKey "$accessKey" '{"accessKey": $accessKey}' 





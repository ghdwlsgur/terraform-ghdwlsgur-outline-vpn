#!/usr/bin/env bash

region=$(echo "$1")
path=$(which outline-vpn)
path="${path//bin/lib}"
path=$(echo $path/outline-vpn/terraform.tfstate.d/"$region"/)


while true; do
  if [ -f "$path"outline.json ]; then
    terraform apply --auto-approve -lock=false
    break
  fi
  sleep 1
done

#!/usr/bin/env bash 

set -o nounset -o errexit -o pipefail -o errtrace

function get_access_key() {
  local path=$(echo "$1")
  local region=$(echo "$2")
  local apiUrl=$(jq ".ApiUrl" "$path"/outline.json | sed 's/\"//g')
  local accessKey=$(curl --insecure -sX POST "$apiUrl"/access-keys | jq '.accessUrl' | sed 's/\"//g')

  jq -n --arg accessKey "$accessKey" '{"accessKey": $accessKey}' 
}

function main() {
  trap finish EXIT

  declare -a path 
  path+=("$(which outline-vpn)")
  path+=("${path[0]}//bin/lib")
  path+=("${path[1]}/outline-vpn/terraform.tfstate.d/"$region"/")

  local region=$(echo "$1")
  get_access_key "$path" "$region"
}

main "$@"
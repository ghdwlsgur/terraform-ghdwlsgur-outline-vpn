#!/usr/bin/env bash

set -o nounset -o errexit -o pipefail -o errtrace

yum update -y
sudo yum install jq yum-utils -y
sudo yum install docker -y
sudo service docker start
sudo chkconfig docker on

sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)" > /var/log/outline-install.log

function create_install_log() {
  local log_file="/var/log/outline-install.log"

cat > /tmp/outline.json << EOF 
{ 
  "ManagementUdpPort" : $(< $log_file grep "Management port" | cut -d ',' -f1 | cut -d ' ' -f4), 
  "VpnTcpUdpPort" : $(< $log_file grep 'Access key port' | cut -d ',' -f1 | cut -d ' ' -f5), 
  "ApiUrl" : "$(< $log_file grep 'apiUrl' | cut -d '"' -f4)",
  "CertSha256" : "$(< $log_file grep 'apiUrl' | cut -d '"' -f8)"
} 
EOF
}

function main() {
  create_install_log
}

main "$@"

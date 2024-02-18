#!/usr/bin/env bash 

set -o nounset -o errexit -o pipefail -o errtrace

function get_install_server_log() {
  local path=$(echo "$1")
  local region=$(echo "$2")
  local public_dns=$(echo "$3")
  local key_pair="~/.ssh/govpn_$(echo "$region").pem"
  local ec2_hostname="ec2-user"
  local outline_file_location="/tmp/outline.json"
      
  rsync -avz -delete -partial -e "ssh -o StrictHostKeyChecking=no -i $key_pair" "$ec2_hostname"@"$public_dns":"$outline_file_location" "$path" > /dev/null
}

function create_terraform_security_group_rules() {
  local path=$(echo "$1")
  local region=$(echo "$2")
  local my_ip=$(echo "$3")
  local get_management_port=$(jq ".ManagementUdpPort" "$path"/outline.json)
	local get_vpn_port=$(jq ".VpnTcpUdpPort" "$path"/outline.json)  
  local get_my_ip=$(echo "[\"$my_ip/32\"]")
  
cat > "$path/tcp_ingress_rules.tf" <<-EOF
resource "aws_security_group_rule" "management_tcp_port" {
  type              = "ingress"
  description       = "Allow Management TCP port from only my ip"
  from_port         = $get_management_port
  to_port           = $get_management_port
  protocol          = "tcp"
  cidr_blocks       = $get_my_ip
  security_group_id = module.outline-vpn.SecurityGroupID
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "vpn_tcp_port" {
  type              = "ingress"
  description       = "Allow TCP port from only my ip"
  from_port         = $get_vpn_port
  to_port           = $get_vpn_port
  protocol          = "tcp"
  cidr_blocks       = $get_my_ip
  security_group_id = module.outline-vpn.SecurityGroupID  
  lifecycle { create_before_destroy = true }
}
EOF

cat > "$path/udp_ingress_rules.tf" <<-EOF
resource "aws_security_group_rule" "management_udp_port" {
  type              = "ingress"
  description       = "Allow Management UDP port from only my ip"
  from_port         = $get_management_port
  to_port           = $get_management_port
  protocol          = "udp"
  cidr_blocks       = $get_my_ip
  security_group_id = module.outline-vpn.SecurityGroupID
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "vpn_udp_port" {
  type              = "ingress"
  description       = "Allow UDP port from only my ip"
  from_port         = $get_vpn_port
  to_port           = $get_vpn_port
  protocol          = "udp"
  cidr_blocks       = $get_my_ip
  security_group_id = module.outline-vpn.SecurityGroupID    
  lifecycle { create_before_destroy = true }
}
EOF
}

function main() {
  trap finish EXIT

  declare -a path 
  path+=("$(which outline-vpn)")
  path+=("${path[0]}//bin/lib")
  path+=("${path[1]}/outline-vpn/terraform.tfstate.d/"$region"/")

  local region=$(echo "$1")
  local public_dns=$(echo "$2")
  local my_ip=$(echo "$3")

  get_install_server_log "$path" "$region" "$public_dns"
  create_terraform_security_group_rules "$path" "$region" "$my_ip"
}

main "$@"
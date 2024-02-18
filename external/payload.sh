#!/usr/bin/env bash

set -o nounset -o errexit -o pipefail -o errtrace

yum update -y
sudo yum install jq yum-utils -y
sudo yum install docker -y
sudo service docker start
sudo chkconfig docker on



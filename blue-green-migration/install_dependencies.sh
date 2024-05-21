#!/bin/bash
echo -e "###################################################################
# Script Name  : install_dependencies.sh
# Version      : 1.0
# Description  : Install all required dependency packages.
#       It assumes that apt tool is already preinstalled
# Author       : Piotr Wolszakiewicz
###################################################################"


apt-get update --quiet
apt-get install curl jq -y -q
# wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# tool to do url encode
# apt-get install gridsite-clients -y -q
#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport
vhost="$1"

echo -e "###################################################################
# Script Name  : disable_federation.sh
# Version      : 1.0
# Description  : Script delete upstream federation and federation policy
#    on the green cluster.
#    Script import environment variables from .env file
# Args         :
#    vhost=${vhost}
#    green_api_url=${green_api_url}
#    green_user=${green_user}
#    green_password=${green_password:0:1}***${green_password: -1}
# Author       : Piotr Wolszakiewicz
###################################################################"

if [ $# -ne 1 ]; then
    echo "Error: vhost ($vhost) argument is required."
    echo "Usage: $0 vhost_name"
    exit 1
fi

source rabbitmq_api_utils.sh

delete_federation_policy "$green_api_url" "$green_user:$green_password" "$vhost"
delete_federation_upstream "$green_api_url" "$green_user:$green_password" "$vhost"

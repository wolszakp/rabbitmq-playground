#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport
vhost="$1"

echo -e "###################################################################
# Script Name  : get_vhost_stats.sh
# Version      : 1.0
# Description  : Script gets queue stats for provided vhost. Script is called
#    on the blue cluster.
#    Script import environment variables from .env file
# Args         :
#    vhost=${vhost}
#    blue_api_url=${blue_api_url}
#    blue_user=${blue_user}
#    blue_password=${blue_password:0:1}***${blue_password: -1}
# Author       : Piotr Wolszakiewicz
###################################################################"

if [ $# -ne 1 ]; then
    echo "Error: vhost ($vhost) argument is required."
    echo "Usage: $0 vhost_name"
    exit 1
fi

source rabbitmq_api_utils.sh

get_vhost_stats "$blue_api_url" "$blue_user:$blue_password" "$vhost"
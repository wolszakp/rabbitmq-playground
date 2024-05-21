#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport
vhost="$1"

echo -e "###################################################################
# Script Name  : enable_federation.sh
# Version      : 1.0
# Description  : Script creates upstream federation and federation policy
#    on the queue level between green and blue cluster.
#    Script import environment variables from .env file
# Args         :
#    vhost=${vhost}
#    federation_queue_pattern=${federation_queue_pattern}
#    blue_host=${blue_host}
#    blue_amqp_port=${blue_amqp_port}
#    blue_protocol=${blue_protocol}
#    blue_user=${blue_user}
#    blue_password=${blue_password:0:1}***${blue_password: -1}
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

blue_password_encoded=$(urlencode "$blue_password")
blue_url="$blue_protocol://$blue_user:$blue_password_encoded@$blue_host:$blue_amqp_port"

create_federation_upstream "$green_api_url" "$green_user:$green_password" "$vhost" "$blue_url"
create_federation_policy "$green_api_url" "$green_user:$green_password" "$vhost" "$federation_queue_pattern"

#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

echo -e "###################################################################
# Script Name  : enable_federation_for_all.sh
# Version      : 1.0
# Description  : Script creates upstream federation and federation policy
#    on the queue level between green and blue cluster
#    for all vhosts in green cluster.
#    Script import environment variables from .env file
# Args         :
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

source rabbitmq_api_utils.sh

blue_password_encoded=$(urlencode "$blue_password")
blue_url="$blue_protocol://$blue_user:$blue_password_encoded@$blue_host:$blue_amqp_port"

cluster_name="green"
logger "Getting vhosts from: $cluster_name cluster"
vhosts=$(get_all_vhosts "$green_api_url" "$green_user:$green_password" $cluster_name)

for vhost in $vhosts; do
    if [[ $vhost = "/" ]]; then
        echo "Skiping root vhost: /"
        continue
    fi
    echo "Processing vhost: $vhost"
    create_federation_upstream "$green_api_url" "$green_user:$green_password" "$vhost" "$blue_url"
    create_federation_policy "$green_api_url" "$green_user:$green_password" "$vhost" "$federation_queue_pattern"
    echo "Processed vhost: $vhost - successfully"
done


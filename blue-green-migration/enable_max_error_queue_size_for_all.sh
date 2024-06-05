#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

echo -e "###################################################################
# Script Name  : enable_max_error_queue_size_for_all.sh
# Version      : 1.0
# Description  : Script creates policy in green cluster
#    on the queue level to limit max number of messages
#    in all queues with suffix _error
#    It runs for all vhosts in green cluster.
#    Script import environment variables from .env file
# Args         :
#    error_queue_pattern=${error_queue_pattern}
#    max_error_queue_size=${max_error_queue_size}
#    green_api_url=${green_api_url}
#    green_user=${green_user}
#    green_password=${green_password:0:1}***${green_password: -1}
# Author       : Piotr Wolszakiewicz
###################################################################"

source rabbitmq_api_utils.sh

cluster_name="green"
logger "Getting vhosts from: $cluster_name cluster"
vhosts=$(get_all_vhosts "$green_api_url" "$green_user:$green_password" $cluster_name)

for vhost in $vhosts; do
    if [[ $vhost = "/" ]]; then
        echo "Skiping root vhost: /"
        continue
    fi
    echo "Processing vhost: $vhost"
    create_max_queue_size_policy "$green_api_url" "$green_user:$green_password" "$vhost" "$error_queue_pattern" "$max_error_queue_size"
    echo "Processed vhost: $vhost - successfully"
done


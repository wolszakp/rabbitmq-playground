#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport
vhost="$1"

echo -e "###################################################################
# Script Name  : enable_max_error_queue_size.sh
# Version      : 1.0
# Description  : Script creates policy in green cluster
#    on the queue level to limit max number of messages
#    in all queues with suffix _error
#    Script import environment variables from .env file
# Args         :
#    vhost=${vhost}
#    error_queue_pattern=${error_queue_pattern}
#    max_error_queue_size=${max_error_queue_size}
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

cluster_name="green"
logger "Processing vhost from: $cluster_name cluster"
create_max_queue_size_policy "$green_api_url" "$green_user:$green_password" "$vhost" "$error_queue_pattern" "$max_error_queue_size"
logger "Processed vhost: $vhost - successfully"
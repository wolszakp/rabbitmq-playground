#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

echo -e "###################################################################
# Script Name  : disable_federation_for_all.sh
# Version      : 1.0
# Description  : Script disable upstream federation and federation policy
#    for all vhosts in green cluster.
#    Script import environment variables from .env file
# Args         :
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
    delete_federation_policy "$green_api_url" "$green_user:$green_password" "$vhost"
    delete_federation_upstream "$green_api_url" "$green_user:$green_password" "$vhost"
    echo "Processed vhost: $vhost - successfully"
done


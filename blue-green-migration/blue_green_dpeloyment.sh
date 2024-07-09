#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport
set -eo pipefail

echo -e "###################################################################
# Script Name  : blue_green_dpeloyment.sh
# Version      : 1.0
# Description  : Script do complete blue-green deploymnet.
#    It export definition from existing cluster - blue
#    Skip _error(queues, bindings, exchanges) and skip cluster name
#    Import definition into new cluster - green
#    Set up queue federation for all vhosts in green cluster
#    Script import environment variables from .env file
# Args         :
#    federation_queue_pattern=${federation_queue_pattern}
#    blue_host=${blue_host}
#    blue_amqp_port=${blue_amqp_port}
#    blue_protocol=${blue_protocol}
#    blue_api_url=${blue_api_url}
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

echo "export definitions from blue cluster"
cluster_definition_file="./blue-cluster-definitions-$RANDOM.json"
get_cluster_definitions "$blue_api_url" "$blue_user:$blue_password" "$cluster_definition_file"
echo "Blue cluster definitions stored in $cluster_definition_file"

echo "Remove error queues, bindings and exchanges"
echo "Remove global_parameters (e.g. cluster_name)"
cluster_definition_file_modified="./modified-blue-cluster-definitions-$RANDOM.json"
jq '
  .queues |= map(select(.name | endswith("_error") | not) | select(.auto_delete == false)) |
  .exchanges |= map(select(.name | endswith("_error") | not) | select(.auto_delete == false)) |
  .bindings |= map(select((.destination | endswith("_error") | not) and (.source | endswith("_error") | not))) |
  del(.global_parameters)
' "$cluster_definition_file" > "$cluster_definition_file_modified"
# cat $cluster_definition_file_modified | jq

set_cluster_definitions "$green_api_url" "$green_user:$green_password" "$cluster_definition_file_modified"

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
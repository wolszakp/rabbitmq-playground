#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport
set -eo pipefail

echo -e "###################################################################
# Script Name  : backup_and_restore.sh
# Version      : 1.0
# Description  : Script do backup and restore between two servers.
#    It export definition from existing cluster - blue
#    Skip _error(queues, bindings, exchanges) and skip cluster name
#    Skip also auto_delete (exchanges and queues) while they are deleted 
#    after connection lost.
#    Import definition into new cluster - green
#    Script import environment variables from .env file
# Args         :
#    blue_api_url=${blue_api_url}
#    blue_user=${blue_user}
#    blue_password=${blue_password:0:1}***${blue_password: -1}
#    green_api_url=${green_api_url}
#    green_user=${green_user}
#    green_password=${green_password:0:1}***${green_password: -1}
# Author       : Piotr Wolszakiewicz
###################################################################"

source rabbitmq_api_utils.sh

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
#!/bin/bash

input_file="$1"
output_file="$2"
vhosts='"alfa", "beta", "gamma", "delta", "omega"'
echo -e "###################################################################
# Script Name  : slim_rabbitmq_definition.sh
# Version      : 1.0
# Description  : Script should be called with json file (export from rabbitmq cluster)
#    Script select definitions related to only some vhosts
# Args         :
#    input_file=${input_file}
#    output_file=${output_file}
#    vhosts=${vhosts[@]}
# Author       : Piotr Wolszakiewicz
###################################################################"

if [ $# -ne 2 ]; then
  echo "Error: input_file ($input_file) and output_file($output_file) arguments are required."
  echo "Usage: $0 input_file output_file"
  exit 1
fi

vhosts_json=$(printf '%s\n' "${vhosts[@]}" | jq -R . | jq -s . | jq -r 'join("")')
echo $vhosts_json

jq  "
  .users |= map(select(.name | IN($vhosts) )) |
  .vhosts |= map(select(.name | IN($vhosts) )) |
  .permissions |= map(select(.vhost | IN($vhosts) )) |
  .policies |= map(select(.vhost | IN($vhosts) )) |
  .queues |= map(select(.vhost | IN($vhosts) )) |
  .exchanges |= map(select(.vhost | IN($vhosts) )) |
  .bindings |= map(select(.vhost | IN($vhosts) ))
" "$input_file" > "$output_file"

echo "Updated JSON has been saved to $output_file"

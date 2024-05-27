#!/bin/bash

input_file="$1"
output_file="$2"
echo -e "###################################################################
# Script Name  : change_queue_definitions_to_quorum.sh
# Version      : 1.0
# Description  : Script should be called with json file (export from rabbitmq cluster)
#    Script exchange classic queue type to quorum for all queues in all vhosts
#    but only those that have auto_delete set to false
#    Script also omit queues, exchanges and bindings for error definitions
#    with name (source, destination for bindings) that has '_error' suffix
# Args         :
#    input_file=${input_file}
#    output_file=${output_file}
# Author       : Piotr Wolszakiewicz
###################################################################"

if [ $# -ne 2 ]; then
  echo "Error: input_file ($input_file) and output_file($output_file) arguments are required."
  echo "Usage: $0 input_file output_file"
  exit 1
fi

jq '
  .queues |= map(select(.name | endswith("_error") | not)) |
  .queues |= map(
    if .type == "classic" and .auto_delete == false then
      .type = "quorum"
    else
      .
    end
  ) |
  .exchanges |= map(select(.name | endswith("_error") | not)) |
  .bindings |= map(select((.destination | endswith("_error") | not) and (.source | endswith("_error") | not)))
' "$input_file" > "$output_file"

echo "Updated JSON has been saved to $output_file"

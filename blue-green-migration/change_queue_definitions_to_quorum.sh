#!/bin/bash

input_file="$1"
output_file="$2"
skipped_queues="lighthouse.notifications_"
echo -e "###################################################################
# Script Name  : change_queue_definitions_to_quorum.sh
# Version      : 1.0
# Description  : Script should be called with json file (export from rabbitmq cluster) 
#    Script exchange classic queue type to quorum for all queues in all vhosts
# Args         :
#    input_file=${input_file}
#    output_file=${output_file}
#    skipped_queues=${skipped_queues} - queues with names starts like this will be omitted
# Author       : Piotr Wolszakiewicz
###################################################################"

if [ $# -ne 2 ]; then
  echo "Error: input_file ($input_file) and output_file($output_file) arguments are required."
  echo "Usage: $0 input_file output_file"
  exit 1
fi

jq '
  .queues |= map(
    if .type == "classic" and (.name | startswith("'$skipped_queues'") | not) then
      .type = "quorum"
    else
      .
    end
  )
' "$input_file" > "$output_file"

echo "Updated JSON has been saved to $output_file"

#!/bin/bash
echo -e "###################################################################
# Script Name  : rabbitmq_api_utils.sh
# Version      : 1.0
# Description  : Source library with rabbitmq function utils
# Author       : Piotr Wolszakiewicz
###################################################################"

# TODO: how to do it conditionally
# source install_dependencies.sh

logger() {
    local log_message="$1"
    local is_success="$2"

    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m' # No Color

    color=$NC
    if [ "$is_success" = true ]; then
        color=$GREEN
    elif [ "$is_success" = false ]; then
        color=$RED
    fi

    echo -e "${color} $(date +"%Y-%m-%d %H:%M:%S") $log_message ${NC}"
}

urlencode() {
    local raw_input="$1"
    echo -n "$raw_input" | jq -sRr @uri
}

get_federation_upstream_name() {
    local vhost="$1"
    echo -n "federation-$vhost-link"
}

get_federation_policy_name() {
    local vhost="$1"
    echo -n "federation-$vhost-policy"
}

create_federation_upstream() {
    local api_url="$1"
    local api_basic_auth="$2"
    local vhost="$3"
    local upstream_url="$4"
    local response_message="/tmp/create_federation_upstream_response-$RANDOM.txt"
    federation_upstream_name=$(get_federation_upstream_name "$vhost")
    request_url="$api_url/parameters/federation-upstream/$vhost/$federation_upstream_name"
    logger "Creating federation upstream $federation_upstream_name for vhost:$vhost"
    logger "Call RabbitMQ API: $request_url"
    data="{\"value\": {\"uri\": \"$upstream_url\", \"ack-mode\": \"on-confirm\"}}"
    logger "Create federation upstream DATA: $data"
    response_status=$(curl -s -i --fail-with-body -u "$api_basic_auth" -o $response_message -w "%{http_code}" -X PUT -H "Content-Type: application/json" -d "$data" "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Created federation upstream $federation_upstream_name for vhost:$vhost with success" true
    else
        cat $response_message
        logger "Error: failed to create federation upstream $federation_upstream_name for vhost:$vhost" false
        return 1
    fi
}

delete_federation_upstream() {
    local api_url="$1"
    local api_basic_auth="$2"
    local vhost="$3"
    local response_message="/tmp/delete_federation_upstream_response-$RANDOM.txt"
    federation_upstream_name=$(get_federation_upstream_name "$vhost")
    request_url="$api_url/parameters/federation-upstream/$vhost/$federation_upstream_name"
    logger "Deleting federation upstream $federation_upstream_name for vhost:$vhost"
    logger "Call RabbitMQ API: $request_url"
    response_status=$(curl -s -i -u "$api_basic_auth" --fail-with-body -o $response_message -w "%{http_code}" -X DELETE "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Delete federation upstream $federation_upstream_name for vhost:$vhost with success" true
    else
        cat $response_message
        logger "Error: failed to delete federation upstream $federation_upstream_name for vhost:$vhost" false
        return 1
    fi
}

create_federation_policy() {
    local api_url="$1"
    local api_basic_auth="$2"
    local vhost="$3"
    local federation_queue_pattern="$4"
    local response_message="/tmp/create_federation_policy_response-$RANDOM.txt"
    federation_upstream_name=$(get_federation_upstream_name "$vhost")
    federation_policy_name=$(get_federation_policy_name "$vhost")
    request_url="$api_url/policies/$vhost/$federation_policy_name"
    logger "Creating federation policy $federation_policy_name for vhost:$vhost"
    logger "Call RabbitMQ API: $request_url"
    data="{\"pattern\":\"$federation_queue_pattern\", \"definition\": {\"federation-upstream\": \"$federation_upstream_name\"}, \"apply-to\": \"queues\"}"
    logger "Create federation policy DATA: $data"
    response_status=$(curl -s -i --fail-with-body -u "$api_basic_auth" -o $response_message -w "%{http_code}" -X PUT -H "Content-Type: application/json" -d "$data" "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Created federation policy $federation_policy_name for vhost:$vhost successfully" true
    else
        logger "Error: Failed to create federation policy $federation_policy_name for vhost:$vhost" false
        cat $response_message
        return 1
    fi
}

delete_federation_policy() {
    local api_url="$1"
    local api_basic_auth="$2"
    local vhost="$3"
    local response_message="/tmp/delete_federation_policy_response-$RANDOM.txt"
    federation_policy_name=$(get_federation_policy_name "$vhost")
    request_url="$api_url/policies/$vhost/$federation_policy_name"
    logger "Deleting federation policy $federation_policy_name for vhost:$vhost"
    logger "Call RabbitMQ API: $request_url"
    response_status=$(curl -s -i -u "$api_basic_auth" --fail-with-body -o $response_message -w "%{http_code}" -X DELETE "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Deleted federation policy $federation_policy_name for vhost:$vhost successfully" true
    else
        logger "Error: Failed to delete federation policy $federation_policy_name for vhost:$vhost" false
        cat $response_message
        return 1
    fi
}

check_api_connection() {
    local api_url="$1"
    local api_basic_auth="$2"
    local api_name="$3"
    local response_message="/tmp/check_api_connection-$RANDOM.txt"
    request_url="$api_url/overview"
    logger "Call RabbitMQ API: $request_url"
    response_status=$(curl -s -i -u "$api_basic_auth" --fail-with-body -o $response_message -w "%{http_code}" -X GET "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Api connection to $api_name cluster finished successfully" true
    else
        logger "Error: Failed to connect to $api_name cluster" false
        cat $response_message
        return 1
    fi
}

get_vhost_stats() {
    local api_url="$1"
    local api_basic_auth="$2"
    local vhost="$3"
    local response_message="/tmp/get_vhost_stats-$RANDOM.txt"
    local response_headers="/tmp/get_vhost_stats_headers-$RANDOM.txt"
    request_url="$api_url/queues/$vhost"
    logger "Getting queue stats for vhost: $vhost"
    logger "Call RabbitMQ API: $request_url"
    response_status=$(curl -s -D $response_headers --fail-with-body -u "$api_basic_auth" -o $response_message -w "%{http_code}" -X GET -H "Accept: application/json" "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Get queue stats for vhost: $vhost finished successfully" true
        total_messages_in_queues=$(cat $response_message | jq '[.[].messages] | add')
        # This is whole outpu json
        # cat $response_message | jq
        echo "There is $total_messages_in_queues messages in all queues for vhost: $vhost"
    else
        logger "Error: Failed to get queue stats for vhost: $vhost" false
        cat $response_headers
        cat $response_message
        return 1
    fi
}

delete_vhost() {
    local api_url="$1"
    local api_basic_auth="$2"
    local api_name="$3"
    local vhost="$4"
    local response_message="/tmp/delete_vhost_response-$RANDOM.txt"
    request_url="$api_url/vhosts/$vhost"
    logger "Deleting vhost: $vhost from: $api_name cluster"
    logger "Call RabbitMQ API: $request_url"
    response_status=$(curl -s -i -u "$api_basic_auth" --fail-with-body -o $response_message -w "%{http_code}" -X DELETE "$request_url")
    # all_vhosts=$(curl -s -D $response_headers -u "$api_basic_auth" --fail-with-body -X GET -H "Accept: application/json" "$api_url/vhosts")
    # number_of_vhosts=$(echo "$all_vhosts" | jq 'length')

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        logger "Deleted vhost: $vhost from $api_name cluster successfully" true
        # logger "There is still $number_of_vhosts vhosts in cluster $api_name"
    else
        logger "Error: Failed to delete vhost: $vhost from $api_name cluster" false
        cat $response_message
        return 1
    fi
}

get_all_vhosts() {
    local api_url="$1"
    local api_basic_auth="$2"
    local api_name="$3"
    local response_message="/tmp/get_all_vhost_response-$RANDOM.txt"
    local response_headers="/tmp/get_all_vhost_headers_response-$RANDOM.txt"
    request_url="$api_url/vhosts"
    response_status=$(curl -s -D $response_headers -u "$api_basic_auth" --fail-with-body -o $response_message -w "%{http_code}" -X GET "$request_url")

    if [[ $response_status -ge 200 && $response_status -lt 300 ]]; then
        vhosts=$(cat $response_message | jq -r '.[].name')
        echo "$vhosts"
    else
        logger "Error: Failed to get all vhosts from $api_name cluster" false
        cat $response_headers
        cat $response_message
        return 1
    fi
}
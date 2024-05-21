#!/bin/bash
# Import env variables from .env file
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

echo -e "###################################################################
# Script Name  : check_connectivity.sh
# Version      : 1.0
# Description  : Script verify if connections configuration
#    to blue and green clusters are valid.
#    Script import environment variables from .env file
# Args         :
#    vhost=${vhost}
#    federation_queue_pattern=${federation_queue_pattern}
#    blue_user=${blue_user}
#    blue_password=${blue_password:0:1}***${blue_password: -1}
#    blue_host=${blue_host}
#    blue_amqp_port=${blue_amqp_port}
#    blue_protocol=${blue_protocol}
#    blue_http_port=${blue_http_port}
#    blue_http_protocol=${blue_http_protocol}
#    blue_url=${blue_url}
#    blue_api_url=${blue_api_url}
#    green_user=${green_user}
#    green_password=${green_password:0:1}***${green_password: -1}
#    green_host=${green_host}
#    green_amqp_port=${green_amqp_port}
#    green_protocol=${green_protocol}
#    green_http_port=${green_http_port}
#    green_http_protocol=${green_http_protocol}
#    green_url=${green_url}
#    green_api_url=${green_api_url}
# Author       : Piotr Wolszakiewicz
###################################################################"
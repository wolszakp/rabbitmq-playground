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
#    blue_api_url=${blue_api_url}
#    blue_user=${blue_user}
#    blue_password=${blue_password:0:1}***${blue_password: -1}
#    green_api_url=${green_api_url}
#    green_user=${green_user}
#    green_password=${green_password:0:1}***${green_password: -1}
# Author       : Piotr Wolszakiewicz
###################################################################"

source rabbitmq_api_utils.sh

check_api_connection "$green_api_url" "$green_user:$green_password" "green"
check_api_connection "$blue_api_url" "$blue_user:$blue_password" "blue"

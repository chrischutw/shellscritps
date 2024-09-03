#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Source Library
source "$SCRIPT_DIR/../lib/cloudrun_functions.sh"

# Parameters
cr_name="$1"
project="$2"
region="$3"
load_balancer="$4"
domain="$5"
cr_name_rm="$6"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"$cr_name\" \"$project\" \"$region\" \"$load_balancer\" \"$domain\" \"$cr_name_rm\" is invalid, please check again"
    echo "Usage: $0 <cloud_run_service_name> <project> <region> <load_balanacer> <domain> <cloud_run_service_to_be_removed>"
    echo "Example: $0 superagent-api-stage-ap sinyi-cloud asia-east1 cr-ap-sinyi-cc-ilb sinyi-superagent-stage"
}

# Main function
main() {
    # Check if the correct number of arguments is passed
    if [[ -z $cr_name || -z $project || -z $region || -z $load_balancer || -z $domain || -z $cr_name_rm ]]; then
        print_usage
        exit 1
    fi

    # Input validation - Check if region is valid, if not, exit
    check_regions "$region"

    # Input validation - Check if the Cloud Run service exists, if not, exit
    check_cloudrun "$cr_name" || exit 1

    # Input validation - Check if the Cloud Run service exists, if not, exit
    check_cloudrun "$cr_name_rm" || exit 1

    # Input validation - Check if the Load Balancer exists, if not, exit
    check_load_balancer "$load_balancer" || exit 1

    # Check NEG, create new NEG if it doesn't exist
    check_neg "$cr_name" || create_neg "$cr_name"

    # Check backend, create new backend if it doesn't exist
    check_backend "$cr_name" || {
        create_backend "$cr_name" && add_backend "$cr_name"
    }

    # Check if the domain exists in the Load Balancer, if exists, remove URL map
    check_lb_domain "$domain" && remove_urlmap "$load_balancer" "$cr_name_rm" || exit 1

    # Add the new cloud run to LB
    check_lb_domain "$domain" || {
        add_urlmap "$load_balancer" "$cr_name" "$domain" || exit 1
    }
}

main "$@"

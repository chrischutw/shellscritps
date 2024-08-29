#!/bin/bash

# Source Library
source ../lib/cloudrun_functions.sh

# Parameters
cr_name="$1"
project="$2"
region="$3"
load_balancer="$4"
domain="$5"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"$cr_name\" \"$project\" \"$region\" \"$load_balancer\" \"$domain\" is invalid, please check again"
    echo "Usage: $0 <cloud_run_service_name> <project> <region> <load_balanacer> <domain>"
    echo "Example: $0 actualprices-api-dev-mp sinyi-cloud asia-east1 cr-ap-sinyi-cc-ilb docuhouseagency-web-dev.ap.sinyi.cc"
}

# Main function
main() {
    # Check if the correct number of arguments is passed
    if [[ -z $cr_name || -z $project || -z $region || -z $load_balancer || -z $domain ]]; then
        print_usage
        exit 1
    fi
    # Check if region is valid, if not, exit
    check_regions

    # Check if the Cloud Run service exists, if not, exit
    check_cr || exit 1

    # Check NEG, create if it doesn't exist
    check_neg || create_neg

    # Check backend, create if it doesn't exist
    check_backend || {
        create_backend && add_backend
    }

    # Check Load Balancer, if not, exit
    check_lb || exit 1

    # Check if the domain exists in the Load Balancer, if not exists, add URL map
    check_lb_domain || {
        add_urlmap || exit 1
    }
}

main "$@"

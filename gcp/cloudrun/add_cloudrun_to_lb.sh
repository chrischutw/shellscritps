#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Sourcr all functions.sh through incl.sh
source "$SCRIPT_DIR/../incl.sh"

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
    check_regions "$region"

    # Check if the Cloud Run service exists, if not, exit
    check_cloudrun "$cr_name" || exit 1

    # Check NEG, create if it doesn't exist
    check_neg "$cr_name" || create_neg "$cr_name"

    # Check backend, create if it doesn't exist
    check_backend "$cr_name" || {
        create_backend "$cr_name" && add_backend "$cr_name"
    }

    # Check Load Balancer, if not, exit
    check_load_balancer "$load_balancer" || exit 1

    # Check if the host domain exists in the Load Balancer, if not exists, add URL map
    check_lb_domain "$domain" || {
        add_urlmap "$load_balancer" "$cr_name" "$domain" || exit 1
    }
}

main "$@"

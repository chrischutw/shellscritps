#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Sourcr all functions.sh through incl.sh
source "${SCRIPT_DIR}/../../incl.sh"

# Parameters
CR_NAME="$1"
PROJECT="$2"
REGION="$3"
LOAD_BALANCER="$4"
DOMAIN="$5"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"${CR_NAME}\" \"${PROJECT}\" \"${REGION}\" \"${LOAD_BALANCER}\" \"${DOMAIN}\" is invalid, please check again"
    echo "Usage: $0 <cloud_run_service_name> <project> <region> <load_balanacer> <domain>"
    echo "Example: $0 actualprices-api-dev-mp sinyi-cloud asia-east1 cr-ap-sinyi-cc-ilb docuhouseagency-web-dev.ap.sinyi.cc"
}

# Main function
main() {
    # Check if the correct number of arguments is passed
    if [[ -z "${CR_NAME}" || -z "${PROJECT}" || -z "${REGION}" || -z "${LOAD_BALANCER}" || -z "${DOMAIN}" ]]; then
        print_usage
        exit 1
    fi
    # Check if region is valid, if not, exit
    check_regions "${REGION}" || exit 1

    # Check Load Balancer, if not, exit
    check_load_balancer "${LOAD_BALANCER}" || exit 1

    # Check if the host domain exists in the Load Balancer, if it exists, delete URL map
    check_lb_domain "${DOMAIN}" "${LOAD_BALANCER}" && remove_urlmap "${LOAD_BALANCER}" "${CR_NAME}" "${DOMAIN}" || exit 1

    # Check backend, delete if it exists
    check_backend "${CR_NAME}" && delete_backend "${CR_NAME}" || exit 1

    # Check NEG, create if it doesn't exist
    check_neg "${CR_NAME}" && delete_neg "${CR_NAME}" || exit 1

    # Check if the Cloud Run service exists, if not, exit
    check_cloudrun "${CR_NAME}" && delete_cloudrun "${CR_NAME}" || exit 1
}

main "$@"

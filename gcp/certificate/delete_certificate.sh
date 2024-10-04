#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Sourcr all functions.sh through incl.sh
source "$SCRIPT_DIR/../../incl.sh"

# Input parameters for global wide
CERT="$1"
PROJECT="$2"
REGION="$3"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"${CERT}\" \"${PROJECT}\" \"${REGION}\" is invalid, please check again"
    echo "Usage: $0 <certificate> <project> <region>"
}

main() {
    if [[ -z "${CERT}" || -z "${PROJECT}" || -z "${REGION}" ]]; then
        print_usage
        exit 1
    fi

    # Input validation - Check if the region is valid, if not, exit
    check_regions "${REGION}" || exit 1

    is_region_global "${REGION}"

    # Check certificate, create if it doesn't exist
    check_ssl && delete_ssl || exit 1
}

main "$@"

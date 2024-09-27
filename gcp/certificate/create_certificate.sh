#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Sourcr all functions.sh through incl.sh
source "$SCRIPT_DIR/../../incl.sh"

# Input parameters for global wide
SOURCE_PATH="$1"
CERT="$2"
PROJECT="$3"
REGION="$4"

# Other global parameters
KEY="$CERT.key"
BUNDLE="$CERT-bundle.crt"
CERT_PATTERN="${CERT%-????????}"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"${source_path}\" \"${certificate}\" \"${project}\" \"${region}\" is invalid, please check again"
    echo "Usage: $0 <source_path> <certificate> <project> <region>"
}

main() {
    if [[ -z "${SOURCE_PATH}" || -z "${CERT}" || -z "${PROJECT}" || -z "${REGION}" ]]; then
        print_usage
        exit 1
    fi

    # Input validation - Check if the certificate and key exists, if not, exit
    check_certificate_and_key "${SOURCE_PATH}" "${BUNDLE}" "${KEY}" || exit 1

    # Input validation - Check if the region is valid, if not, exit
    check_regions "${REGION}" || exit 1

    is_region_global "${REGION}"

    # Check certificate, create if it doesn't exist
    check_ssl || {
        create_ssl || exit 1
    }

}

main "$@"
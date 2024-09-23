#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Sourcr all functions.sh through incl.sh
source "${SCRIPT_DIR}/../incl.sh"

# Input parameters for global wide
SOURCE_PATH="$1"
TARGET_PATH="$2"
CERT="$3"
KEY="$4"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"${SOURCE_PATH}\" \"${TARGET_PATH}\" \"${CERT}\" \"${KEY}\" is invalid, please check again"
    echo "Usage: $0 <ssl_path> <certificate> <key>"
    echo "ssl_path    : Path to the SSL directory"
    echo "certificate : Certificate file name"
    echo "key         : Key file name"
    echo "Example: $0 ~/work/secret/ssl star-sinyi-com-tw-2024.crt star-sinyi-com-tw-2024-nopassword.key"
}

main() {
    # Check if the correct number of arguments is passed
    if [[ -z "${SOURCE_PATH}" || -z "${TARGET_PATH}" || -z "${CERT}" || -z "${KEY}" ]]; then
        print_usage
        exit 1
    fi

    # Input Validation: Check if the ceritificate and key exsits.
    check_certificate_and_key "${SOURCE_PATH}" "${CERT}" "${KEY}" || exit 1

    # Verify the certificate and intermediate certificate
    check_certificate_and_intermediate "${CERT}" || exit 1

    # Verify the certificate and key checksum
    check_certificate_and_key_match "${CERT}" "${KEY}" || exit 1

    # Get the certificate common name and end date
    common_name=$(get_common_name)
    end_date=$(get_enddate)

    # Confirm common name is FQDN
    is_fqdn "${common_name}" || exit 1

    # Change the common name format to meet certificate naming
    converted_common_name=$(get_converted_common_name "${common_name}")

    # Rename certificate and key
    rename_cert_key "${converted_common_name}" "${end_date}"

    get_bundle_cert "${converted_common_name}" "${end_date}"
}

main "$@"

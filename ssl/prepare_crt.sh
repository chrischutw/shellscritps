#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Source the functions script from the lib directory relative to the script's directory
source "$SCRIPT_DIR/ssl_functions.sh"

# Parameters
ssl_path="$1"
certificate="$2"
key="$3"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"$ssl_path\" \"$certificate\" \"$key\" is invalid, please check again"
    echo "Usage: $0 <ssl_path> <certificate> <key>"
    echo "ssl_path    : Path to the SSL directory"
    echo "certificate : Certificate file name"
    echo "key         : Key file name"
    echo "Example: $0 ~/work/secret/ssl star-sinyi-com-tw-2024.crt star-sinyi-com-tw-2024-nopassword.key"
}

main() {
    # Check if the correct number of arguments is passed
    if [[ -z $ssl_path || -z $certificate || -z $key ]]; then
        print_usage
        exit 1
    fi

    # Perform operations
    check_certificate || exit 1

    # Get the certificate common name and end date
    common_name=$(get_common_name)
    end_date=$(get_enddate)
    echo $end_date
    # Confirm common name is FQDN
    is_fqdn "$common_name" || exit 1

    # Change the common name format to meet certificate naming
    converted_common_name=$(get_converted_common_name )

    # Rename certificate and key
    rename_cert_key "$converted_common_name" "$end_date"
}

main "$@"
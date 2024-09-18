#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Sourcr all functions.sh through incl.sh
source "${SCRIPT_DIR}/../../incl.sh"

# Parameters
domain="$1"
rrdata="$2"
type="$3"
project="$4"

# Print usage instructions
print_usage() {
    echo "Your input: \"$0\" \"${domain}\" \"${rrdata}\" \"${type}\" \"${project}\" is invalid, please check again"
    echo "Usage: $0 <domain> <rrdata> <type> <project>"
}

main() {
    if [[ -z "${domain}" || -z "${rrdata}" || -z "${type}" || -z "${project}" ]]; then
        print_usage
        exit 1
    fi

    # Input validation - Check if the domain is FQDN, if not, exit
    is_fqdn "${domain}" || exit 1

    # Input validation - Check if the rrdata is FQDN or IP, if not, exit
    is_fqdn "${rrdata}" || is_ip "${rrdata}" || exit 1

    # Get formatted zone name
    zone=$(get_zone "${domain}")

    # Input validation - Check if the zone exists, if not, exit
    check_zone ${zone} || exit 1

    # Input validation - Check if the rrdata exists, if not, create it
    check_recordset "${domain}" "${zone}" || {
        add_recordset "${domain}" "${zone}" "${rrdata}" "${type}" 
    }
}

main "$@"

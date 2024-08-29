#!/bin/bash

# Check if the certificate exists
check_certificate() {
    if [ -f "$ssl_path/$certificate" ]; then
        echo "Certificate found."
        return 0
    else
        echo "Certificate not found!"
        return 1
    fi
}

is_fqdn() {
    local common_name="$1"
    local fqdn_regex="^(\*\.)?([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$"
    if [[ "$common_name" =~ $fqdn_regex ]]; then
        echo "Valid FQDN".
        return 0
    else
        echo "Invalid FQDN"
        return 1
    fi
}

# Get the certificate's end date
get_enddate() {
    end_date=$(openssl x509 -in "$ssl_path/$certificate" -enddate -noout | cut -d= -f2 | date -d - +%Y%m%d)
    echo "$end_date"
}

# Get the certificate's common name
get_common_name() {
    common_name=$(openssl x509 -in "$ssl_path/$certificate" -noout -subject | sed -n '/^subject/s/^.*CN = //p' | cut -d'/' -f1)
    echo "$common_name"
}

get_converted_common_name() {
    # Check if the common name starts with *.
    if [[ "$common_name" == \*.* ]]; then
        # Replace * with wildcard and replace . with -
        converted_common_name="wildcard-$(echo "$common_name" | sed 's/\*\.//' | tr '.' '-')"
    else
        converted_common_name=$(echo "$common_name" | sed 's/\*\.//' | tr '.' '-')
    fi
    echo "$converted_common_name"
}

rename_cert_key() {
    local common_name="$1"
    local end_date="$2"

    mv "$ssl_path/$certificate" "$ssl_path/${common_name}-${end_date}.crt"
    mv "$ssl_path/$key" "$ssl_path/${common_name}-${end_date}.key"
    echo "Certificate and key renamed to ${common_name}-${end_date}.crt and ${common_name}-${end_date}.key"
}

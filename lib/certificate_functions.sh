#!/bin/bash

# Check if the certificate and key exist
check_certificate_and_key() {
    local source_path="$1"
    local cert="$2"
    local key="$3"

    if [ -f "$source_path/$cert" ] && [ -f "$source_path/$key" ]; then
        echo "Certificate and key found."
        return 0
    else
        if [ ! -f "$source_path/$cert" ]; then
            echo "Certificate not found!"
        fi
        if [ ! -f "$source_path/$key" ]; then
            echo "Key not found!"
        fi
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

check_certificate_and_intermediate() {
    local source_path="$1"
    local cert="$2"
    openssl verify -untrusted "$source_path/$cert" "$source_path/twca_intermediate.crt" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "Certificate and intermediate are valid."
        return 0
    else
        echo "Error: Certificate verification failed!"
        return 1
    fi
}

check_certificate_and_key_match() {
    local source_path="$1"
    local cert="$2"
    local key="$3"

    # Extract the Modulus from the certificate
    local cert_modulus=$(openssl x509 -noout -modulus -in "$source_path/$cert" | openssl md5)

    # Extract the Modulus from the key
    local key_modulus=$(openssl rsa -noout -modulus -in "$source_path/$key" | openssl md5)

    # Compare the Modulus values
    if [ "$cert_modulus" == "$key_modulus" ]; then
        echo "Certificate and key match."
        return 0
    else
        echo "Error: Certificate and key do not match!"
        return 1
    fi
}

# Get the certificate's end date
get_enddate() {
    local source_path="$1"
    local cert="$2"
    end_date=$(openssl x509 -in "$source_path/$cert" -enddate -noout | cut -d= -f2 | xargs -I{} date -d {} +%Y%m%d)
    echo "$end_date"
}

# Get the certificate's common name
get_common_name() {
    local source_path="$1"
    local cert="$2"
    common_name=$(openssl x509 -in "$source_path/$cert" -noout -subject | sed -n '/^subject/s/^.*CN = //p' | cut -d'/' -f1)
    echo "${common_name}"
}

get_converted_common_name() {
    common_name="$1"
    # Check if the common name starts with *.
    if [[ "${common_name}" == \*.* ]]; then
        # Replace * with wildcard and replace . with -
        converted_common_name="wildcard-$(echo "${common_name}" | sed 's/\*\.//' | tr '.' '-')"
    else
        converted_common_name=$(echo "${common_name}" | sed 's/\*\.//' | tr '.' '-')
    fi
    echo "${converted_common_name}"
}

rename_cert_key() {
    local source_path="$1"
    local target_path="$2"
    local cert="$3"
    local key="$4"
    local common_name="$5"
    local end_date="$6"

    cp "${source_path}/${cert}" "${target_path}/${common_name}-${end_date}.crt"
    cp "${source_path}/${key}" "${target_path}/${common_name}-${end_date}.key"
    echo "Certificate and key renamed to \"${common_name}-${end_date}.crt\" and \"${common_name}-${end_date}.key\""
}

get_bundle_cert() {
    local source_path="$1"
    local target_path="$2"
    local common_name="$3"
    local end_date="$4"

    cat "${target_path}/${common_name}-${end_date}.crt" "${source_path}/twca_intermediate.crt" > "${target_path}/${common_name}-${end_date}-bundle.crt"
    echo "Create \"${common_name}-${end_date}-bundle.crt\""
}


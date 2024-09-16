print_error() {
    local message="$1"
    echo "Error: $message"
    exit 1
}

is_region_global() {
    # When region is global, change certificate name and region flag
    if [[ "${REGION}" == "global" ]]; then
        CERT_NAME="${CERT}-global"
        REION_FLAG="--global"
        FILTER="sslCertificates~"${CERT_PATTERN}" AND region:null"
    else
        CERT_NAME="${CERT}"
        REION_FLAG="--region="${REGION}""
        FILTER="sslCertificates~"${CERT_PATTERN}" AND region="${REGION}""
    fi
}

check_ssl() {
    output=$(gcloud compute ssl-certificates list --filter="name="${CERT_NAME}"" --format="value(name)")
    if [ -n "$output" ]; then
        echo "Certificate: \"${CERT_NAME}\" exists."
        return 0 # Exists
    else
        echo "Certificate: \"${CERT_NAME}\" doesn't exist."
        return 1 # Not Exists
    fi
}

create_ssl() {
    gcloud compute ssl-certificates create "${CERT_NAME}" \
        --project="${PROJECT}" \
        "${REION_FLAG}" \
        --certificate="${SOURCE_PATH}"/"${BUNDLE}" \
        --private-key="${SOURCE_PATH}"/"${KEY}"
}

# Function to extract all load balancers and SSL certificates associated with a specific pattern
fetch_ssl_certificates_by_pattern() {
    # Initialize arrays to store load balancers and certificates
    load_balancers=()
    certificates=()

    # Fetch data from gcloud and populate the arrays
    while read -r line; do
        # Use awk to split the line into load_balancer and certificates
        local load_balancer=$(echo "${line}" | awk '{print $1}')
        local certs=$(echo "${line}" | awk '{print $2}')

        # Append load balancer and certificates to respective arrays
        load_balancers+=("${load_balancer}")
        certificates+=("${certs}")
    done < <(gcloud compute target-https-proxies list \
        --project="${PROJECT}" \
        --format="value(name,sslCertificates)" \
        --filter="${FILTER}")
}

# Function to extract the certificate with a matching pattern
get_matching_certificate() {
    local certificates="$1"
    # Find and return the certificate that matches the pattern
    echo "${certificates}" | tr ',' '\n' | grep "${CERT_PATTERN}"
}

# Function to check if the certificate's expiration year is the current year
is_certificate_this_year() {
    local certificate="$1"
    local current_year=$(date +"%Y")
    # Extract the year from the certificate (last 8 digits) and compare with the current year
    local cert_year="${certificate: -8:4}"

    # Return true if the certificate year matches the current year
    [[ "${cert_year}" == "${current_year}" ]]
}

# Function to replace the old certificate with a new one in the certificates list
replace_certificate() {
    local certificates="$1"
    local old_certificate="$2"
    local new_certificate="$3"

    # Replace the old certificate with the new one in the certificates string
    echo "${certificates}" | sed "s|"${old_certificate}"|"${new_certificate}"|"
}

# Function to process each load balancer's certificate
process_load_balancer() {
    local load_balancer="$1"
    local certificates="$2"
    # Step 2: Find the certificate that matches the pattern
    local matching_certificate=$(get_matching_certificate "${certificates}" ""${CERT_PATTERN}"")
    # Step 3: Check if the matching certificate is from this year
    if is_certificate_this_year "$matching_certificate"; then
        # Step 4: Replace the old certificate with the new one
        local updated_certificates=$(replace_certificate "${certificates}" "${matching_certificate}" "${CERT}")
        update_certificate "${load_balancer}" "${updated_certificates}"
        echo "Updated Certificates for \"${load_balancer}\": \"${updated_certificates}\""
    else
        echo "No certificate from this year found for pattern: \"${CERT_PATTERN}\" in \"${load_balancer}\""
    fi
}

update_certificate() {
    local load_balancer="$1"
    local certificates="$2"

    gcloud compute target-https-proxies update "${load_balancer}" \
        --project="${PROJECT}" \
        "${REION_FLAG}" \
        --ssl-certificates="${certificates}"
}

# Check if the cloud run exists

# To be implemented
# check_projects() {}

check_regions() {
    local valid_regions=(
        "africa-south1" "asia-east1" "asia-east2" "asia-northeast1" "asia-northeast2" "asia-northeast3"
        "asia-south1" "asia-south2" "asia-southeast1" "asia-southeast2" "australia-southeast1" "australia-southeast2"
        "europe-central2" "europe-north1" "europe-southwest1" "europe-west1" "europe-west10" "europe-west12"
        "europe-west2" "europe-west3" "europe-west4" "europe-west6" "europe-west8" "europe-west9"
        "me-central1" "me-central2" "me-west1" "northamerica-northeast1" "northamerica-northeast2"
        "southamerica-east1" "southamerica-west1" "us-central1" "us-east1" "us-east4" "us-east5"
        "us-south1" "us-west1" "us-west2" "us-west3" "us-west4"
    )

    for valid_region in "${valid_regions[@]}"; do
        if [[ "$region" == "$valid_region" ]]; then
            return 0 # Region is valid
        fi
    done

    return 1 # Region is not valid
}

check_cr() {
    local output=$(gcloud run services list --project="${project}" --region="${region}" --filter="metadata.name=${cr_name}" --format="value(metadata.name)")
    if [ -n "$output" ]; then
        echo "Cloud Run check passed. \"${cr_name}\" exists"
        return 0 # Exists
    else
        return 1 # Not Exists
    fi
}

# Check if the network endpoint group exists
check_neg() {
    local output=$(
        gcloud compute network-endpoint-groups list \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--regions=${region}") \
            --filter="name=${cr_name}-endpoint" \
            --format="value(name)"
    )

    if [ -n "$output" ]; then
        echo "\"${cr_name}-endpoint\" exists"
        return 0 # Exists
    else
        return 1 # Not Exists
    fi
}

# Check if the backend service exists
check_backend() {
    local output=$(
        gcloud compute backend-services list \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--regions=${region}") \
            --filter="name=${cr_name}-backend" \
            --format="value(name)"
    )
    if [ -n "$output" ]; then
        echo ""${cr_name}-backend" exists"
        return 0 # Exists
    else
        return 1 # Not Exists
    fi
}

# Check if the load balancer exists
check_lb() {
    local output=$(gcloud compute url-maps list --project="${project}" --filter="name:${load_balancer}" --format="value(name)")

    if [ -n "$output" ]; then
        echo "Load Balancer check passed. \"${load_balancer}\" exists"
        return 0 # Exists
    else
        return 1 # Not Exists
    fi
}

# Check if a domain exsits in a Load Balancer
check_lb_domain() {
    local host_rules=$(
        gcloud compute url-maps describe "${load_balancer}" \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
            --format="value(hostRules)"
    )

    if echo "$host_rules" | grep -q "'hosts': \['${domain}'"; then
        echo "Host ${domain} exists."
        return 0 # Exists
    else
        echo "Host ${domain} does not exist."
        return 1 # Not Exists
    fi
}

# Create the network endpoint group
create_neg() {
    gcloud compute network-endpoint-groups create "${cr_name}-endpoint" \
        --project="${project}" \
        --region="${region}" \
        --network-endpoint-type=serverless \
        --cloud-run-service="${cr_name}"

    if [ $? -eq 0 ]; then
        echo "Successfully created ${cr_name}-endpoint"
        return 0 # Create Successfully
    else
        return 1 # Failuare
    fi
}

# Create the backend service
create_backend() {
    gcloud compute backend-services create "${cr_name}-backend" \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --load-balancing-scheme=INTERNAL_MANAGED \
        --protocol=HTTPS \
        --enable-logging \
        --logging-sample-rate=1

    if [ $? -eq 0 ]; then
        echo "Successfully created ${cr_name}-backend"
        return 0 # Create Successfully
    else
        echo "Failed to create ${cr_name}-backend"
        return 1 # Failuare
    fi
}

# Add network endpoint group to the backend service
add_backend() {
    gcloud compute backend-services add-backend ${cr_name}-backend \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --network-endpoint-group=${cr_name}-endpoint \
        --network-endpoint-group-region="${region}"

    if [ $? -ne 0 ]; then
        echo "Successfully added ${cr_name}-endpoint to ${cr_name}-backend"
        return 0 # Create Successfully
    else
        return 1 # Failuare
    fi
}

# Add urlpath to load balancer
add_urlmap() {
    gcloud compute url-maps add-path-matcher "${load_balancer}" \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --path-matcher-name="${cr_name}-backend" \
        --default-service="${cr_name}-backend" \
        --new-hosts="${domain}"

    if [ $? -eq 0 ]; then
        echo "Successfully created Add \"${domain}\" to \"${load_balancer}\""
        return 0 # Create Successfully
    else
        return 1 # Failuare
    fi
}

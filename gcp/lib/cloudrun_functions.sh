# check_projects() {}

print_error() {
  local message="$1"
  echo "Error: $message"
  exit 1
}

# Check if the region is valid
check_regions() {
    local valid_regions=(
        "africa-south1" "asia-east1" "asia-east2" "asia-northeast1" "asia-northeast2" "asia-northeast3"
        "asia-south1" "asia-south2" "asia-southeast1" "asia-southeast2" "australia-southeast1" "australia-southeast2"
        "europe-central2" "europe-north1" "europe-southwest1" "europe-west1" "europe-west10" "europe-west12"
        "europe-west2" "europe-west3" "europe-west4" "europe-west6" "europe-west8" "europe-west9"
        "me-central1" "me-central2" "me-west1" "northamerica-northeast1" "northamerica-northeast2"
        "southamerica-east1" "southamerica-west1" "us-central1" "us-east1" "us-east4" "us-east5"
        "us-south1" "us-west1" "us-west2" "us-west3" "us-west4" "global"
    )

    for valid_region in "${valid_regions[@]}"; do
        if [[ "$region" == "$valid_region" ]]; then
            echo "Region: \"${region}\" check passed."
            return 0 # Region is valid
        fi
    done
    print_error "Region: \"${region}\" doesn't exist."
}

# Check if the cloud run exists
check_cr() {
    local output=$(gcloud run services list --project="${project}" --region="${region}" --filter="metadata.name=${cr_name}" --format="value(metadata.name)")
    if [ -n "$output" ]; then
        echo "Cloud Run: \"${cr_name}\" check passed."
        return 0 # Exists
    else
        echo "Cloud Run: \"${cr_name}\" doesn't exist."
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
        echo "Network Endpoint Group: \"${cr_name}-endpoint\" exists."
        return 0 # Exists
    else
        echo "Network Endpoint Group: \"${cr_name}-endpoint\" doesn't exists."
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
        echo "Backend: \"${cr_name}-backend\" exists."
        return 0 # Exists
    else
        echo "Backend: \"${cr_name}-backend\" doesn't exists."
        return 1 # Not Exists
    fi
}

# Check if the load balancer exists
check_lb() {
    local output=$(gcloud compute url-maps list --project="${project}" --filter="name:${load_balancer}" --format="value(name)")

    if [ -n "$output" ]; then
        echo "Load Balancer: \"${load_balancer}\" exists"
        return 0 # Exists
    else
         echo "Load Balancer: \"${load_balancer}\" doesn't exists"
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
        echo "Domain: \"${domain}\" exists."
        return 0 # Exists
    else
        echo "Domain: \"${domain}\" doesn't exist."
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
        echo "Successfully create Network Endpoint Group: \"${cr_name}-endpoint\"."
        return 0 # Create Successfully
    else
        print_error "Fail to create Network Endpoint Group: \"${cr_name}-endpoint\"."
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
        echo "Successfully created \"${cr_name}-backend\""
        return 0 # Create Successfully
    else
        print_error "Failed to create \"${cr_name}-backend\""
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

    if [ $? -eq 0 ]; then
        echo "Successfully added \"${cr_name}-endpoint\" to \"${cr_name}-backend\""
        return 0 # Create Successfully
    else
        print_error "Failed to add \"${cr_name}-endpoint\" to \"${cr_name}-backend\"" 
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
        echo "Successfully added \"${domain}\" to \"${load_balancer}\" with backend: \"${cr_name}-backend\""
        return 0 # Create Successfully
    else
        print_error "Failed to add \"${domain}\" to \"${load_balancer}\" with backend: \"${cr_name}-backend\""
        return 1 # Failuare
    fi
}

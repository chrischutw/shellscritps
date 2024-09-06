# check_projects() {}

print_error() {
    local message="$1"
    echo "Error: $message"
    exit 1
}

# Check if the region is valid
check_regions() {
    local region="$1"
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
check_cloudrun() {
    local cloudrun="$1"
    local output=$(gcloud run services list --project="${project}" --region="${region}" --filter="metadata.name=${cloudrun}" --format="value(metadata.name)")
    if [ -n "$output" ]; then
        echo "Cloud Run: \"${cloudrun}\" check passed."
        return 0 # Exists
    else
        echo "Cloud Run: \"${cloudrun}\" doesn't exist."
        return 1 # Not Exists
    fi
}

# Check if the network endpoint group(NEG) exists
check_neg() {
    local neg="$1"-endpoint
    local output=$(
        gcloud compute network-endpoint-groups list \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--regions=${region}") \
            --filter="name=${neg}" \
            --format="value(name)"
    )

    if [ -n "$output" ]; then
        echo "Network Endpoint Group: \"${neg}\" check passed."
        return 0 # Exists
    else
        echo "Network Endpoint Group: \"${neg}\" doesn't exists."
        return 1 # Not Exists
    fi
}

# Check if the backend service exists
check_backend() {
    local backend="$1"-backend
    local output=$(
        gcloud compute backend-services list \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--regions=${region}") \
            --filter="name=${backend}" \
            --format="value(name)"
    )
    if [ -n "$output" ]; then
        echo "Backend: \"${backend}\" check passed."
        return 0 # Exists
    else
        echo "Backend: \"${backend}\" doesn't exists."
        return 1 # Not Exists
    fi
}

# Check if the backend service is used by load balancer
check_backend_used() {
    local backend="$1" #-backend
    local output=$(
        gcloud compute backend-services describe "${backend}" \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") |
            grep urlMaps
    )
    if [ -n "$output" ]; then
        local usedby=$(echo $output | sed -E "s/.*urlMaps\/([^']*).*/\1/")
        echo "Backend: \"${backend}\" is used by \"${usedby}\"."
        return 0 # In used
    else
        echo "Backend: \"${backend}\" is not in used."
        return 1 # Not in used
    fi
}

# Check if the load balancer exists
check_load_balancer() {
    local load_balancer="$1"
    local output=$(gcloud compute url-maps list --project="${project}" --filter="name:${load_balancer}" --format="value(name)")

    if [ -n "$output" ]; then
        echo "Load Balancer: \"${load_balancer}\" check passed."
        return 0 # Exists
    else
        echo "Load Balancer: \"${load_balancer}\" doesn't exists."
        return 1 # Not Exists
    fi
}

# Check if a domain exsits in a Load Balancer
check_lb_domain() {
    local domain="$1"
    local host_rules=$(
        gcloud compute url-maps describe "${load_balancer}" \
            --project="${project}" \
            $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
            --format="value(hostRules)"
    )

    if echo "$host_rules" | grep -q "'hosts': \['${domain}'"; then
        echo "Domain: \"${domain}\" exists in \"${load_balancer}\"."
        return 0 # Exists
    else
        echo "Domain: \"${domain}\" doesn't exist in \"${load_balancer}\"."
        return 1 # Not Exists
    fi
}

# Create the network endpoint group
create_neg() {
    local cloudrun="$1"
    local neg="$1"-endpoint
    gcloud compute network-endpoint-groups create "${neg}" \
        --project="${project}" \
        --region="${region}" \
        --network-endpoint-type=serverless \
        --cloud-run-service="${cloudrun}"

    if [ $? -eq 0 ]; then
        echo "Successfully create Network Endpoint Group: \"${neg}\"."
        return 0 # Create Successfully
    else
        print_error "Fail to create Network Endpoint Group: \"${neg}\"."
        return 1 # Failuare
    fi
}

# Create the backend service
create_backend() {
    local backend="$1"-backend
    gcloud compute backend-services create "${backend}" \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --load-balancing-scheme=INTERNAL_MANAGED \
        --protocol=HTTPS \
        --enable-logging \
        --logging-sample-rate=1

    if [ $? -eq 0 ]; then
        echo "Successfully created \"${backend}\""
        return 0 # Create Successfully
    else
        print_error "Failed to create \"${backend}\""
        return 1 # Failuare
    fi
}

# Add network endpoint group to the backend service
add_backend() {
    local backend="$1"-backend
    gcloud compute backend-services add-backend ${backend} \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --network-endpoint-group=${cr_name}-endpoint \
        --network-endpoint-group-region="${region}"

    if [ $? -eq 0 ]; then
        echo "Successfully added \"${cr_name}-endpoint\" to \"${backend}\""
        return 0 # Create Successfully
    else
        print_error "Failed to add \"${cr_name}-endpoint\" to \"${backend}\""
        return 1 # Failuare
    fi
}

# Add urlpath to load balancer
add_urlmap() {
    local load_balancer="$1"
    local backend="$2"-backend
    local domain="$3"
    gcloud compute url-maps add-path-matcher "${load_balancer}" \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --path-matcher-name="${backend}" \
        --default-service="${backend}" \
        --new-hosts="${domain}"

    if [ $? -eq 0 ]; then
        echo "Successfully added \"${domain}\" to \"${load_balancer}\" with backend: \"${backend}\""
        return 0 # Create Successfully
    else
        print_error "Failed to add \"${domain}\" to \"${load_balancer}\" with backend: \"${backend}\""
        return 1 # Failuare
    fi
}

remove_urlmap() {
    local load_balancer="$1"
    local backend="$2"-backend
    gcloud compute url-maps remove-path-matcher "${load_balancer}" \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --path-matcher-name="${backend}"

    if [ $? -eq 0 ]; then
        echo "Successfully removed \"${domain}\" to \"${load_balancer}\" with backend: \"${backend}\""
        return 0 # Create Successfully
    else
        print_error "Failed to remove \"${domain}\" to \"${load_balancer}\" with backend: \"${backend}\""
        return 1 # Failuare
    fi
}

delete_backend() {
    local backend="$1" #-backend
    gcloud compute backend-services delete ${backend} \
        --project="${project}" \
        $([[ "${region}" == "global" ]] && echo "--global" || echo "--region=${region}") \
        --quiet

    if [ $? -eq 0 ]; then
        echo "Successfully deleted \"${backend}\""
        return 0 # Create Successfully
    else
        print_error "Failed to delete \"${backend}\""
        return 1 # Failuare
    fi
}

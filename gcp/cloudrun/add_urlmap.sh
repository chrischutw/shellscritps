#!/bin/bash

# Parameters
cr_name="$1"
project="$2"
region="$3"
load_balancer="$4"
domain="$5"

# Print usage instructions
print_usage() {
  echo "Your input: \"$0\" \"$cr_name\" \"$project\" \"$region\" \"$load_balancer\" \"$domain\" is invalid, please check again"
  echo "Usage: $0 <cloud_run_service_name> <project> <region>"
  echo "Example: $0 actualprices-api-dev-mp sinyi-cloud asia-east1"
}

# Check if the load balancer exists
check_lb() {
  local output=$(gcloud compute url-maps list --project="${project}" --filter="name:${load_balancer}" --format="value(name)")

  if [ -n "$output" ]; then
    echo "Load Balancer check passed. \"${load_balancer}\" exists"
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Check if a domain exsits in a  Load Balancer
check_lb_domain() {
  local host_rules=$(gcloud compute url-maps describe "${load_balancer}" --project="${project}" --region="${region}" --format="value(hostRules)")

  if echo "$input" | grep -q "'hosts': \['${target_host}'"; then
  echo "Host ${target_host} exists."
  else
  echo "Host ${target_host} does not exist."
  fi
}


# Check if the network endpoint group exists
check_neg() {
  local output=$(gcloud compute network-endpoint-groups list --project="${project}" --regions="${region}" --filter="name=${cr_name}-endpoint" --format="value(name)")

  if [ -n "$output" ]; then
    echo "\"${cr_name}-endpoint\" exists"
    return 0  # Success
  else
    echo "\"${cr_name}-endpoint\" does not exist"
    return 1  # Failure
  fi
}

# Add urlpath to load balancer
add_urlmap() {
  gcloud compute url-maps add-path-matcher "${load_balancer}" \
    --project="${project}" \
    --region="${region}" \
    --path-matcher-name="${cr_name}-backend" \
    --default-service="${cr_name}-backend" \
    --new-hosts="${domain}"
  
  if [ $? -eq 0 ]; then
    echo "Successfully created Add \"${domain}\" to \"${load_balancer}\""
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Main function
main() {
  # Check if the correct number of arguments is passed
  if [[ -z $cr_name || -z $project || -z $region || -z $load_balancer || -z $domain ]]; then
    print_usage
    exit 1
  fi

  # Check if the Cloud Run service exists
  check_cr || {
    echo "Error: Cloud Run service \"${cr_name}\" does not exist."
    exit 1
  }

  # Check if network endpoint group exists, if not, create it
  check_neg || create_neg || {
    echo "Error: Failed to create ${cr_name}-endpoint."
    exit 1
  }
}

# Execute main function with arguments
main "$@"

#!/bin/bash

# Parameters
cr_name="$1"
project="$2"
region="$3"

# Print usage instructions
print_usage() {
  echo "Your input: \"$0\" \"$cr_name\" \"$project\" \"$region\" is invalid, please check again"
  echo "Usage: $0 <cloud_run_service_name> <project> <region>"
  echo "Example: $0 actualprices-api-dev-mp sinyi-cloud asia-east1"
}

# Check if the backend service exists
check_backend() {
  local output=$(gcloud compute backend-services list --project="${project}" --regions="${region}" --filter="name=${cr_name}-backend" --format="value(name)")
  if [ -n "$output" ]; then
    echo ""${cr_name}-backend" exists"
    return 0  # Success
  else
    echo ""${cr_name}-backend" does not exist"
    return 1  # Failure
  fi
}

# Create the backend service
create_backend() {
  gcloud compute backend-services create "${cr_name}-backend" \
    --project="${project}" \
    --region="${region}" \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=HTTPS \
    --enable-logging \
    --logging-sample-rate=1

  if [ $? -eq 0 ]; then
    echo "Successfully created ${cr_name}-backend"    
    return 0  # Success
  else
    echo "Failed to create ${cr_name}-backend"
    return 1  # Failure
  fi
}

# Add network endpoint group to the backend service
add_backend() {
  gcloud compute backend-services add-backend ${cr_name}-backend \
    --project="${project}" \
    --region="${region}" \
    --network-endpoint-group=${cr_name}-endpoint \
    --network-endpoint-group-region="${region}"

  if [ $? -ne 0 ]; then
    echo "Failed to add ${cr_name}-endpoint to ${cr_name}-backend"
    return 1  # Failure
  fi
  echo "Successfully added ${cr_name}-endpoint to ${cr_name}-backend"
  return 0  # Success
}

# Main function
main() {
  # Check if the correct number of arguments is passed
  if [[ -z $cr_name || -z $project || -z $region ]]; then
    print_usage
    exit 1
  fi

  # Check if backend service exists, if not, create it
  check_backend || create_backend || {
    echo "Error: Failed to create ${cr_name}-backend."
    exit 1
  }

  # Add network endpoint group to backend service
  add_backend || {
    echo "Error: Failed to add ${cr_name}-endpoint to ${cr_name}-backend."
    exit 1
  }
}

# Execute main function with arguments
main "$@"

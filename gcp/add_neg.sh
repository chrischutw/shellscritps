#!/bin/bash

# Parameters
cr_name="$1"
project="$2"
region="$3"

# Print usage instructions
print_usage() {
  echo "Your input: "$0" "$cr_name" "$project" "$region" is invalid, please check again"
  echo "Usage: $0 <cloud_run_service_name> <project> <region>"
  echo "Example: $0 actualprices-api-dev-mp sinyi-cloud asia-east1"
}

# Check if the network endpoint group exists
check_neg() {
  local output=$(gcloud compute network-endpoint-groups list --project="${project}" --regions="${region}" --filter="name=${cr_name}-endpoint" --format="value(name)")

  if [ -n "$output" ]; then
    echo ""${cr_name}-endpoint" exists"
    return 0  # Success
  else
    echo ""${cr_name}-endpoint" does not exist"
    return 1  # Failure
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
    return 0  # Success
  else
    echo "Failed to create ${cr_name}-endpoint"
    return 1  # Failure
  fi
}

# Main function
main() {
  # Check if the correct number of arguments is passed
  if [[ -z $3 ]]; then
    print_usage
    exit 1
  fi

  if check_neg "${cr_name}"; then
    echo "No need to create, ${cr_name}-endpoint already exists."
  else
    if create_neg "${cr_name}"; then
      echo "${cr_name}-endpoint created successfully."
    else
      echo "Error: Failed to create ${cr_name}-endpoint."
      exit 1
    fi
  fi
}

# Execute main function with arguments
main "$1" "$2" "$3"

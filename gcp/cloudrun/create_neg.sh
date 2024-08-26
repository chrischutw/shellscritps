#!/bin/bash

# Parameters
cr_name="$1"
project="$2"
region="$3"

# Print usage instructions
neg_usage() {
  echo "Your input: \"$0\" \"$cr_name\" \"$project\" \"$region\" is invalid, please check again"
  echo "Usage: $0 <cloud_run_service_name> <project> <region>"
  echo "Example: $0 actualprices-api-dev-mp sinyi-cloud asia-east1"
}

# Check if the cloud run exists
check_cr() {
  local output=$(gcloud run services list --project="${project}" --region="${region}" --filter="metadata.name=${cr_name}" --format="value(metadata.name)")
  if [ -n "$output" ]; then
    echo "Cloud Run check passed. \"${cr_name}\" exists"
    return 0  # Success
  else
    return 1  # Failure
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
    return 1  # Failure
  fi
}

# Main function
main() {
  # Check if the correct number of arguments is passed
  if [[ -z $cr_name || -z $project || -z $region ]]; then
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

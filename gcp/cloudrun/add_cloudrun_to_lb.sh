#!/bin/bash

# Source Library
source ../lib/cloudrun_functions.sh

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

# Main function
main() {
    # Check if the correct number of arguments is passed
    if [[ -z $cr_name || -z $project || -z $region || -z $load_balancer || -z $domain ]]; then
        print_usage
        exit 1
    fi

    # Check if region is valid
    check_regions || {
        echo "Error: Region \"${region}\" is not valid."
        exit 1
    }

    # Check if the Cloud Run service exists
    check_cr || {
        echo "Error: Cloud Run service \"${cr_name}\" does not exist."
        exit 1
    }

    # Check NEG, create if it doesn't exist
    check_neg || {
        echo "${cr_name}-endpoint does not exist. Creating..."
        create_neg || {
            echo "Error: Failed to create ${cr_name}-endpoint."
            exit 1
        }
    }

    # Check backend, create if it doesn't exist
    check_backend || {
        echo "${cr_name}-backend does not exist. Creating..."
        create_backend || add_backend || {
            echo "Error: Failed to create ${cr_name}-backend."
            exit 1
        }
    }
    # Check Load Balancer, then check domain, if not exists, add URL map
    check_lb || {
        echo "Error: Load Balancer \"${load_balancer}\" does not exist."
        exit 1
    }

    check_lb_domain || {
        echo "Domain \"${domain}\" does not exist in the Load Balancer \"${load_balancer}\". Adding URL map..."
        add_urlmap || {
            echo "Error: Failed to add URL map for domain \"${domain}\" to Load Balancer \"${load_balancer}\"."
            exit 1
        }
    }
}

# Execute main function with arguments
main "$@"

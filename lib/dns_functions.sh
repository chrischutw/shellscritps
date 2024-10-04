print_error() {
    local message="$1"
    echo "Error: $message"
    exit 1
}

is_fqdn() {
    local domain="$1"
    local fqdn_regex="^(\*\.)?([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$"
    if [[ "$domain" =~ $fqdn_regex ]]; then
        echo "\"$domain\" is valid FQDN".
        return 0
    else
        echo "\"$domain\" is invalid FQDN"
        return 1
    fi
}

is_ip() {
    local ip="$1"

    # check IPv4 format
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # check every number is between 0-255
        for octet in $(echo "$ip" | tr '.' ' '); do
            if ((octet < 0 || octet > 255)); then
                echo "Invalid IP"
                return 1
            fi
        done
        echo "\"$ip\" is valid IP"
        return 0
    else
        echo "\"$ip\" is invalid IP"
        return 1
    fi
}

check_zone() {
    local zone="$1"
    local output=$(gcloud dns managed-zones list --project="${project}" --filter="name=${zone}" --format="value(name)")
    if [ -n "$output" ]; then
        echo "Manage Zone: \"${zone}\" check passed."
        return 0 # Exists
    else
        echo "Manage Zone: \"${zone}\" doesn't exist."
        return 1 # Not Exists
    fi
}

check_recordset() {
    local domain="$1"
    local zone="$2"
    local output=$(gcloud dns record-sets list --project="${project}" --zone="${zone}" --name="${domain}" --format="value(name)")
    if [ -n "$output" ]; then
        echo "Record sets: \"${domain}\" exists in \"${zone}\"."
        return 0 # Exists
    else
        echo "Record sets: \"${domain}\" doesn't exist in \"${zone}\"."
        return 1 # Not Exists
    fi
}

get_zone() {
    local domain="$1"
    local zone=$(echo "$domain" | sed -E 's/^[^.]*\.//') # delete string before first dot
    formatted_zone=$(echo "$zone" | tr '.' '-')          # replace dot to dash
    echo $formatted_zone
}

add_recordset() {
    local domain="$1"
    local zone="$2"
    local rrdata="$3"
    local type"$4"
    gcloud dns record-sets create "${domain}" \
        --project="${project}" \
        --rrdatas="${rrdata}" \
        --type="${type}" \
        --ttl=300 \
        --zone="${zone}"

    if [ $? -eq 0 ]; then
        echo "Successfully created recordset: \"${rrdata}\" \"${type}\" \"${domain}\""
        return 0 # Create Successfully
    else
        print_error "Failed to create recordset: \"${rrdata}\" \"${type}\" \"${domain}\""
        return 1 # Failuare
    fi
}

update_recordset() {
    local domain="$1"
    local zone="$2"
    local rrdata="$3"
    local type"$4"
    gcloud dns record-sets update "${domain}" \
        --project="${project}" \
        --rrdatas="${rrdata}" \
        --type="${type}" \
        --ttl=300 \
        --zone="${zone}"

    if [ $? -eq 0 ]; then
        echo "Successfully updated recordset: \"${rrdata}\" \"${type}\" \"${domain}\""
        return 0 # Create Successfully
    else
        print_error "Failed to update recordset: \"${rrdata}\" \"${type}\" \"${domain}\""
        return 1 # Failuare
    fi
}

delete_recordset() {
    local domain="$1"
    local zone="$2"
    local type"$3"
    gcloud dns record-sets delete "${domain}" \
        --project="${project}" \
        --type="${type}" \
        --zone="${zone}"

    if [ $? -eq 0 ]; then
        echo "Successfully deleted recordset: \"${rrdata}\" \"${type}\" \"${domain}\""
        return 0 # Create Successfully
    else
        print_error "Failed to delete recordset: \"${rrdata}\" \"${type}\" \"${domain}\""
        return 1 # Failuare
    fi
}
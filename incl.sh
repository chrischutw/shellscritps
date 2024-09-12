#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
LIB_DIR=""$SCRIPT_DIR"/lib"
# Source all functions.sh in lib directory
for file in "$LIB_DIR"/*.sh; do
    if [ -f "$file" ]; then
        source "$file"
    else
        echo ""$LIB_DIR" is not found"
        exit 1
    fi
done

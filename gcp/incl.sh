#!/bin/bash

# Obtain incl.sh absolute path
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# Source all functions.sh in lib directory
for file in "$SCRIPT_DIR"/lib/*.sh; do
    if [ -f "$file" ]; then
        source "$file"
    fi
done

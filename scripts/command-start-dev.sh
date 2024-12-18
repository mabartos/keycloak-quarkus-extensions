#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

handle_command_start_dev() {
    # Find the Keycloak distribution zip file in the target directory
    keycloak_zip=$(find "$ROOT_DIR" -maxdepth 1 -name 'keycloak-extended-*.zip' | head -n 1)

    # Check if the zip file was found
    if [ -z "$keycloak_zip" ]; then
        echo "Error: No Keycloak distribution zip file found in target directory."
        exit 1
    fi

    rm -rf "$ROOT_DIR"/target/

    # Unzip the distribution
    echo "Unzipping Keycloak distribution from: $keycloak_zip"
    unzip -q "$keycloak_zip" -d "$ROOT_DIR"/target/

    # Change to the directory of the unzipped distribution
    keycloak_dir=$(basename "$keycloak_zip" .zip)
    cd "$ROOT_DIR/target/$keycloak_dir" || exit

    echo "Starting Keycloak in development mode..."

    ./bin/kc.sh start-dev
}

handle_command_start_dev "$@"

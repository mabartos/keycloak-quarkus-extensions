#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

show_help_start_dev() {
    echo "Execute the generated Keycloak distribution in development mode."
    echo
    echo "Usage: ./kc-extension.sh start-dev [OPTIONS] [ARGUMENTS]"
    echo
    echo "Options:"
    echo "  --version <version>             Specify the version of generated extended Keycloak distribution. Defaults to Keycloak version from 'pom.xml' if not provided."
    echo "  -h, --help                      Displays this help message."
    echo
    echo "Arguments:"
    echo "  Any other arguments will be passed directly to the 'kc.sh start-dev' command."
}

handle_command_start_dev() {
    version=""
    additional_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --version*)
            # Extract value from option
            version="${1#*=}"
            if [[ -z "$version" || "$version" == "$1" ]]; then
                echo "Error: Missing value for --version."
                exit 1
            fi
            echo "Extended Keycloak version set to: $version"
            ;;
        -h | --help)
            show_help_start_dev
            exit 0
            ;;
        --*)
            additional_args+=("$1")
            ;;
        *)
            echo "Unknown option: $1"
            echo "Type ./kc-extension.sh start-dev --help' for available options."
            exit 1
            ;;
        esac
        shift
    done

    # If no version is provided, get the one from pom.xml
    if [[ -z "$version" ]]; then
        version=$(get_keycloak_version_from_pom)
        echo "Using extended Keycloak version from pom.xml: $version"
    fi

    keycloak_zip="$ROOT_DIR"/keycloak-extended-"$version".zip

    # Check whether zip exists
    if [ ! -f "$keycloak_zip" ]; then
        echo "Error: No Keycloak distribution zip file found in target directory. ("$keycloak_zip")"
        echo "Did you execute the './kc-extension.sh build' command before?"
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

    ./bin/kc.sh start-dev "${additional_args[@]}"
}

handle_command_start_dev "$@"

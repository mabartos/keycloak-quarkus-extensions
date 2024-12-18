#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

# Function to show help message for build command
show_help_build() {
    echo "Build Keycloak distribution with provided Quarkus/Quarkiverse extensions"
    echo
    echo "Usage: $0 build [OPTIONS]"
    echo
    echo "Options:"
    echo "  --keycloak-version <version>    Specify the Keycloak version. Defaults to version from 'pom.xml' if not provided."
    echo "  --quarkus-version <version>     Specify the Quarkus version. Defaults to version from 'pom.xml' if not provided."
    echo "  -h, --help                      Displays this help message."
}

handle_command_build() {
    # Initialize variables
    keycloak_version=""
    quarkus_version=""
    distPath=""
    additional_properties=""

    # Process parameters for `build`
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --keycloak-version*)
            # Extract value from option
            keycloak_version="${1#*=}"
            if [[ -z "$keycloak_version" || "$keycloak_version" == "$1" ]]; then
                echo "Error: Missing value for --keycloak-version."
                exit 1
            fi
            echo "Keycloak version set to: $keycloak_version"
            ;;
        --quarkus-version*)
            # Extract value from option
            quarkus_version="${1#*=}"
            if [[ -z "$quarkus_version" || "$quarkus_version" == "$1" ]]; then
                echo "Error: Missing value for --quarkus-version."
                exit 1
            fi
            echo "Quarkus version set to: $quarkus_version"
            ;;
        -h | --help)
            show_help_build
            exit 0
            ;;
        *)
            echo "Unknown build option: $1"
            echo "Type '$0 build --help' for available build options."
            exit 1
            ;;
        esac
        shift
    done

    # Get keycloak version from pom.xml only if it's not set
    if [[ -z "$keycloak_version" ]]; then
        keycloak_version=$(get_keycloak_version_from_pom) # Get default keycloak version from pom.xml
        echo "Using keycloak version from pom.xml: $keycloak_version"
    fi

    # Get quarkus version from pom.xml only if it's not set
    if [[ -z "$quarkus_version" ]]; then
        quarkus_version=$(get_quarkus_version_from_pom) # Get default quarkus version from pom.xml
        echo "Using quarkus version from pom.xml: $quarkus_version"
    fi

    # Build logic goes here using $keycloak_version, $quarkus_version, or $distPath variables
    echo "Executing build with '--keycloak-version': $keycloak_version, '--quarkus-version': $quarkus_version, and '--distPath': ${distPath:-N/A}"
    echo "Additional properties: $additional_properties"
    "$ROOT_DIR"/mvnw clean install -f "$ROOT_DIR"/pom.xml -DskipTests -Dkeycloak.version="$keycloak_version" -Dquarkus.version="$quarkus_version" $additional_properties
}

handle_command_build "$@"

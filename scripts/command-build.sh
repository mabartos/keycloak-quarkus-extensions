#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

show_help_build() {
    echo "Build Keycloak distribution with provided Quarkus/Quarkiverse extensions"
    echo
    echo "Usage: ./kc-extension.sh build [OPTIONS]"
    echo
    echo "Options:"
    echo "  --keycloak-version <version>    Specify the Keycloak version. Defaults to version from 'pom.xml' if not provided."
    echo "  --quarkus-version <version>     Specify the Quarkus version. Defaults to version from 'pom.xml' if not provided."
    echo "  -h, --help                      Displays this help message."
}

get_quarkus_version_for_keycloak() {
    # Get Quarkus version based on known versions in Keycloak releases
    local keycloak_version="$1"

    case "$keycloak_version" in
    26.1.* | 26.0.*)
        echo "3.15.3.1"
        ;;
    999.0.0-SNAPSHOT)
        echo "Quarkus version will be get from pom.xml"
        return 1
        ;;
    *)
        echo "Unknown Quarkus version for Keycloak '$keycloak_version'. Use explicitly --quarkus-version property." >&2
        return 1
        ;;
    esac
}

handle_command_build() {
    # Initialize variables
    keycloak_version=""
    quarkus_version=""
    additional_properties=""

    # Process parameters for `build`
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --keycloak-version*)
            # Extract value from option
            keycloak_version="${1#*=}"
            if [[ -z "$keycloak_version" || "$keycloak_version" == "$1" ]]; then
                echo "Error: Missing value for --keycloak-version." >&2
                exit 1
            fi

            # If keycloak-version is 'main', set it to 999.0.0-SNAPSHOT
            if [[ "$keycloak_version" == "main" ]]; then
                keycloak_version="999.0.0-SNAPSHOT"
            fi

            echo "Keycloak version set to: $keycloak_version"
            ;;
        --quarkus-version*)
            # Extract value from option
            quarkus_version="${1#*=}"
            echo "Quarkus version set to: $quarkus_version"
            ;;
        -h | --help)
            show_help_build
            exit 0
            ;;
        *)
            echo "Unknown build option: $1" >&2
            echo "Type './kc-extension.sh build --help' for available build options."
            exit 1
            ;;
        esac
        shift
    done

    # Get Keycloak version from pom.xml only if it's not set
    if [[ -z "$keycloak_version" ]]; then
        keycloak_version=$(get_keycloak_version_from_pom) # Get default keycloak version from pom.xml
        echo "Using Keycloak version from pom.xml: $keycloak_version"
    fi

    if [[ "$keycloak_version" == "999.0.0-SNAPSHOT" ]]; then
        echo "Be aware that in order to use Keycloak nightly, you need to rebuild Keycloak repository in your local."
    fi

    # Get Quarkus version from Keycloak known releases or from pom.xml if not set
    if [[ -z "$quarkus_version" ]]; then
        if [[ "$keycloak_version" == "999.0.0-SNAPSHOT" ]]; then
            echo "You need to specify --quarkus-version when building on top of the Keycloak nightly" >&2
            exit 1
        fi
        
        if quarkus_version=$(get_quarkus_version_for_keycloak "$keycloak_version"); then
            echo "Using inferred Quarkus version: $quarkus_version"
        else
            quarkus_version=$(get_quarkus_version_from_pom)
            echo "Using Quarkus version from pom.xml: $quarkus_version"
        fi
    fi

    # Build the distribution
    echo "Executing build with '--keycloak-version': $keycloak_version, and '--quarkus-version': $quarkus_version"
    echo "Additional properties: $additional_properties"
    "$ROOT_DIR"/mvnw clean install -f "$ROOT_DIR"/pom.xml -DskipTests -Dkeycloak.version="$keycloak_version" -Dquarkus.version="$quarkus_version" $additional_properties
}

handle_command_build "$@"

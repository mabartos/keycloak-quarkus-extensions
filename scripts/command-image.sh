#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

show_help_image() {
    echo "Build extended Keycloak builder image with your custom extensions"
    echo
    echo "Usage: $0 image [OPTIONS]"
    echo
    echo "Options:"
    echo "  --use-docker                   Use Docker instead of Podman. Default is Podman."
    echo "  --version <version>            Specify the extended Keycloak version to use. Defaults to the version from 'pom.xml'."
    echo "  --name <name>                  Specify the image name. Defaults to 'keycloak-extended-{keycloak.version}'."
    echo "  -h, --help                     Displays this help message."
}

handle_command_image() {
    local use_docker=false
    local version=""
    local name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --use-docker)
            use_docker=true
            ;;
        --version)
            version="$2"
            shift
            ;;
        --name)
            name="$2"
            shift
            ;;
        -h | --help)
            show_help_image
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Type '$0 container --help' for available options."
            exit 1
            ;;
        esac
        shift
    done

    # Get keycloak.version from pom.xml if not provided
    if [[ -z "$version" ]]; then
        version=$(get_keycloak_version_from_pom)
        echo "Using version from pom.xml: $version"
    fi

    # Set default image name if not provided
    if [[ -z "$name" ]]; then
        name="keycloak-extended-${version}"
        echo "Using default image name: $name"
    fi

    if [ ! -f "$ROOT_DIR/keycloak-extended-$version.tar.gz" ]; then
        echo "Error: No extended Keycloak distribution (keycloak-extended-$version.tar.gz) found in root directory. Did you execute 'build' command?"
    fi

    # Determine the container engine
    local container_engine="podman"
    if [[ "$use_docker" == true ]]; then
        container_engine="docker"
    fi

    echo "Building Keycloak container image with $container_engine..."

    # Execute the container build command
    $container_engine build -t "$name" --build-arg=KEYCLOAK_DIST=keycloak-extended-"$version".tar.gz -f https://raw.githubusercontent.com/keycloak/keycloak/"$version"/quarkus/container/Dockerfile "$ROOT_DIR"

}

handle_command_image "$@"

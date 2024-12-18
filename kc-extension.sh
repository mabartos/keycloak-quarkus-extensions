#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

show_help() {
    echo "Add Quarkus/Quarkiverse extensions to your Keycloak deployment"
    echo
    echo "Usage: $0 [OPTIONS] <command>"
    echo
    echo "Options:"
    echo "  -h, --help                          Display this help message."
    echo
    echo "Commands:"
    echo "  add <extension>                     Add Quarkus/Quarkiverse extension present in the list of extensions."
    echo "  add <groupId:artifactId:version>    Manually add Quarkiverse or your own extension to the project by specifying GAV."
    echo "  build                               Rebuild the Keycloak distribution with custom extensions."
    echo "  list                                Display all available extensions."
    echo "  start-dev                           Execute the generated Keycloak distribution in development mode."
}

show_help_image() {
    echo "Build enhanced Keycloak builder image with your custom extensions"
    echo
    echo "Usage: $0 image [OPTIONS]"
    echo
    echo "Options:"
    echo "  --use-docker                   Use Docker instead of Podman. Default is Podman."
    echo "  --keycloak-version <version>   Specify the Keycloak version to use. Defaults to the version from 'pom.xml'."
    echo "  --name <name>                  Specify the image name. Defaults to 'keycloak-extended-{keycloak.version}'."
    echo "  -h, --help                     Displays this help message."
}

handle_image_command() {
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
            -h|--help)
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
        name="keycloak-extended-${keycloak_version}"
        echo "Using default image name: $name"
    fi

    if [ ! -f "$SCRIPT_DIR/keycloak-extended-$version.tar.gz" ]; then
        echo "Error: No extended Keycloak distribution (keycloak-extended-$version.tar.gz) found in root directory. Did you execute 'build' command?"
    fi

    # Determine the container engine
    local container_engine="podman"
    if [[ "$use_docker" == true ]]; then
        container_engine="docker"
    fi

    echo "Building Keycloak container image with $container_engine..."

    # Execute the container build command
    $container_engine build -t "$name" --build-arg=KEYCLOAK_DIST=keycloak-extended-"$version".tar.gz -f https://raw.githubusercontent.com/keycloak/keycloak/"$version"/quarkus/container/Dockerfile "$SCRIPT_DIR"
}

# Store the subcommand and shift it out of the argument list
command="${1:-help}"
shift

# Use case to handle different subcommands
case "$command" in
    add)
        "$SCRIPT_DIR"/scripts/command-add.sh "$@"
        ;;
    build)
        "$SCRIPT_DIR"/scripts/command-build.sh "$@"
        ;;
    list)
        "$SCRIPT_DIR"/scripts/command-list.sh "$@"
        ;;
    start-dev)
        # Find the Keycloak distribution zip file in the target directory
        keycloak_zip=$(find "$SCRIPT_DIR" -maxdepth 1 -name 'keycloak-extended-*.zip' | head -n 1)

        # Check if the zip file was found
        if [ -z "$keycloak_zip" ]; then
            echo "Error: No Keycloak distribution zip file found in target directory."
            exit 1
        fi

        rm -rf "$SCRIPT_DIR"/target/

        # Unzip the distribution
        echo "Unzipping Keycloak distribution from: $keycloak_zip"
        unzip -q "$keycloak_zip" -d "$SCRIPT_DIR"/target/

        # Change to the directory of the unzipped distribution
        keycloak_dir=$(basename "$keycloak_zip" .zip)
        cd "$SCRIPT_DIR/target/$keycloak_dir" || exit

        echo "Starting Keycloak in development mode..."

        ./bin/kc.sh start-dev
        ;;
    image)
        handle_image_command "$@"
        ;;

    -h|--help)
        show_help
        ;;

    *)
        echo "Unknown command: $command"
        echo "Type '$0 --help' for available commands."
        exit 1
        ;;
esac

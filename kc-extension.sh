#!/bin/bash

show_help() {
    echo "Add Quarkus/Quarkiverse extensions to your Keycloak deployment"
    echo
    echo "Usage: $0 [OPTIONS] <command>"
    echo
    echo "Options:"
    echo "  -h, --help                Displays this help message."
    echo
    echo "Commands:"
    echo "  add <extension(s)>        Adds one or more Quarkus/Quarkiverse extensions."
    echo "  build                     Rebuild the Keycloak distribution with custom extensions."
    echo "  list                      Displays all available extensions."
}

# Function to show help message for build command
show_help_build() {
    echo "Usage: $0 build [OPTIONS]"
    echo
    echo "Options:"
    echo "  --keycloak-version <version>    Specifies the Keycloak version (optional). Defaults to version from 'pom.xml' if not provided."
    echo "  --quarkus-version <version>     Specifies the Quarkus version (optional). Defaults to version from 'pom.xml' if not provided."
    echo "  --distPath <path>               Specifies the distribution path (optional)."
    echo "  -h, --help                      Displays this help message."
}

# Function to get keycloak.version from pom.xml
get_keycloak_version_from_pom() {
    # Extract the keycloak.version using grep
    version=$(grep -oPm1 "(?<=<keycloak.version>)[^<]+" pom.xml)
    # Check if version was found
    if [[ -z "$version" ]]; then
        echo "Error: No keycloak.version found in pom.xml."
        exit 1
    fi
    echo "$version"
}

# Function to get quarkus.version from pom.xml
get_quarkus_version_from_pom() {
    # Extract the quarkus.version using grep
    version=$(grep -oPm1 "(?<=<quarkus.version>)[^<]+" pom.xml)
    # Check if version was found
    if [[ -z "$version" ]]; then
        echo "Error: No quarkus.version found in pom.xml."
        exit 1
    fi
    echo "$version"
}

# Store the subcommand and shift it out of the argument list
command="${1:-help}"
shift

# Use case to handle different subcommands
case "$command" in
    add)
        # Check if additional arguments were provided
        if [ $# -eq 0 ]; then
            echo "Error: No extensions name provided."
            exit 1
        fi

        # Store all provided strings into a variable
        extensions="$@"

        ./mvnw -f runtime/pom.xml quarkus:add-extension -Dextensions="$extensions"

        echo "-------------------------------------------------------------------------------------------------------------------------------------------------------------"
        echo "WARNING: Do not forget to add the same extension present in runtime/pom.xml to the deployment/pom.xml with the suffix '-deployment' in artifactId (if exists)"
        echo "-------------------------------------------------------------------------------------------------------------------------------------------------------------"
        ;;

    build)
        # Initialize variables
        keycloak_version=""
        quarkus_version=""
        distPath=""

        # Process parameters for `build`
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --keycloak-version)
                    shift
                    if [[ -n "$1" ]]; then
                        keycloak_version="$1"
                        echo "Keycloak version set to: $keycloak_version"
                    else
                        echo "Error: Missing value for --keycloak-version."
                        exit 1
                    fi
                    ;;
                --quarkus-version)
                    shift
                    if [[ -n "$1" ]]; then
                        quarkus_version="$1"
                        echo "Quarkus version set to: $quarkus_version"
                    else
                        echo "Error: Missing value for --quarkus-version."
                        exit 1
                    fi
                    ;;
                --distPath)
                    shift
                    if [[ -n "$1" ]]; then
                        distPath="$1"
                        echo "Distribution path set to: $distPath"
                    else
                        echo "Error: Missing value for --distPath."
                        exit 1
                    fi
                    ;;
                -h|--help)
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
            keycloak_version=$(get_keycloak_version_from_pom)  # Get default keycloak version from pom.xml
            echo "Using keycloak version from pom.xml: $keycloak_version"
        fi

        # Get quarkus version from pom.xml only if it's not set
        if [[ -z "$quarkus_version" ]]; then
            quarkus_version=$(get_quarkus_version_from_pom)  # Get default quarkus version from pom.xml
            echo "Using quarkus version from pom.xml: $quarkus_version"
        fi

        # Build logic goes here using $keycloak_version, $quarkus_version, or $distPath variables
        echo "Executing build with '--keycloak-version': $keycloak_version, '--quarkus-version': $quarkus_version, and '--distPath': ${distPath:-N/A}"
        ;;

    list)
        ./mvnw -f runtime/pom.xml quarkus:list-extensions
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

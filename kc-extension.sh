#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
    echo "  start-dev                 Executes the generated Keycloak distribution in development mode."
}

# Function to show help message for build command
show_help_build() {
    echo "Build Keycloak distribution with provided Quarkus/Quarkiverse extensions"
    echo
    echo "Usage: $0 build [OPTIONS]"
    echo
    echo "Options:"
    echo "  --keycloak-version <version>    Specifies the Keycloak version. Defaults to version from 'pom.xml' if not provided."
    echo "  --quarkus-version <version>     Specifies the Quarkus version. Defaults to version from 'pom.xml' if not provided."
    echo "  --distPath <path>               Specifies the distribution path."
    echo "  -h, --help                      Displays this help message."
}

# Function to get keycloak.version from pom.xml
get_keycloak_version_from_pom() {
    # Extract the keycloak.version
    version=$("$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/pom.xml help:evaluate -Dexpression=keycloak.version -q -DforceStdout)
    # Check if version was found
    if [[ -z "$version" ]]; then
        echo "Error: No keycloak.version found in pom.xml."
        exit 1
    fi
    echo "$version"
}

# Function to get quarkus.version from pom.xml
get_quarkus_version_from_pom() {
    # Extract the quarkus.version
    version=$("$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/pom.xml help:evaluate -Dexpression=quarkus.version -q -DforceStdout)
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
        "$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/runtime/pom.xml quarkus:add-extension -Dextensions="$extensions"

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
                --distPath*)
                    # Extract value from option
                    distPath="${1#*=}"
                    if [[ -z "$distPath" || "$distPath" == "$1" ]]; then
                        echo "Error: Missing value for --distPath."
                        exit 1
                    fi
                    echo "Distribution path set to: $distPath"
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
        "$SCRIPT_DIR"/mvnw clean install -f "$SCRIPT_DIR"/pom.xml -DskipTests -Dkeycloak.version="$keycloak_version" -Dquarkus.version="$quarkus_version"
        ;;

    list)
        "$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/runtime/pom.xml quarkus:list-extensions
        ;;

    start-dev)
        # Check if target directory is empty
        if [ ! -d "$SCRIPT_DIR/target" ] || [ -z "$(ls -A "$SCRIPT_DIR"/target)" ]; then
            echo "Error: No generated Keycloak distribution found. Please run 'build' command first."
            exit 1
        fi

        # Find the Keycloak distribution zip file in the target directory
        keycloak_zip=$(find "$SCRIPT_DIR"/target -maxdepth 1 -name 'keycloak*.zip' | head -n 1)

        # Check if the zip file was found
        if [ -z "$keycloak_zip" ]; then
            echo "Error: No Keycloak distribution zip file found in target directory."
            exit 1
        fi

        # Unzip the distribution
        echo "Unzipping Keycloak distribution from: $keycloak_zip"
        unzip -q "$keycloak_zip" -d "$SCRIPT_DIR"/target/

        # Change to the directory of the unzipped distribution
        keycloak_dir=$(basename "$keycloak_zip" .zip)
        cd "$SCRIPT_DIR/target/$keycloak_dir" || exit

        # Start Keycloak in development mode
        echo "Starting Keycloak in development mode..."
        # Modify this command as needed for your specific distribution structure
        ./bin/kc.sh start-dev
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

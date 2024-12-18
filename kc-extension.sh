#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Explicitly add dependency to specific pom.xml file
add_dependency() {
    local groupId="$1"
    local artifactId="$2"
    local version="$3"
    local pomFile="$4"
    local show_version="$5"

    # Build the dependency snippet based on whether version is provided or not
    local dependencySnippet="\t\t<dependency>\n\
    \t\t<groupId>${groupId}</groupId>\n\
    \t\t<artifactId>${artifactId}</artifactId>\n"

    if [[ "$show_version" == true ]]; then
        dependencySnippet+="\t\t\t<version>${version}</version>\n"
    fi

    dependencySnippet+="\t\t</dependency>"

    # Insert the dependency XML snippet just before the closing </dependencies> tag
    sed -i "/<\/dependencies>/ i \\
$dependencySnippet" "$pomFile"
}

# Handle adding extension for deployment/pom.xml and for particular platform BOM
handle_add_extension() {
    local groupId="$1"
    local artifactId="$2"
    local version="$3"
    local show_version="$4"
    local pom_file="$5"

    echo "Handling extension with groupId '$groupId'."

    "$SCRIPT_DIR"/mvnw dependency:get -Dartifact="${groupId}:${artifactId}:${version}" -Dtransitive=false

    if [[ $? -eq 0 ]]; then
        if "$SCRIPT_DIR"/mvnw -f "$pom_file" dependency:tree | grep -q "${groupId}:${artifactId}"; then
            echo "Dependency ('$artifactId') is already part of '$pom_file'. Ignoring adding."
        else
            add_dependency "$groupId" "$artifactId" "$version" "$pom_file" "$show_version"
            echo "Automatically added dependency ('$artifactId')."
        fi
    else
        echo "Dependency '$artifactId' does not exist (exit code $?). Please, revisit the $pom_file."
    fi
}

handle_add_extension_gav() {
    local gav="$1"

    groupId=$(echo "$gav" | cut -d: -f1)
    artifactId=$(echo "$gav" | cut -d: -f2)
    version=$(echo "$gav" | cut -d: -f3)

    echo "Adding extension from GAV: $groupId:$artifactId:$version"

    handle_add_extension "$groupId" "$artifactId" "$version" true "$SCRIPT_DIR/runtime/pom.xml"
    handle_add_extension "$groupId" "${artifactId}-deployment" "$version" true "$SCRIPT_DIR/deployment/pom.xml"
}

handle_add_extension_name() {
    local artifactId="$1"
    output=$("$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/runtime/pom.xml quarkus:list-extensions -Dformat=origins | grep -w "$artifactId" | head -n 1)

    extension_name=$(echo "$output" | awk '{print ($2 == "✬" ? $3 : $2)}')
    version=$(echo "$output" | awk '{print $(NF-1)}')
    bom_info=$(echo "$output" | awk '{print $NF}')

    echo "Extension Name: $extension_name"
    echo "ArtifactId: $artifactId"
    echo "Version: $version"
    echo "BOM Info: $bom_info"

    if [[ $bom_info == io.quarkus.platform:quarkus-bom:* ]]; then
        handle_add_extension io.quarkus "${artifactId}-deployment" "$version" false "$SCRIPT_DIR/deployment/pom.xml"
    else
        echo "Error: Cannot find the extension. Specify it as GAV (groupId:artifactId:version)"
        exit 1
    fi

    "$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/runtime/pom.xml quarkus:add-extension -Dextension="$artifactId"
}

# Store the subcommand and shift it out of the argument list
command="${1:-help}"
shift

# Use case to handle different subcommands
case "$command" in
    add)
        # Check if additional arguments were provided
        if [ $# -eq 0 ]; then
            echo "Error: No extension name or GAV provided."
            exit 1
        elif [ $# -gt 1 ]; then
            echo "Error: You can specify only one extension at a time."
            exit 1
        fi
        input="$1"

        if [[ "$input" == *:*:* ]]; then
          # GAV
          handle_add_extension_gav "$input"
        else
          # Extension name
          handle_add_extension_name "$input"
        fi
        ;;

    build)
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
        echo "Additional properties: $additional_properties"
        "$SCRIPT_DIR"/mvnw clean install -f "$SCRIPT_DIR"/pom.xml -DskipTests -Dkeycloak.version="$keycloak_version" -Dquarkus.version="$quarkus_version" $additional_properties
        ;;

    list)
        "$SCRIPT_DIR"/mvnw -f "$SCRIPT_DIR"/runtime/pom.xml quarkus:list-extensions
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

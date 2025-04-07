#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

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

    "$ROOT_DIR"/mvnw dependency:get -Dartifact="${groupId}:${artifactId}:${version}" -Dtransitive=false

    if [[ $? -eq 0 ]]; then
        if "$ROOT_DIR"/mvnw -f "$pom_file" dependency:tree | grep -q "${groupId}:${artifactId}"; then
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

    handle_add_extension "$groupId" "$artifactId" "$version" true "$ROOT_DIR/runtime/pom.xml"
    handle_add_extension "$groupId" "${artifactId}-deployment" "$version" true "$ROOT_DIR/deployment/pom.xml"
}

handle_add_extension_name() {
    local artifactId="$1"
    output=$("$ROOT_DIR"/mvnw -f "$ROOT_DIR"/runtime/pom.xml quarkus:list-extensions -Dformat=origins | grep -w "$artifactId" | head -n 1)

    extension_name=$(echo "$output" | awk '{print ($2 == "✬" ? $3 : $2)}')
    version=$(echo "$output" | awk '{print $(NF-1)}')
    bom_info=$(echo "$output" | awk '{print $NF}')

    echo "Extension Name: $extension_name"
    echo "ArtifactId: $artifactId"
    echo "Version: $version"
    echo "BOM Info: $bom_info"

    if [[ $bom_info == io.quarkus.platform:quarkus-bom:* ]]; then
        handle_add_extension io.quarkus "${artifactId}-deployment" "$version" false "$ROOT_DIR/deployment/pom.xml"
    else
        echo "Error: Cannot find the extension. Specify it as GAV (groupId:artifactId:version)" >&2
        exit 1
    fi

    "$ROOT_DIR"/mvnw -f "$ROOT_DIR"/runtime/pom.xml quarkus:add-extension -Dextension="$artifactId"
}

handle_command_add() {
    # Check if additional arguments were provided
    if [ $# -eq 0 ]; then
        echo "Error: No extension name or GAV provided." >&2
        exit 1
    elif [ $# -gt 1 ]; then
        echo "Error: You can specify only one extension at a time." >&2
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
}

handle_command_add "$@"

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to get keycloak.version from pom.xml
get_keycloak_version_from_pom() {
    # Extract the keycloak.version
    version=$("$ROOT_DIR"/mvnw -f "$ROOT_DIR"/pom.xml help:evaluate -Dexpression=keycloak.version -q -DforceStdout)
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
    version=$("$ROOT_DIR"/mvnw -f "$ROOT_DIR"/pom.xml help:evaluate -Dexpression=quarkus.version -q -DforceStdout)
    # Check if version was found
    if [[ -z "$version" ]]; then
        echo "Error: No quarkus.version found in pom.xml."
        exit 1
    fi
    echo "$version"
}


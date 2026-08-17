#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to get keycloak.version from pom.xml
get_keycloak_version_from_pom() {
    # Extract the keycloak.version
    version=$("$ROOT_DIR"/mvnw -f "$ROOT_DIR"/pom.xml help:evaluate -Dexpression=keycloak.version -q -DforceStdout)
    # Check if version was found
    if [[ -z "$version" ]]; then
        echo "Error: No keycloak.version found in pom.xml." >&2
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
        echo "Error: No quarkus.version found in pom.xml." >&2
        exit 1
    fi
    echo "$version"
}

VERSIONS_FILE="$ROOT_DIR/keycloak-quarkus-versions.properties"

# Parse a line from the versions file (format: minor=keycloak-version:quarkus-version)
# Returns the value part after '=' for a given key
_get_versions_entry() {
    local key="$1"
    grep "^${key}=" "$VERSIONS_FILE" 2>/dev/null | cut -d'=' -f2
}

# Look up the Quarkus version for a given Keycloak version (e.g. 26.7.1) from the versions file
get_quarkus_version_for_keycloak() {
    local keycloak_version="$1"
    local minor="${keycloak_version%.*}"

    local entry
    entry=$(_get_versions_entry "$minor")

    if [[ -z "$entry" ]]; then
        echo "Unknown Quarkus version for Keycloak '$keycloak_version'. Use explicitly --quarkus-version property." >&2
        return 1
    fi
    echo "${entry#*:}"
}

# Look up the latest Keycloak micro version for a given minor (e.g. 26.7 -> 26.7.1)
get_latest_keycloak_version() {
    local minor="$1"

    local entry
    entry=$(_get_versions_entry "$minor")

    if [[ -z "$entry" ]]; then
        echo "Unknown Keycloak minor version '$minor'." >&2
        return 1
    fi
    echo "${entry%%:*}"
}

# Get the nightly Quarkus version from the versions file
get_quarkus_nightly_version() {
    local entry
    entry=$(_get_versions_entry "nightly")

    if [[ -z "$entry" ]]; then
        echo "Error: No nightly entry found in $VERSIONS_FILE." >&2
        exit 1
    fi
    echo "${entry#*:}"
}

# Get all supported Keycloak versions (for CI matrix)
get_all_keycloak_versions() {
    grep -v '^#' "$VERSIONS_FILE" | grep -v '^nightly=' | grep -v '^$' | cut -d'=' -f2 | cut -d':' -f1
}


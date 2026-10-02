#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSIONS_FILE="$ROOT_DIR/keycloak-quarkus-versions.properties"
README_FILE="$ROOT_DIR/README.md"
LATEST_KEYCLOAK_VERSION=$(awk -F'[=:]' '$1 !~ /^[[:space:]]*#/ && $1 != "nightly" && NF >= 3 { print $2 }' "$VERSIONS_FILE" | sort -V | tail -n 1)

if [[ -z "$LATEST_KEYCLOAK_VERSION" ]]; then
    echo "Could not find a stable Keycloak version in keycloak-quarkus-versions.properties." >&2
    exit 1
fi

if ! grep -q '^## Supported Keycloak versions$' "$README_FILE"; then
    echo "Could not find supported Keycloak versions section in README.md." >&2
    exit 1
fi

readme_tmp=$(mktemp)
trap 'rm -f "$readme_tmp"' EXIT

awk -v versions_file="$VERSIONS_FILE" -v latest_keycloak_version="$LATEST_KEYCLOAK_VERSION" '
    function print_readme_line(line) {
        if (line ~ /^\* `keycloak-extended-/ && line ~ /\.tar\.gz`$/) {
            line = "* `keycloak-extended-" latest_keycloak_version ".tar.gz`"
        } else if (line ~ /^\* `keycloak-extended-/ && line ~ /\.zip`$/) {
            line = "* `keycloak-extended-" latest_keycloak_version ".zip`"
        }
        print line
    }

    $0 == "## Supported Keycloak versions" {
        print_readme_line($0)
        line_status = getline line
        while (line_status > 0 && line !~ /^\|/) {
            print_readme_line(line)
            line_status = getline line
        }
        while (line_status > 0 && line ~ /^\|/) {
            line_status = getline line
        }

        print "| Keycloak | Quarkus  |"
        print "|----------|----------|"
        while ((getline version_line < versions_file) > 0) {
            if (version_line ~ /^[[:space:]]*#/ || version_line ~ /^[[:space:]]*$/) {
                continue
            }
            split(version_line, fields, /[=:]/)
            keycloak_version = fields[1] == "nightly" ? "nightly" : fields[1] ".x"
            printf "| %-8s | %-8s |\n", keycloak_version, fields[3]
        }
        close(versions_file)

        if (line_status > 0) {
            print_readme_line(line)
        }
        next
    }
    { print_readme_line($0) }
' "$README_FILE" > "$readme_tmp"

if ! cmp -s "$README_FILE" "$readme_tmp"; then
    mv "$readme_tmp" "$README_FILE"
fi

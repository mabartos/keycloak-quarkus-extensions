#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$ROOT_DIR/scripts/utils.sh"

handle_command_list() {
    "$ROOT_DIR"/mvnw -f "$ROOT_DIR"/runtime/pom.xml quarkus:list-extensions
}

handle_command_list "$@"

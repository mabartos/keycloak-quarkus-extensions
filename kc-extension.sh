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
    echo "  image                               Build extended Keycloak builder image with your custom extensions."
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
        "$SCRIPT_DIR"/scripts/command-start-dev.sh "$@"
        ;;
    image)
        "$SCRIPT_DIR"/scripts/command-image.sh "$@"
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

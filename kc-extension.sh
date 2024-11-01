#!/bin/bash

# Check if there's at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <command> [arguments...]"
    echo "Type '$0 help' for available commands."
    exit 1
fi

# Store the subcommand and shift it out of the argument list
command="$1"
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

    list)
        ./mvnw -f runtime/pom.xml quarkus:list-extensions
        ;;

    help)
        echo "Add Quarkus/Quarkiverse extensions to your Keycloak deployment"
        echo
        echo "Usage: $0 <command> [arguments...]"
        echo
        echo "Available commands:"
        echo "  add <extension(s)>   Adds one or more Quarkus/Quarkiverse extensions."
        echo "  list                 Displays all available extensions"
        echo "  help                 Displays this help message."
        ;;

    *)
        echo "Unknown command: $command"
        echo "Type '$0 help' for available commands."
        exit 1
        ;;
esac

![Keycloak-extended](logo.png)
![GitHub Release](https://img.shields.io/github/v/release/mabartos/keycloak-quarkus-extensions)
![CI Status](https://github.com/mabartos/keycloak-quarkus-extensions/actions/workflows/main.yml/badge.svg)

# Keycloak Quarkus Extensions

**Easily add Quarkus/Quarkiverse extension to your Keycloak distribution.**

The principle is quite basic as it mimics the process of building Keycloak distribution for the main Keycloak.
It will just include all Quarkus/Quarkiverse extensions in the distribution.

```shell
Add Quarkus/Quarkiverse extensions to your Keycloak deployment

Usage: ./kc-extension.sh <command>

Options:
  -h, --help                Display this help message.

Commands:
  add    <extension>        Add Quarkus/Quarkiverse extension.
  add    <GAV>              Manually add Quarkiverse or your own extension to the project by specifying <groupId:artifactId:version>.
  build                     Rebuild the Keycloak distribution with custom extensions.
  list                      Display all available extensions.
  start-dev                 Execute the generated Keycloak distribution in development mode.
  image                     Build extended Keycloak builder image with your custom extensions.
```

For more advanced use-cases, see the [Configuration guides](examples/README.md#configuration).

## Your first extended Keycloak

How to add your first extensions to your Keycloak deployment? Follow this simple guidelines:

```shell 
# Add official Quarkus extension
./kc-extension.sh add <extension-name>

# Add Quarkiverse extension by specifying the whole GAV
./kc-extension.sh add <groupId:artifactId:version>

# Add the necessary Quarkus properties in 'quarkus.properties' file

# Build the extended Keycloak distribution
./kc-extension.sh build

# Try it out by starting the extended distribution in dev mode
./kc-extension.sh start-dev
```

Now, you should be able to access extended nightly Keycloak instance at `localhost:8080`.

The `build` command generates extended Keycloak distribution as files:

* `keycloak-extended-26.4.7.tar.gz`
* `keycloak-extended-26.4.7.zip`

For more options how to build the distribution, check the [Advanced configuration](examples/advanced-configuration.md) guide or execute:
```shell
./kc-extension.sh build --help
```

## Container

Do you want to use the extended Keycloak as a container image?
Follow instructions in the [Container](docs/container.md) guide.

## Examples

For more examples how to configure the tool or add Quarkus/Quarkiverse extensions, see the [Examples](examples/README.md).

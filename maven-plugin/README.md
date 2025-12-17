# Keycloak Distribution Maven Plugin

A Maven plugin for building enhanced Keycloak distributions with custom Quarkus extensions.

## Overview

This plugin allows you to create a customized Keycloak distribution by adding Quarkus extensions through Maven dependency configuration. The plugin handles downloading the base Keycloak distribution, integrating your extensions, and building the final distribution package.

## Installation

First, build and install the plugin:

```bash
cd /path/to/keycloak-quarkus-extensions
./mvnw clean install
```

## Usage

### Basic Configuration

Create a Maven project with the following `pom.xml` configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>my-keycloak-distribution</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>

    <properties>
        <keycloak.version>26.4.1</keycloak.version>
        <quarkus.version>3.27.0</quarkus.version>
    </properties>

    <build>
        <plugins>
            <plugin>
                <groupId>org.keycloak.maven</groupId>
                <artifactId>keycloak-distribution-maven-plugin</artifactId>
                <version>1.0-SNAPSHOT</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>build</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <keycloakVersion>${keycloak.version}</keycloakVersion>
                    <quarkusVersion>${quarkus.version}</quarkusVersion>
                    <finalName>keycloak-custom-${keycloak.version}</finalName>
                    <extensions>
                        <dependency>
                            <groupId>io.quarkus</groupId>
                            <artifactId>quarkus-mongodb-client</artifactId>
                            <version>3.27.0</version>
                        </dependency>
                        <dependency>
                            <groupId>io.quarkus</groupId>
                            <artifactId>quarkus-redis-client</artifactId>
                            <version>3.27.0</version>
                        </dependency>
                    </extensions>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### Configuration Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `keycloakVersion` | Yes | - | The Keycloak version to use for the base distribution |
| `quarkusVersion` | No | Auto-detected from GitHub | The Quarkus version (auto-detected from Keycloak's parent pom.xml on GitHub if not specified) |
| `extensions` | No | - | List of additional dependencies (Quarkus extensions) to include |
| `finalName` | No | `keycloak-extended-${keycloak.version}` | The name of the final distribution |
| `skip` | No | `false` | Skip the plugin execution |

### Automatic Quarkus Version Detection

The plugin automatically detects the correct Quarkus version by fetching Keycloak's parent `pom.xml` from GitHub. This ensures perfect version alignment without manual configuration.

**How it works:**
1. Plugin fetches `https://raw.githubusercontent.com/keycloak/keycloak/refs/tags/{version}/pom.xml`
2. Extracts the `<quarkus.version>` property
3. Uses the detected version for the build

**Example - No need to specify quarkusVersion:**
```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <!-- quarkusVersion is automatically detected as 3.27.0 -->
    <extensions>...</extensions>
</configuration>
```

**To override auto-detection**, explicitly specify the version:
```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <quarkusVersion>3.27.0</quarkusVersion>
    <extensions>...</extensions>
</configuration>
```

### Building the Distribution

Run Maven to build your custom Keycloak distribution:

```bash
mvn clean package
```

The plugin will:
1. Auto-detect the Quarkus version from Keycloak's GitHub repository (if not specified)
2. Download the base Keycloak distribution (version specified in `keycloakVersion`)
3. Unpack the distribution
4. Create a temporary build project with your specified extensions
5. Build the distribution using Quarkus Maven Plugin
6. Package the final distribution

The resulting distribution will be available in:
- `target/keycloak-custom-26.4.1/` (unpacked directory)

## Examples

### Example 1: Adding MongoDB Support

```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <quarkusVersion>3.27.0</quarkusVersion>
    <extensions>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-mongodb-client</artifactId>
            <version>3.27.0</version>
        </dependency>
    </extensions>
</configuration>
```

### Example 2: Adding Multiple Quarkiverse Extensions

```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <quarkusVersion>3.27.0</quarkusVersion>
    <extensions>
        <dependency>
            <groupId>io.quarkiverse.logging.cloudwatch</groupId>
            <artifactId>quarkus-logging-cloudwatch</artifactId>
            <version>3.1.1</version>
        </dependency>
        <dependency>
            <groupId>io.quarkiverse.amazonservices</groupId>
            <artifactId>quarkus-amazon-s3</artifactId>
            <version>2.18.3</version>
        </dependency>
    </extensions>
</configuration>
```

### Example 3: Adding Custom Extension with Scope

```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <quarkusVersion>3.27.0</quarkusVersion>
    <extensions>
        <dependency>
            <groupId>com.mycompany</groupId>
            <artifactId>my-custom-keycloak-extension</artifactId>
            <version>1.0.0</version>
        </dependency>
    </extensions>
</configuration>
```

## Command Line Usage

You can also specify parameters from the command line:

```bash
mvn org.keycloak.maven:keycloak-distribution-maven-plugin:1.0-SNAPSHOT:build \
  -Dkeycloak.version=26.4.1 \
  -Dquarkus.version=3.27.0
```

To skip the plugin execution:

```bash
mvn clean package -Dkeycloak.dist.skip=true
```

## Version Compatibility

The Quarkus version must be aligned with your Keycloak version:

| Keycloak Version | Quarkus Version |
|------------------|-----------------|
| 26.4.x | 3.27.0 |
| 26.3.x | 3.20.3 |
| 26.2.x | 3.20.3 |

## Troubleshooting

### Issue: Distribution not found

Make sure the Keycloak version you specified is available in Maven Central or your configured repositories.

### Issue: Incompatible Quarkus version

Ensure that the Quarkus version is compatible with your Keycloak version. Refer to the Keycloak release notes for the correct Quarkus version.

### Issue: Extension not working

Some Quarkus extensions may require additional configuration in the Keycloak configuration files. Check the extension documentation for required properties.

## Customization

### Template-Based Configuration

The plugin uses template files instead of building POMs programmatically. This makes it easy to customize the build process without modifying Java code.

Templates are located in `src/main/resources/templates/`:
- `build-project-template.xml` - Template for the build project POM
- `unpack-distribution-template.xml` - Template for unpacking the Keycloak distribution

To customize:
1. Edit the template files
2. Rebuild the plugin with `mvn clean install`

For detailed information about templates and customization, see [TEMPLATES.md](TEMPLATES.md).

### Example: Adding a Custom Repository

Edit `build-project-template.xml` to add a custom Maven repository:

```xml
</dependencies>

<repositories>
    <repository>
        <id>my-repo</id>
        <url>https://my-repo.example.com/maven2</url>
    </repository>
</repositories>

<build>
```

## Building the Plugin

To build the plugin from source:

```bash
cd keycloak-quarkus-extensions/maven-plugin
mvn clean install
```

## License

This plugin is part of the Keycloak Quarkus Extensions project.

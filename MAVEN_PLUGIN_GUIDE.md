# Keycloak Distribution Maven Plugin Guide

## Overview

A Maven plugin has been created that allows you to build enhanced Keycloak distributions with custom Quarkus extensions by simply declaring dependencies in a Maven pom.xml.

## What Was Created

### 1. Maven Plugin Module (`maven-plugin/`)

- **Location**: `/maven-plugin/`
- **Artifact**: `org.keycloak.maven:keycloak-distribution-maven-plugin:1.0-SNAPSHOT`
- **Main Class**: `BuildDistributionMojo.java`

### 2. Documentation

- **Plugin README**: `/maven-plugin/README.md` - Comprehensive usage guide
- **Example Project**: `/maven-plugin/examples/simple-distribution/` - Working example

## Quick Start

### Step 1: Build the Plugin

```bash
cd /home/mabartos/Documents/RH/keycloak-quarkus-extensions
./mvnw clean install
```

### Step 2: Use the Plugin in Your Project

Create a new Maven project with this `pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>my-keycloak</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>

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
                    <keycloakVersion>26.4.1</keycloakVersion>
                    <!-- quarkusVersion is OPTIONAL - auto-detected from GitHub if not specified -->
                    <extensions>
                        <!-- Add your dependencies here -->
                        <dependency>
                            <groupId>io.quarkus</groupId>
                            <artifactId>quarkus-mongodb-client</artifactId>
                            <version>3.27.0</version>
                        </dependency>
                    </extensions>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### Step 3: Build Your Distribution

```bash
mvn clean package
```

Your custom Keycloak distribution will be in `target/keycloak-extended-26.4.1/`

## Automatic Quarkus Version Detection

**NEW FEATURE**: The plugin now automatically detects the correct Quarkus version!

You no longer need to specify `quarkusVersion` - the plugin fetches it from Keycloak's parent `pom.xml` on GitHub:

```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <!-- No need to specify quarkusVersion - auto-detected as 3.27.0 -->
    <extensions>...</extensions>
</configuration>
```

**How it works:**
- Fetches `https://raw.githubusercontent.com/keycloak/keycloak/refs/tags/{version}/pom.xml`
- Parses the `<quarkus.version>` property
- Uses the detected version automatically

**Override if needed:**
```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <quarkusVersion>3.27.0</quarkusVersion> <!-- Explicit override -->
</configuration>
```

## How It Works

The plugin performs these steps:

1. **Auto-detects** Quarkus version from Keycloak's GitHub pom.xml (if not specified)
2. **Downloads** the base Keycloak distribution (specified by `keycloakVersion`)
3. **Unpacks** it to `target/unpacked/`
4. **Creates** a temporary build project with:
   - Base Keycloak dependencies
   - Your custom extensions (from `<extensions>`)
5. **Builds** using the Quarkus Maven Plugin
6. **Packages** the final distribution in `target/`

## Configuration Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `keycloakVersion` | String | Yes | - | Keycloak version (e.g., "26.4.1") |
| `quarkusVersion` | String | **No** | Auto-detected from GitHub | Quarkus version (e.g., "3.27.0"). Auto-detected from Keycloak's pom.xml if not specified |
| `extensions` | List<Dependency> | No | [] | List of extensions to include |
| `finalName` | String | No | `keycloak-extended-${keycloak.version}` | Distribution name |
| `skip` | Boolean | No | false | Skip plugin execution |

## Extension Configuration

Each extension in the `<extensions>` list is a standard Maven dependency:

```xml
<dependency>
    <groupId>...</groupId>
    <artifactId>...</artifactId>
    <version>...</version>
    <!-- Optional -->
    <scope>...</scope>
    <type>...</type>
</dependency>
```

## Examples

### MongoDB + Redis Support

```xml
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
```

### AWS Services (Quarkiverse)

```xml
<extensions>
    <dependency>
        <groupId>io.quarkiverse.amazonservices</groupId>
        <artifactId>quarkus-amazon-s3</artifactId>
        <version>2.18.3</version>
    </dependency>
    <dependency>
        <groupId>io.quarkiverse.logging.cloudwatch</groupId>
        <artifactId>quarkus-logging-cloudwatch</artifactId>
        <version>3.1.1</version>
    </dependency>
</extensions>
```

### Custom Extension

```xml
<extensions>
    <dependency>
        <groupId>com.mycompany</groupId>
        <artifactId>my-keycloak-extension</artifactId>
        <version>1.0.0</version>
    </dependency>
</extensions>
```

## Version Compatibility

| Keycloak | Quarkus |
|----------|---------|
| 26.4.x   | 3.27.0  |
| 26.3.x   | 3.20.3  |
| 26.2.x   | 3.20.3  |

Always check the Keycloak release notes for the correct Quarkus version.

## Try the Example

A working example is provided in `/maven-plugin/examples/simple-distribution/`:

```bash
cd /home/mabartos/Documents/RH/keycloak-quarkus-extensions/maven-plugin/examples/simple-distribution
mvn clean package
```

This will create a Keycloak distribution with MongoDB and Redis support.

## Command Line Usage

You can also invoke the plugin directly:

```bash
mvn org.keycloak.maven:keycloak-distribution-maven-plugin:1.0-SNAPSHOT:build \
  -Dkeycloak.version=26.4.1 \
  -Dquarkus.version=3.27.0
```

## Project Structure

```
keycloak-quarkus-extensions/
├── maven-plugin/              # The Maven plugin
│   ├── src/main/java/
│   │   └── org/keycloak/maven/
│   │       └── BuildDistributionMojo.java
│   ├── examples/
│   │   └── simple-distribution/
│   │       ├── pom.xml        # Example usage
│   │       └── README.md
│   ├── pom.xml
│   └── README.md
├── runtime/                   # Existing modules
├── deployment/
├── resolver/
├── pom.xml                    # Updated to include maven-plugin module
└── MAVEN_PLUGIN_GUIDE.md     # This file
```

## Next Steps

1. **Build the plugin**: `./mvnw clean install`
2. **Try the example**: `cd maven-plugin/examples/simple-distribution && mvn clean package`
3. **Create your own**: Copy the example and modify the `<extensions>` section
4. **Explore extensions**: Visit https://quarkus.io/extensions/ and https://quarkiverse.io/

## Troubleshooting

### Maven can't find the plugin

Make sure you've run `./mvnw clean install` in the root directory to install the plugin to your local Maven repository.

### Wrong Quarkus version

Ensure the Quarkus version matches your Keycloak version. Check the Keycloak release notes.

### Distribution build fails

- Verify all extension GAV coordinates are correct
- Check that extensions are compatible with your Quarkus/Keycloak version
- Review build logs in `target/` for detailed error messages

## Advanced Usage

### Custom Distribution Name

```xml
<configuration>
    <keycloakVersion>26.4.1</keycloakVersion>
    <quarkusVersion>3.27.0</quarkusVersion>
    <finalName>my-custom-keycloak-${keycloak.version}</finalName>
    ...
</configuration>
```

### Skip Plugin Execution

```bash
mvn clean package -Dkeycloak.dist.skip=true
```

### Multiple Profiles

```xml
<profiles>
    <profile>
        <id>dev</id>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.keycloak.maven</groupId>
                    <artifactId>keycloak-distribution-maven-plugin</artifactId>
                    <configuration>
                        <keycloakVersion>26.4.1</keycloakVersion>
                        <extensions>
                            <!-- Dev extensions -->
                        </extensions>
                    </configuration>
                </plugin>
            </plugins>
        </build>
    </profile>
    <profile>
        <id>prod</id>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.keycloak.maven</groupId>
                    <artifactId>keycloak-distribution-maven-plugin</artifactId>
                    <configuration>
                        <keycloakVersion>26.4.1</keycloakVersion>
                        <extensions>
                            <!-- Prod extensions -->
                        </extensions>
                    </configuration>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

## Benefits Over Manual Approach

- **Declarative**: Just list dependencies, no manual script editing
- **Reproducible**: Same pom.xml = same distribution
- **Maven Integration**: Works with standard Maven lifecycle
- **Portable**: Share pom.xml instead of custom scripts
- **Version Control**: Easy to track changes in Git
- **Template-Based**: Easy to customize build process without Java code

## Customization and Templates

The plugin uses XML template files for POM generation, making it easy to customize without modifying Java code.

### Template Files

Located in `maven-plugin/src/main/resources/templates/`:

- **build-project-template.xml** - Template for the temporary build project
- **unpack-distribution-template.xml** - Template for unpacking Keycloak distribution

### Customizing Templates

To customize the build process:

1. Edit the template file (e.g., `build-project-template.xml`)
2. Rebuild the plugin: `cd maven-plugin && mvn clean install`
3. Use the updated plugin in your project

**Example**: Add a custom Maven repository to all builds by editing `build-project-template.xml`:

```xml
</dependencies>

<repositories>
    <repository>
        <id>corporate-repo</id>
        <url>https://repo.example.com/maven2</url>
    </repository>
</repositories>

<build>
```

For detailed information, see `/maven-plugin/TEMPLATES.md`.

## License

Part of the Keycloak Quarkus Extensions project.

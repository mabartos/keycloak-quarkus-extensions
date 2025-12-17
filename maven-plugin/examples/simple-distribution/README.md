# Simple Keycloak Distribution Example

This example demonstrates how to use the Keycloak Distribution Maven Plugin to create a custom Keycloak distribution with additional Quarkus extensions.

## What This Example Does

This example creates a Keycloak distribution that includes:
- Base Keycloak 26.4.1 distribution
- MongoDB client extension (quarkus-mongodb-client)
- Redis client extension (quarkus-redis-client)

## Prerequisites

1. Java 17 or later
2. Maven 3.8.1 or later
3. The Keycloak Distribution Maven Plugin must be installed in your local Maven repository

## Building the Plugin

First, build and install the plugin:

```bash
cd ../../..
./mvnw clean install
```

## Building the Distribution

From this directory, run:

```bash
mvn clean package
```

## What Happens

The plugin will:
1. Auto-detect the Quarkus version from Keycloak's GitHub repository (no need to specify it manually!)
2. Download the Keycloak 26.4.1 distribution from Maven Central
3. Unpack it to `target/unpacked/`
4. Create a build project with the specified extensions
4. Build the distribution using the Quarkus Maven Plugin
5. Package the result in `target/keycloak-with-mongodb-26.4.1/`

## Customizing the Distribution

To add or remove extensions, edit the `pom.xml` file and modify the `<extensions>` section:

```xml
<extensions>
    <dependency>
        <groupId>GROUP_ID</groupId>
        <artifactId>ARTIFACT_ID</artifactId>
        <version>VERSION</version>
    </dependency>
</extensions>
```

## Running the Distribution

After building, navigate to the distribution directory:

```bash
cd target/keycloak-with-mongodb-26.4.1/
```

Start Keycloak in development mode:

```bash
./bin/kc.sh start-dev
```

## Available Extensions

You can add any Quarkus extension. Some popular ones include:

- **Database clients**:
  - `quarkus-mongodb-client` - MongoDB support
  - `quarkus-redis-client` - Redis support
  - `quarkus-neo4j` - Neo4j support

- **Messaging**:
  - `quarkus-kafka-client` - Apache Kafka
  - `quarkus-messaging-amqp` - AMQP messaging

- **Cloud services** (Quarkiverse):
  - `quarkus-amazon-s3` - AWS S3
  - `quarkus-amazon-dynamodb` - AWS DynamoDB
  - `quarkus-google-cloud-storage` - Google Cloud Storage

- **Monitoring**:
  - `quarkus-micrometer-registry-prometheus` - Prometheus metrics
  - `quarkus-logging-cloudwatch` - CloudWatch logging

Find more extensions at:
- Quarkus Extensions: https://quarkus.io/extensions/
- Quarkiverse Hub: https://quarkiverse.io/

## Notes

- Ensure the Quarkus version matches the version used by your Keycloak version
- Keycloak 26.4.x uses Quarkus 3.27.0
- Some extensions may require additional configuration in Keycloak

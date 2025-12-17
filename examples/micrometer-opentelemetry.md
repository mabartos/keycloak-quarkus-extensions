# Micrometer OpenTelemetry Bridge

**Quarkus extension**: `quarkus-micrometer-opentelemetry`

**Quarkiverse extension?**: No

**INFO:** The Micrometer OpenTelemetry bridge will probably be part of Keycloak 26.5 release by default.

This extension provides support for both Micrometer and OpenTelemetry in Quarkus applications. It streamlines integration by incorporating both extensions along with a bridge that enables sending Micrometer metrics via OpenTelemetry.

For more information, check the [Micrometer and OpenTelemetry extension](https://quarkus.io/guides/telemetry-micrometer-to-opentelemetry)
website.

## Guide

1. Add the extension:

```shell
./kc-extension.sh add quarkus-micrometer-opentelemetry
```

2. Add Quarkus properties in
   root `quarkus.properties`:

```properties
quarkus.otel.enabled=true
quarkus.otel.metrics.enabled=true
```

3. Build the extended Keycloak distribution:

```shell
./kc-extension.sh build
```

4. Verify it works by running the distribution in dev mode (access at `localhost:8080`):

```shell
./kc-extension.sh start-dev --metrics-enabled=true
```

## Container support

The generated distribution should be available in the root directory with prefix `keycloak-extended-*.tar.gz`.

5. Create a builder image:

```shell
./kc-extension.sh image
```

6. Create your Containerfile/Dockerfile with the builder image

```Dockerfile
FROM localhost/keycloak-extended:nightly AS builder

# Put your build-time config options
ENV KC_METRICS_ENABLED=true

RUN /opt/keycloak/bin/kc.sh build

FROM localhost/keycloak-extended:nightly
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Put your runtime config options

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

7. Execute the Containerfile/Dockerfile

```shell
podman build --tag keycloak-otel-bridge -f Dockerfile .
```

8. Start the optimized image

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
keycloak-otel-bridge \
start --hostname-strict=false --http-enabled=true --optimized
```

## Summary

You should be able to use the Micrometer OpenTelemetry bridge in your Keycloak deployment or your Keycloak extension.

For more information, check the [Quarkus LangChain4j](https://quarkus.io/guides/telemetry-micrometer-to-opentelemetry) guide.
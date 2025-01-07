# OpenTelemetry Exporter for Google Cloud Platform _(experimental)_

**Quarkus extension**: `quarkus-opentelemetry-exporter-gcp`

**Quarkiverse extension?**: Yes

Exporters are OpenTelemetry SDK Plugins which implement the Exporter interface, and emit telemetry to consumers, usually observability vendors.
This exporter sends data to Google Cloud Platform using [opentelemetry-operations-java](https://github.com/GoogleCloudPlatform/opentelemetry-operations-java) library.

For more information, check the [Quarkiverse OTel Exporter guide](https://docs.quarkiverse.io/quarkus-opentelemetry-exporter/dev/quarkus-opentelemetry-exporter-gcp.html), and the [Google Cloud guides](https://cloud.google.com/docs/authentication/provide-credentials-adc#how-to).

**WARN**: This example is only experimental and you should verify it works as expected - this is only a possible theoretical solution. 

## Guide

1. Add the extension:

```shell
./kc-extension.sh add io.quarkiverse.opentelemetry.exporter:quarkus-opentelemetry-exporter-gcp:3.16.2.0
```

2. Add Quarkus properties in root `quarkus.properties` to disable the default exporter and enable the GCP:

```properties
quarkus.opentelemetry.tracer.exporter.otlp.enabled=false
quarkus.opentelemetry.tracer.exporter.gcp.enabled=true
```

3. Build the extended Keycloak distribution:

```shell
./kc-extension.sh build
```

4. Verify it works by running the distribution in dev mode (access at `localhost:8080`):

```shell
./kc-extension.sh start-dev --tracing-enabled=true
```

### Container support

The generated distribution should be available in the root directory with prefix `keycloak-extended-*.tar.gz`.

5. Create a builder image:

```shell
./kc-extension.sh image
```

6. Create your Containerfile/Dockerfile with the builder image

```Dockerfile
FROM localhost/keycloak-extended:nightly AS builder

# Put your build-time config options
ENV KC_TRACING_ENABLED true

RUN /opt/keycloak/bin/kc.sh build

FROM localhost/keycloak-extended:nightly
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Put your runtime config options

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

7. Execute the Containerfile/Dockerfile

```shell
podman build --tag keycloak-otel-gcp -f Dockerfile .
```

8. Start the optimized image

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
keycloak-otel-gcp \
start --hostname-strict=false --http-enabled=true --optimized
```

## Summary

You should be able to use OpenTelemetry Exporter for GCP now.

For more information, check the [Quarkiverse OTel Exporter guide](https://docs.quarkiverse.io/quarkus-opentelemetry-exporter/dev/quarkus-opentelemetry-exporter-gcp.html), and the [Google Cloud guides](https://cloud.google.com/docs/authentication/provide-credentials-adc#how-to).

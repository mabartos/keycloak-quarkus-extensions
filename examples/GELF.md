# Quarkus GELF extension

**Quarkus extension**: `quarkus-logging-gelf`

**Quarkiverse extension?**: No

Centralized log management with Graylog Extended Log Format (GELF).

For more information, check the [Centralized Log Management](https://quarkus.io/guides/centralized-log-management)
Quarkus guide.

## Guide

1. Add the extension `quarkus-logging-gelf`:

```shell
./kc-extension.sh add quarkus-logging-gelf
```

2. Add Quarkus properties in root `quarkus.properties`:

```properties
quarkus.log.handler.gelf.enabled=true
quarkus.log.handler.gelf.host=localhost
quarkus.log.handler.gelf.port=12201
```

3. Build the extended Keycloak distribution:

```shell
./kc-extension.sh build
```

4. Verify it works by running the distribution in dev mode (access at `localhost:8080`):

```shell
./kc-extension.sh start-dev
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

RUN /opt/keycloak/bin/kc.sh build

FROM localhost/keycloak-extended:nightly
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Put your runtime config options

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

7. Execute the Containerfile/Dockerfile

```shell
podman build --tag keycloak-gelf -f Dockerfile .
```

8. Start the optimized image

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
keycloak-gelf \
start --hostname-strict=false --http-enabled=true --optimized
```

## Summary

You should be able to send logs to your GELF receiver.

For more information, check
the [Send logs to Graylog](https://quarkus.io/guides/centralized-log-management#send-logs-to-graylog) Quarkus guide.
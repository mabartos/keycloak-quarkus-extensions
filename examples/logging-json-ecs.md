# Quarkiverse Logging JSON (ECS)

**Quarkus extension**: `quarkus-logging-json`

**Quarkiverse extension?**: Yes

Quarkus logging extension outputting the logging in JSON with the support of ECS (Elastic Common Schema).

For more information, check the [Quarkus Logging Json](https://github.com/quarkiverse/quarkus-logging-json) repository.

## Guide

1. Add the extension:

```shell
./kc-extension.sh add io.quarkiverse.loggingjson:quarkus-logging-json:3.1.0
```

2. Add Quarkus properties in root `quarkus.properties`:

```properties
quarkus.log.json.log-format=ecs
```

3. Build the extended Keycloak distribution:

```shell
./kc-extension.sh build
```

4. Verify it works by running the distribution in dev mode (access at `localhost:8080`):

```shell
./kc-extension.sh start-dev
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

RUN /opt/keycloak/bin/kc.sh build

FROM localhost/keycloak-extended:nightly
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Put your runtime config options

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

7. Execute the Containerfile/Dockerfile

```shell
podman build --tag keycloak-logging-ecs -f Dockerfile .
```

8. Start the optimized image

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
keycloak-logging-ecs \
start --hostname-strict=false --http-enabled=true --optimized
```

## Summary

You should be able to have logs in ECS format.

For more information, check
the [Quarkus Logging Json](https://github.com/quarkiverse/quarkus-logging-json) repository.
# Keycloak Adaptive Authentication extension

**(Quarkus custom extension)**

[Keycloak Adaptive Authentication](https://github.com/mabartos/keycloak-adaptive-authn) extension is a custom Keycloak extension made as Quarkus extension.
This approach might be used for deploying custom Keycloak extensions in Keycloak installation without need for used JARs.

This extension adds the capability to use Risk-based authentication and leveraging AI engines for further processing of login actions.

## Guide

In this example, you can see how to smoothly include the extension to your Keycloak installation.
You need to build the extension on your local machine as based on recent information, the extension is not publicly published anywhere yet.

1. Clone the extension repository

```shell
git clone git@github.com:mabartos/keycloak-adaptive-authn.git
```

2. Build the extension

```shell
cd keycloak-adaptive-authn && ./mvnw clean install -DskipTests
```

3. Add the extension

```shell
./kc-extension.sh add io.github.mabartos:keycloak-adaptive-authn:999.0.0-SNAPSHOT
```

3. Build the extended Keycloak distribution:

```shell
./kc-extension.sh build
```

4. Verify it works by running the distribution in dev mode (access at `localhost:8080`):

```shell
./kc-extension.sh start-dev
```

5. (optional) Do not forget to add necessary Environment variables to leverage all functionalities of the extension

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

# Put your environment variables here
ENV RECAPTCHA_SITE_KEY=xxxx
ENV OPEN_AI_API_URL=xxxxx

# Put your runtime config options

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

7. Execute the Containerfile/Dockerfile

```shell
podman build --tag keycloak-adaptive-authn -f Dockerfile .
```

8. Start the optimized image

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
keycloak-adaptive-authn \
start --hostname-strict=false --http-enabled=true --optimized
```

## Summary

You should be able to use the Keycloak Adaptive Authentication in your Keycloak installation.
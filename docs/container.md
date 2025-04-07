# Container Support

Do you want to use extended Keycloak as a container image?
We provide command `image` that builds image, which purpose is to be a `builder` image in your Containerfile/Dockerfile
as described
in [Writing your optimized Keycloak Containerfile](https://www.keycloak.org/server/containers#_writing_your_optimized_keycloak_containerfile).

For more options, execute `./kc-extension.sh image --help`.

## Create a builder image

To create the builder image, execute:

```shell
./kc-extension.sh image
```

**INFO**: You need to have `curl` installed. 

It will create an image `keycloak-extended` with tag of used version (`nightly` by default).

**INFO**: If you use `docker` instead of `podman`, you should add option `--use-docker`.

It can be used in your Containerfile/Dockerfile as follows:

```Dockerfile
FROM localhost/keycloak-extended:nightly AS builder
```

**INFO**: You can push the image to more available sources

## Create an optimized enhanced image

As mentioned in the
guide [Writing your optimized Keycloak Containerfile](https://www.keycloak.org/server/containers#_writing_your_optimized_keycloak_containerfile),
you can create your own optimized image.
The builder image might be used as shown in the [Containerfile-example](../examples/Containerfile-example):

```Dockerfile
FROM localhost/keycloak-extended:nightly AS builder

ENV KC_HEALTH_ENABLED true
ENV KC_METRICS_ENABLED=true

# Put your build-time config options

RUN /opt/keycloak/bin/kc.sh build

FROM localhost/keycloak-extended:nightly
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Put your runtime config options

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
```

Note the used builder image `keycloak-extended:nightly` created by us.

The optimized image can be created as follows:

```shell
podman build --tag my-extended-keycloak -f examples/Containerfile-example .
```

## Start the optimized image

We have created the optimized image and we can start it as mentioned in the [Container](https://www.keycloak.org/getting-started/getting-started-podman) guide, and as follows:

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
my-extended-keycloak \
start --hostname-strict=false --http-enabled=true --optimized
```

You should see the extended Keycloak accessible at `localhost:8080`.

**INFO**: Use `docker` if you don't use `podman`.
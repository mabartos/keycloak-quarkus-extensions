# Advanced configuration

You can achieve much more with the configuration of the tool and the advanced configuration is described here.

## Different Keycloak version

If you want to add extensions to some other version of Keycloak, you can specify the version.
Be aware that the Quarkus version needs to be explicitly set (for now) and be aligned with the Keycloak version.
You can find the Quarkus version in the parent `pom.xml` of the specific Keycloak version -
for [Keycloak 25.0.6](https://github.com/keycloak/keycloak/blob/25.0.6/pom.xml#L48).

Use the `--keycloak-version`, and `--quarkus-version` properties for the `build` command as follows for Keycloak 25.0.6:

```shell
./kc-extension.sh build --keycloak-version=25.0.6 --quarkus-version=3.8.5
```

## Dev start for a different extended Keycloak version

If you want to start in dev mode the extended Keycloak distribution, but you have generated more distributions with
different versions, you can set the required version.

Use the `--version` option for the `start-dev` command for generated distribution with version 25.0.6 as follows:

```shell
./kc-extension.sh start-dev --version=25.0.6
```

## Container

### Use `docker` for creating builder image

When the `image` command is executed, the default container engine is `podman`.
If you want to use `docker` instead, use the `--use-docker` option as follows:

```shell
./kc-extension.sh image --use-docker
```

### Create builder image for different distribution version

If you generated extended Keycloak distribution with different version and want to create the builder image for it, you
need to specify the version of the distribution.

You can leverage the `--version` option for the `image` command for version 25.0.6 as follows:

```shell
./kc-extension.sh image --version=25.0.6
```

### Use different name for the builder image

The default builder image name is `keycloak-extended:{version}`, but you can override it via `--name` option of
the `image` command as follows:

```shell
./kc-extension.sh image --name=my-custom-name
```

It will create the builder image with name `my-custom-name:{version}`.
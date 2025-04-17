# Advanced configuration

You can achieve much more with the configuration of the tool and the advanced configuration is described here.

## Build on top of Keycloak nightly

Set the `--keycloak-version` property for the `build` command to `main` with the `--quarkus-version` set to the one used in [nightly build](https://github.com/keycloak/keycloak/blob/nightly/pom.xml#L55).

Example:

```shell
./kc-extension.sh build --keycloak-version=main --quarkus-version=3.20.0
```

## Different Keycloak version

Use the `--keycloak-version` property for the `build` command as follows for Keycloak 26.0.8:

```shell
./kc-extension.sh build --keycloak-version=26.0.8
```

**INFO:** 
We need to know the Quarkus version tied with the certain Keycloak release.
We use Quarkus version for known Keycloak releases and if not found, using the one specified in the parent `pom.xml`.
Find the Quarkus version in the Keycloak parent `pom.xml` of the specific Keycloak version (if any issue occurs) -
for [Keycloak 26.0.8](https://github.com/keycloak/keycloak/blob/26.0.8/pom.xml#L54).

## Dev start for a different extended Keycloak version

If you want to start in dev mode the extended Keycloak distribution, but you have generated more distributions with
different versions, you can set the required version.

Use the `--version` option for the `start-dev` command for generated distribution with version 26.0.8 as follows:

```shell
./kc-extension.sh start-dev --version=26.0.8
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

You can leverage the `--version` option for the `image` command for version 26.0.8 as follows:

```shell
./kc-extension.sh image --version=26.0.8
```

### Use different name for the builder image

The default builder image name is `keycloak-extended:{version}`, but you can override it via `--name` option of
the `image` command as follows:

```shell
./kc-extension.sh image --name=my-custom-name
```

It will create the builder image with name `my-custom-name:{version}`.
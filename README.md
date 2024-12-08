## Keycloak Quarkus extensions

Easily add Quarkus/Quarkiverse extension to your Keycloak distribution.

```shell
Add Quarkus/Quarkiverse extensions to your Keycloak deployment

Usage: ../kc-extension.sh [OPTIONS] <command>

Options:
  -h, --help                Display this help message.

Commands:
  add <extension>           Add Quarkus/Quarkiverse extension.
  build                     Rebuild the Keycloak distribution with custom extensions.
  list                      Display all available extensions.
  start-dev                 Execute the generated Keycloak distribution in development mode.
```

**INFO**: Work is still in a progress and code MAY change!

### Add extension

Execute this shell script:

```shell
./kc-extension.sh add <extension>
```

### Build the distribution with the extensions

Build the distribution with all provided extensions:

```shell
Build Keycloak distribution with provided Quarkus/Quarkiverse extensions

Usage: ./kc-extension.sh build [OPTIONS]

Options:
  --keycloak-version <version>    Specify the Keycloak version. Defaults to version from 'pom.xml' if not provided.
  --quarkus-version <version>     Specify the Quarkus version. Defaults to version from 'pom.xml' if not provided.
  --distPath <path>               Specify the distribution path.
  --container                     Specify the build is run in container. No external distribution is fetched and only necessary files are generated.
  -h, --help                      Displays this help message.
```

### Start the built Keycloak distribution in dev mode

The resulted Keycloak distribution is packaged as `.zip` file in `/target` folder.

Start in dev mode:

```shell
./kc-extension.sh start-dev
```
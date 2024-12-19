# Quarkiverse LangChain4j

**Quarkus extension**: `quarkus-langchain4j-*`

**Quarkiverse extension?**: Yes

LangChain4j extensions seamlessly integrates LLMs into Quarkus applications, enabling the harnessing of LLM capabilities
for the development of more intelligent applications.

It is possible to connect with various LLMs as:

* OpenAI
* HuggingFace
* Ollama
* Mistral
* IBM Watson
* More

For more information, check the [Quarkus LangChain4j](https://docs.quarkiverse.io/quarkus-langchain4j/dev/index.html)
website.

## Guide

In this guide, we will show an example with OpenAI, but you can use any other LLM available on
the [website](https://docs.quarkiverse.io/quarkus-langchain4j/dev/llms.html).

1. Add the extension:

```shell
./kc-extension.sh add io.quarkiverse.langchain4j:quarkus-langchain4j-openai:0.22.0
```

2. Add Quarkus properties in
   root `quarkus.properties`([more available options](https://docs.quarkiverse.io/quarkus-langchain4j/dev/openai.html)):

```properties
quarkus.langchain4j.openai.api-key=sk-...
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
podman build --tag keycloak-langchain4j -f Dockerfile .
```

8. Start the optimized image

```shell
podman run -p 8080:8080 \
-e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
-e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
keycloak-langchain4j \
start --hostname-strict=false --http-enabled=true --optimized
```

## Summary

You should be able to use LangChain4j in your Keycloak deployment or your Keycloak extension.

For more information, check the [Quarkus LangChain4j](https://docs.quarkiverse.io/quarkus-langchain4j/dev/index.html)
website.
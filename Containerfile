FROM registry.access.redhat.com/ubi9 AS ubi-micro-build

ENV KEYCLOAK_VERSION 26.0.5
ARG KEYCLOAK_DIST=https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.zip

RUN dnf install -y unzip java-21-openjdk-headless

ADD $KEYCLOAK_DIST /tmp/keycloak/

RUN (cd /tmp/keycloak && unzip /tmp/keycloak/keycloak-*.zip && rm /tmp/keycloak/keycloak-*.zip)

RUN mv /tmp/keycloak/keycloak-* /opt/keycloak && mkdir -p /opt/keycloak/data
RUN chmod -R g+rwX /opt/keycloak

ADD . /opt/keycloak-quarkus-extensions

WORKDIR /opt/keycloak-quarkus-extensions

RUN rm -rf keycloak-extended-*.zip
RUN rm -rf keycloak-extended-*.tar.gz

ADD ubi-null.sh /tmp/
RUN bash /tmp/ubi-null.sh glibc-langpack-en findutils

# ------------------------ #
# ADD YOUR EXTENSIONS HERE
#
# f.e RUN ./kc-extension.sh add <extension>
#
# -----------BEGIN------------- #

RUN ./kc-extension.sh add quarkus-spring-security
RUN ./kc-extension.sh add quarkus-smallrye-fault-tolerance

# -----------END--------------- #

RUN ./kc-extension.sh build --container --keycloak-version=${KEYCLOAK_VERSION}

RUN (unzip keycloak-*.zip && rm keycloak-*.zip)
RUN rm -rf /opt/keycloak/lib
RUN mv keycloak-*/lib /opt/keycloak/lib
ADD application.properties /opt/keycloak/conf/

RUN bash /tmp/ubi-null.sh java-21-openjdk-headless
RUN rm -rf /root/.m2/

FROM registry.access.redhat.com/ubi9-micro
ENV LANG en_US.UTF-8

# Flag for determining app is running in container
ENV KC_RUN_IN_CONTAINER true

COPY --from=ubi-micro-build /tmp/null/rootfs/ /
COPY --from=ubi-micro-build --chown=1000:0 /opt/keycloak /opt/keycloak

RUN echo "keycloak:x:0:root" >> /etc/group && \
    echo "keycloak:x:1000:0:keycloak user:/opt/keycloak:/sbin/nologin" >> /etc/passwd

USER 1000

EXPOSE 8080
EXPOSE 8443
EXPOSE 9000

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]
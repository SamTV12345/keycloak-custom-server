ARG KeycloakVersion=26.1.4


FROM alpine:edge

RUN apk add bash binutils openjdk21-jre-headless --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community && \
    echo "keycloak:x:0:root" >> /etc/group && \
    echo "keycloak:x:1000:0:keycloak user:/opt/keycloak:/sbin/nologin" >> /etc/passwd

RUN apk add tzdata bash --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community && \
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime # set timezone

COPY --chown=$USER ./target/$KeycloakVersion/ /opt/keycloak/

RUN echo "Add certificates to cacerts truststore" \
    && ls -l /opt/keycloak/conf/certs/* \
    && cat /opt/keycloak/conf/certs/*.pem > /usr/local/share/ca-certificates/ca-certficates.crt \
    && echo "Updating cacerts truststore..."\
    && update-ca-certificates \
    && echo "Certificates added to cacerts truststore" \
    || (echo "Could not import certificates" && exit 1)

# Note you can check if certs were added with the following commands
# keytool -list -keystore /etc/pki/java/cacerts -storepass changeit |& head
# keytool -list -keystore /etc/pki/java/cacerts -storepass changeit |& grep -i mycustomcert
USER root
RUN chmod +x /opt/keycloak/bin/kc.sh
RUN chown -R keycloak:keycloak /opt/keycloak
USER keycloak

EXPOSE 8080
EXPOSE 8443



ENTRYPOINT [ "/opt/keycloak/bin/kc.sh", "start"]
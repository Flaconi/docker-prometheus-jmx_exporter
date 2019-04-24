ARG GOMPLATE_VERSION=v3.3.1
FROM hairyhenderson/gomplate:${GOMPLATE_VERSION}-slim as gomplate

# Until we have a base image containing "gosu", we install it following
# https://github.com/tianon/gosu/blob/master/INSTALL.md
FROM debian:stretch-slim as gosu
ARG GOSU_VERSION=1.11
RUN set -eux; \
    # save list of currently installed packages for later so we can clean up
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget; \
    if ! command -v gpg; then \
        apt-get install -y --no-install-recommends gnupg2 dirmngr; \
    fi; \
    rm -rf /var/lib/apt/lists/*; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -q -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -q -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    \
    # verify the signature
    export GNUPGHOME="$(mktemp -d)"; \
    # for flaky keyservers, consider https://github.com/tianon/pgp-happy-eyeballs, ala https://github.com/docker-library/php/pull/666
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    command -v gpgconf && gpgconf --kill all || :; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    \
    # clean up fetch dependencies
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    \
    chmod +x /usr/local/bin/gosu; \
    # verify that the binary works
    gosu --version; \
    gosu nobody true

FROM flaconi/java-base:stretch-slim-openjdk-java8
LABEL maintainer="devops@flaconi.de"

ARG JMX_EXPORTER_VERSION=0.11.0
ENV JMX_EXPORTER_JAR=jmx_prometheus_httpserver-${JMX_EXPORTER_VERSION}-jar-with-dependencies.jar

ENV JMX_HOST=localhost
ENV JMX_PORT=1099
ENV JMX_USERNAME=""
ENV JMX_PASSWORD=""
ENV JMX_RULES=""

ENV EXPORTER_PORT=10990

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests wget; \
    mkdir -p /opt/jmx_exporter/config; \
    wget -q -O /opt/jmx_exporter/${JMX_EXPORTER_JAR} https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/${JMX_EXPORTER_VERSION}/${JMX_EXPORTER_JAR}; \
    apt-get remove --purge --auto-remove -y wget; \
    rm -rf /var/lib/apt/lists/*

COPY --from=gomplate /gomplate /bin/gomplate
COPY --from=gosu /usr/local/bin/gosu /bin/gosu

COPY config.yml /opt/jmx_exporter/config/
COPY start.sh /opt/jmx_exporter/

ENTRYPOINT ["/opt/jmx_exporter/start.sh"]

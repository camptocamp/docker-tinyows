FROM ubuntu:24.04 AS builder
LABEL maintainer="info@camptocamp.com"

RUN --mount=type=cache,target=/var/lib/apt/lists \
    --mount=type=cache,target=/var/cache,sharing=locked \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
        git curl ca-certificates ccache clang autoconf libxml2-dev libpq-dev postgis flex libfcgi-dev make \
        libfl-dev

ARG TINYOWS_BRANCH
RUN git clone https://github.com/mapserver/tinyows.git --branch=${TINYOWS_BRANCH} --depth=100 /src

ENV \
    CXX="/usr/lib/ccache/clang++" \
    CC="/usr/lib/ccache/clang"

WORKDIR /src/

RUN autoconf
RUN ./configure --prefix /usr/local
RUN make

RUN ccache -M10G
RUN make install
RUN mkdir -p /usr/local/bin
RUN cp tinyows /usr/local/bin/
RUN ccache -s

FROM ubuntu:24.04 AS runner
LABEL maintainer="info@camptocamp.com"

# let's copy a few of the settings from /etc/init.d/apache2
ENV APACHE_CONFDIR=/etc/apache2 \
    APACHE_ENVVARS=/etc/apache2/envvars \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_PID_FILE=/etc/apache2/apache2.pid \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2

RUN --mount=type=cache,target=/var/lib/apt/lists \
    --mount=type=cache,target=/var/cache,sharing=locked \
    apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --assume-yes --no-install-recommends \
        apache2 libapache2-mod-fcgid libpq5 libfcgi0ldbl libxml2 libfl2 glibc-tools adduser \
    && a2enmod fcgid headers \
    && a2dismod -f auth_basic authn_file authn_core authz_host authz_user autoindex dir status \
    && rm /etc/apache2/mods-enabled/alias.conf \
    && mkdir --parent ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} \
    && find "$APACHE_CONFDIR" -type f -exec sed -ri ' \
       s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
       s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
       ' '{}' ';' \
    && sed -ri 's!LogFormat "(.*)" combined!LogFormat "%{us}T %{X-Request-Id}i \1" combined!g' /etc/apache2/apache2.conf \
    && echo 'ErrorLogFormat "%{X-Request-Id}i [%l] [pid %P] %M"' >> /etc/apache2/apache2.conf

EXPOSE 80

COPY --from=builder /usr/local/bin /usr/local/bin/
COPY --from=builder /usr/local/lib /usr/local/lib/
COPY --from=builder /usr/local/share/tinyows/ /usr/local/share/tinyows/
COPY runtime /

RUN adduser www-data root \
    && chmod -R g+rw ${APACHE_CONFDIR} ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} /var/lib/apache2/fcgid /var/log \
    && chgrp -R root ${APACHE_LOG_DIR} /var/lib/apache2/fcgid

ENV MAX_REQUESTS_PER_PROCESS=1000

ENTRYPOINT ["/docker-entrypoint"]

CMD ["/usr/local/bin/start-server"]

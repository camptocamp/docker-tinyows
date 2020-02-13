FROM ubuntu:18.04 as builder
LABEL maintainer="info@camptocamp.com"


RUN apt-get update && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
        git curl ca-certificates ccache clang autoconf libxml2-dev libpq-dev postgis flex libfcgi-dev make \
        libfl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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


FROM ubuntu:18.04 as runner
LABEL maintainer="info@camptocamp.com"

# let's copy a few of the settings from /etc/init.d/apache2
ENV APACHE_CONFDIR=/etc/apache2 \
    APACHE_ENVVARS=/etc/apache2/envvars \
# and then a few more from $APACHE_CONFDIR/envvars itself
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_PID_FILE=/etc/apache2/apache2.pid \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    LANG=C

RUN apt-get update && \
    apt-get install --assume-yes --no-install-recommends \
        apache2 libapache2-mod-fcgid libpq5 libfcgi0ldbl libxml2 libfl2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod fcgid headers && \
    a2dismod -f auth_basic authn_file authn_core authz_host authz_user autoindex dir status && \
    rm /etc/apache2/mods-enabled/alias.conf && \
    mkdir --parent ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} && \
    find "$APACHE_CONFDIR" -type f -exec sed -ri ' \
       s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
       s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
       ' '{}' ';' && \
    sed -ri 's!LogFormat "(.*)" combined!LogFormat "%{us}T %{X-Request-Id}i \1" combined!g' /etc/apache2/apache2.conf && \
    echo 'ErrorLogFormat "%{X-Request-Id}i [%l] [pid %P] %M"' >> /etc/apache2/apache2.conf

EXPOSE 80

COPY --from=builder /usr/local/bin /usr/local/bin/
COPY --from=builder /usr/local/lib /usr/local/lib/
COPY --from=builder /usr/local/share/tinyows/ /usr/local/share/tinyows/
COPY runtime /

RUN adduser www-data root && \
    chmod -R g+rw ${APACHE_CONFDIR} ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} /var/lib/apache2/fcgid /var/log && \
    chgrp -R root ${APACHE_LOG_DIR} /var/lib/apache2/fcgid

ENV MAX_REQUESTS_PER_PROCESS=1000

ENTRYPOINT ["/docker-entrypoint"]

CMD ["/usr/local/bin/start-server"]

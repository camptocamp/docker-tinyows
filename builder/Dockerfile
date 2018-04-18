FROM ubuntu:17.10
MAINTAINER Camptocamp<info@camptocamp.com>

RUN apt-get -y update && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y git curl ccache clang autoconf libxml2-dev

RUN curl -L "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64" > /usr/bin/gosu && \
    chmod a+x /usr/bin/gosu

RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y libpq-dev postgis
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y flex libfcgi-dev make libfl-dev

COPY . /

ENTRYPOINT ["/entry.sh"]
CMD ["/build.sh"]

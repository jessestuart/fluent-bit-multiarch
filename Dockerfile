ARG target
FROM $target/debian as builder

ARG arch
ENV ARCH=$arch

COPY qemu-$ARCH-static* /usr/bin/

# Fluent Bit version
ENV FLB_MAJOR 0
ENV FLB_MINOR 13
ENV FLB_PATCH 0
ENV FLB_VERSION 0.13.0

ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/

COPY . /tmp/src/
RUN ls -alh /tmp/src

RUN rm -rf /tmp/src/build/*

RUN \
  apt update -yq && \
  apt install -yq \
    build-essential \
    cmake \
    libasl-dev \
    libssl1.0-dev \
    libsystemd-dev \
    make \
    unzip \
    wget

WORKDIR /tmp/src/build/
RUN ls -alh
RUN cmake -DFLB_DEBUG=On \
  -DFLB_TRACE=Off \
  -DFLB_JEMALLOC=On \
  -DFLB_BUFFERING=On \
  -DFLB_TLS=On \
  -DFLB_WITHOUT_SHARED_LIB=On \
  -DFLB_WITHOUT_EXAMPLES=On \
  -DFLB_HTTP_SERVER=On \
  -DFLB_OUT_KAFKA=On ..
RUN make
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY conf/fluent-bit.conf \
  conf/parsers.conf \
  conf/parsers_java.conf \
  conf/parsers_extra.conf \
  conf/parsers_openstack.conf \
  conf/parsers_cinder.conf \
  /fluent-bit/etc/

FROM $target/debian
LABEL maintainer="Jesse Stuart <hi@jessestuart.com>"
LABEL Description="Fluent Bit docker image" Vendor="Fluent Organization" Version="1.1"

RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install --no-install-recommends ca-certificates libssl1.0.2 -y \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoclean
COPY --from=builder /fluent-bit /fluent-bit

EXPOSE 2020

CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]

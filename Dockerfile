ARG target
FROM $target/debian:stretch as builder

COPY qemu-* /usr/bin/

# Fluent Bit version
ENV FLB_MAJOR 1
ENV FLB_MINOR 1
ENV FLB_PATCH 0
ENV FLB_VERSION 1.1.0

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      make \
      wget \
      unzip \
      libssl1.0-dev \
      libasl-dev \
      libsasl2-dev \
      pkg-config \
      libsystemd-dev \
      zlib1g-dev

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/
COPY . /tmp/src/
RUN rm -rf /tmp/src/build/*

WORKDIR /tmp/src/build/
RUN cmake -DFLB_DEBUG=Off \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_BUFFERING=On \
          -DFLB_TLS=On \
          -DFLB_SHARED_LIB=Off \
          -DFLB_EXAMPLES=Off \
          -DFLB_HTTP_SERVER=On \
          -DFLB_IN_SYSTEMD=On \
          -DFLB_OUT_KAFKA=On ..

RUN make -j $(getconf _NPROCESSORS_ONLN)
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY conf/fluent-bit.conf \
     conf/parsers.conf \
     conf/parsers_java.conf \
     conf/parsers_extra.conf \
     conf/parsers_openstack.conf \
     conf/parsers_cinder.conf \
     conf/plugins.conf \
     /fluent-bit/etc/

FROM $target/debian:stretch

ARG lib_target

COPY qemu-* /usr/bin/

LABEL maintainer="Jesse Stuart <hi@jessestuart.com>"
LABEL Description="Fluent Bit Docker image" Vendor="Fluent Organization" Version="1.1"

COPY --from=builder /usr/lib/${lib_target}-linux-gnu/*sasl* /usr/lib/${lib_target}-linux-gnu/
COPY --from=builder /usr/lib/${lib_target}-linux-gnu/libz* /usr/lib/${lib_target}-linux-gnu/
COPY --from=builder /lib/${lib_target}-linux-gnu/libz* /lib/${lib_target}-linux-gnu/
COPY --from=builder /usr/lib/${lib_target}-linux-gnu/libssl.so* /usr/lib/${lib_target}-linux-gnu/
COPY --from=builder /usr/lib/${lib_target}-linux-gnu/libcrypto.so* /usr/lib/${lib_target}-linux-gnu/
# These below are all needed for systemd
COPY --from=builder /lib/${lib_target}-linux-gnu/libsystemd* /lib/${lib_target}-linux-gnu/
COPY --from=builder /lib/${lib_target}-linux-gnu/libselinux.so* /lib/${lib_target}-linux-gnu/
COPY --from=builder /lib/${lib_target}-linux-gnu/liblzma.so* /lib/${lib_target}-linux-gnu/
COPY --from=builder /usr/lib/${lib_target}-linux-gnu/liblz4.so* /usr/lib/${lib_target}-linux-gnu/
COPY --from=builder /lib/${lib_target}-linux-gnu/libgcrypt.so* /lib/${lib_target}-linux-gnu/
COPY --from=builder /lib/${lib_target}-linux-gnu/libpcre.so* /lib/${lib_target}-linux-gnu/
COPY --from=builder /lib/${lib_target}-linux-gnu/libgpg-error.so* /lib/${lib_target}-linux-gnu/

COPY --from=builder /fluent-bit /fluent-bit

EXPOSE 2020

# # Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]

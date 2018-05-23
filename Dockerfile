ARG target
# Super simple base image built on `$target/debian`,
# with below dependencies pre-installed.
# FROM jessestuart/fluent-bit-builder as builder
FROM gcr.io/google-containers/debian-base-$target:0.3 as builder

COPY qemu-* /usr/bin/

ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/

COPY . /tmp/src/

RUN rm -rf /tmp/src/build/*

# These should already be installed by the base image.
RUN \
  apt update -yq && \
  apt install -yq \
    build-essential \
    cmake \
    # libasl-dev \
    libssl1.0-dev \
    libsystemd-dev \
    make \
    unzip \
    wget

WORKDIR /tmp/src/build/
RUN cmake \
  -DFLB_BUFFERING=On \
  -DFLB_DEBUG=Off \
  -DFLB_HTTP_SERVER=On \
  # "Jemalloc is an alternative memory allocator that can reduce fragmentation
  # (among others things) resulting in better performance."
  -DFLB_JEMALLOC=On \
  # Luajit v2.0.5 fails to compile on arm64.
  # (Experimental support is available in the v2.1.x-beta branch)
  -DFLB_LUAJIT=Off \
  -DFLB_METRICS=On \
  -DFLB_TLS=On \
  -DFLB_TRACE=Off \
  -DFLB_WITHOUT_EXAMPLES=On \
  -DFLB_WITHOUT_SHARED_LIB=On \
  # Kafka is the only "output" plugin disabled by default in CMakeLists.
  -DFLB_OUT_KAFKA=On ..

RUN make -j8
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY conf/fluent-bit.conf \
  conf/parsers.conf \
  conf/parsers_java.conf \
  conf/parsers_extra.conf \
  conf/parsers_openstack.conf \
  conf/parsers_cinder.conf \
  /fluent-bit/etc/

# =================
FROM gcr.io/google-containers/debian-base-$target:0.3
# =================

COPY qemu-* /usr/bin/

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

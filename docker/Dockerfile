FROM buildpack-deps:bookworm AS builder

ARG XMP_TOOLKIT_SDK_VERSION=2025.03
ARG EXPAT_VERSION=2.5.0

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV XMP_TOOLKIT_SDK_VERSION=${XMP_TOOLKIT_SDK_VERSION}
ENV EXPAT_VERSION=${EXPAT_VERSION}

RUN set -eux; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p /usr/src/XMP-Toolkit-SDK

RUN set -eux; \
    cd /usr/src/XMP-Toolkit-SDK && \
    curl -LO https://github.com/adobe/XMP-Toolkit-SDK/archive/refs/tags/v${XMP_TOOLKIT_SDK_VERSION}.tar.gz && \
    tar -xzf v${XMP_TOOLKIT_SDK_VERSION}.tar.gz --strip-components=1 && \
    cd third-party && \
    cd zlib && \
    curl -O https://zlib.net/zlib.tar.gz && \
    tar --strip-components=1 -xzf zlib.tar.gz &&\
    cd .. && \
    cd expat && \
    export TAG="R_$(echo "$EXPAT_VERSION" | sed 's/\./_/g')" && \
    export URL="https://github.com/libexpat/libexpat/releases/download/${TAG}/expat-${EXPAT_VERSION}.tar.gz" &&\
    curl -LO  "$URL" && \
    tar --strip-components=1  -xzf expat-${EXPAT_VERSION}.tar.gz

COPY ./docker/ProductConfig.cmake.patch /tmp/
COPY ./docker/ToolchainGCC.cmake.patch /tmp/

RUN set -eux; \
    cd /usr/src/XMP-Toolkit-SDK/build && \
    patch -p0 < /tmp/ProductConfig.cmake.patch && \
    patch -p0 < /tmp/ToolchainGCC.cmake.patch

RUN set -eux; \
    cd /usr/src/XMP-Toolkit-SDK/build && \
    make

FROM ruby:3.3

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    mkdir -p /usr/local/XMP-Toolkit-SDK

# for later testing
RUN set -eux; \
    cd /tmp && \
    curl -LO https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf

COPY ./spec/fixtures/sample.pdf /tmp/dummy.pdf
COPY --from=builder /usr/src/XMP-Toolkit-SDK/public /usr/local/XMP-Toolkit-SDK/public
COPY --from=builder /usr/src/XMP-Toolkit-SDK/XMPFilesPlugins/PDF_Handler /usr/local/XMP-Toolkit-SDK/XMPFilesPlugins/PDF_Handler

COPY ./pkg/xmp_toolkit_ruby-*.gem ./

RUN gem install  ./xmp_toolkit_ruby-*.gem -- --with-xmp-lib /usr/local/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug --with-xmp-include /usr/local/XMP-Toolkit-SDK/public/include

RUN ruby -r xmp_toolkit_ruby -e 'puts "XMP Toolkit Ruby version: #{XmpToolkitRuby::VERSION}"; puts XmpToolkitRuby.xmp_from_file("/tmp/dummy.pdf")["xmp_data"]'

# Create a non-root user
RUN set -eux; \
    groupadd -r appuser && useradd -r -g appuser -m -d /home/appuser appuser


RUN set -eux; \
    mkdir -p /workspace

# Set working directory
WORKDIR /workspace

RUN chown -R appuser:appuser /workspace

# Switch to non-root user
USER appuser

CMD ["/usr/bin/bash"]


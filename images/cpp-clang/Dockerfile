# syntax=docker/dockerfile:1
# C++ development environment - Clang only variant.
# Built off core. Use when you only need Clang (smaller image).

ARG CORE_IMAGE=ghcr.io/anticlimaxtic/cde:core

# =============================================================================
# Versions (override via bake.hcl)
# =============================================================================
ARG CLANG_VERSION=19
ARG CMAKE_VERSION=3.30.5
ARG BAZELISK_VERSION=1.20.0
ARG MESON_VERSION=1.5.1
ARG CONAN_VERSION=2.8.0

FROM ${CORE_IMAGE}

ARG CLANG_VERSION
ARG CMAKE_VERSION
ARG BAZELISK_VERSION
ARG MESON_VERSION
ARG CONAN_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ccache \
        ninja-build \
        software-properties-common \
        wget \
        curl \
        unzip \
        file \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Clang only
# ------------------------------------------------------------------------------
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null \
    && echo "deb http://apt.llvm.org/noble/ llvm-toolchain-noble-${CLANG_VERSION} main" > /etc/apt/sources.list.d/llvm-${CLANG_VERSION}.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        clang-${CLANG_VERSION} \
        clang++-${CLANG_VERSION} \
        lld-${CLANG_VERSION} \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100 \
    && rm -rf /var/lib/apt/lists/*

ENV CC=clang
ENV CXX=clang++

# ------------------------------------------------------------------------------
# Common tools (cmake, bazel, meson, conan, ccache)
# Same as cpp
# ------------------------------------------------------------------------------
RUN mkdir -p /opt/cmake \
    && if [ "$(uname -m)" = "x86_64" ]; then \
         CMAKE_ARCH=x86_64; \
       else \
         CMAKE_ARCH=aarch64; \
       fi \
    && curl -fsSL -o /tmp/cmake.tar.gz \
         "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz" \
    && tar -xzf /tmp/cmake.tar.gz -C /opt/cmake --strip-components=1 \
    && rm /tmp/cmake.tar.gz

ENV CMAKE_HOME=/opt/cmake
ENV PATH=/opt/cmake/bin:$PATH

RUN curl -fsSL -o /usr/local/bin/bazel \
      "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-amd64" \
    && chmod +x /usr/local/bin/bazel

ENV UV_TOOL_BIN_DIR=/root/.local/bin
ENV PATH="/root/.local/bin:${PATH}"

RUN uv tool install meson==${MESON_VERSION} \
    && uv tool install conan==${CONAN_VERSION}

RUN mkdir -p /ccache
ENV CCACHE_DIR=/ccache
ENV CCACHE_BASEDIR=/
ENV CC="ccache ${CC}"
ENV CXX="ccache ${CXX}"

RUN mkdir -p /etc/profile.d \
    && cat > /etc/profile.d/70-cpp.sh << 'EOF'
export CCACHE_DIR=/ccache
export CCACHE_BASEDIR=/

export CC=ccache clang
export CXX=ccache clang++

export PATH=/opt/cmake/bin:/root/.local/bin:$PATH

# See cpp/Dockerfile for full distributed build hooks (icecream, FASTbuild, ccache notes)
EOF

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

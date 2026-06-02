# syntax=docker/dockerfile:1
# C++ development environment built on core.
# Provides a full-featured C++ toolchain with multiple compiler options.
#
# This image (cpp) includes both Clang and GCC, with Clang as the default (CC/CXX).
# Use cpp-clang or cpp-gcc for single-compiler minimal variants.
#
# Tools installed:
# - ninja, cmake (/opt/cmake), bazel (via bazelisk), meson, conan2 (via uv tool)
# - ccache with /ccache cache directory (mount as volume for persistence)
# - Expandable: add new compiler sections below following the same pattern.
#
# Future distributed build hooks:
# - icecream: install icecc package, then use CC="icecc clang" (or configure icecc)
# - FASTbuild: similar wrapper configuration possible.
# See /etc/profile.d/70-cpp.sh for env and comments.

ARG CORE_IMAGE=ghcr.io/anticlimaxtic/cde:core

# =============================================================================
# Versions - set centrally in docker-bake.hcl (these are defaults/fallbacks)
# =============================================================================
ARG CLANG_VERSION=19
ARG GCC_VERSION=14
ARG CMAKE_VERSION=3.30.5
ARG BAZELISK_VERSION=1.20.0
ARG MESON_VERSION=1.5.1
ARG CONAN_VERSION=2.8.0

FROM ${CORE_IMAGE}

# Re-declare for use after FROM
ARG CLANG_VERSION
ARG GCC_VERSION
ARG CMAKE_VERSION
ARG BAZELISK_VERSION
ARG MESON_VERSION
ARG CONAN_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# Install base build deps and ccache
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
# Clang (latest via LLVM apt repo for the requested major version)
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

# ------------------------------------------------------------------------------
# GCC (via test ppa for newer versions)
# ------------------------------------------------------------------------------
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc-${GCC_VERSION} \
        g++-${GCC_VERSION} \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 100 \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Set Clang as default for this image (cpp variant has both, prefers clang)
# ------------------------------------------------------------------------------
RUN update-alternatives --set clang /usr/bin/clang-${CLANG_VERSION} \
    && update-alternatives --set clang++ /usr/bin/clang++-${CLANG_VERSION}

ENV CC=clang
ENV CXX=clang++

# ------------------------------------------------------------------------------
# CMake (isolated in /opt/cmake)
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

# ------------------------------------------------------------------------------
# Bazel via bazelisk (latest stable via version arg)
# ------------------------------------------------------------------------------
RUN curl -fsSL -o /usr/local/bin/bazel \
      "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-amd64" \
    && chmod +x /usr/local/bin/bazel

# ------------------------------------------------------------------------------
# Meson and Conan via uv (from core)
# ------------------------------------------------------------------------------
ENV UV_TOOL_BIN_DIR=/root/.local/bin
ENV PATH="/root/.local/bin:${PATH}"

RUN uv tool install meson==${MESON_VERSION} \
    && uv tool install conan==${CONAN_VERSION}

# ------------------------------------------------------------------------------
# ccache setup (cache dir for volume mount)
# ------------------------------------------------------------------------------
RUN mkdir -p /ccache
ENV CCACHE_DIR=/ccache
ENV CCACHE_BASEDIR=/
# Wrap compilers with ccache (common pattern)
ENV CC="ccache ${CC}"
ENV CXX="ccache ${CXX}"

# ------------------------------------------------------------------------------
# Shell environment and hooks for distributed builds
# ------------------------------------------------------------------------------
RUN mkdir -p /etc/profile.d \
    && cat > /etc/profile.d/70-cpp.sh << 'EOF'
# C++ environment
export CCACHE_DIR=/ccache
export CCACHE_BASEDIR=/

# Default to clang (overridden in pure gcc variant)
export CC=ccache clang
export CXX=ccache clang++

export PATH=/opt/cmake/bin:/root/.local/bin:$PATH

# ------------------------------------------------------------------------------
# Hooks / plans for distributed build systems (icecream / FASTbuild)
# ------------------------------------------------------------------------------
# Icecream (icecc):
#   apt-get install -y icecc
#   Then: export CC="icecc clang" ; export CXX="icecc clang++"
#   Or configure icecc to automatically wrap.
#   Start scheduler/daemon as needed in your compose or entrypoint.
#
# FASTbuild:
#   Download fbuild binary, set environment to use it as wrapper.
#   Example: export CC="fbuild clang" (with appropriate .bff config)
#
# ccache is already enabled above. Combine with distributed as needed
# (e.g. icecream can work with ccache in some configs).
#
# To persist ccache across runs: -v my-ccache:/ccache
EOF

# ------------------------------------------------------------------------------
# Clean up
# ------------------------------------------------------------------------------
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

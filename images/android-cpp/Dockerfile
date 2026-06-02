# syntax=docker/dockerfile:1
# Android C++ / Native development environment.
# Built on top of the cpp image (provides clang/gcc, cmake, ninja, bazel, meson, conan, ccache).
# Adds Java + Android SDK + NDK for native Android development (JNI, games, performance libs, etc.).
#
# Tools in /opt for isolation and volume composability:
#   /opt/java, /opt/android (includes ndk subdir), /opt/cmake (from base cpp)

ARG BASE_IMAGE=ghcr.io/anticlimaxtic/cde:cpp

# =============================================================================
# Android-specific versions (also set in docker-bake.hcl)
# =============================================================================
ARG JAVA_VERSION=21.0.4
ARG JAVA_BUILD=7
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708
ARG ANDROID_PLATFORM=35
ARG ANDROID_BUILD_TOOLS=35.0.0
ARG NDK_VERSION=27.0.12077973

FROM ${BASE_IMAGE}

# Re-declare Android ARGs
ARG JAVA_VERSION
ARG JAVA_BUILD
ARG ANDROID_CMDLINE_TOOLS_VERSION
ARG ANDROID_PLATFORM
ARG ANDROID_BUILD_TOOLS
ARG NDK_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# Base deps for Android SDK download
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        unzip \
        wget \
        file \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Java (for Gradle / Android builds)
# ------------------------------------------------------------------------------
ARG TARGETARCH
RUN mkdir -p /opt/java \
    && if [ "${TARGETARCH}" = "amd64" ]; then \
         JAVA_ARCH=x64; \
       else \
         JAVA_ARCH=aarch64; \
       fi \
    && JAVA_TAR=OpenJDK21U-jdk_${JAVA_ARCH}_linux_hotspot_${JAVA_VERSION}_${JAVA_BUILD}.tar.gz \
    && curl -fsSL -o /tmp/java.tar.gz \
         "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-${JAVA_VERSION}%2B${JAVA_BUILD}/${JAVA_TAR}" \
    && tar -xzf /tmp/java.tar.gz -C /opt/java --strip-components=1 \
    && rm /tmp/java.tar.gz \
    && /opt/java/bin/java -version

ENV JAVA_HOME=/opt/java
ENV PATH=/opt/java/bin:$PATH

# ------------------------------------------------------------------------------
# Android SDK + NDK
# ------------------------------------------------------------------------------
ENV ANDROID_HOME=/opt/android
ENV ANDROID_NDK_HOME=/opt/android/ndk/${NDK_VERSION}
ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_NDK_HOME}:$PATH

RUN mkdir -p /opt/android/cmdline-tools \
    && curl -fsSL -o /tmp/cmdline-tools.zip \
         "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
    && unzip -q /tmp/cmdline-tools.zip -d /opt/android/cmdline-tools \
    && mv /opt/android/cmdline-tools/cmdline-tools /opt/android/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# Licenses + core SDK components + NDK
RUN yes | /opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android --licenses \
    && /opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android \
        "platform-tools" \
        "platforms;android-${ANDROID_PLATFORM}" \
        "build-tools;${ANDROID_BUILD_TOOLS}" \
        "ndk;${NDK_VERSION}"

# ------------------------------------------------------------------------------
# Extend profile from cpp base with Android env
# ------------------------------------------------------------------------------
RUN cat >> /etc/profile.d/60-android.sh << EOF
export JAVA_HOME=/opt/java
export PATH=/opt/java/bin:$PATH

export ANDROID_HOME=/opt/android
export ANDROID_NDK_HOME=/opt/android/ndk/${NDK_VERSION}
export PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_NDK_HOME}:$PATH
EOF

# Note: cmake, ninja, etc. come from the cpp base image.
# ccache is also inherited and will wrap the default CC/CXX (clang from cpp).

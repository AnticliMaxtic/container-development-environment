# syntax=docker/dockerfile:1
# Pure Java/Kotlin Android image (lighter variant).
# Built directly on core.
# Provides JDK + Android SDK for standard Android app development (Kotlin/Java/Gradle builds).
# No NDK or heavy C++ toolchain by default (use android-cpp for native C++ work).
#
# Tools isolated under /opt for volume mount composability:
#   /opt/java   - OpenJDK (latest LTS)
#   /opt/android - Android SDK (cmdline-tools, platform-tools, platforms, build-tools)

ARG CORE_IMAGE=ghcr.io/anticlimaxtic/cde:core

# =============================================================================
# Versions - pulled to top / set in docker-bake.hcl (these are defaults)
# =============================================================================
ARG JAVA_VERSION=21.0.4
ARG JAVA_BUILD=7
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708
ARG ANDROID_PLATFORM=35
ARG ANDROID_BUILD_TOOLS=35.0.0

FROM ${CORE_IMAGE}

# Re-declare ARGs after FROM
ARG JAVA_VERSION
ARG JAVA_BUILD
ARG ANDROID_CMDLINE_TOOLS_VERSION
ARG ANDROID_PLATFORM
ARG ANDROID_BUILD_TOOLS
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# Base tools for downloads
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        unzip \
        wget \
        file \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Java - Latest open-source LTS (Eclipse Temurin)
# ------------------------------------------------------------------------------
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
# Android SDK (Command Line Tools + essentials)
# ------------------------------------------------------------------------------
ENV ANDROID_HOME=/opt/android
ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:$PATH

RUN mkdir -p /opt/android/cmdline-tools \
    && curl -fsSL -o /tmp/cmdline-tools.zip \
         "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
    && unzip -q /tmp/cmdline-tools.zip -d /opt/android/cmdline-tools \
    && mv /opt/android/cmdline-tools/cmdline-tools /opt/android/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# Accept licenses and install core SDK components (no NDK here - see android-cpp)
RUN yes | /opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android --licenses \
    && /opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android \
        "platform-tools" \
        "platforms;android-${ANDROID_PLATFORM}" \
        "build-tools;${ANDROID_BUILD_TOOLS}"

# ------------------------------------------------------------------------------
# Environment (profile.d)
# ------------------------------------------------------------------------------
RUN mkdir -p /etc/profile.d \
    && cat > /etc/profile.d/60-android.sh << 'EOF'
export JAVA_HOME=/opt/java
export PATH=/opt/java/bin:$PATH

export ANDROID_HOME=/opt/android
export PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:$PATH
EOF

# Clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

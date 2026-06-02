// Docker Bake definition for composable CDE images
// Usage:
//   docker buildx bake core
//   docker buildx bake --set core.tags=ghcr.io/anticlimaxtic/cde:core-0.0.1-abc1234 core

// =============================================================================
// C++ / Android image family version defaults
// Latest LTS / recommended stable versions. These are the single source of truth.
// Set/override here; they flow to all Dockerfiles via build args.
// =============================================================================

// C++ compilers
variable "CLANG_VERSION" {
  default = "19"
}
variable "GCC_VERSION" {
  default = "14"
}

// Common C++ build tools
variable "CMAKE_VERSION" {
  default = "3.30.5"
}
variable "BAZELISK_VERSION" {
  default = "1.20.0"
}
variable "MESON_VERSION" {
  default = "1.5.1"
}
variable "CONAN_VERSION" {
  default = "2.8.0"
}

// Android-specific (for android-cpp)
variable "JAVA_VERSION" {
  default = "21.0.4"
}
variable "JAVA_BUILD" {
  default = "7"
}
variable "ANDROID_CMDLINE_TOOLS_VERSION" {
  default = "11076708"
}
variable "ANDROID_PLATFORM" {
  default = "35"
}
variable "ANDROID_BUILD_TOOLS" {
  default = "35.0.0"
}
variable "NDK_VERSION" {
  default = "27.0.12077973"
}

variable "CPP_BASE_IMAGE" {
  default = "ghcr.io/anticlimaxtic/cde:cpp"
}

variable "PLATFORMS" {
  default = ["linux/amd64", "linux/arm64"]
}

group "default" {
  targets = ["core", "cpp", "android"]
}

group "cpp" {
  targets = ["cpp", "cpp-clang", "cpp-gcc"]
}

group "android" {
  targets = ["android", "android-cpp"]
}

// Core minimal development environment
// Base for all other CDE variants
target "core" {
  context    = "images/core"
  dockerfile = "Dockerfile"
  platforms  = PLATFORMS
  tags = [
    "ghcr.io/anticlimaxtic/cde:core"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

// =============================================================================
// C++ images (built on core)
// =============================================================================

// cpp: both clang + gcc (clang as default CC/CXX) + full toolset
target "cpp" {
  context    = "images/cpp"
  dockerfile = "Dockerfile"
  platforms  = PLATFORMS
  args = {
    CLANG_VERSION   = CLANG_VERSION
    GCC_VERSION     = GCC_VERSION
    CMAKE_VERSION   = CMAKE_VERSION
    BAZELISK_VERSION = BAZELISK_VERSION
    MESON_VERSION   = MESON_VERSION
    CONAN_VERSION   = CONAN_VERSION
  }
  tags = [
    "ghcr.io/anticlimaxtic/cde:cpp"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

// cpp-clang: clang only + full toolset (minimal for clang users)
target "cpp-clang" {
  context    = "images/cpp-clang"
  dockerfile = "Dockerfile"
  platforms  = PLATFORMS
  args = {
    CLANG_VERSION   = CLANG_VERSION
    CMAKE_VERSION   = CMAKE_VERSION
    BAZELISK_VERSION = BAZELISK_VERSION
    MESON_VERSION   = MESON_VERSION
    CONAN_VERSION   = CONAN_VERSION
  }
  tags = [
    "ghcr.io/anticlimaxtic/cde:cpp-clang"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

// cpp-gcc: gcc only + full toolset
target "cpp-gcc" {
  context    = "images/cpp-gcc"
  dockerfile = "Dockerfile"
  platforms  = PLATFORMS
  args = {
    GCC_VERSION     = GCC_VERSION
    CMAKE_VERSION   = CMAKE_VERSION
    BAZELISK_VERSION = BAZELISK_VERSION
    MESON_VERSION   = MESON_VERSION
    CONAN_VERSION   = CONAN_VERSION
  }
  tags = [
    "ghcr.io/anticlimaxtic/cde:cpp-gcc"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

// =============================================================================
// android: lighter pure Java/Kotlin Android image (built on core)
// No NDK or heavy C++ toolchain. For standard Android app builds.
// =============================================================================
target "android" {
  context    = "images/android"
  dockerfile = "Dockerfile"
  platforms  = PLATFORMS
  args = {
    JAVA_VERSION                = JAVA_VERSION
    JAVA_BUILD                  = JAVA_BUILD
    ANDROID_CMDLINE_TOOLS_VERSION = ANDROID_CMDLINE_TOOLS_VERSION
    ANDROID_PLATFORM            = ANDROID_PLATFORM
    ANDROID_BUILD_TOOLS         = ANDROID_BUILD_TOOLS
  }
  tags = [
    "ghcr.io/anticlimaxtic/cde:android"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

// =============================================================================
// android-cpp: Android native development (SDK + NDK) on top of cpp
// =============================================================================
target "android-cpp" {
  context    = "images/android-cpp"
  dockerfile = "Dockerfile"
  platforms  = PLATFORMS
  args = {
    BASE_IMAGE                  = CPP_BASE_IMAGE
    JAVA_VERSION                = JAVA_VERSION
    JAVA_BUILD                  = JAVA_BUILD
    ANDROID_CMDLINE_TOOLS_VERSION = ANDROID_CMDLINE_TOOLS_VERSION
    ANDROID_PLATFORM            = ANDROID_PLATFORM
    ANDROID_BUILD_TOOLS         = ANDROID_BUILD_TOOLS
    NDK_VERSION                 = NDK_VERSION
  }
  tags = [
    "ghcr.io/anticlimaxtic/cde:android-cpp"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

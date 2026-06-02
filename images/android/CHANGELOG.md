# Changelog

All notable changes to the `android` image will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-06-02

### Added
- `android` (pure Java/Kotlin): lighter image with OpenJDK 21 + Android SDK (no NDK)
- Tools in `/opt/java` and `/opt/android` for isolation and volume composability
- Builds directly on `core`
- Intended for standard Android app development (Kotlin/Java/Gradle)
- See `android-cpp` for the native C++ / NDK variant (built on the `cpp` family)

# Changelog

All notable changes to the `cpp` C++ development images will be documented in this file.

## [0.0.1] - 2026-06-02

### Added
- `cpp`: Both Clang (default) and GCC + full C++ toolset (ninja, cmake, bazel, meson, conan2, ccache)
- `cpp-clang`: Clang-only variant
- `cpp-gcc`: GCC-only variant
- All tools isolated where possible; ccache cache dir at /ccache
- Expandable compiler support and hooks for icecream/FASTbuild
- Built on top of `core`

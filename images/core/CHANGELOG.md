# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-05-29

### Added
- Initial `core` image: minimal Ubuntu 24.04 base with essential CLI tools (git, curl, build-essential, vim)
- Astral `uv` (Python package manager) installed system-wide
- `nvm` + Node LTS with shell-agnostic activation via `/etc/profile.d`
- `tmux` and `zsh` with explicit completions (`compinit`) and `uv` completion
- Persistent shell history design for both bash/zsh under `/root/.history/` (volume-mount friendly)
- Full OCI labels and multi-arch (`linux/amd64`, `linux/arm64`) support via Docker Bake
- Release Please + GitHub Actions CI/CD with immutable + shadowing semantic tags
- Conventional Commits enforcement (husky + commitlint)

### Notes
- Root-only execution for now (dedicated dev user planned for later)
- Designed as the composable foundation for higher-level CDE variant images

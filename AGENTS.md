# AGENTS.md

This file provides instructions for AI coding agents (Grok, Cursor, Claude, etc.) working in this repository.

## Project Overview

This repository builds **composable containerized development environments (CDE)** published under the image name `anticlimaxtic/cde`.

- **Primary registry**: `ghcr.io/anticlimaxtic/cde` (GitHub Container Registry)
- **Core image**: `ghcr.io/anticlimaxtic/cde:core` — a minimal Ubuntu-based base image
- **Philosophy**: Start extremely minimal (`core`). All other images should build on top of `core` when possible.

## Core Design Principles

- **Composability first**: Every new image should be designed to layer on `core` or other existing images.
- **Minimal core**: Only add tools to `core` if they are universally required. Prefer adding tools in higher-level variant images.
- **Reproducible + cache-friendly**: Favor explicit versions and clean layer ordering.
- **Multi-arch support**: We ship both `linux/amd64` and `linux/arm64`.

## Build System

**We use Docker Buildx Bake** (`docker-bake.hcl`), not raw `docker build`.

- All image definitions live in `docker-bake.hcl`.
- New images should be added as named targets in the bake file.
- Use `docker buildx bake <target>` for local builds.
- The CI pipeline uses `docker/bake-action` and heavily overrides targets via `set:`.

**Do not** introduce new images using standalone Dockerfiles + shell scripts unless there is a very strong reason. Prefer extending the bake model.

## Tagging & Versioning Strategy (Critical)

We use a strict semantic versioning + shadowing tag system:

Given version `0.0.1` and short commit `abc1234`:

| Tag                              | Mutable?   | Notes |
|----------------------------------|------------|-------|
| `core-0.0.1-abc1234`             | **No**     | Immutable. Always contains the full semver + sha. |
| `core-0.0.1`                     | Yes        | Latest patch in the 0.0.1 series |
| `core-0.0`                       | Yes        | Latest in the 0.0 minor series |
| `core-0`                         | Yes        | Latest in major version 0 |
| `core`                           | Yes        | Latest overall (use with caution) |

**Rules for agents**:
- Never suggest overwriting an immutable tag.
- The `VERSION` file inside each image package directory (e.g. `images/core/VERSION`) is the source of truth for that component's semver. Release Please updates it via `extra-files` during the Release PR.
- When adding new images, they must follow the exact same tagging pattern (the CI workflow is generic).

## Adding a New Composable Image

1. Create a directory: `images/<name>/Dockerfile`
2. Add a target in `docker-bake.hcl`:
   ```hcl
   target "full" {
     context    = "images/full"
     dockerfile = "Dockerfile"
     platforms  = ["linux/amd64", "linux/arm64"]
     tags       = ["ghcr.io/anticlimaxtic/cde:full"]
     # Prefer depending on the published core image when possible
   }
   ```
3. Add a new entry under `packages` in `.github/release-please-config.json` so the new image gets its own independent versioning and Release PR.
4. Update this `AGENTS.md` and `README.md` with usage notes.
5. The `publish.yml` workflow can be manually dispatched for any target.

## CI / Release Pipeline Rules

We use **Release Please** (manifest mode) for automated semantic versioning.

### Key Workflows

| Workflow                  | Purpose                                      | Trigger                     |
|---------------------------|----------------------------------------------|-----------------------------|
| `ci.yml`                  | PR validation + manual test builds           | PRs + `workflow_dispatch`   |
| `release-please.yml`      | Maintains Release PR(s) with version + changelog | Push to `main`         |
| `publish.yml`             | Builds + publishes with full custom tagging  | `release` event + manual    |

### Important Behavior

- **Pull Requests**: Always **single-arch** (`linux/amd64`) + `load: true`. Fast validation only. Never pushes.
- **Release Please**: On every push to `main`, it updates a Release PR for the `core` component (and future components). Uses Conventional Commits to determine the next semver.
- **Publishing**: Only occurs in `publish.yml`. It generates the full tag set (`core-X.Y.Z-<sha>`, `core-X.Y.Z`, `core-X.Y`, `core-X`, `core`) and pushes multi-arch.
- Release Please is configured to update the per-package `VERSION` file (e.g. `images/core/VERSION`) automatically as part of the Release PR (see release-please-config.json extra-files).

**Never** re-introduce automatic publishing logic on push to `main` inside `ci.yml`. Versioning and publishing are deliberately separated.

## Local Development Commands

```bash
# Full multi-arch build (default)
docker buildx bake core

# Fast single-arch build (recommended for iteration)
docker buildx bake --set core.platforms=linux/amd64 core

# Build a specific target
docker buildx bake full

# Override tags for local testing
docker buildx bake --set core.tags=localhost:5000/cde:core-test core
```

## Versioning Process (Release Please)

1. Make changes and use Conventional Commits (`feat:`, `fix:`, `BREAKING CHANGE:` etc.).
2. On push to `main`, Release Please will open or update a **Release PR** showing the pending version bump and changelog.
3. Review and merge the Release PR when ready.
4. Release Please creates the git tag (e.g. `core-0.0.2`) and GitHub Release.
5. The `publish.yml` workflow automatically builds and publishes the Docker image with the full tagging strategy (immutable + shadowing tags).

Release Please also updates the per-package `VERSION` file (e.g. `images/core/VERSION`) automatically (via `extra-files` in the release-please-config).

For emergency/hotfix publishes, you can use manual dispatch on `publish.yml` with an explicit version.

## Things to Be Careful About

- **Immutable tags**: Once published, `core-X.Y.Z-<sha>` tags must never change.
- **Platform handling**: Respect the validation vs publish platform split in CI.
- **Bake over build**: Prefer extending `docker-bake.hcl` rather than adding raw `docker buildx build` commands.
- **Minimalism**: Push back on adding tools to `core` unless they are truly foundational.
- **OCI labels**: Keep the standard labels (`org.opencontainers.image.*`) consistent across images.

## General Guidelines

- Keep changes small and focused.
- When in doubt about architecture or tagging, ask before implementing.
- Update `AGENTS.md` when project conventions change.
- Prefer clear, boring solutions over clever ones.

## Shell & Dotfiles Philosophy (Core Image)

When modifying `images/core/Dockerfile`:

- We are intentionally staying **root-only** for now. A dedicated `dev` user will be added much later.
- Install `tmux` and `zsh` (zsh is available but not forced as default shell yet).
- Prefer **shell-agnostic** configuration:
  - Use `/etc/profile.d/` for environment variables and PATH
  - Avoid dumping configuration into `/etc/bash.bashrc` when possible
- **Completions**: Always explicitly enable zsh completions (`compinit`) and generate tool-specific completions (e.g. for `uv`) when the base packages do not enable them by default.

- **Shell history**: Both bash and zsh are configured to write their history files under `/root/.history/<shell>/` (e.g. `bash_history` and `zsh_history`). This design allows the entire `/root/.history` directory to be mounted as a Docker volume for persistent command history across container rebuilds and runs. See the "Persistent shell history" section in `images/core/Dockerfile`.

These preferences are recorded in global memory and should be followed for consistency in the CDE images.

## Conventional Commits

This project strictly enforces Conventional Commits.

- **CI enforcement**: `.github/workflows/commitlint.yml` (runs on every PR)
- **Local enforcement**: Husky + commitlint (use `yarn sync` to install deps + set up hooks)

See:
- `.commitlintrc.json`
- `package.json` (dev dependencies)
- `.yarnrc.yml`
- `.husky/commit-msg`

**Note**: This repo uses Yarn Berry (via Corepack). Run `corepack enable && yarn sync` for local development (this installs deps + sets up git hooks).

When making changes, always use proper Conventional Commit messages. This directly affects the quality of Release Please version bumps and changelogs.

---

This file should be updated as the project evolves (especially when new images or significant build/CI patterns are introduced).
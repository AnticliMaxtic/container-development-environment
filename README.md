# container-development-environment

Composable containerized development environments (CDE) published as `anticlimaxtic/cde`.

## Free Container Registry

Images are published to **GitHub Container Registry** (free for public packages):

```
ghcr.io/anticlimaxtic/cde:core
ghcr.io/anticlimaxtic/cde:core-0.0.1
ghcr.io/anticlimaxtic/cde:core-0.0.1-<commit-sha>
```

**Why ghcr.io?**
- Completely free with no pull rate limits (unlike Docker Hub)
- Native GitHub Actions integration
- Supports public packages without authentication for pulls
- Excellent multi-arch and OCI support

Docker Hub (`anticlimaxtic/cde`) can be added later as a secondary mirror if needed.

## Current Images

| Image | Description | Base |
|-------|-------------|------|
| `ghcr.io/anticlimaxtic/cde:core` | Minimal core development environment | `ubuntu:24.04` + git + vim + uv + nvm (no default Node) |

## Tagging Strategy (Semantic Versioning)

Every build produces **one immutable tag** and **several moving "shadow" tags**:

Given version `0.0.1` and commit `abc1234`:

| Tag | Mutable? | Purpose |
|-----|----------|---------|
| `core-0.0.1-abc1234` | **No** (immutable) | Exact reproducible build |
| `core-0.0.1` | Yes | Latest patch of 0.0.1 |
| `core-0.0` | Yes | Latest minor of 0.0 |
| `core-0` | Yes | Latest major 0 release |
| `core` | Yes | Latest overall (bleeding edge) |

**Rule**: The full `core-<semver>-<sha>` tag is **never overwritten**. All other tags move forward when a new build with the same version prefix is published.

## Usage

### Pull the latest core image

```bash
docker pull ghcr.io/anticlimaxtic/cde:core
```

### Use a specific immutable version (recommended for CI/reproducibility)

```bash
docker pull ghcr.io/anticlimaxtic/cde:core-0.0.1-abc1234
```

### Run interactively

```bash
docker run -it --rm ghcr.io/anticlimaxtic/cde:core bash
```

## Local Development

### Prerequisites

- Docker with Buildx (`docker buildx version`)
- (Optional) `docker bake` support

### Build the core image locally

```bash
# Using bake (recommended) — builds both amd64 + arm64 by default
docker buildx bake core

# Single-arch (much faster locally)
docker buildx bake --set core.platforms=linux/amd64 core

# Or using docker build directly
docker build -t cde:core -f images/core/Dockerfile images/core
```

> **Note**: On Docker Desktop (Mac/Windows), QEMU emulation for the non-native architecture is usually enabled automatically. On Linux hosts you may need `docker run --privileged --rm tonistiigi/binfmt --install arm64`.

### Override tags during local bake

```bash
docker buildx bake --set core.tags=localhost:5000/cde:core-test core
```

## CI / Release Process

This project uses **Release Please** (in manifest mode) for automated semantic versioning combined with dedicated publishing workflows.

### Workflow Overview

| Workflow             | Purpose                                      | Trigger                     |
|----------------------|----------------------------------------------|-----------------------------|
| `ci.yml`             | Validation builds + manual testing           | Pull requests + manual      |
| `release-please.yml` | Creates/updates Release PR with version bump + changelog | Push to `main`         |
| `publish.yml`        | Builds and publishes images with full tagging strategy | `release` created + manual |

### How Releasing Works

1. Make changes using **Conventional Commits** (`feat:`, `fix:`, `BREAKING CHANGE:`, etc.).
2. Push to `main` → Release Please opens or updates a **Release PR** showing the next version and generated changelog.
3. Review the Release PR (you can edit the notes if needed) and merge it.
4. Release Please creates a git tag (e.g. `core-0.0.2`) and a GitHub Release.
5. The `publish.yml` workflow automatically triggers and publishes the Docker image with your full tagging strategy:
   - Immutable: `core-0.0.2-<short-sha>`
   - Moving: `core-0.0.2`, `core-0.0`, `core-0`, `core`

### Validation vs Publishing Builds

- **PRs and manual dry-runs** (`ci.yml`): Single-arch (`linux/amd64`) only, using `load: true`. Fast feedback.
- **Actual publishes** (`publish.yml`): Multi-arch (`linux/amd64` + `linux/arm64`).

This split exists because Docker cannot load multi-platform images locally.

### Manual / Emergency Publish

Use **Actions → Publish Images → Run workflow** and supply a `version` if needed.

### Multi-Architecture Builds

See the note above about validation vs publish builds. You can force single-arch locally:

```bash
docker buildx bake --set core.platforms=linux/amd64 core
```

## Project Structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # PR validation + manual test builds
│   │   ├── commitlint.yml      # Enforces Conventional Commits
│   │   ├── release-please.yml  # Manages Release PRs
│   │   └── publish.yml         # Builds + publishes images on release
│   ├── release-please-config.json
│   ├── .release-please-manifest.json
│   └── pull_request_template.md
├── .husky/                     # Git hooks (commit-msg for conventional commits)
├── .yarn/                      # Yarn Berry (releases, plugins, cache metadata)
├── .yarnrc.yml                 # Yarn Berry configuration
├── .commitlintrc.json          # Commitlint configuration
├── package.json                # Dev tooling only (husky + commitlint)
└── yarn.lock                   # Yarn Berry lockfile (commit this)
├── docker-bake.hcl             # Multi-target build definitions
├── images/
│   └── core/
│       ├── Dockerfile
│       ├── VERSION             # Per-component semver (updated by Release Please via extra-files)
│       └── CHANGELOG.md
├── AGENTS.md                   # Instructions for AI agents
├── .dockerignore
├── LICENSE
└── README.md
```

## Adding New Composable Images

Future images (e.g. `full`, `rust`, `node`) should:

1. Live in `images/<name>/Dockerfile`
2. Be added as a target in `docker-bake.hcl`
3. Inherit from `ghcr.io/anticlimaxtic/cde:core` when possible
4. Follow the same tagging rules (the CI is generic over bake targets)

Example future target in `docker-bake.hcl`:

```hcl
target "full" {
  context    = "images/full"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  tags = ["ghcr.io/anticlimaxtic/cde:full"]
  inherits = ["core"]   # or just depend on the published core image
}
```

## Contributing

### Commit Messages

This project **enforces Conventional Commits** using commitlint. All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

This is required because we use **Release Please** to automate semantic versioning and changelogs.

**Allowed types** (and their effect on versioning):

| Type      | Description                        | Version Bump |
|-----------|------------------------------------|--------------|
| `feat`    | A new feature                      | Minor        |
| `fix`     | A bug fix                          | Patch        |
| `docs`    | Documentation only changes         | None         |
| `refactor`| Code change that is not a fix/feat | None         |
| `perf`    | Performance improvement            | None         |
| `test`    | Adding or fixing tests             | None         |
| `build`   | Build system / dependency changes  | None         |
| `ci`      | CI configuration changes           | None         |
| `chore`   | Other maintenance tasks            | None         |
| `revert`  | Revert a previous commit           | None         |

**Examples:**

```bash
feat: add arm64 support to publish workflow
fix: handle missing VERSION file during manual publish
docs: clarify Release Please workflow in README
chore: update commitlint rules
```

Breaking changes should be indicated with `!` after the type or a `BREAKING CHANGE:` footer:

```bash
feat!: change default image tag format
```

### Local Validation & Git Hooks

This project uses **Yarn Berry** (v4) + Corepack + Husky for local Conventional Commit enforcement.

#### First-time setup

```bash
# Enable Corepack (comes with modern Node.js)
corepack enable

# Install dependencies + set up git hooks (recommended)
yarn sync
```

After this, `git commit` will automatically validate your commit message using commitlint.

#### Subsequent work

Use `yarn sync` whenever you want to ensure dependencies and hooks are in sync (e.g. after pulling changes, switching branches, or if hooks stop working).

`yarn install` will still work (via the `prepare` hook), but `yarn sync` is the explicit command for this project.

**Manual validation** (without local setup):

```bash
npx commitlint --from HEAD~1 --to HEAD --config .commitlintrc.json
```

### Pull Requests

- Use the PR template.
- Keep commits focused and well-described.
- Rebase or squash as needed before merging so the history stays clean for Release Please.

## License

MIT — see [LICENSE](LICENSE).

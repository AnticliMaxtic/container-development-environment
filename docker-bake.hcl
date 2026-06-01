// Docker Bake definition for composable CDE images
// Usage:
//   docker buildx bake core
//   docker buildx bake --set core.tags=ghcr.io/anticlimaxtic/cde:core-0.0.1-abc1234 core

group "default" {
  targets = ["core"]
}

// Core minimal development environment
// Base for all other CDE variants
target "core" {
  context    = "images/core"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  tags = [
    "ghcr.io/anticlimaxtic/cde:core"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/AnticliMaxtic/container-development-environment"
  }
}

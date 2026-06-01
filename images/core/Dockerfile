# syntax=docker/dockerfile:1
FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/AnticliMaxtic/container-development-environment
LABEL org.opencontainers.image.description="AnticliMaxtic Core Development Environment (CDE)"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="cde:core"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Locale setup (prevents "locale not supported" and encoding headaches in containers)
# ------------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------------------------
# Essential CLI tools for headless/container development
# ------------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        wget \
        git \
        ca-certificates \
        gnupg \
        vim \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Astral uv (modern Python package manager)
# ------------------------------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && mv /root/.local/bin/uvx /usr/local/bin/uvx

# ------------------------------------------------------------------------------
# nvm (Node Version Manager)
# nvm is provided so projects can easily install and manage their own Node
# version(s) via `.nvmrc` + `nvm install` / `nvm use`. No Node version is
# pre-installed in core — this keeps the image much smaller.
# ------------------------------------------------------------------------------
ENV NVM_DIR=/usr/local/nvm

RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && rm -rf \
        $NVM_DIR/.git \
        $NVM_DIR/test \
        $NVM_DIR/.github \
        $NVM_DIR/README.md \
        $NVM_DIR/LICENSE.md \
        $NVM_DIR/.gitignore \
        $NVM_DIR/.travis.yml \
        $NVM_DIR/.nvmrc \
        $NVM_DIR/.editorconfig \
    && rm -rf $NVM_DIR/.cache

# Make nvm available via shell-agnostic profile.d (preferred over bashrc)
RUN mkdir -p /etc/profile.d \
    && cat > /etc/profile.d/50-nvm.sh << 'EOF'
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOF

# ------------------------------------------------------------------------------
# tmux + zsh
# Completions are explicitly enabled because minimal zsh installs do not enable them by default.
# (No dedicated dev user yet — will be added much later.)
# ------------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tmux \
        zsh \
    && rm -rf /var/lib/apt/lists/*

# Zsh completions setup (system-wide)
RUN mkdir -p /etc/zsh/zshrc.d \
    && cat > /etc/zsh/zshrc.d/00-completions.zsh << 'EOF'
autoload -Uz compinit
compinit -i
EOF

# Generate completion for uv (not provided automatically)
RUN mkdir -p /usr/share/zsh/vendor-completions \
    && uv generate-shell-completion zsh > /usr/share/zsh/vendor-completions/_uv || true

# ------------------------------------------------------------------------------
# Persistent shell history (designed for volume mount)
# Both bash and zsh write to /root/.history/<shell>/ so the entire
# .history directory can be mounted as a volume for persistence.
# ------------------------------------------------------------------------------
RUN mkdir -p /root/.history/bash /root/.history/zsh \
    && chmod 700 /root/.history /root/.history/bash /root/.history/zsh

# Bash history configuration (sourced for interactive shells)
RUN cat > /etc/profile.d/90-history.sh << 'EOF'
# Persistent bash history under /root/.history/bash
export HISTFILE=/root/.history/bash/bash_history
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL=ignoredups:erasedups
EOF

# Zsh history configuration (sourced via zshrc.d for all interactive zsh sessions)
RUN cat > /etc/zsh/zshrc.d/10-history.zsh << 'EOF'
# Persistent zsh history under /root/.history/zsh
export HISTFILE=/root/.history/zsh/zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
EOF

# ------------------------------------------------------------------------------
# Final image cleanup (reduces size without affecting functionality)
# ------------------------------------------------------------------------------
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
              /usr/share/doc/* /usr/share/man/* /var/cache/apt/*

# ------------------------------------------------------------------------------
# Future composable images will build on this core target.
# Only add tools here when they are truly universal.
# ------------------------------------------------------------------------------

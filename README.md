# ccjail

Run [Claude Code](https://claude.ai/claude-code) inside a Docker container for any project.

## Why

- **Isolation** — Claude Code runs in a container, not directly on your host
- **Reproducible** — the Dockerfile is checked into your project
- **Customizable** — add whatever tools your project needs to the Dockerfile
- **Simple** — one shell script, no dependencies beyond bash and Docker

## Requirements

- bash
- Docker
- Linux or macOS

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/artilugio0/claude-code-jail/main/install.sh | sh
```

Or manually:

```sh
curl -fsSL https://raw.githubusercontent.com/artilugio0/claude-code-jail/main/ccjail.sh -o ~/.local/bin/ccjail
chmod +x ~/.local/bin/ccjail
```

> If you install manually, place `templates/Dockerfile` at `~/.local/share/ccjail/templates/Dockerfile`
> or keep `ccjail.sh` alongside the `templates/` directory.

## Usage

```sh
cd your-project

ccjail init     # scaffold a Dockerfile into .ccjail/
ccjail build    # build the Docker image
ccjail run      # start Claude Code inside the container
```

### `ccjail init`

Creates a `.ccjail/` directory with:
- `Dockerfile` — minimal image with Node.js, git, and Claude Code installed
- `config` — stores the Docker image name (`ccjail-<project-name>`)

Run with `--force` to overwrite an existing `.ccjail/` directory.

### `ccjail build`

Builds the Docker image defined in `.ccjail/Dockerfile`. Passes your current user's UID and GID as build arguments so files created inside the container are owned by you on the host.

### `ccjail run`

Starts Claude Code interactively. The following are mounted/forwarded automatically:

| What | Host | Container |
|------|------|-----------|
| Project files | `$PWD` | `/workspace` |
| Claude config & auth | `~/.claude` | `/home/node/.claude` |
| API key (if set) | `$ANTHROPIC_API_KEY` | `$ANTHROPIC_API_KEY` |
| SSH agent (if running) | `$SSH_AUTH_SOCK` | `/ssh-agent` |

## Customizing the Dockerfile

After running `ccjail init`, edit `.ccjail/Dockerfile` to add tools your project needs:

```dockerfile
FROM node:lts-slim

ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3 jq awscli \   # <-- add your tools here
    && rm -rf /var/lib/apt/lists/*

# ... rest of the file unchanged
```

Then rebuild with `ccjail build`.

## Authentication

ccjail mounts `~/.claude` from your host, so any existing Claude Code authentication is available inside the container. If you use an API key directly, set `ANTHROPIC_API_KEY` in your environment before running `ccjail run`.

## Committing `.ccjail/`

It's recommended to commit `.ccjail/Dockerfile` and `.ccjail/config` to your repository so teammates can run `ccjail build && ccjail run` without any additional setup.

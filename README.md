# claude-code-jail

Run [Claude Code](https://claude.ai/claude-code) inside an isolated Docker container for any project. Each project gets its own container image with exactly the tools it needs, keeping your host system clean and giving Claude a controlled, reproducible environment to work in. The whole thing is a single shell script with no dependencies beyond bash and Docker.

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

`ccjail run` will automatically run `init` and `build` if they haven't been run yet, so you can often just run `ccjail run` directly in a fresh project.

### `ccjail init`

Creates a `.ccjail/` directory with:
- `Dockerfile` — Ubuntu 24.04 image with Claude Code installed
- `config` — stores the Docker image name (`ccjail-<project-name>`)

Run with `--force` to overwrite an existing `.ccjail/` directory.

### `ccjail build`

Builds the Docker image defined in `.ccjail/Dockerfile`. Passes your current user's UID and GID as build arguments so files created inside the container are owned by you on the host.

### `ccjail run [--allow-docker] [ARGS...]`

Starts Claude Code interactively. The following are mounted/forwarded automatically:

| What | Host | Container |
|------|------|-----------|
| Project files | `$PWD` | `$PWD` (same absolute path) |
| Claude config & auth | `~/.claude` / `~/.claude.json` | `/home/user/.claude` / `/home/user/.claude.json` |
| API key (if set) | `$ANTHROPIC_API_KEY` | `$ANTHROPIC_API_KEY` |
| SSH agent (if running) | `$SSH_AUTH_SOCK` | `/ssh-agent` |
| Docker socket (with `--allow-docker`) | `/var/run/docker.sock` | `/var/run/docker.sock` |

The project directory is mounted at the **same absolute path** on both sides. This ensures that any `docker run -v $(pwd):...` commands Claude issues inside the container resolve correctly on the host.

Any additional arguments are forwarded directly to `claude`:

```sh
ccjail run -- --model claude-opus-4-5
```

#### `--allow-docker`

Mounts the host Docker socket into the container, allowing Claude to start sibling containers.  
Please be aware that this will share the Docker socket to the container, making it possible to
run processes as root in the host.

```sh
ccjail run --allow-docker
```

## Customizing the Dockerfile

After running `ccjail init`, edit `.ccjail/Dockerfile` to add tools your project needs. Then rebuild with `ccjail build`.

## Authentication

ccjail mounts `~/.claude` and `~/.claude.json` from your host, so any existing Claude Code authentication is available inside the container. If you use an API key directly, set `ANTHROPIC_API_KEY` in your environment before running `ccjail run`.

## Committing `.ccjail/`

It's recommended to commit `.ccjail/Dockerfile` and `.ccjail/config` to your repository so teammates can run `ccjail build && ccjail run` without any additional setup.

## Testing

The project includes an implementation-agnostic [bats-core](https://github.com/bats-core/bats-core) test suite. Tests call `ccjail` as a black-box CLI and use a fake Docker stub so no real image builds are needed for the fast suite.

```sh
./run_tests.sh               # ~62 fast tests
./run_tests.sh --integration # + integration tests (real Docker build)
```

Bats submodules are initialized automatically on first run.

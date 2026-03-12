#!/bin/sh
# ccjail — run Claude Code inside a Docker container for any project
set -e

CCJAIL_DIR=".ccjail"
CONFIG_FILE="$CCJAIL_DIR/config"

# Resolve the directory where this script lives so we can find templates/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DOCKERFILE="$SCRIPT_DIR/templates/Dockerfile"

usage() {
    cat <<EOF
ccjail — run Claude Code inside a Docker container

Usage:
  ccjail init [--force]   Scaffold a Dockerfile into the current project
  ccjail build            Build the Docker image for this project
  ccjail run              Start Claude Code in the container
  ccjail help             Show this help message

Getting started:
  1. cd your-project
  2. ccjail init
  3. ccjail build
  4. ccjail run
EOF
}

cmd_init() {
    force=0
    for arg in "$@"; do
        case "$arg" in
            --force) force=1 ;;
            *) echo "ccjail init: unknown option: $arg" >&2; exit 1 ;;
        esac
    done

    if [ -d "$CCJAIL_DIR" ] && [ "$force" -eq 0 ]; then
        echo "ccjail: '$CCJAIL_DIR' already exists. Use --force to overwrite." >&2
        exit 1
    fi

    if [ ! -f "$TEMPLATE_DOCKERFILE" ]; then
        echo "ccjail: template Dockerfile not found at: $TEMPLATE_DOCKERFILE" >&2
        echo "Make sure ccjail is installed correctly." >&2
        exit 1
    fi

    mkdir -p "$CCJAIL_DIR"

    cp "$TEMPLATE_DOCKERFILE" "$CCJAIL_DIR/Dockerfile"

    project_name="$(basename "$(pwd)")"
    # Sanitize: lowercase, replace non-alphanumeric (except dash) with dash
    image_name="ccjail-$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"

    cat > "$CONFIG_FILE" <<EOF
# ccjail configuration — edit IMAGE_NAME to change the Docker image tag
IMAGE_NAME=$image_name
EOF

    echo "ccjail: initialized in '$CCJAIL_DIR/'"
    echo "  Dockerfile: $CCJAIL_DIR/Dockerfile"
    echo "  Image name: $image_name"
    echo ""
    echo "Next steps:"
    echo "  ccjail build   # build the Docker image"
    echo "  ccjail run     # start Claude Code"
}

cmd_build() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ccjail: '$CONFIG_FILE' not found. Run 'ccjail init' first." >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    . "$CONFIG_FILE"

    if [ -z "$IMAGE_NAME" ]; then
        echo "ccjail: IMAGE_NAME is not set in '$CONFIG_FILE'." >&2
        exit 1
    fi

    echo "ccjail: building image '$IMAGE_NAME'..."
    docker build \
        --build-arg USER_UID="$(id -u)" \
        --build-arg USER_GID="$(id -g)" \
        -t "$IMAGE_NAME" \
        "$CCJAIL_DIR"
}

cmd_run() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ccjail: '$CONFIG_FILE' not found. Run 'ccjail init' first." >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    . "$CONFIG_FILE"

    if [ -z "$IMAGE_NAME" ]; then
        echo "ccjail: IMAGE_NAME is not set in '$CONFIG_FILE'." >&2
        exit 1
    fi

    # Ensure .claude and .claude.json exist with correct ownership before mounting.
    [ -d "$HOME/.claude" ]      || mkdir -p "$HOME/.claude"
    [ -f "$HOME/.claude.json" ] || touch "$HOME/.claude.json"

    # Base arguments
    set -- \
        run --rm -it \
        -v "$(pwd):/workspace" \
        -v "$HOME/.claude:/home/node/.claude" \
        -v "$HOME/.claude.json:/home/node/.claude.json" \
        -u "$(id -u):$(id -g)" \
        -w /workspace

    # Pass through API key if set
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        set -- "$@" -e ANTHROPIC_API_KEY
    fi

    # Pass through SSH agent socket if available
    if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        set -- "$@" \
            -v "$SSH_AUTH_SOCK:/ssh-agent" \
            -e SSH_AUTH_SOCK=/ssh-agent
    fi

    set -- "$@" "$IMAGE_NAME"

    exec docker "$@"
}

# Entry point
case "${1:-}" in
    init)    shift; cmd_init "$@" ;;
    build)   cmd_build ;;
    run)     cmd_run ;;
    help|--help|-h) usage ;;
    "")      usage; exit 1 ;;
    *)       echo "ccjail: unknown command: $1" >&2; echo "Run 'ccjail help' for usage." >&2; exit 1 ;;
esac

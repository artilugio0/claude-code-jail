#!/usr/bin/env bash

docker run -it --rm \
    -u $(id -u):$(id -g) \
    -v "$PWD:/development" \
    -v "$HOME/.claude:/home/user/.claude" \
    claude-code-jail claude

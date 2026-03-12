#!/bin/sh
# Run the ccjail test suite.
# Usage:
#   ./run_tests.sh               # fast tests only (no real Docker builds)
#   ./run_tests.sh --integration # fast tests + integration tests (real Docker)
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$REPO_ROOT/tests"
BATS="$TESTS_DIR/bats/bin/bats"

# Populate submodules if they haven't been initialized yet (e.g. after
# a plain `git clone` without --recurse-submodules).
if [ ! -f "$BATS" ]; then
    echo "Initializing bats submodules..."
    git -C "$REPO_ROOT" submodule update --init --recursive
fi

"$BATS" \
    "$TESTS_DIR/test_help.bats" \
    "$TESTS_DIR/test_init.bats" \
    "$TESTS_DIR/test_build.bats" \
    "$TESTS_DIR/test_run.bats"

if [ "${1:-}" = "--integration" ]; then
    "$BATS" "$TESTS_DIR/test_integration.bats"
fi

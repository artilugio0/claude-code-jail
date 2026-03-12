load 'bats-support/load'
load 'bats-assert/load'
load 'helpers/setup'

# Integration tests use real Docker.  They are slow (image build) and opt-in:
#   ./run_tests.sh --integration
#
# The image is built once for the whole file via setup_file / teardown_file.

INT_PROJ=""
INT_IMAGE=""

setup_file() {
    INT_PROJ="$(mktemp -d)/ccjail-integration-test"
    mkdir -p "$INT_PROJ"

    # Use ccjail.sh from the repo root (no fake docker).
    local ccjail
    ccjail="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/ccjail.sh"

    # Init and build a real image.
    sh -c "cd '$INT_PROJ' && bash '$ccjail' init"
    sh -c "cd '$INT_PROJ' && bash '$ccjail' build"

    INT_IMAGE="$(grep '^IMAGE_NAME=' "$INT_PROJ/.ccjail/config" | cut -d= -f2)"

    # Export so individual tests can use them.
    export INT_PROJ INT_IMAGE
}

teardown_file() {
    if [ -n "$INT_IMAGE" ]; then
        docker rmi "$INT_IMAGE" 2>/dev/null || true
    fi
    rm -rf "$(dirname "$INT_PROJ")"
}

# ---------------------------------------------------------------------------
# Image existence
# ---------------------------------------------------------------------------

@test "ccjail build produces a docker image" {
    docker image inspect "$INT_IMAGE" >/dev/null
}

# ---------------------------------------------------------------------------
# Image configuration
# ---------------------------------------------------------------------------

@test "built image has claude as its entrypoint" {
    local entrypoint
    entrypoint="$(docker image inspect "$INT_IMAGE" --format '{{json .Config.Entrypoint}}')"
    echo "$entrypoint" | grep -q '"claude"'
}

# ---------------------------------------------------------------------------
# Image functionality
# ---------------------------------------------------------------------------

@test "claude --version runs successfully inside the built image" {
    run docker run --rm --entrypoint claude "$INT_IMAGE" --version
    assert_success
}

@test "claude --version output identifies Claude Code" {
    run docker run --rm --entrypoint claude "$INT_IMAGE" --version
    assert_output --partial "Claude"
}

# ---------------------------------------------------------------------------
# Build idempotency
# ---------------------------------------------------------------------------

@test "running ccjail build a second time succeeds" {
    local ccjail
    ccjail="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/ccjail.sh"
    run sh -c "cd '$INT_PROJ' && bash '$ccjail' build"
    assert_success
}

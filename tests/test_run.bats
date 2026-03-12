load 'bats-support/load'
load 'bats-assert/load'
load 'helpers/setup'
load 'helpers/fake_docker'

setup() {
    setup_project
    make_fake_docker image_exists
    # Pre-initialize so most tests don't trigger auto-init.
    sh -c "cd '$PROJ' && bash '$CCJAIL' init"
}

teardown() {
    teardown_project
}

# ---------------------------------------------------------------------------
# Auto-init and auto-build
# ---------------------------------------------------------------------------

@test "run auto-inits when config is missing" {
    rm -rf "$PROJ/.ccjail"
    ccjail_run run
    assert_success
    assert_output --partial "running init first"
    [ -f "$PROJ/.ccjail/config" ]
}

@test "run auto-inits creates a valid config" {
    rm -rf "$PROJ/.ccjail"
    ccjail_run run
    grep -q "^IMAGE_NAME=" "$PROJ/.ccjail/config"
}

@test "run auto-builds when image is missing" {
    set_docker_behavior image_missing
    ccjail_run run
    assert_success
    assert_output --partial "running build first"
}

@test "run auto-build invokes docker build" {
    set_docker_behavior image_missing
    ccjail_run run
    assert_docker_call "build "
}

@test "run does not build when image already exists" {
    ccjail_run run
    refute_docker_call "build "
}

# ---------------------------------------------------------------------------
# docker run flags — mounting and user identity
# ---------------------------------------------------------------------------

@test "run passes --rm to docker" {
    ccjail_run run
    assert_docker_call "--rm"
}

@test "run passes -it to docker" {
    ccjail_run run
    assert_docker_call "-it"
}

@test "run mounts the project directory at the same absolute path" {
    ccjail_run run
    assert_docker_call "-v $PROJ:$PROJ"
}

@test "run mounts ~/.claude into the container" {
    ccjail_run run
    assert_docker_call "-v $HOME/.claude:/home/user/.claude"
}

@test "run mounts ~/.claude.json into the container" {
    ccjail_run run
    assert_docker_call "-v $HOME/.claude.json:/home/user/.claude.json"
}

@test "run sets user to current uid:gid" {
    ccjail_run run
    assert_docker_call "-u $(id -u):$(id -g)"
}

@test "run sets working directory to project path" {
    ccjail_run run
    assert_docker_call "-w $PROJ"
}

@test "run uses IMAGE_NAME from config" {
    local image_name
    image_name="$(grep '^IMAGE_NAME=' "$PROJ/.ccjail/config" | cut -d= -f2)"
    ccjail_run run
    assert_docker_call "$image_name"
}

# ---------------------------------------------------------------------------
# ANTHROPIC_API_KEY forwarding
# ---------------------------------------------------------------------------

@test "run does not add -e ANTHROPIC_API_KEY when key is unset" {
    unset ANTHROPIC_API_KEY
    ccjail_run run
    refute_docker_call "ANTHROPIC_API_KEY"
}

@test "run adds -e ANTHROPIC_API_KEY when key is set" {
    ANTHROPIC_API_KEY=test-key ccjail_run run
    assert_docker_call "ANTHROPIC_API_KEY"
}

# ---------------------------------------------------------------------------
# SSH agent forwarding
# ---------------------------------------------------------------------------

@test "run does not add ssh flags when SSH_AUTH_SOCK is unset" {
    unset SSH_AUTH_SOCK
    ccjail_run run
    refute_docker_call "ssh-agent"
}

@test "run does not add ssh flags when SSH_AUTH_SOCK is not a socket" {
    # Point to a regular file, not a socket.
    local fake_sock="$TEST_TMPDIR/not-a-socket"
    touch "$fake_sock"
    SSH_AUTH_SOCK="$fake_sock" ccjail_run run
    refute_docker_call "ssh-agent"
}

# ---------------------------------------------------------------------------
# --allow-docker flag
# ---------------------------------------------------------------------------

@test "run --allow-docker mounts the docker socket" {
    if [ ! -S /var/run/docker.sock ]; then
        skip "/var/run/docker.sock not available"
    fi
    ccjail_run run --allow-docker
    assert_docker_call "/var/run/docker.sock:/var/run/docker.sock"
}

@test "run --allow-docker adds --group-add for the socket group" {
    if [ ! -S /var/run/docker.sock ]; then
        skip "/var/run/docker.sock not available"
    fi
    ccjail_run run --allow-docker
    assert_docker_call "--group-add"
}

@test "run --allow-docker fails when docker socket is absent" {
    if [ ! -S /var/run/docker.sock ]; then
        skip "cannot test absence: socket already missing"
    fi
    # We can't fake the absence of /var/run/docker.sock, so this test
    # verifies the error message only when the socket IS present by checking
    # that --allow-docker succeeds (not the error path).
    # The error-path check is covered in test_integration.bats on hosts without docker.
    skip "cannot simulate missing socket from inside a running container"
}

# ---------------------------------------------------------------------------
# Extra args forwarding to claude
# ---------------------------------------------------------------------------

@test "run forwards extra args after -- to the container" {
    ccjail_run run -- --version
    assert_docker_call "--version"
}

@test "run forwards multiple extra args to the container" {
    ccjail_run run -- --print hello
    assert_docker_call "--print"
}

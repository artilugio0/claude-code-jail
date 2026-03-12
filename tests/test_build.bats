load 'bats-support/load'
load 'bats-assert/load'
load 'helpers/setup'
load 'helpers/fake_docker'

setup() {
    setup_project
    make_fake_docker image_exists
}

teardown() {
    teardown_project
}

# ---------------------------------------------------------------------------
# Pre-condition checks
# ---------------------------------------------------------------------------

@test "build fails without ccjail init" {
    ccjail_run build
    assert_failure
}

@test "build error without init mentions ccjail init" {
    ccjail_run build
    assert_output --partial "ccjail init"
}

# ---------------------------------------------------------------------------
# docker build invocation
# ---------------------------------------------------------------------------

@test "build invokes docker build" {
    ccjail_run init
    ccjail_run build
    assert_success
    assert_docker_call "build "
}

@test "build tags the image with the name from config" {
    ccjail_run init
    local image_name
    image_name="$(grep '^IMAGE_NAME=' "$PROJ/.ccjail/config" | cut -d= -f2)"
    ccjail_run build
    assert_docker_call "-t $image_name"
}

@test "build uses .ccjail as the build context" {
    ccjail_run init
    ccjail_run build
    assert_docker_call ".ccjail"
}

@test "build passes USER_UID build arg" {
    ccjail_run init
    ccjail_run build
    assert_docker_call "--build-arg USER_UID="
}

@test "build passes USER_GID build arg" {
    ccjail_run init
    ccjail_run build
    assert_docker_call "--build-arg USER_GID="
}

@test "build USER_UID matches current user" {
    ccjail_run init
    ccjail_run build
    assert_docker_call "--build-arg USER_UID=$(id -u)"
}

@test "build USER_GID matches current user" {
    ccjail_run init
    ccjail_run build
    assert_docker_call "--build-arg USER_GID=$(id -g)"
}

# ---------------------------------------------------------------------------
# Custom IMAGE_NAME
# ---------------------------------------------------------------------------

@test "build uses a custom IMAGE_NAME from config" {
    ccjail_run init
    # Override the image name
    sed -i 's/^IMAGE_NAME=.*/IMAGE_NAME=my-custom-image/' "$PROJ/.ccjail/config"
    ccjail_run build
    assert_docker_call "-t my-custom-image"
}

# ---------------------------------------------------------------------------
# docker failure propagation
# ---------------------------------------------------------------------------

@test "build exits non-zero when docker build fails" {
    ccjail_run init
    set_docker_behavior build_fails
    ccjail_run build
    assert_failure
}

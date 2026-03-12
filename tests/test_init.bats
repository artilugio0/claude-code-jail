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
# File creation
# ---------------------------------------------------------------------------

@test "init creates .ccjail directory" {
    ccjail_run init
    assert_success
    [ -d "$PROJ/.ccjail" ]
}

@test "init creates .ccjail/Dockerfile" {
    ccjail_run init
    [ -f "$PROJ/.ccjail/Dockerfile" ]
}

@test "init creates .ccjail/config" {
    ccjail_run init
    [ -f "$PROJ/.ccjail/config" ]
}

@test "init config contains IMAGE_NAME" {
    ccjail_run init
    grep -q "^IMAGE_NAME=" "$PROJ/.ccjail/config"
}

@test "init output mentions .ccjail/" {
    ccjail_run init
    assert_output --partial ".ccjail/"
}

# ---------------------------------------------------------------------------
# Dockerfile content
# ---------------------------------------------------------------------------

@test "init Dockerfile matches the template" {
    ccjail_run init
    diff "$PROJ/.ccjail/Dockerfile" "$(dirname "$CCJAIL")/templates/Dockerfile"
}

# ---------------------------------------------------------------------------
# IMAGE_NAME derivation and sanitization
# ---------------------------------------------------------------------------

@test "image name is prefixed with ccjail-" {
    ccjail_run init
    grep -q "^IMAGE_NAME=ccjail-" "$PROJ/.ccjail/config"
}

@test "image name uses the project directory name" {
    ccjail_run init
    grep -q "^IMAGE_NAME=ccjail-testproject$" "$PROJ/.ccjail/config"
}

@test "image name is lowercased" {
    PROJ="$TEST_TMPDIR/MyApp"
    mkdir -p "$PROJ"
    ccjail_run init
    grep -q "^IMAGE_NAME=ccjail-myapp$" "$PROJ/.ccjail/config"
}

@test "underscores in directory name become dashes" {
    PROJ="$TEST_TMPDIR/my_app"
    mkdir -p "$PROJ"
    ccjail_run init
    grep -q "^IMAGE_NAME=ccjail-my-app$" "$PROJ/.ccjail/config"
}

@test "dots in directory name become dashes" {
    PROJ="$TEST_TMPDIR/foo.bar"
    mkdir -p "$PROJ"
    ccjail_run init
    grep -q "^IMAGE_NAME=ccjail-foo-bar$" "$PROJ/.ccjail/config"
}

# ---------------------------------------------------------------------------
# --force flag
# ---------------------------------------------------------------------------

@test "init fails if .ccjail already exists" {
    ccjail_run init
    ccjail_run init
    assert_failure
}

@test "init failure mentions --force" {
    ccjail_run init
    ccjail_run init
    assert_output --partial "--force"
}

@test "init --force succeeds when .ccjail already exists" {
    ccjail_run init
    ccjail_run init --force
    assert_success
}

@test "init --force on a fresh directory succeeds" {
    ccjail_run init --force
    assert_success
}

@test "init --force recreates the Dockerfile" {
    ccjail_run init
    echo "MODIFIED" >> "$PROJ/.ccjail/Dockerfile"
    ccjail_run init --force
    # After --force, content should match the template again
    diff "$PROJ/.ccjail/Dockerfile" "$(dirname "$CCJAIL")/templates/Dockerfile"
}

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------

@test "init rejects unknown flags" {
    ccjail_run init --bad-flag
    assert_failure
}

@test "init unknown flag error mentions the flag" {
    ccjail_run init --bad-flag
    assert_output --partial "--bad-flag"
}

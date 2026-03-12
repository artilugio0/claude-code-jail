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
# help command
# ---------------------------------------------------------------------------

@test "ccjail help exits 0" {
    ccjail_run help
    assert_success
}

@test "ccjail --help exits 0" {
    ccjail_run --help
    assert_success
}

@test "ccjail -h exits 0" {
    ccjail_run -h
    assert_success
}

@test "ccjail help output contains init" {
    ccjail_run help
    assert_output --partial "init"
}

@test "ccjail help output contains build" {
    ccjail_run help
    assert_output --partial "build"
}

@test "ccjail help output contains run" {
    ccjail_run help
    assert_output --partial "run"
}

# ---------------------------------------------------------------------------
# no-args / unknown command
# ---------------------------------------------------------------------------

@test "ccjail with no args exits non-zero" {
    ccjail_run
    assert_failure
}

@test "ccjail with no args still prints usage" {
    ccjail_run
    assert_output --partial "ccjail"
}

@test "ccjail unknown command exits non-zero" {
    ccjail_run boguscmd
    assert_failure
}

@test "ccjail unknown command mentions the unknown command" {
    ccjail_run boguscmd
    assert_output --partial "boguscmd"
}

@test "ccjail unknown command suggests ccjail help" {
    ccjail_run boguscmd
    assert_output --partial "ccjail help"
}

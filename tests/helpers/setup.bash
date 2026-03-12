# Shared setup/teardown for all ccjail test suites.
#
# Provides:
#   $CCJAIL       - absolute path to ccjail.sh (the implementation under test)
#   $PROJ         - isolated project directory for the current test
#   $TEST_TMPDIR  - temporary directory cleaned up in teardown
#
# To adapt tests for a Go (or other) reimplementation:
#   Change CCJAIL to point to the new binary, e.g.:  CCJAIL="$(command -v ccjail)"

CCJAIL="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/ccjail.sh"

setup_project() {
    TEST_TMPDIR="$(mktemp -d)"
    PROJ="$TEST_TMPDIR/testproject"
    mkdir -p "$PROJ"
}

teardown_project() {
    rm -rf "$TEST_TMPDIR"
}

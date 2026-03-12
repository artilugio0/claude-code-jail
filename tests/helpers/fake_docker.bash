# Helpers for testing ccjail with a fake docker binary.
#
# The fake docker binary records every invocation to $DOCKER_CALLS (one line
# per call, format: "subcommand arg1 arg2 ...") and returns configurable exit
# codes based on $TEST_TMPDIR/docker_behavior.
#
# Behaviors:
#   image_exists  (default) - "docker image inspect" returns 0
#   image_missing           - "docker image inspect" returns 1 (triggers auto-build)
#   build_fails             - "docker build" returns 1
#
# Usage in tests:
#   make_fake_docker [behavior]  # call in setup()
#   set_docker_behavior <name>   # change behavior mid-test
#   ccjail_run [args...]         # runs ccjail in $PROJ with fake docker on PATH
#   assert_docker_call "str"     # assert DOCKER_CALLS contains substring
#   refute_docker_call "str"     # assert DOCKER_CALLS does NOT contain substring

make_fake_docker() {
    local behavior="${1:-image_exists}"

    FAKE_BIN="$TEST_TMPDIR/fakebin"
    DOCKER_CALLS="$TEST_TMPDIR/docker_calls.txt"
    local behavior_file="$TEST_TMPDIR/docker_behavior"

    mkdir -p "$FAKE_BIN"
    printf '%s\n' "$behavior" > "$behavior_file"
    : > "$DOCKER_CALLS"

    # Write the static part of the stub (no variable expansion in heredoc body).
    {
        printf '#!/bin/sh\n'
        printf 'CALLS_FILE=%s\n' "'$DOCKER_CALLS'"
        printf 'BEHAVIOR_FILE=%s\n' "'$behavior_file'"
        cat << 'STUB'
printf '%s\n' "$*" >> "$CALLS_FILE"
behavior="$(cat "$BEHAVIOR_FILE")"
case "$1" in
    image)  [ "$behavior" = "image_missing" ] && exit 1 || exit 0 ;;
    build)  [ "$behavior" = "build_fails"   ] && exit 1 || exit 0 ;;
    *)      exit 0 ;;
esac
STUB
    } > "$FAKE_BIN/docker"
    chmod +x "$FAKE_BIN/docker"
}

set_docker_behavior() {
    printf '%s\n' "$1" > "$TEST_TMPDIR/docker_behavior"
}

# Run ccjail in $PROJ with fake docker prepended to PATH.
# Captures stdout and stderr combined in bats' $output; sets $status.
ccjail_run() {
    run sh -c "cd '$PROJ' && PATH='$FAKE_BIN':\"\$PATH\" bash '$CCJAIL' \"\$@\" 2>&1" -- "$@"
}

assert_docker_call() {
    if ! grep -qF -- "$1" "$DOCKER_CALLS" 2>/dev/null; then
        local calls
        calls="$(cat "$DOCKER_CALLS" 2>/dev/null || echo '(no calls recorded)')"
        fail "Expected docker to be called with: '$1'
Actual docker calls:
$calls"
    fi
}

refute_docker_call() {
    if grep -qF -- "$1" "$DOCKER_CALLS" 2>/dev/null; then
        local calls
        calls="$(cat "$DOCKER_CALLS" 2>/dev/null)"
        fail "Expected docker NOT to be called with: '$1'
Actual docker calls:
$calls"
    fi
}

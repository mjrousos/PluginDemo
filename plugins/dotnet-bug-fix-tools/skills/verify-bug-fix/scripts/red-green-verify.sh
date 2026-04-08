#!/usr/bin/env bash
# TDD Red/Green Bug Fix Verification
# Stashes uncommitted changes (the fix), runs tests expecting failure,
# restores the fix, and runs tests expecting success.
set -uo pipefail

TEST_CMD="${*:-dotnet test}"
STASH_MSG="tdd-verify: temporarily stashing fix for red/green check"

# --- Preflight checks ---

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "ERROR: Not inside a git repository."
    exit 1
fi

if git diff --quiet && git diff --cached --quiet; then
    echo "ERROR: No uncommitted changes found."
    echo "The bug fix must be present as uncommitted changes (staged or unstaged)."
    exit 1
fi

echo "Test command: $TEST_CMD"
echo ""

# --- RED phase: remove fix, expect failure ---

echo "========================================"
echo " RED PHASE — tests should FAIL without the fix"
echo "========================================"
echo ""

git stash push -m "$STASH_MSG" --include-untracked --quiet

# Ensure stash is restored even if the script is interrupted
restore_stash() {
    echo ""
    echo "Restoring stashed changes..."
    git stash pop --quiet 2>/dev/null || true
}
trap restore_stash EXIT

set +e
eval "$TEST_CMD"
RED_EXIT=$?
set -e

echo ""

if [ $RED_EXIT -eq 0 ]; then
    echo "RESULT: RED phase FAILED"
    echo "Tests passed WITHOUT the fix — the test does not cover the bug."
    echo "Write a test that fails for the unfixed code, then try again."
    exit 1
fi

echo "RESULT: RED confirmed — tests fail without the fix"
echo ""

# --- GREEN phase: restore fix, expect success ---

echo "========================================"
echo " GREEN PHASE — tests should PASS with the fix"
echo "========================================"
echo ""

# Disable the trap since we're popping manually
trap - EXIT
git stash pop --quiet

set +e
eval "$TEST_CMD"
GREEN_EXIT=$?
set -e

echo ""

if [ $GREEN_EXIT -ne 0 ]; then
    echo "RESULT: GREEN phase FAILED"
    echo "Tests fail WITH the fix — the fix is incomplete or breaks something."
    exit 1
fi

echo "RESULT: GREEN confirmed — tests pass with the fix"
echo ""
echo "========================================"
echo " TDD RED/GREEN VERIFICATION PASSED"
echo "========================================"

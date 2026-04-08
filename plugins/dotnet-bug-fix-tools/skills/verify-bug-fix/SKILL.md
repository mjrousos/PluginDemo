---
name: verify-bug-fix
description: "**WORKFLOW SKILL** — Verify bug fixes using TDD red/green confirmation. WHEN: \"verify fix\", \"red green verify\", \"verify bug fix\", \"confirm bug fix\", \"test regression\", \"stash and test\". INVOKES: git stash, test runner (dotnet test). FOR SINGLE OPERATIONS: run the script directly from the terminal."
---

# TDD Red/Green Bug Fix Verification

Confirms a bug fix is valid by proving tests **fail without** the fix (RED) and **pass with** it (GREEN). Uses `git stash` to temporarily remove uncommitted changes.

## When to Use

- After writing a fix for a bug, before committing
- To confirm a test actually covers the bug (not a false positive)
- As a pre-commit verification step for regression fixes

## Prerequisites

- The fix must be **uncommitted** (staged or unstaged changes)
- At least one test must exercise the bug being fixed
- Git working tree must be otherwise clean (no unrelated changes), or unrelated changes should be committed/stashed first

## Procedure

1. Ensure the bug fix is uncommitted and relevant test(s) exist
2. Run the verification script:

   ```bash
   bash .github/skills/verify-bug-fix/scripts/red-green-verify.sh [test-command]
   ```

   Default test command: `dotnet test`

3. The script will:
   - **RED phase**: Stash the fix → run tests → confirm at least one failure
   - **GREEN phase**: Restore the fix → run tests → confirm all pass
4. Review the output — both phases must succeed for verification to pass

## Examples

```bash
# Use default test command (dotnet test)
bash .github/skills/verify-bug-fix/scripts/red-green-verify.sh

# Custom test command
bash .github/skills/verify-bug-fix/scripts/red-green-verify.sh "dotnet test --filter ClassName=PackageScannerTests"

# Run specific tests with verbose output
bash .github/skills/verify-bug-fix/scripts/red-green-verify.sh "dotnet test --filter DisplayName~ScanDirectory -v normal"
```

## Failure Modes

| Outcome | Meaning |
|---------|---------|
| RED phase fails (tests pass without fix) | The test doesn't actually cover the bug — write a better test |
| GREEN phase fails (tests fail with fix) | The fix is incomplete or breaks something else |
| No uncommitted changes | Nothing to verify — make your fix first |

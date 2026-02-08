#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

pass() { ((PASS++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); echo "  FAIL: $1 -- $2"; }

check_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    pass "$desc"
  else
    fail "$desc" "output does not contain '$needle'"
  fi
}

echo "Running tests for: changelog-gen"
echo "================================"

# Demo test
echo ""
echo "Demo:"
result=$("$SCRIPT_DIR/run.sh" --demo 2>/dev/null)
check_contains "demo has changelog header" "# Changelog" "$result"
check_contains "demo has features section" "### Features" "$result"
check_contains "demo has bug fixes section" "### Bug Fixes" "$result"

ok_msg=$("$SCRIPT_DIR/run.sh" --demo 2>&1 >/dev/null)
check_contains "demo produces OK message" "OK:" "$ok_msg"

# Validate test
echo ""
echo "Validate:"
result=$("$SCRIPT_DIR/run.sh" --validate 2>&1)
check_contains "validate passes" "PASS: all checks passed" "$result"

# Error cases
echo ""
echo "Error cases:"
set +e
"$SCRIPT_DIR/run.sh" 2>/dev/null; rc=$?
set -e
# Running without a git repo in the cwd should fail (unless we're in one)
# Just test --help works
set +e
"$SCRIPT_DIR/run.sh" --help >/dev/null 2>&1; rc=$?
set -e
[[ $rc -eq 0 ]] && pass "help exits 0" || fail "help" "expected exit 0, got $rc"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1

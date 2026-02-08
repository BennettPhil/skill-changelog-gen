#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
PASS=0
FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

check_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF -- "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (output does not contain '$needle')"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== changelog-gen tests ==="

# Setup a test git repo
REPO="$TMPDIR/test-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email "test@test.com"
git -C "$REPO" config user.name "Tester"

# Create initial commit and tag
echo "init" > "$REPO/file.txt"
git -C "$REPO" add . && git -C "$REPO" commit -q -m "initial commit"
git -C "$REPO" tag v1.0.0

# Add conventional commits
echo "a" >> "$REPO/file.txt" && git -C "$REPO" add . && git -C "$REPO" commit -q -m "feat: add user login"
echo "b" >> "$REPO/file.txt" && git -C "$REPO" add . && git -C "$REPO" commit -q -m "fix: resolve null pointer in auth"
echo "c" >> "$REPO/file.txt" && git -C "$REPO" add . && git -C "$REPO" commit -q -m "docs: update README"
echo "d" >> "$REPO/file.txt" && git -C "$REPO" add . && git -C "$REPO" commit -q -m "some random commit"
git -C "$REPO" tag v1.1.0

# Test 1: markdown output contains Features section
output=$(bash "$SCRIPT_DIR/run.sh" --repo "$REPO" v1.0.0 v1.1.0)
check_contains "md: has Features header" "## Features" "$output"
check_contains "md: has Bug Fixes header" "## Bug Fixes" "$output"
check_contains "md: has user login commit" "add user login" "$output"
check_contains "md: has fix commit" "resolve null pointer" "$output"
check_contains "md: has changelog header" "Changelog: v1.0.0...v1.1.0" "$output"

# Test 2: JSON output
json_output=$(bash "$SCRIPT_DIR/run.sh" --repo "$REPO" --format json v1.0.0 v1.1.0)
total=$(echo "$json_output" | python3 -c "import json,sys; print(json.load(sys.stdin)['total'])")
check "json: total commits" "4" "$total"
has_features=$(echo "$json_output" | python3 -c "import json,sys; print('Features' in json.load(sys.stdin)['groups'])")
check "json: has Features group" "True" "$has_features"

# Test 3: --help exits 0
bash "$SCRIPT_DIR/run.sh" --help >/dev/null 2>&1 && code=0 || code=$?
check "--help exits 0" "0" "$code"

# Test 4: missing ref exits non-zero
set +e
bash "$SCRIPT_DIR/run.sh" 2>/dev/null
missing_code=$?
set -e
check "missing ref exits non-zero" "1" "$((missing_code > 0 ? 1 : 0))"

# Test 5: from tag to HEAD (no TO_REF)
output_head=$(bash "$SCRIPT_DIR/run.sh" --repo "$REPO" v1.0.0)
check_contains "head: has commits" "add user login" "$output_head"

echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]

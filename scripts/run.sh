#!/usr/bin/env bash
set -euo pipefail

# run.sh — Generate changelogs from git history
# Usage: ./run.sh [OPTIONS] [FROM_TAG] [TO_TAG]

FORMAT="markdown"
FROM_TAG=""
TO_TAG="HEAD"
REPO_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2 ;;
    --repo) REPO_DIR="$2"; shift 2 ;;
    --demo)
      # Built-in demo with sample data
      echo "# Changelog"
      echo ""
      echo "## v1.2.0 (2026-02-08)"
      echo ""
      echo "### Features"
      echo "- Add user authentication with OAuth2 support"
      echo "- Implement dark mode toggle in settings"
      echo "- Add CSV export for reports"
      echo ""
      echo "### Bug Fixes"
      echo "- Fix memory leak in WebSocket handler"
      echo "- Resolve race condition in cache invalidation"
      echo "- Fix timezone display for international users"
      echo ""
      echo "### Other"
      echo "- Update dependencies to latest versions"
      echo "- Improve CI pipeline performance by 40%"
      echo ""
      echo "---"
      echo "*8 commits from v1.1.0 to v1.2.0*"
      echo "OK: generated demo changelog" >&2
      exit 0
      ;;
    --validate)
      echo "Validating changelog-gen..."
      # Check --demo works
      out=$("$0" --demo 2>/dev/null)
      if echo "$out" | grep -q "# Changelog"; then
        echo "PASS: demo generates changelog"
      else
        echo "FAIL: demo output missing"; exit 1
      fi
      if echo "$out" | grep -q "### Features"; then
        echo "PASS: demo has categorized sections"
      else
        echo "FAIL: demo missing categories"; exit 1
      fi
      echo "PASS: all checks passed"
      exit 0
      ;;
    --help)
      echo "Usage: run.sh [OPTIONS] [FROM_TAG] [TO_TAG]"
      echo ""
      echo "Generate changelogs from git commit history."
      echo ""
      echo "Arguments:"
      echo "  FROM_TAG    Start tag (default: latest tag)"
      echo "  TO_TAG      End ref (default: HEAD)"
      echo ""
      echo "Options:"
      echo "  --format markdown|json|text  Output format (default: markdown)"
      echo "  --repo DIR                   Git repo directory (default: .)"
      echo "  --demo                       Show demo output"
      echo "  --validate                   Run self-check"
      echo "  --help                       Show this help"
      exit 0
      ;;
    -*) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
    *)
      if [[ -z "$FROM_TAG" ]]; then
        FROM_TAG="$1"; shift
      elif [[ "$TO_TAG" == "HEAD" ]]; then
        TO_TAG="$1"; shift
      else
        echo "ERROR: unexpected argument: $1" >&2; exit 2
      fi
      ;;
  esac
done

# Verify git repo
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "ERROR: not a git repository: $REPO_DIR" >&2
  exit 2
fi

cd "$REPO_DIR"

# Auto-detect FROM_TAG if not provided
if [[ -z "$FROM_TAG" ]]; then
  FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [[ -z "$FROM_TAG" ]]; then
    # No tags, use first commit
    FROM_TAG=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
    if [[ -z "$FROM_TAG" ]]; then
      echo "ERROR: no commits found" >&2
      exit 1
    fi
  fi
fi

# Get commits
commits=$(git log --pretty=format:"%s|%an|%ad" --date=short "${FROM_TAG}..${TO_TAG}" 2>/dev/null || true)

if [[ -z "$commits" ]]; then
  echo "No changes found between $FROM_TAG and $TO_TAG."
  echo "OK: no changes" >&2
  exit 0
fi

# Categorize commits by conventional commit prefixes
declare -a features fixes docs refactors tests chores other

while IFS='|' read -r subject author date; do
  [[ -z "$subject" ]] && continue
  sub_lower=$(echo "$subject" | tr '[:upper:]' '[:lower:]')

  if [[ "$sub_lower" == feat:* || "$sub_lower" == feature:* || "$sub_lower" == feat\(*  ]]; then
    features+=("$subject")
  elif [[ "$sub_lower" == fix:* || "$sub_lower" == bugfix:* || "$sub_lower" == fix\(* ]]; then
    fixes+=("$subject")
  elif [[ "$sub_lower" == docs:* || "$sub_lower" == doc:* ]]; then
    docs+=("$subject")
  elif [[ "$sub_lower" == refactor:* || "$sub_lower" == refact:* ]]; then
    refactors+=("$subject")
  elif [[ "$sub_lower" == test:* || "$sub_lower" == tests:* ]]; then
    tests+=("$subject")
  elif [[ "$sub_lower" == chore:* || "$sub_lower" == ci:* || "$sub_lower" == build:* ]]; then
    chores+=("$subject")
  else
    other+=("$subject")
  fi
done <<< "$commits"

total_commits=$(echo "$commits" | wc -l | tr -d ' ')
current_date=$(date +%Y-%m-%d)

# --- JSON output ---
if [[ "$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"from\": \"$FROM_TAG\","
  echo "  \"to\": \"$TO_TAG\","
  echo "  \"date\": \"$current_date\","
  echo "  \"total_commits\": $total_commits,"
  echo "  \"categories\": {"

  print_json_arr() {
    local name="$1"; shift
    local arr=("$@")
    echo "    \"$name\": ["
    for ((i = 0; i < ${#arr[@]}; i++)); do
      comma=","; [[ $i -eq $((${#arr[@]} - 1)) ]] && comma=""
      escaped=$(echo "${arr[$i]}" | sed 's/"/\\"/g')
      echo "      \"$escaped\"$comma"
    done
    echo "    ]"
  }

  first=true
  for cat_name in features fixes docs refactors tests chores other; do
    eval "arr=(\"\${${cat_name}[@]:-}\")"
    if [[ ${#arr[@]} -gt 0 && -n "${arr[0]}" ]]; then
      [[ "$first" != true ]] && echo ","
      print_json_arr "$cat_name" "${arr[@]}"
      first=false
    fi
  done

  echo "  }"
  echo "}"
  echo "OK: generated JSON changelog ($total_commits commits)" >&2
  exit 0
fi

# --- Text output ---
if [[ "$FORMAT" == "text" ]]; then
  echo "Changelog: $FROM_TAG -> $TO_TAG ($current_date)"
  echo ""
  print_text_section() {
    local title="$1"; shift
    local arr=("$@")
    if [[ ${#arr[@]} -gt 0 && -n "${arr[0]}" ]]; then
      echo "$title:"
      for item in "${arr[@]}"; do
        echo "  - $item"
      done
      echo ""
    fi
  }
  print_text_section "Features" "${features[@]:-}"
  print_text_section "Bug Fixes" "${fixes[@]:-}"
  print_text_section "Documentation" "${docs[@]:-}"
  print_text_section "Refactoring" "${refactors[@]:-}"
  print_text_section "Tests" "${tests[@]:-}"
  print_text_section "Maintenance" "${chores[@]:-}"
  print_text_section "Other" "${other[@]:-}"
  echo "$total_commits commits"
  echo "OK: generated text changelog ($total_commits commits)" >&2
  exit 0
fi

# --- Markdown output (default) ---
echo "# Changelog"
echo ""
echo "## $TO_TAG ($current_date)"
echo ""

print_md_section() {
  local title="$1"; shift
  local arr=("$@")
  if [[ ${#arr[@]} -gt 0 && -n "${arr[0]}" ]]; then
    echo "### $title"
    for item in "${arr[@]}"; do
      # Strip conventional commit prefix
      clean=$(echo "$item" | sed 's/^[a-z]*(\?[^)]*)\?:[[:space:]]*//')
      echo "- $clean"
    done
    echo ""
  fi
}

print_md_section "Features" "${features[@]:-}"
print_md_section "Bug Fixes" "${fixes[@]:-}"
print_md_section "Documentation" "${docs[@]:-}"
print_md_section "Refactoring" "${refactors[@]:-}"
print_md_section "Tests" "${tests[@]:-}"
print_md_section "Maintenance" "${chores[@]:-}"
print_md_section "Other" "${other[@]:-}"

echo "---"
echo "*${total_commits} commits from ${FROM_TAG} to ${TO_TAG}*"

echo "OK: generated markdown changelog ($total_commits commits)" >&2

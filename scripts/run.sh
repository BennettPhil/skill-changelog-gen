#!/usr/bin/env bash
set -euo pipefail

# changelog-gen: generate changelog from git history

FROM_REF=""
TO_REF="HEAD"
FORMAT="md"
TITLE=""

usage() {
  cat <<'EOF'
Usage: changelog-gen [OPTIONS]

Generate a formatted CHANGELOG from git history.

Options:
  --from <ref>      Starting ref (default: latest tag)
  --to <ref>        Ending ref (default: HEAD)
  --format <md|json> Output format (default: md)
  --title <text>    Version title for the section
  --help            Show this help message

Must be run inside a git repository.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)   FROM_REF="$2"; shift 2 ;;
    --to)     TO_REF="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --title)  TITLE="$2"; shift 2 ;;
    --help)   usage; exit 0 ;;
    -*)       echo "Error: unknown option '$1'" >&2; exit 1 ;;
    *)        echo "Error: unexpected argument '$1'" >&2; exit 1 ;;
  esac
done

# Verify we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: not a git repository" >&2
  exit 1
fi

# Default from: latest tag
if [ -z "$FROM_REF" ]; then
  FROM_REF=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ -z "$FROM_REF" ]; then
    # No tags, use first commit
    FROM_REF=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
  fi
fi

# Default title
if [ -z "$TITLE" ]; then
  TITLE="Changelog ($FROM_REF...$TO_REF)"
fi

# Get commit log
COMMITS=$(git log --format="%H|%s|%an|%aI" "$FROM_REF".."$TO_REF" 2>/dev/null || true)

if [ -z "$COMMITS" ]; then
  if [ "$FORMAT" = "json" ]; then
    echo "[]"
  else
    echo "No commits found between $FROM_REF and $TO_REF"
  fi
  exit 0
fi

# Parse commits into categories
declare -A CATEGORIES
CATEGORIES=(
  [feat]="Features"
  [fix]="Bug Fixes"
  [docs]="Documentation"
  [style]="Styles"
  [refactor]="Refactoring"
  [perf]="Performance"
  [test]="Tests"
  [build]="Build"
  [ci]="CI"
  [chore]="Chores"
  [revert]="Reverts"
)

# Collect commits by category
declare -A CAT_COMMITS

while IFS= read -r line; do
  [ -z "$line" ] && continue
  sha=$(echo "$line" | cut -d'|' -f1)
  msg=$(echo "$line" | cut -d'|' -f2)
  author=$(echo "$line" | cut -d'|' -f3)
  date=$(echo "$line" | cut -d'|' -f4)

  # Parse conventional commit: type(scope): description
  category="other"
  scope=""
  description="$msg"

  if echo "$msg" | grep -qE '^[a-z]+(\([^)]+\))?(!)?:'; then
    category=$(echo "$msg" | sed 's/^\([a-z]*\).*/\1/')
    if echo "$msg" | grep -qE '^\w+\([^)]+\)'; then
      scope=$(echo "$msg" | sed 's/^[a-z]*(\([^)]*\)).*/\1/')
    fi
    description=$(echo "$msg" | sed 's/^[a-z]*\(([^)]*)\)\{0,1\}!*:[[:space:]]*//')
  fi

  short_sha="${sha:0:7}"

  if [ -n "${CAT_COMMITS[$category]+x}" ]; then
    CAT_COMMITS[$category]="${CAT_COMMITS[$category]}"$'\n'"${short_sha}|${scope}|${description}|${author}"
  else
    CAT_COMMITS[$category]="${short_sha}|${scope}|${description}|${author}"
  fi
done <<< "$COMMITS"

if [ "$FORMAT" = "json" ]; then
  echo "["
  first=true
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    sha=$(echo "$line" | cut -d'|' -f1)
    msg=$(echo "$line" | cut -d'|' -f2)
    author=$(echo "$line" | cut -d'|' -f3)
    date=$(echo "$line" | cut -d'|' -f4)

    category="other"
    scope=""
    description="$msg"

    if echo "$msg" | grep -qE '^[a-z]+(\([^)]+\))?(!)?:'; then
      category=$(echo "$msg" | sed 's/^\([a-z]*\).*/\1/')
      if echo "$msg" | grep -qE '^\w+\([^)]+\)'; then
        scope=$(echo "$msg" | sed 's/^[a-z]*(\([^)]*\)).*/\1/')
      fi
      description=$(echo "$msg" | sed 's/^[a-z]*\(([^)]*)\)\{0,1\}!*:[[:space:]]*//')
    fi

    if $first; then first=false; else echo ","; fi
    description_escaped=$(echo "$description" | sed 's/"/\\"/g')
    printf '  {"sha": "%s", "type": "%s", "scope": "%s", "description": "%s", "author": "%s", "date": "%s"}' \
      "${sha:0:7}" "$category" "$scope" "$description_escaped" "$author" "$date"
  done <<< "$COMMITS"
  echo ""
  echo "]"
else
  # Markdown output
  echo "# $TITLE"
  echo ""
  DATE=$(date +%Y-%m-%d)
  echo "_Generated on ${DATE}_"
  echo ""

  # Output known categories first
  for cat_key in feat fix docs style refactor perf test build ci chore revert; do
    if [ -n "${CAT_COMMITS[$cat_key]+x}" ]; then
      cat_name="${CATEGORIES[$cat_key]}"
      echo "## $cat_name"
      echo ""
      while IFS='|' read -r short_sha scope desc author; do
        [ -z "$short_sha" ] && continue
        if [ -n "$scope" ]; then
          echo "- **${scope}**: ${desc} (${short_sha})"
        else
          echo "- ${desc} (${short_sha})"
        fi
      done <<< "${CAT_COMMITS[$cat_key]}"
      echo ""
    fi
  done

  # Other (non-conventional commits)
  if [ -n "${CAT_COMMITS[other]+x}" ]; then
    echo "## Other"
    echo ""
    while IFS='|' read -r short_sha scope desc author; do
      [ -z "$short_sha" ] && continue
      echo "- ${desc} (${short_sha})"
    done <<< "${CAT_COMMITS[other]}"
    echo ""
  fi
fi

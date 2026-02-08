#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat >&2 <<'EOF'
Usage: run.sh [OPTIONS] FROM_REF [TO_REF]

Generate a changelog from git history between two refs.

Arguments:
    FROM_REF    Starting ref (tag, branch, or SHA)
    TO_REF      Ending ref (default: HEAD)

Options:
    --format md|json   Output format (default: md)
    --repo PATH        Path to git repo (default: .)
    -h, --help         Show this help message
EOF
    exit "${1:-0}"
}

FORMAT="md"
REPO="."
FROM=""
TO="HEAD"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format) FORMAT="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        -h|--help) usage 0 ;;
        -*) echo "Unknown option: $1" >&2; usage 1 ;;
        *)
            if [[ -z "$FROM" ]]; then
                FROM="$1"
            else
                TO="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$FROM" ]]; then
    echo "Error: FROM_REF is required" >&2
    usage 1
fi

if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: $REPO is not a git repository" >&2
    exit 1
fi

if ! git -C "$REPO" rev-parse "$FROM" >/dev/null 2>&1; then
    echo "Error: ref '$FROM' not found" >&2
    exit 1
fi

# Get commits between refs
LOG=$(git -C "$REPO" log --format="%H|%h|%an|%s" "$FROM".."$TO" 2>/dev/null || true)

if [[ -z "$LOG" ]]; then
    if [[ "$FORMAT" == "json" ]]; then
        echo '{"from":"'"$FROM"'","to":"'"$TO"'","date":"'"$(date +%Y-%m-%d)"'","groups":{},"total":0}'
    else
        echo "# Changelog: $FROM...$TO"
        echo ""
        echo "No commits found."
    fi
    exit 0
fi

# Parse and group commits
python3 "$SCRIPT_DIR/format_changelog.py" --format "$FORMAT" --from-ref "$FROM" --to-ref "$TO" <<< "$LOG"

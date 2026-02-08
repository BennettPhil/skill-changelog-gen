#!/usr/bin/env python3
"""Generate CHANGELOG entries from git history between two refs."""

import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

CATEGORIES = {
    "feat": "Added",
    "fix": "Fixed",
    "refactor": "Changed",
    "perf": "Changed",
    "deprecate": "Deprecated",
    "remove": "Removed",
    "security": "Security",
    "docs": "Other",
    "style": "Other",
    "test": "Other",
    "ci": "Other",
    "chore": "Other",
    "build": "Other",
}

CONV_RE = re.compile(r"^(\w+)(?:\(.+?\))?!?:\s*(.+)")
PR_RE = re.compile(r"\(#(\d+)\)")


def git(args: list[str], repo: str = ".") -> tuple[int, str]:
    result = subprocess.run(
        ["git", "-C", repo] + args,
        capture_output=True, text=True
    )
    return result.returncode, result.stdout.strip()


def parse_commit(message: str) -> tuple[str, str, str | None]:
    """Parse a commit message. Returns (category, description, pr_number)."""
    first_line = message.split("\n")[0].strip()
    pr_match = PR_RE.search(first_line)
    pr_num = pr_match.group(1) if pr_match else None

    conv_match = CONV_RE.match(first_line)
    if conv_match:
        prefix = conv_match.group(1).lower()
        desc = conv_match.group(2).strip()
        category = CATEGORIES.get(prefix, "Uncategorized")
        return category, desc, pr_num

    return "Uncategorized", first_line, pr_num


def get_commits(from_ref: str, to_ref: str, repo: str) -> list[dict]:
    code, output = git(["log", f"{from_ref}..{to_ref}", "--pretty=format:%s"], repo)
    if code != 0:
        return []
    if not output:
        return []

    commits = []
    for line in output.split("\n"):
        if not line.strip():
            continue
        category, desc, pr = parse_commit(line)
        commits.append({"category": category, "description": desc, "pr": pr})
    return commits


def format_markdown(commits: list[dict], version: str, include_links: bool) -> str:
    today = date.today().isoformat()
    lines = [f"## [{version}] - {today}", ""]

    # Group by category
    groups: dict[str, list] = {}
    for c in commits:
        groups.setdefault(c["category"], []).append(c)

    # Output in Keep a Changelog order
    order = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security", "Other", "Uncategorized"]
    for cat in order:
        if cat not in groups:
            continue
        lines.append(f"### {cat}")
        for c in groups[cat]:
            entry = f"- {c['description']}"
            if c["pr"] and include_links:
                entry += f" (#{c['pr']})"
            lines.append(entry)
        lines.append("")

    return "\n".join(lines)


def format_json(commits: list[dict], version: str) -> str:
    today = date.today().isoformat()
    groups: dict[str, list] = {}
    for c in commits:
        groups.setdefault(c["category"], []).append(c)
    return json.dumps({"version": version, "date": today, "categories": groups}, indent=2) + "\n"


def main():
    args = sys.argv[1:]
    if "--help" in args or "-h" in args:
        print("Usage: run.py [OPTIONS] <from-ref> [to-ref]")
        print()
        print("Generate CHANGELOG entries from git history.")
        print()
        print("Options:")
        print("  --repo PATH      Path to git repository (default: .)")
        print("  --version VER    Version label (default: auto-detect from to-ref)")
        print("  --format FMT     Output: markdown or json (default: markdown)")
        print("  --output PATH    Write to file instead of stdout")
        print("  --no-links       Omit PR/issue links")
        print("  -h, --help       Show this help")
        sys.exit(0)

    repo = "."
    version = None
    fmt = "markdown"
    output_path = None
    include_links = True
    refs = []

    i = 0
    while i < len(args):
        if args[i] == "--repo" and i + 1 < len(args):
            repo = args[i + 1]; i += 2
        elif args[i] == "--version" and i + 1 < len(args):
            version = args[i + 1]; i += 2
        elif args[i] == "--format" and i + 1 < len(args):
            fmt = args[i + 1]; i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output_path = args[i + 1]; i += 2
        elif args[i] == "--no-links":
            include_links = False; i += 1
        else:
            refs.append(args[i]); i += 1

    if not refs:
        print("Error: at least one git ref is required.", file=sys.stderr)
        sys.exit(1)

    from_ref = refs[0]
    to_ref = refs[1] if len(refs) > 1 else "HEAD"

    # Verify repo
    code, _ = git(["rev-parse", "--git-dir"], repo)
    if code != 0:
        print(f"Error: {repo} is not a git repository", file=sys.stderr)
        sys.exit(2)

    # Verify refs
    code, _ = git(["rev-parse", from_ref], repo)
    if code != 0:
        print(f"Error: ref not found: {from_ref}", file=sys.stderr)
        sys.exit(2)

    code, _ = git(["rev-parse", to_ref], repo)
    if code != 0:
        print(f"Error: ref not found: {to_ref}", file=sys.stderr)
        sys.exit(2)

    if not version:
        version = to_ref.lstrip("v") if to_ref != "HEAD" else "Unreleased"

    commits = get_commits(from_ref, to_ref, repo)

    if fmt == "json":
        result = format_json(commits, version)
    else:
        result = format_markdown(commits, version, include_links)

    if output_path:
        Path(output_path).write_text(result)
        print(f"Changelog written to {output_path}", file=sys.stderr)
    else:
        print(result, end="")


if __name__ == "__main__":
    main()

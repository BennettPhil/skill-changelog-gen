#!/usr/bin/env python3
"""Format git log into a grouped changelog."""

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import date

GROUPS = {
    "feat": "Features",
    "fix": "Bug Fixes",
    "docs": "Documentation",
    "refactor": "Refactoring",
    "perf": "Performance",
    "test": "Tests",
    "chore": "Chores",
    "ci": "CI/CD",
    "style": "Style",
    "build": "Build",
}

CONV_RE = re.compile(r'^(\w+)(?:\(.+?\))?!?:\s*(.+)$')

def parse_commits(lines):
    commits = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        parts = line.split("|", 3)
        if len(parts) < 4:
            continue
        full_hash, short_hash, author, subject = parts
        match = CONV_RE.match(subject)
        if match:
            ctype = match.group(1).lower()
            message = match.group(2)
        else:
            ctype = "other"
            message = subject
        commits.append({
            "hash": full_hash,
            "short_hash": short_hash,
            "author": author,
            "type": ctype,
            "message": message,
            "subject": subject,
        })
    return commits

def group_commits(commits):
    grouped = defaultdict(list)
    for c in commits:
        group_name = GROUPS.get(c["type"], "Other")
        grouped[group_name].append(c)
    return dict(grouped)

def format_md(grouped, from_ref, to_ref):
    lines = [f"# Changelog: {from_ref}...{to_ref}", f"*Generated {date.today().isoformat()}*", ""]
    for group_name in list(GROUPS.values()) + ["Other"]:
        if group_name not in grouped:
            continue
        lines.append(f"## {group_name}")
        lines.append("")
        for c in grouped[group_name]:
            lines.append(f"- {c['message']} ({c['short_hash']}) — {c['author']}")
        lines.append("")
    return "\n".join(lines)

def format_json(grouped, from_ref, to_ref):
    total = sum(len(v) for v in grouped.values())
    data = {
        "from": from_ref,
        "to": to_ref,
        "date": date.today().isoformat(),
        "groups": {},
        "total": total,
    }
    for name, commits in grouped.items():
        data["groups"][name] = [
            {"message": c["message"], "hash": c["short_hash"], "author": c["author"]}
            for c in commits
        ]
    return json.dumps(data, indent=2)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", choices=["md", "json"], default="md")
    parser.add_argument("--from-ref", required=True)
    parser.add_argument("--to-ref", default="HEAD")
    args = parser.parse_args()

    lines = sys.stdin.read().strip().splitlines()
    commits = parse_commits(lines)
    grouped = group_commits(commits)

    if args.format == "json":
        print(format_json(grouped, args.from_ref, args.to_ref))
    else:
        print(format_md(grouped, args.from_ref, args.to_ref))

if __name__ == "__main__":
    main()

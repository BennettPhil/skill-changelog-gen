---
name: changelog-gen
description: Generates a formatted CHANGELOG from git history between two tags or refs, grouping commits by type.
version: 0.1.0
license: Apache-2.0
---

# Changelog Generator

Reads git commit history between two refs (tags, branches, or SHAs) and produces a formatted CHANGELOG grouped by conventional commit types (feat, fix, docs, chore, etc.).

## Usage

```bash
# Generate changelog between two tags
./scripts/run.sh v1.0.0 v1.1.0

# Generate changelog from a tag to HEAD
./scripts/run.sh v1.0.0

# Output as markdown (default) or JSON
./scripts/run.sh --format json v1.0.0 v1.1.0
```

## Options

- `--format md|json` — Output format (default: `md`)
- `--repo PATH` — Path to git repository (default: current directory)
- `--help` — Show usage information

## Commit Grouping

Commits are grouped by conventional commit prefix:
- **Features** (`feat:`) — New features
- **Bug Fixes** (`fix:`) — Bug fixes
- **Documentation** (`docs:`) — Documentation changes
- **Refactoring** (`refactor:`) — Code refactoring
- **Other** — Commits without a recognized prefix

## Output

Markdown output includes a header with the version range and date, followed by grouped commits with short SHAs and author names.

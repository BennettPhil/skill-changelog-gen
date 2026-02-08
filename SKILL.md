---
name: changelog-gen
description: Generate formatted changelogs from git history between tags, with conventional commit categorization.
version: 0.1.0
license: Apache-2.0
---

Generate formatted changelogs from git commit history, automatically categorizing by conventional commit types.

## Try It Now

```bash
./scripts/run.sh --demo
```

## Contract

- Reads git log between two refs (tags, commits, or HEAD)
- Categorizes commits by conventional commit prefixes: feat, fix, docs, refactor, test, chore
- Outputs formatted changelog to stdout in markdown, text, or JSON
- Auto-detects latest tag if FROM_TAG not provided
- Side effects: none (read-only git operations)
- Exit 0: success, prints `OK: generated <format> changelog (N commits)` to stderr
- Exit 1: runtime error (not a git repo, no commits)
- Exit 2: invalid usage

## Real Usage

```bash
# Generate markdown changelog from latest tag to HEAD
./scripts/run.sh

# Between specific tags
./scripts/run.sh v1.0.0 v1.1.0

# JSON output for CI integration
./scripts/run.sh --format json v1.0.0 HEAD

# From a different repo
./scripts/run.sh --repo /path/to/project
```

## Options Table

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| FROM_TAG | No | latest tag | Start ref |
| TO_TAG | No | HEAD | End ref |
| --format | No | markdown | Output: markdown, json, text |
| --repo | No | . | Git repository path |
| --demo | No | - | Show demo output |
| --validate | No | - | Run self-check |
| --help | No | - | Show usage |

## Validation

```bash
./scripts/run.sh --validate
```

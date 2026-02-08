---
name: changelog-gen
description: Generates a formatted CHANGELOG from git history between two tags or refs
version: 0.1.0
license: Apache-2.0
---

# changelog-gen

Reads git commit history between two refs (tags, branches, SHAs) and produces a formatted CHANGELOG grouped by conventional commit type.

## Purpose

Generating changelogs manually is tedious and error-prone. This tool reads your git history and organizes commits into a clean, readable changelog format. It understands conventional commits (feat, fix, refactor, etc.) and groups them automatically.

## Instructions

When a user needs to generate a changelog:

1. Run `./scripts/run.sh` in a git repository
2. By default, it generates a changelog from the last tag to HEAD
3. Use `--from <ref>` and `--to <ref>` to specify a custom range
4. Use `--format md` (default) or `--format json` for output format
5. Output goes to stdout; redirect to a file as needed

## Inputs

- `--from <ref>`: Starting git ref (tag, branch, SHA). Default: latest tag
- `--to <ref>`: Ending git ref. Default: HEAD
- `--format <md|json>`: Output format. Default: md
- `--title <text>`: Version title for the changelog section
- `--help`: Show usage

## Outputs

Markdown changelog grouped by type, or JSON array of commits with parsed metadata.

## Constraints

- Must be run inside a git repository
- Requires git to be installed
- Works best with conventional commit messages (feat:, fix:, etc.)
- Non-conventional commits are grouped under "Other"

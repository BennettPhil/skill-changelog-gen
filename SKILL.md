---
name: changelog-gen
description: Generate formatted CHANGELOG entries from git history between two tags using Keep a Changelog format.
version: 0.1.0
license: Apache-2.0
---

# Changelog Generator

## Purpose

Reads git commit history between two tags (or refs) and produces a formatted CHANGELOG entry following the Keep a Changelog format. Supports conventional commits for automatic categorization into Added, Changed, Fixed, Deprecated, Removed, and Security sections.

## Quick Start

```bash
python3 scripts/run.py v1.0.0 v1.1.0
```

## Reference Index

- [references/api.md](references/api.md) — CLI flags, exit codes, output formats
- [references/usage-guide.md](references/usage-guide.md) — Walkthrough from basic to advanced usage
- [references/examples.md](references/examples.md) — Concrete examples with expected output

## Implementation

See `scripts/run.py` — a single Python script using only `subprocess` and stdlib.

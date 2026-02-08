# changelog-gen

Generates a formatted CHANGELOG from git history between two tags or refs.

## Quick Start

```bash
# In a git repo:
./scripts/run.sh
```

## Custom Range

```bash
./scripts/run.sh --from v1.0.0 --to v2.0.0
```

## JSON Output

```bash
./scripts/run.sh --format json
```

## Prerequisites

- Git
- Must be run inside a git repository
- Works best with conventional commits (feat:, fix:, etc.)

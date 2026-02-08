# Usage Guide

## Basic Usage

Generate a changelog between two tags:

```bash
python3 scripts/run.py v1.0.0 v1.1.0
```

## From a Tag to HEAD

```bash
python3 scripts/run.py v1.0.0
```

## Custom Repository Path

```bash
python3 scripts/run.py --repo /path/to/repo v1.0.0 v1.1.0
```

## Custom Version Label

```bash
python3 scripts/run.py --version "2.0.0-beta" v1.0.0 v2.0.0-beta
```

## JSON Output

```bash
python3 scripts/run.py --format json v1.0.0 v1.1.0
```

## Append to Existing CHANGELOG

```bash
python3 scripts/run.py v1.0.0 v1.1.0 --output CHANGELOG.md
```

## How Categories Work

The tool parses conventional commit prefixes:

- `feat: add user search` → **Added**
- `fix: resolve login bug` → **Fixed**
- `refactor: simplify auth flow` → **Changed**
- Non-conventional commits appear under **Uncategorized**

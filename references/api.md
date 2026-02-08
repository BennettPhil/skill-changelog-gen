# API Reference

## Command

```
python3 scripts/run.py [OPTIONS] <from-ref> [to-ref]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `from-ref` | Yes | Starting git ref (tag, branch, or commit SHA) |
| `to-ref` | No | Ending git ref. Default: `HEAD` |

## Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--repo` | string | `.` | Path to git repository |
| `--version` | string | auto | Version label for the entry (auto-detects from to-ref tag) |
| `--format` | string | markdown | Output format: `markdown` or `json` |
| `--output` | string | - | Write to file instead of stdout |
| `--no-links` | flag | false | Omit PR/issue links |
| `-h, --help` | flag | - | Show help message |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments |
| 2 | Git error (not a repo, ref not found) |

## Conventional Commit Mapping

| Prefix | Category |
|--------|----------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:` | Changed |
| `deprecate:` | Deprecated |
| `remove:` | Removed |
| `security:` | Security |
| `docs:`, `style:`, `test:`, `ci:`, `chore:`, `build:` | Other |
| No prefix | Uncategorized |

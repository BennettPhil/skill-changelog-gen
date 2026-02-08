# Examples

## 1. Standard Changelog Output

```markdown
## [1.1.0] - 2026-02-08

### Added
- Add user search endpoint (#42)
- Add dark mode toggle

### Fixed
- Fix login redirect loop (#38)
- Fix memory leak in worker pool

### Changed
- Refactor authentication middleware
```

## 2. Error: Not a Git Repo

```bash
$ python3 scripts/run.py --repo /tmp v1.0 v1.1
Error: /tmp is not a git repository
```

## 3. Error: Unknown Ref

```bash
$ python3 scripts/run.py v99.0.0
Error: ref not found: v99.0.0
```

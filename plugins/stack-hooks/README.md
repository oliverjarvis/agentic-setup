# stack-hooks

Stack-aware lifecycle hooks for Claude Code, plus a git-hook installer. One plugin whose
hook scripts detect the project stack at runtime and dispatch, so the same plugin works in
a TypeScript, Expo, Convex, Python, Swift, Go, or Rust repo without per-stack variants.

## What it does

### Claude Code hooks (agent-time)
| Event | Script | Behavior |
|-------|--------|----------|
| **PostToolUse** (`Write\|Edit\|MultiEdit`) | `format-on-edit.sh` | Formats just the edited file with the project's formatter (Biome or Prettier for JS/TS, Ruff for Python, SwiftFormat/SwiftLint for Swift, gofmt, rustfmt). Prefers `node_modules/.bin`. Always non-blocking. |
| **PreToolUse** (`Bash`) | `guard-bash.sh` | Denies destructive commands (recursive `rm` on `/`,`~`,`$HOME`,`*`; fork bombs; `mkfs`/`dd` to devices). Asks for confirmation on force-push, `curl \| sh`, and `sudo rm`. |
| **PreToolUse** (`Write\|Edit\|MultiEdit`) | `protect-paths.sh` | Denies edits to secret files (`.env`, `*.pem`, `*.key`, ssh keys, `.npmrc`, ...). Allows `.example`/`.sample`/`.template`. |
| **Stop** | `verify-on-stop.sh` | **Opt-in** typecheck gate. Off by default. Set `CLAUDE_STACK_HOOKS_VERIFY=1` to run `tsc --noEmit` / `ruff check` / `go vet` for detected stacks and block until issues are fixed. Respects `stop_hook_active`. |

### Git hooks (commit-time), via `/install-git-hooks`
Generates a stack-aware `.pre-commit-config.yaml` (using the [pre-commit](https://pre-commit.com) framework) and installs the `pre-commit`, `commit-msg`, and `pre-push` stages:
- **pre-commit:** housekeeping (`trailing-whitespace`, `end-of-file-fixer`, `check-merge-conflict`, `check-added-large-files`, `check-yaml/json`), secret scan (`gitleaks`), and per-stack format/lint on changed files (Ruff, SwiftLint, ESLint+Prettier).
- **commit-msg:** `commitlint` (conventional commits) for Node repos.
- **pre-push:** slower gates (`tsc --noEmit`, `convex codegen`).

This gives defense-in-depth: fast per-file checks at agent-time, only-changed-files checks at commit-time, slow gates at push/CI.

## Stack detection
`detect-stack.sh` reads marker files: `package.json`+`tsconfig` (ts), `app.json`/`app.config.*`+expo dep (expo), `convex/` (convex), `pyproject.toml`/`setup.cfg`/`requirements.txt` (python), `*.xcodeproj`/`Package.swift` (swift), `go.mod` (go), `Cargo.toml` (rust).

## Notes
- Hooks require `jq` (the agentic-setup installer provides it) and run arbitrary shell with your full user permissions. Review the scripts before enabling.
- Pinned `rev`s in the generated config are snapshots; run `pre-commit autoupdate` to refresh.
- Formatting is best-effort: a missing formatter is a silent no-op, never an error.

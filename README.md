# agentic-setup

My portable Claude Code setup, packaged as a single plugin marketplace plus a
one-line installer. Run it on a fresh machine, or inside any new project, and you
get the same agentic toolkit every time.

## Quick start

Run this anywhere (it is idempotent, so re-running is safe):

```bash
curl -fsSL https://raw.githubusercontent.com/oliverjarvis/agentic-setup/main/install.sh | bash
```

To also bootstrap the deepsec security scanner in the current repo:

```bash
curl -fsSL https://raw.githubusercontent.com/oliverjarvis/agentic-setup/main/install.sh | bash -s -- --with-deepsec
```

Then restart Claude Code (or open `/plugin`) so the new plugins load.

## What gets installed

### Marketplace

A single aggregator marketplace named **`agentic-setup`** (defined in
[`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)). It lists every
plugin below, so one `marketplace add` plus three `install` commands cover the whole
setup.

### Plugins

| Plugin | Source | What it does |
|--------|--------|--------------|
| **superpowers** | [obra/superpowers](https://github.com/obra/superpowers) | Core skills library: TDD, systematic debugging, brainstorming, planning, code review, and collaboration workflows. |
| **caveman** | [juliusbrussee/caveman](https://github.com/juliusbrussee/caveman) | Ultra-compressed "caveman" communication mode. Cuts roughly 75% of tokens while keeping full technical accuracy. |
| **no-em-dash** | bundled in this repo ([`plugins/no-em-dash`](plugins/no-em-dash)) | Custom plugin. Never use em-dashes (U+2014) or en-dashes (U+2013). Ships an invocable skill plus an always-on SessionStart hook that injects the rule into every session. |
| **stack-hooks** | bundled in this repo ([`plugins/stack-hooks`](plugins/stack-hooks)) | Custom plugin. Stack-aware lifecycle hooks: auto-format on edit, dangerous-command and secret-file guards, an opt-in stop-time typecheck, and a `/install-git-hooks` command that scaffolds a stack-aware `.pre-commit-config.yaml`. |

### stack-hooks (lifecycle hooks)

A single plugin whose hook scripts **detect the stack at runtime** (TS, Expo, Convex, Python, Swift, Go, Rust) and dispatch, so it works in any repo without per-stack variants. Agent-time it auto-formats the edited file (Biome/Prettier/Ruff/SwiftFormat), blocks destructive bash and edits to secret files, and (opt-in via `CLAUDE_STACK_HOOKS_VERIFY=1`) typechecks at Stop. Run `/install-git-hooks` in a repo to also generate a stack-aware `.pre-commit-config.yaml` (housekeeping + gitleaks + per-stack lint/format at commit-time, commitlint at commit-msg, typecheck at pre-push). See [`plugins/stack-hooks/README.md`](plugins/stack-hooks/README.md). Requires `jq`; hooks run arbitrary shell with your permissions, so review the scripts.

### graphify (knowledge graph)

[graphify](https://github.com/safishamsi/graphify) (PyPI package `graphifyy` with a
double y, CLI command `graphify`) turns a project into a queryable knowledge graph, so
the assistant can navigate straight to relevant files instead of grepping the whole
repo. It is a Python CLI rather than a Claude plugin, so the installer handles it
best-effort: if `uv`, `pipx`, or `pip` is available it installs `graphifyy` and runs
`graphify install` to register the user-scoped `/graphify` skill. If no Python tooling
is found, it is skipped with a hint. Opt out entirely with `--no-graphify`.

Usage once installed:

```bash
/graphify .              # build graphify-out/ (graph.html, GRAPH_REPORT.md, graph.json)
graphify claude install  # per project: add a PreToolUse hook so Claude always consults the graph
```

Requires Python 3.10+ (uv or pipx recommended over pip). Building a graph uses an LLM
backend: your assistant's own subagents, or a configured backend such as OpenRouter or
a local Ollama model.

### deepsec (optional, per project)

[deepsec](https://github.com/vercel-labs/deepsec) is an agent-powered vulnerability
scanner from Vercel Labs. It is **not** a Claude Code plugin: it is an npm CLI you
bootstrap inside a repo with `npx deepsec init`, and its scans use paid models (they
need an `AI_GATEWAY_API_KEY` or `ANTHROPIC_*` credentials and can cost real money on
large codebases). For that reason the installer only touches deepsec when you pass
`--with-deepsec`. Typical workflow:

```bash
npx deepsec init            # scaffolds .deepsec/ in the current repo
cd .deepsec && pnpm install
# let your agent fill in data/<id>/INFO.md per data/<id>/SETUP.md, then:
pnpm deepsec scan
pnpm deepsec process
pnpm deepsec export --format md-dir --out ./findings
```

### Settings

The installer merges these preferences into `~/.claude/settings.json` (existing keys
are backed up first, and CLI-managed keys such as `enabledPlugins` are preserved). Skip
this with `--no-settings`.

| Key | Value | Purpose |
|-----|-------|---------|
| `effortLevel` | `xhigh` | Maximum reasoning effort. |
| `autoUpdatesChannel` | `latest` | Track the latest Claude Code release. |
| `permissions.defaultMode` | `auto` | Auto-approve standard tool calls. |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | Enable experimental agent teams. |
| `skipDangerousModePermissionPrompt` | `true` | Skip the dangerous-mode prompt. |
| `skipAutoPermissionPrompt` | `true` | Skip the auto-permission prompt. |
| `skipWorkflowUsageWarning` | `true` | Skip the workflow usage warning. |
| `voiceEnabled` | `true` | Enable voice input. |
| `tui` | `fullscreen` | Fullscreen terminal UI. |
| `extraKnownMarketplaces.expo-plugins` | `expo/skills` | Keep the Expo skills marketplace known. |

> Note: `defaultMode: auto` and the `skip*` flags are permissive. Review them before
> running this on a shared or untrusted machine, or use `--no-settings`.

## Installer options

```text
install.sh [options]

--with-deepsec     Also bootstrap deepsec in the current repo (paid scans, needs API keys).
--no-graphify      Do not install graphify (the knowledge-graph skill).
--no-settings      Do not modify ~/.claude/settings.json.
--scope <scope>    Install scope: user (default), project, or local.
-h, --help         Show help.
```

## Manual install

If you would rather not pipe a script, run the equivalent commands yourself:

```bash
claude plugin marketplace add oliverjarvis/agentic-setup --scope user
claude plugin install superpowers@agentic-setup --scope user
claude plugin install caveman@agentic-setup     --scope user
claude plugin install no-em-dash@agentic-setup  --scope user

# graphify (knowledge-graph skill), optional:
uv tool install graphifyy && graphify install
```

## Updating

```bash
claude plugin marketplace update agentic-setup   # refresh the catalog
claude plugin update superpowers@agentic-setup   # update one plugin
```

Or just re-run the quick-start one-liner.

## Uninstall

```bash
claude plugin uninstall superpowers@agentic-setup
claude plugin uninstall caveman@agentic-setup
claude plugin uninstall no-em-dash@agentic-setup
claude plugin marketplace remove agentic-setup
```

See the Claude Code docs on [removing a marketplace](https://code.claude.com/docs/en/plugin-marketplaces#plugin-marketplace-remove).

## Requirements

- [Claude Code](https://code.claude.com/docs) (`claude` CLI)
- `git` (used to fetch GitHub-sourced plugins)
- `jq` (for the settings merge; the installer tries to install it via Homebrew or apt if missing)
- Python 3.10+ with `uv` or `pipx`, for graphify (skipped gracefully if absent; opt out with `--no-graphify`)
- Node.js 22+ with `npx`, only if you use `--with-deepsec`

## Repo layout

```text
agentic-setup/
├── .claude-plugin/
│   └── marketplace.json          # the agentic-setup marketplace catalog
├── plugins/
│   └── no-em-dash/               # custom plugin, bundled here
│       ├── .claude-plugin/plugin.json
│       ├── skills/no-em-dash/SKILL.md
│       └── hooks/inject-no-em-dash.sh
├── install.sh                    # the installer
└── README.md
```

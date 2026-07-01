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
| **stack-tests** | bundled in this repo ([`plugins/stack-tests`](plugins/stack-tests)) | Custom plugin. Stack-aware testing: `/scaffold-tests` writes unit/integration/e2e config + sample tests per detected stack (Vitest, convex-test, jest-expo + Maestro, Playwright, pytest, Swift Testing); `/verify-ui` runs the Playwright-MCP / simulator screenshot loop; ships a `testing-setup` skill. |
| **pr-review** | bundled in this repo ([`plugins/pr-review`](plugins/pr-review)) | Custom plugin. `/setup-pr-review` scaffolds a security-hardened Claude Code review GitHub Actions workflow (same-repo-only, SHA-pinned); `/address-review` reads a PR's human review threads, pushes fixes, and resolves them; ships a `pr-review` skill. |

### stack-hooks (lifecycle hooks)

A single plugin whose hook scripts **detect the stack at runtime** (TS, Expo, Convex, Python, Swift, Go, Rust) and dispatch, so it works in any repo without per-stack variants. Agent-time it auto-formats the edited file (Biome/Prettier/Ruff/SwiftFormat), blocks destructive bash and edits to secret files, and (opt-in via `CLAUDE_STACK_HOOKS_VERIFY=1`) typechecks at Stop. Run `/install-git-hooks` in a repo to also generate a stack-aware `.pre-commit-config.yaml` (housekeeping + gitleaks + per-stack lint/format at commit-time, commitlint at commit-msg, typecheck at pre-push). See [`plugins/stack-hooks/README.md`](plugins/stack-hooks/README.md). Requires `jq`; hooks run arbitrary shell with your permissions, so review the scripts.

### stack-tests (testing setup)

Detects the stack and scaffolds the right test frameworks. Run **`/scaffold-tests`** in a repo: it writes config + a sample test per detected stack (Vitest for TS/Node, convex-test for Convex, jest-expo + a Maestro flow for Expo/RN, Playwright for web e2e, pytest for Python, Swift Testing for Swift), non-destructively, and prints the exact install commands (it never installs on its own). Run **`/verify-ui`** for the agent screenshot/verify loop (Playwright MCP for web, `xcrun simctl`/`adb` capture for mobile). The bundled `testing-setup` skill holds the per-stack rationale. See [`plugins/stack-tests/README.md`](plugins/stack-tests/README.md).

### pr-review (Claude PR review)

Claude-powered pull-request review. Run **`/setup-pr-review`** in a repo to scaffold a security-hardened GitHub Actions workflow (`.github/workflows/claude-code-review.yml`): it triggers on PR open/update, runs the `code-review` plugin via `anthropics/claude-code-action`, uses least-privilege permissions, pins actions to full commit SHAs, and reviews **same-repo PRs only** by default (fork PRs skipped). Run **`/address-review [PR#]`** to read a PR's human review threads, push scoped fixes, and resolve them via `gh`. For your own findings, use `/code-review --fix`. The bundled `pr-review` skill covers auth (API key / OAuth / Bedrock / Vertex) and fork-PR hardening. See [`plugins/pr-review/README.md`](plugins/pr-review/README.md).

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
│   └── marketplace.json          # marketplace catalog (lists every plugin)
├── plugins/
│   ├── no-em-dash/               # skill + always-on SessionStart rule
│   ├── stack-hooks/              # lifecycle hooks + git-hook installer
│   ├── stack-tests/              # test scaffolding + screenshot/verify
│   └── pr-review/                # hardened CI review + review-comment fix loop
├── install.sh                    # idempotent installer (marketplace, plugins, settings, graphify, deepsec)
└── README.md
```

## Extending agentic-setup

The system has exactly two moving parts:

1. **The marketplace** (`.claude-plugin/marketplace.json`): a catalog of Claude Code plugins. Each entry is either **bundled** (a `./plugins/<name>` directory in this repo) or **external** (a `github` source pointing at someone else's repo).
2. **The installer** (`install.sh`): adds the marketplace, installs every plugin in the `PLUGINS=(...)` array, deep-merges settings, and wires in external CLI tools (graphify, deepsec) that are not Claude plugins.

Extending the system means touching one or both. Pick the recipe that matches what you want to add.

### 1. Add a bundled plugin (owned by this repo)

Use this for a new capability you want to author and version here (like `stack-hooks`).

```text
plugins/<name>/
├── .claude-plugin/plugin.json    # required: name, description, version
├── skills/<name>/SKILL.md        # optional: an invocable skill
├── commands/<name>.md            # optional: a /slash-command
├── agents/<name>.md              # optional: a subagent
├── hooks/hooks.json              # optional: lifecycle hooks
├── scripts/*.sh                  # optional: scripts your components call
└── .mcp.json                     # optional: bundled MCP server(s)
```

Then:
1. Register it in `marketplace.json` under `plugins`: `{ "name": "<name>", "description": "...", "category": "workflow", "source": "./plugins/<name>" }`.
2. Add `<name>` to `PLUGINS=(...)` in `install.sh` so it installs by default.
3. Add a row to the **Plugins** table and a short section above.
4. Validate: `claude plugin validate plugins/<name>` and `claude plugin validate .`.

### 2. Add an external marketplace plugin (someone else's repo)

Use this to bundle a third-party plugin (like `superpowers`, `caveman`). No local files needed:

```jsonc
// in marketplace.json -> plugins[]
{ "name": "their-plugin", "source": { "source": "github", "repo": "owner/repo" } }
```

Then add `their-plugin` to `PLUGINS=(...)` in `install.sh`. Pin a specific commit with `"sha": "<40-char>"` (and/or `"ref": "<tag>"`) inside the source object when you want reproducibility.

### 3. Add an external CLI tool (not a Claude plugin)

Use this for tools installed via npm/pip/etc. that are not plugins (like `graphify`, `deepsec`). In `install.sh`:
1. Write a `setup_<tool>()` function that installs the tool best-effort (probe `uv`/`pipx`/`pip`/`npx`, degrade to a printed hint if absent).
2. Add a flag: default-on with a `--no-<tool>` opt-out, or opt-in with `--with-<tool>` (use opt-in for anything slow, paid, or per-project).
3. Call it in the run sequence near the bottom, and document it in this README.

### 4. Add a component to an existing plugin

- **Skill:** `skills/<name>/SKILL.md` with frontmatter (`name`, `description`). The description is what triggers activation, so make it specific.
- **Command:** `commands/<name>.md` with frontmatter (`description`, optional `allowed-tools`, `argument-hint`). The body is the prompt; it can run a bundled script via `${CLAUDE_PLUGIN_ROOT}/scripts/<x>.sh` and reference args with `$1`/`$ARGUMENTS`.
- **Hook:** add an entry to `hooks/hooks.json` (`event -> matcher groups -> command handlers`). Reference bundled scripts with `${CLAUDE_PLUGIN_ROOT}`. Decision semantics: exit `0` (stdout parsed as JSON), exit `2` (block, stderr fed back to Claude), other (non-blocking). PreToolUse gates via `hookSpecificOutput.permissionDecision`; PostToolUse/Stop use top-level `decision: "block"`.
- **Agent:** `agents/<name>.md`. **MCP server:** `.mcp.json`.

### 5. Add support for a new stack (stack-hooks and stack-tests)

Both plugins detect the stack via a copy of `scripts/detect-stack.sh`, so:
1. Add a marker-file check + `add <tag>` to **both** `plugins/stack-hooks/scripts/detect-stack.sh` and `plugins/stack-tests/scripts/detect-stack.sh`.
2. In `stack-hooks`: teach `format-on-edit.sh` the new file extensions, and add a repos/hooks block for the tag in `install-git-hooks.sh`.
3. In `stack-tests`: add an `if has <tag>` block to `scaffold-tests.sh` (write config + a sample test, append an install command) and a row to the `testing-setup` skill matrix.

### 6. Change the applied settings

Edit the inline `SETTINGS_JSON` heredoc in `install.sh`. It is deep-merged (existing keys win where you do not override) into `~/.claude/settings.json`, with a timestamped backup.

### Conventions

- **No em-dashes** anywhere (enforced by the `no-em-dash` plugin; a repo-wide grep for U+2014/U+2013 should return nothing).
- **Scripts** are non-destructive (skip existing files, never overwrite), best-effort (a missing tool is a silent no-op, not an error), read the hook payload from stdin with `jq`, and reference bundled files via `${CLAUDE_PLUGIN_ROOT}`.
- **Validate** before committing: `claude plugin validate .` and `bash -n` on any script.
- **One PR per change**, and keep the Plugins table, sections, and `PLUGINS=(...)` array in sync.


#!/usr/bin/env bash
#
# agentic-setup installer
# https://github.com/oliverjarvis/agentic-setup
#
# Wires Oliver Jarvis's Claude Code agentic setup into this machine:
#   - adds the "agentic-setup" plugin marketplace
#   - installs the superpowers, caveman, and no-em-dash plugins
#   - applies preferred ~/.claude/settings.json
#   - optionally bootstraps the deepsec security scanner in the current repo
#
# Idempotent: safe to re-run, and safe to run inside any new project.
#
# Quick start:
#   curl -fsSL https://raw.githubusercontent.com/oliverjarvis/agentic-setup/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/oliverjarvis/agentic-setup/main/install.sh | bash -s -- --with-deepsec

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
MARKETPLACE_REPO="oliverjarvis/agentic-setup"
MARKETPLACE_NAME="agentic-setup"
PLUGINS=(superpowers caveman no-em-dash stack-hooks stack-tests pr-review)

SCOPE="user"
WITH_DEEPSEC=0
WITH_GRAPHIFY=1
APPLY_SETTINGS=1

# Preferred Claude Code settings, merged (not overwritten) into ~/.claude/settings.json.
read -r -d '' SETTINGS_JSON <<'JSON' || true
{
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
  "permissions": { "defaultMode": "auto" },
  "effortLevel": "xhigh",
  "autoUpdatesChannel": "latest",
  "skipDangerousModePermissionPrompt": true,
  "skipWorkflowUsageWarning": true,
  "skipAutoPermissionPrompt": true,
  "voiceEnabled": true,
  "tui": "fullscreen",
  "extraKnownMarketplaces": {
    "expo-plugins": { "source": { "source": "github", "repo": "expo/skills" } }
  }
}
JSON

# ----------------------------------------------------------------------------
# Output helpers
# ----------------------------------------------------------------------------
if [ -t 1 ]; then
  BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"; BLUE="$(printf '\033[34m')"; RESET="$(printf '\033[0m')"
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi
info()  { printf '%s\n' "${BLUE}==>${RESET} $*"; }
ok()    { printf '%s\n' "${GREEN}  ok${RESET} $*"; }
skip()  { printf '%s\n' "${DIM}  -- $*${RESET}"; }
warn()  { printf '%s\n' "${YELLOW}  !!${RESET} $*" >&2; }
die()   { printf '%s\n' "${RED}error:${RESET} $*" >&2; exit 1; }

usage() {
  cat <<USAGE
${BOLD}agentic-setup installer${RESET}

Usage: install.sh [options]

Options:
  --with-deepsec     Also bootstrap the deepsec security scanner in the current
                     repo (runs 'npx deepsec init'; scans are paid and need API keys).
  --no-graphify      Do not install graphify (the knowledge-graph skill).
  --no-settings      Do not modify ~/.claude/settings.json.
  --scope <scope>    Install scope for the marketplace and plugins:
                     user (default), project, or local.
  -h, --help         Show this help.
USAGE
}

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --with-deepsec) WITH_DEEPSEC=1 ;;
    --no-graphify)  WITH_GRAPHIFY=0 ;;
    --no-settings)  APPLY_SETTINGS=0 ;;
    --scope)        SCOPE="${2:-}"; [ -n "$SCOPE" ] || die "--scope needs a value"; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              usage; die "unknown option: $1" ;;
  esac
  shift
done

case "$SCOPE" in user|project|local) ;; *) die "invalid --scope '$SCOPE' (use user, project, or local)";; esac

# ----------------------------------------------------------------------------
# Preflight
# ----------------------------------------------------------------------------
info "Checking prerequisites"
command -v claude >/dev/null 2>&1 || die "the 'claude' CLI was not found. Install Claude Code first: https://code.claude.com/docs"
command -v git    >/dev/null 2>&1 || die "'git' is required to fetch plugins from GitHub."
ok "claude and git found"

# ----------------------------------------------------------------------------
# Settings
# ----------------------------------------------------------------------------
apply_settings() {
  [ "$APPLY_SETTINGS" -eq 1 ] || { skip "settings skipped (--no-settings)"; return; }
  info "Applying ~/.claude/settings.json preferences"

  if ! command -v jq >/dev/null 2>&1; then
    warn "'jq' not found; attempting to install it"
    if command -v brew >/dev/null 2>&1; then brew install jq >/dev/null 2>&1 || true
    elif command -v apt-get >/dev/null 2>&1; then sudo apt-get update -y >/dev/null 2>&1 && sudo apt-get install -y jq >/dev/null 2>&1 || true
    fi
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "could not get 'jq'; skipping settings merge. Apply these keys manually:"
    printf '%s\n' "$SETTINGS_JSON"
    return
  fi

  local dir="$HOME/.claude" file="$HOME/.claude/settings.json"
  mkdir -p "$dir"
  if [ -f "$file" ]; then
    local backup="$file.bak.$(date +%Y%m%d%H%M%S)"
    cp "$file" "$backup"
    local tmp; tmp="$(mktemp)"
    # Existing settings are the base; preferred keys win on conflict. Recursive merge
    # preserves CLI-managed keys such as enabledPlugins and the agentic-setup marketplace.
    printf '%s' "$SETTINGS_JSON" | jq -s '.[0] * .[1]' "$file" - > "$tmp"
    mv "$tmp" "$file"
    ok "merged preferences (backup: ${backup##*/})"
  else
    printf '%s\n' "$SETTINGS_JSON" | jq '.' > "$file"
    ok "created $file"
  fi
}

# ----------------------------------------------------------------------------
# Marketplace + plugins
# ----------------------------------------------------------------------------
setup_marketplace() {
  info "Configuring the '$MARKETPLACE_NAME' marketplace"
  if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
    claude plugin marketplace update "$MARKETPLACE_NAME" >/dev/null && ok "marketplace updated"
  else
    claude plugin marketplace add "$MARKETPLACE_REPO" --scope "$SCOPE" && ok "marketplace added ($MARKETPLACE_REPO)"
  fi
}

install_plugins() {
  info "Installing plugins (scope: $SCOPE)"
  local installed; installed="$(claude plugin list 2>/dev/null || true)"
  local p
  for p in "${PLUGINS[@]}"; do
    if printf '%s' "$installed" | grep -q "${p}@${MARKETPLACE_NAME}"; then
      skip "${p}@${MARKETPLACE_NAME} already installed"
      continue
    fi
    if printf '%s' "$installed" | grep -qE "(^|[^a-zA-Z0-9_-])${p}@"; then
      local other; other="$(printf '%s' "$installed" | grep -oE "${p}@[a-zA-Z0-9_-]+" | head -1)"
      warn "'${other}' is installed from another marketplace. Installing ${p}@${MARKETPLACE_NAME} as well."
      warn "  To avoid duplicate skills, consider: claude plugin uninstall ${other}"
    fi
    claude plugin install "${p}@${MARKETPLACE_NAME}" --scope "$SCOPE" && ok "installed ${p}@${MARKETPLACE_NAME}"
  done
}

# ----------------------------------------------------------------------------
# graphify (knowledge-graph skill, external Python CLI)
# ----------------------------------------------------------------------------
setup_graphify() {
  [ "$WITH_GRAPHIFY" -eq 1 ] || { skip "graphify skipped (--no-graphify)"; return; }
  info "Setting up graphify (knowledge-graph skill)"

  # graphify is a Python CLI (PyPI package 'graphifyy', command 'graphify'), not a
  # Claude plugin. Install best-effort via uv (preferred), pipx, or pip.
  if command -v graphify >/dev/null 2>&1; then
    ok "graphify CLI already installed"
  elif command -v uv >/dev/null 2>&1; then
    uv tool install graphifyy >/dev/null 2>&1 && ok "installed graphifyy (uv)" || { warn "uv tool install graphifyy failed; skipping graphify"; return; }
    uv tool update-shell >/dev/null 2>&1 || true
  elif command -v pipx >/dev/null 2>&1; then
    pipx install graphifyy >/dev/null 2>&1 && ok "installed graphifyy (pipx)" || { warn "pipx install graphifyy failed; skipping graphify"; return; }
    pipx ensurepath >/dev/null 2>&1 || true
  elif command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
    local pipcmd; pipcmd="$(command -v pip3 || command -v pip)"
    "$pipcmd" install --user graphifyy >/dev/null 2>&1 && ok "installed graphifyy (pip)" || { warn "pip install graphifyy failed; skipping graphify"; return; }
  else
    warn "no uv/pipx/pip found; skipping graphify."
    warn "  Install Python 3.10+ and uv, then run: uv tool install graphifyy && graphify install"
    return
  fi

  # Register the user-scoped Claude Code skill so /graphify works everywhere.
  if command -v graphify >/dev/null 2>&1; then
    graphify install >/dev/null 2>&1 && ok "registered the graphify skill (user scope)" || warn "run 'graphify install' manually to register the skill"
  else
    warn "graphify is installed but not on PATH yet. Open a new shell, then run: graphify install"
  fi
}

# ----------------------------------------------------------------------------
# deepsec (optional, per-project)
# ----------------------------------------------------------------------------
bootstrap_deepsec() {
  [ "$WITH_DEEPSEC" -eq 1 ] || return
  info "Bootstrapping deepsec in $(pwd)"
  command -v npx >/dev/null 2>&1 || { warn "'npx' (Node.js 22+) not found; skipping deepsec."; return; }
  npx deepsec init || { warn "deepsec init did not complete."; return; }
  cat <<'NEXT'
  deepsec scaffolded into .deepsec/. Next steps:
    cd .deepsec && pnpm install
    # let your agent fill in data/<id>/INFO.md (see .deepsec/data/<id>/SETUP.md), then:
    pnpm deepsec scan
    pnpm deepsec process
    pnpm deepsec export --format md-dir --out ./findings
  Scans use paid models. Set AI_GATEWAY_API_KEY (or ANTHROPIC_*) first.
  Docs: https://github.com/vercel-labs/deepsec
NEXT
}

# ----------------------------------------------------------------------------
# Run
# ----------------------------------------------------------------------------
printf '%s\n' "${BOLD}agentic-setup${RESET} ${DIM}(scope: $SCOPE)${RESET}"
apply_settings
setup_marketplace
install_plugins
setup_graphify
bootstrap_deepsec

printf '\n%s\n' "${GREEN}${BOLD}Done.${RESET} Restart Claude Code (or run /plugin) to load everything."
[ "$WITH_GRAPHIFY" -eq 1 ] && printf '%s\n' "${DIM}Tip: in a repo, run /graphify . to build a knowledge graph (graphify-out/).${RESET}"
[ "$WITH_DEEPSEC" -eq 1 ] || printf '%s\n' "${DIM}Tip: re-run with --with-deepsec inside a repo to add the security scanner.${RESET}"

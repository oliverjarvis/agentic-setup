#!/usr/bin/env bash
#
# verify-on-stop.sh: Stop hook. Opt-in whole-project typecheck gate.
#
# Disabled by default (Stop-time typechecks can be slow and disruptive).
# Enable by exporting CLAUDE_STACK_HOOKS_VERIFY=1. When enabled and a detected
# stack's typecheck fails, it blocks so Claude fixes the issue before finishing.
# Respects stop_hook_active to avoid infinite loops.

set -uo pipefail

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

# Opt-in only.
[ "${CLAUDE_STACK_HOOKS_VERIFY:-0}" = "1" ] || exit 0

# Do not re-trigger if we are already inside a Stop-hook continuation.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)"
[ "$active" = "true" ] && exit 0

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
have() { command -v "$1" >/dev/null 2>&1; }
local_bin() { [ -x "$dir/node_modules/.bin/$1" ] && printf '%s' "$dir/node_modules/.bin/$1"; }

tags="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-stack.sh" "$dir" 2>/dev/null || true)"
problems=""
note() { problems="${problems}
- $1"; }

for t in $tags; do
  case "$t" in
    ts)
      tsc="$(local_bin tsc)"; [ -n "$tsc" ] || { have tsc && tsc="tsc"; }
      if [ -n "${tsc:-}" ]; then
        out="$(cd "$dir" && "$tsc" --noEmit 2>&1)" || note "TypeScript typecheck (tsc --noEmit) failed:
$out"
      fi
      ;;
    python)
      if have ruff; then
        out="$(cd "$dir" && ruff check . 2>&1)" || note "Ruff check failed:
$out"
      fi
      ;;
    go)
      if have go; then
        out="$(cd "$dir" && go vet ./... 2>&1)" || note "go vet failed:
$out"
      fi
      ;;
  esac
done

if [ -n "$problems" ]; then
  reason="stack-hooks verification found issues that should be fixed before finishing:${problems}"
  jq -nc --arg r "$reason" '{decision:"block", reason:$r}'
fi

exit 0

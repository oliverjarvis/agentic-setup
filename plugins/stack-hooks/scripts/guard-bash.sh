#!/usr/bin/env bash
#
# guard-bash.sh: PreToolUse hook (matcher: Bash).
# Denies clearly destructive commands and asks for confirmation on risky ones.
# Emits a PreToolUse permission decision as JSON; silent exit 0 = allow (default).

set -uo pipefail

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

decide() { # $1 = allow|deny|ask, $2 = reason
  jq -nc --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

# Hard deny: recursive/forced rm targeting root, home, or a bare glob; fork bomb.
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f?[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(/|~|\$HOME|\*)([[:space:]]|$)'; then
  decide deny "Blocked: recursive rm targeting / , ~ , \$HOME, or a bare glob. Narrow the target and retry."
fi
if printf '%s' "$cmd" | grep -Eq ':\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:'; then
  decide deny "Blocked: fork bomb pattern."
fi
if printf '%s' "$cmd" | grep -Eq '(^|[^a-zA-Z])(mkfs|dd[[:space:]]+if=)|>[[:space:]]*/dev/sd'; then
  decide deny "Blocked: raw disk write / mkfs / dd to a device."
fi

# Ask (confirm) on risky but sometimes-legitimate commands.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]]|$).*(--force([[:space:]]|=|$)|[[:space:]]-f([[:space:]]|$))'; then
  decide ask "Force-push detected. Confirm the target branch before proceeding."
fi
if printf '%s' "$cmd" | grep -Eq '(curl|wget)[[:space:]].*\|[[:space:]]*(sudo[[:space:]]+)?(bash|sh|zsh)([[:space:]]|$)'; then
  decide ask "Piping a remote script straight into a shell. Confirm you trust the source."
fi
if printf '%s' "$cmd" | grep -Eq '(^|[^a-zA-Z])sudo[[:space:]]+rm([[:space:]]|$)'; then
  decide ask "sudo rm detected. Confirm the path before proceeding."
fi

exit 0

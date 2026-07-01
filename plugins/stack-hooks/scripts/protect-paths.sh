#!/usr/bin/env bash
#
# protect-paths.sh: PreToolUse hook (matcher: Write|Edit|MultiEdit).
# Denies edits to secret/credential files so the agent cannot silently rewrite them.
# Example/sample/template variants are allowed. Silent exit 0 = allow (default).

set -uo pipefail

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
[ -n "$fp" ] || exit 0

base="$(basename "$fp")"

deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Allow sharable placeholder files even if they look secret-ish.
case "$base" in
  *.example|*.sample|*.template|*.dist) exit 0 ;;
esac

case "$base" in
  .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa|id_dsa|id_ecdsa|id_ed25519|.npmrc|.pypirc|.netrc)
    deny "Blocked: '$base' looks like a secret/credential file. Edit it manually if this is intended." ;;
esac

case "$fp" in
  */.env|*/.env.*|*/secrets/*|*/.ssh/*)
    deny "Blocked: '$fp' appears to hold secrets. Edit it manually if this is intended." ;;
esac

exit 0

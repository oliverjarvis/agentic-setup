#!/usr/bin/env bash
#
# format-on-edit.sh: PostToolUse hook (matcher: Write|Edit|MultiEdit).
# Auto-formats the single edited file using whatever formatter the project has.
# Always non-blocking: any failure or missing tool is a no-op (exit 0).
#
# Prefers project-local binaries (node_modules/.bin) to avoid npx startup cost.
# Reads the tool payload as JSON on stdin.

set -uo pipefail

input="$(cat)"
have() { command -v "$1" >/dev/null 2>&1; }

# jq is required to read the payload; degrade to a no-op if absent.
have jq || exit 0

fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
[ -n "$fp" ] && [ -f "$fp" ] || exit 0

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
run() { "$@" >/dev/null 2>&1 || true; }

# Echo a runnable path to a project-local node binary, or fail.
local_bin() { [ -x "$dir/node_modules/.bin/$1" ] && printf '%s' "$dir/node_modules/.bin/$1"; }

ext="${fp##*.}"
case "$ext" in
  ts|tsx|js|jsx|mjs|cjs|json|jsonc|css|scss|less|md|mdx|html|yaml|yml|graphql)
    if bin="$(local_bin biome)" && [ -n "$bin" ]; then run "$bin" format --write "$fp"
    elif bin="$(local_bin prettier)" && [ -n "$bin" ]; then run "$bin" --write "$fp"
    elif have biome; then run biome format --write "$fp"
    elif have prettier; then run prettier --write "$fp"
    fi
    ;;
  py)
    if have ruff; then run ruff format "$fp"; run ruff check --fix "$fp"; fi
    ;;
  swift)
    if have swiftformat; then run swiftformat "$fp"; fi
    if have swiftlint; then run swiftlint --fix --quiet "$fp"; fi
    ;;
  go)
    if have gofmt; then run gofmt -w "$fp"; fi
    ;;
  rs)
    if have rustfmt; then run rustfmt "$fp"; fi
    ;;
esac

exit 0

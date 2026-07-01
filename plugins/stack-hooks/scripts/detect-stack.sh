#!/usr/bin/env bash
#
# detect-stack.sh: print detected stack tags (one per line) for a project directory.
# Usage: detect-stack.sh [DIR]   (DIR defaults to $CLAUDE_PROJECT_DIR, then $PWD)
#
# Tags: node ts expo convex python swift go rust
# Detection is by canonical marker files. A repo can match several tags (monorepos).

set -uo pipefail

dir="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"

tags=""
add() { case " $tags " in *" $1 "*) ;; *) tags="$tags $1" ;; esac; }

if [ -f "$dir/package.json" ]; then
  add node
  if [ -f "$dir/tsconfig.json" ] || ls "$dir"/tsconfig*.json >/dev/null 2>&1; then add ts; fi
  # Expo: an app config plus the expo dependency (grep is a cheap heuristic).
  if { [ -f "$dir/app.json" ] || ls "$dir"/app.config.* >/dev/null 2>&1; } && grep -q '"expo"' "$dir/package.json" 2>/dev/null; then
    add expo
  fi
  [ -d "$dir/convex" ] && add convex
fi

if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.cfg" ] || [ -f "$dir/requirements.txt" ]; then add python; fi
if ls "$dir"/*.xcodeproj >/dev/null 2>&1 || [ -f "$dir/Package.swift" ]; then add swift; fi
[ -f "$dir/go.mod" ] && add go
[ -f "$dir/Cargo.toml" ] && add rust

for t in $tags; do printf '%s\n' "$t"; done

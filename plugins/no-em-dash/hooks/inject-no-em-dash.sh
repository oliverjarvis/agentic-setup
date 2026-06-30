#!/usr/bin/env bash
# SessionStart hook for the no-em-dash plugin.
# Injects an always-on output rule so the constraint is active in every session,
# not only when the no-em-dash skill is explicitly invoked.
#
# Claude Code reads stdout of a SessionStart hook and, when it is the documented
# JSON shape below, adds `additionalContext` to the session context.

set -euo pipefail

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"OUTPUT RULE (no-em-dash plugin): Never use the em-dash character (U+2014) or the en-dash character (U+2013) in any output, including prose, code comments, commit messages, and PR descriptions. Substitute a comma, a colon, parentheses, or two separate sentences. For numeric ranges use the word 'to'. A regular hyphen is fine where a hyphen genuinely belongs. This rule is always active for this session."}}
JSON

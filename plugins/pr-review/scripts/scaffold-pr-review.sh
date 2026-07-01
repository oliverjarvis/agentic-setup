#!/usr/bin/env bash
#
# scaffold-pr-review.sh: install a security-hardened Claude Code review workflow into
# .github/workflows/. Non-destructive (skips an existing file) and prints setup steps.

set -uo pipefail

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tpl="$here/../templates/claude-code-review.yml"
dest="$dir/.github/workflows/claude-code-review.yml"

[ -f "$tpl" ] || { echo "template not found: $tpl" >&2; exit 1; }

if [ -e "$dest" ]; then
  echo "skip (exists): .github/workflows/claude-code-review.yml"
else
  mkdir -p "$(dirname "$dest")"
  cp "$tpl" "$dest"
  echo "wrote: .github/workflows/claude-code-review.yml"
fi

cat <<'NEXT'

Next steps:
  1. Add credentials as a repo secret (direct Claude API):
       gh secret set ANTHROPIC_API_KEY
     Alternatives: a Claude Pro/Max OAuth token (CLAUDE_CODE_OAUTH_TOKEN via
     `claude setup-token`), or Amazon Bedrock / Google Vertex via OIDC (no static key).
  2. Install the Claude GitHub App on the repo so the action can post review comments:
     run /install-github-app in Claude Code (requires repo admin).
  3. Open a PR from a branch in THIS repo to trigger the review.

Security notes:
  - Reviews SAME-REPO PRs only by default; fork PRs are skipped.
  - Third-party actions are pinned to full commit SHAs.
  - Before enabling fork-PR review, read "Reviewing fork PRs" in the pr-review README
    (update action versions, keep the write-access gate, require human approval).
NEXT

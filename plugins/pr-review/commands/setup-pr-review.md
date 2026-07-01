---
description: Scaffold a security-hardened Claude Code PR-review GitHub Actions workflow
allowed-tools: Bash(bash:*), Bash(gh:*), Bash(git:*)
---

Install the Claude Code review workflow into the current repository:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold-pr-review.sh"
```

Then help the user finish setup:
- confirm the workflow was written to `.github/workflows/claude-code-review.yml`,
- offer to set the API key secret with `gh secret set ANTHROPIC_API_KEY`,
- remind them to install the Claude GitHub App (`/install-github-app`, repo admin),
- summarize the security posture (same-repo PRs only, SHA-pinned actions) and point to
  the `pr-review` skill before enabling fork-PR review.

Do not commit the workflow unless the user asks.

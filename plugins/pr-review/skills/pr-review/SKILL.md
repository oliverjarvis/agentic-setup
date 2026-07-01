---
name: pr-review
description: Use when setting up Claude PR review (CI or local) or handling review comments. Covers the GitHub Action, auth, fork-PR security, local review, and fix loops.
---

# PR review with Claude

## Two paths
- **CI (automated):** the [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions). Run `/setup-pr-review` to scaffold a hardened workflow, or `/install-github-app` (repo admin) for the guided quickstart. The workflow triggers on `pull_request` `[opened, synchronize]` and runs the `code-review` plugin.
- **Local (interactive):** `/code-review` (working diff, effort `low|medium|high|max`, `--comment` to post, `--fix` to apply), `/review <PR#>` for a GitHub PR, `/security-review` for a security pass, `ultra` for a cloud multi-agent review.

## Auth (four options)
- `ANTHROPIC_API_KEY` (direct API, repo secret) [default]
- `CLAUDE_CODE_OAUTH_TOKEN` (Claude Pro/Max, generate with `claude setup-token`)
- Workload Identity Federation (OIDC, no stored secret)
- Amazon Bedrock / Google Vertex (`use_bedrock` / `use_vertex`, OIDC)

## Permissions
- GitHub App: Contents, Issues, Pull requests at Read & write.
- Workflow job: `contents: read`, `pull-requests: write`, `id-token: write` for review; add `contents/issues: write` for PR-creating/triage jobs; `security-events: write` for security workflows.

## Security for fork / untrusted PRs (important)
- Default gate: only users with **write access** can trigger the action. `allowed_non_write_users`/`allowed_bots` are risky bypasses.
- **Never** check out an untrusted ref into the workspace root; avoid `pull_request_target` + head checkout (the "pwn request" that leaks secrets). Check out the base ref, isolate the head via `--add-dir`.
- **Pin** every third-party action to a full commit SHA. Keep `claude-code-action` and `@anthropic-ai/claude-code` updated (real prompt-injection-to-RCE and API-key-exfil CVEs have been patched).
- Require **human approval** via a GitHub `environment:` protection rule before acting on agent output.
- The scaffolded workflow reviews **same-repo PRs only** by default; keep it that way unless the above are all in place.

## Fixing comments
- **Claude's own findings:** `/code-review --fix` applies them to the working tree; then commit and iterate.
- **Human reviewer comments:** run `/address-review [PR#]`. It reads the review threads (`gh` + GraphQL), pushes scoped fixes, replies, and resolves each thread only after the fix is pushed. Evaluate feedback critically (see `receiving-code-review`) rather than implementing blindly.

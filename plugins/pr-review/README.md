# pr-review

Claude-powered pull-request review for Claude Code: a security-hardened CI workflow plus a
guided loop for resolving human reviewer comments.

## Commands
- **`/setup-pr-review`** runs [`scripts/scaffold-pr-review.sh`](scripts/scaffold-pr-review.sh): installs [`templates/claude-code-review.yml`](templates/claude-code-review.yml) into `.github/workflows/` (non-destructive) and prints setup steps.
- **`/address-review [PR#]`** reads a PR's human review threads, pushes scoped fixes, then replies to and resolves each thread (via `gh` + GraphQL).

## Skill
- **`pr-review`** encodes the verified setup, auth, security, and fix-loop guidance (see [`skills/pr-review/SKILL.md`](skills/pr-review/SKILL.md)).

## The scaffolded workflow
- Triggers on `pull_request` `[opened, synchronize]`, runs the `code-review` plugin via `anthropics/claude-code-action`.
- Least-privilege permissions: `contents: read`, `pull-requests: write`, `id-token: write`.
- Third-party actions are **pinned to full commit SHAs** (`actions/checkout` v7.0.0, `claude-code-action` v1).
- Reviews **same-repo PRs only** by default (`head.repo.full_name == github.repository`).

## Setup
1. `gh secret set ANTHROPIC_API_KEY` (or use a Pro/Max OAuth token, or Bedrock/Vertex OIDC).
2. Install the Claude GitHub App: `/install-github-app` (repo admin).
3. Open a same-repo PR to trigger it.

## Reviewing fork PRs
Fork PRs run untrusted code and must not reach repo secrets. Before removing the same-repo
guard: keep the default write-access trigger gate, keep actions SHA-pinned and updated, do
not check out the fork head into the workspace root (isolate it via `--add-dir`), and gate
any agent action behind a GitHub `environment:` approval rule. See the `pr-review` skill.

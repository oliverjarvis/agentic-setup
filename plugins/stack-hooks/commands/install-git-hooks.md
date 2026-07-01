---
description: Generate a stack-aware .pre-commit-config.yaml and install git hooks for this repo
allowed-tools: Bash(bash:*), Bash(pre-commit:*), Bash(git:*), Bash(npx:*)
---

Run the stack-aware git-hook installer for the current repository:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-git-hooks.sh"
```

Then briefly summarize to the user:
- which stacks were detected and which hooks were written,
- whether `pre-commit` was installed or needs installing,
- any project devDependencies they still need (for Node repos: commitlint/eslint/prettier).

Do not commit the generated `.pre-commit-config.yaml` unless the user asks.

---
description: Detect the project stack and scaffold test frameworks + sample tests (unit/integration/e2e)
allowed-tools: Bash(bash:*), Bash(npm:*), Bash(npx:*), Bash(uv:*), Bash(pip:*)
---

Scaffold stack-appropriate tests for the current repository:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold-tests.sh"
```

The script is non-destructive (it skips existing files) and does not install anything.
After it runs:
- summarize which stacks were detected and which files were written,
- show the user the exact install commands the script printed,
- offer to run those install commands and then the test suite.

Consult the `testing-setup` skill for the per-stack rationale and screen-capture options.

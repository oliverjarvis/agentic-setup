# stack-tests

Stack-aware testing setup for Claude Code. Detects the project stack and scaffolds the
right unit/integration/e2e frameworks, plus screenshot and agent-verify tooling. One
plugin, runtime dispatch, no per-stack variants.

## Commands
- **`/scaffold-tests`** runs [`scripts/scaffold-tests.sh`](scripts/scaffold-tests.sh): detects the stack and writes config + a sample test per stack. Non-destructive (skips existing files) and never installs anything; it prints the exact install commands.
- **`/verify-ui`** sets up the agent screenshot/verify loop: Playwright MCP for web (`claude mcp add playwright npx @playwright/mcp@latest`) and simulator capture for mobile (`xcrun simctl io booted screenshot`, `adb exec-out screencap`).

## Skill
- **`testing-setup`** encodes the verified per-stack matrix and screen-capture options (see [`skills/testing-setup/SKILL.md`](skills/testing-setup/SKILL.md)).

## What gets scaffolded per stack
| Stack | Files written | Install |
|-------|---------------|---------|
| TS / Node | `vitest.config.ts` (node or jsdom), `vitest.setup.ts` (web), `src/__tests__/sample.test.ts` | Vitest (+ RTL/jsdom for web) |
| Convex | `vitest.config.ts` (edge-runtime), `convex/example.test.ts` | `vitest convex-test @edge-runtime/vm` |
| Expo / RN | `jest.config.js` (jest-expo), `__tests__/example.test.tsx`, `.maestro/smoke.yaml` | jest-expo + RTL-native; Maestro (e2e runner) |
| Web e2e | `playwright.config.ts` (trace/video/screenshot on failure), `e2e/example.spec.ts` (with `toHaveScreenshot`) | `@playwright/test` + browsers |
| Python | `pytest.ini`, `tests/test_sample.py` | pytest, coverage |
| Swift | `Tests/ExampleTests.swift` (Swift Testing) | swift-snapshot-testing via SPM (manual wiring) |

## Notes
- Convex owns `vitest.config.ts` when present (it requires `environment: 'edge-runtime'`).
- Swift scaffolding is a starting file plus guidance; wiring it into an Xcode/SPM test target is manual.
- Requires `jq` for stack detection (provided by the agentic-setup installer).

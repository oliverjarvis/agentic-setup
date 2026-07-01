---
name: testing-setup
description: Use when setting up or choosing testing frameworks (unit, integration, e2e) and screenshot/visual tooling for any stack. Encodes verified per-stack defaults for TS/React/RN/Expo/Convex, Python, and Swift.
---

# Testing setup (stack-aware)

Pick the default per stack, scaffold unit + integration + e2e, and add screen-capture
where it earns its keep. Run `/scaffold-tests` to write configs and sample tests for the
detected stack; run `/verify-ui` for the agent screenshot/verify loop.

## Tiers
Many fast unit tests, fewer integration tests, few e2e. Lean integration-heavy for UI apps
(most real bugs live at the seams). Treat ratios as guidance, not a hard gate.

## Per-stack defaults

| Stack | Unit / integration | E2E | Notes |
|-------|--------------------|-----|-------|
| **TypeScript / Node** | **Vitest** (default) or Jest | Playwright | Vitest is a near drop-in for the Jest API and shares one Vite pipeline. Coverage via v8. |
| **React (web)** | Vitest + React Testing Library (`jsdom`) + MSW for API mocking | Playwright | Test behavior, not snapshots-of-everything. |
| **React Native / Expo** | `jest-expo` preset + `@testing-library/react-native` | **Maestro** (the e2e runner for RN/Expo) | Maestro drives real flows via YAML in `.maestro/`. Detox is the heavier gray-box alternative. |
| **Convex** | **convex-test** + Vitest (**requires** `@edge-runtime/vm`, `environment: 'edge-runtime'`) | via the app's web/RN e2e | In-memory mock of the backend; for real-backend behavior use the local backend. |
| **Python** | **pytest** (+ coverage.py; hypothesis for property tests) | playwright-python | tox/nox for matrix runs. |
| **Swift** | **Swift Testing** (Xcode 16+) or XCTest | XCUITest | Visual/snapshot via `pointfreeco/swift-snapshot-testing` (SPM, test target only). |

## Screen capture
- **Web visual regression:** Playwright `expect(page).toHaveScreenshot()` (golden baselines, per-browser/per-platform, pixelmatch diff, retries until two consecutive captures match). Generate baselines on a pinned CI image (official Playwright Docker) so local and CI baselines match.
- **Jest projects:** `jest-image-snapshot`. **Self-hosted:** `reg-suit` (bring-your-own S3/GCS). **Hosted:** Chromatic (Storybook) or Percy.
- **iOS/Swift:** `swift-snapshot-testing`.
- **E2E artifacts:** Playwright trace + video + screenshot-on-failure (`trace: 'on-first-retry'`, `video: 'retain-on-failure'`); upload as CI artifacts.
- **Agent verify loop:** Playwright MCP (`claude mcp add playwright npx @playwright/mcp@latest`); it drives the browser via the accessibility tree by default (token-cheap) with `browser_take_screenshot` for pixels. Mobile: `xcrun simctl io booted screenshot out.png` (iOS), `adb exec-out screencap -p > out.png` (Android).

## Stable screenshots
Disable animations, use deterministic seed data, mask dynamic regions (timestamps, avatars), tune diff thresholds, and pin the rendering environment.

---
description: Set up and run an agent-driven UI verification loop (Playwright MCP for web, simulator capture for mobile)
allowed-tools: Bash(claude:*), Bash(xcrun:*), Bash(adb:*), Bash(npx:*)
---

Help the user verify UI changes by actually seeing the running app.

## Web (Playwright MCP)
If the Playwright MCP server is not already configured, add it:

```
claude mcp add playwright npx @playwright/mcp@latest
```

Then, with the app running, drive it via the MCP tools: `browser_navigate` to the page,
`browser_snapshot` (accessibility tree, token-cheap) to inspect, and `browser_take_screenshot`
to capture pixels. Compare against the expected UI and report what you see.

## Mobile (simulator/emulator capture)
- iOS: `xcrun simctl io booted screenshot /tmp/ui.png`
- Android: `adb exec-out screencap -p > /tmp/ui.png`

Capture after the relevant screen is visible, then read the image to verify the change.

## Notes
- Prefer the accessibility snapshot for assertions; use screenshots for visual confirmation.
- For committed visual-regression baselines, use Playwright `toHaveScreenshot()` (see the
  `testing-setup` skill), not this ad-hoc loop.

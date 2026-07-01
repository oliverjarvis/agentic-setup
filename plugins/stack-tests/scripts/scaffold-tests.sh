#!/usr/bin/env bash
#
# scaffold-tests.sh: detect the project stack and scaffold test config + a sample test
# per stack. Non-destructive: existing files are skipped, never overwritten. Does NOT
# install dependencies; it prints the exact install commands to run.

set -uo pipefail

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tags="$(bash "$here/detect-stack.sh" "$dir" 2>/dev/null || true)"
has() { printf '%s\n' "$tags" | grep -qx "$1"; }
pkg_has() { [ -f "$dir/package.json" ] && grep -q "\"$1\"" "$dir/package.json" 2>/dev/null; }

installs=""
add_install() { installs="${installs}
  $1"; }

write_if_absent() { # $1 = relative path; content on stdin
  local p="$dir/$1"
  if [ -e "$p" ]; then printf '  skip (exists): %s\n' "$1"; cat >/dev/null; return; fi
  mkdir -p "$(dirname "$p")"
  cat > "$p"
  printf '  wrote: %s\n' "$1"
}

echo "Detected stacks: ${tags//$'\n'/ }"
[ -n "$tags" ] || { echo "No known stack detected. Nothing to scaffold."; exit 0; }

is_web_node=0
if has node && pkg_has react-dom || pkg_has next || pkg_has vite || pkg_has astro; then is_web_node=1; fi

# ---------------------------------------------------------------------------
# Convex (takes precedence for the Vitest config: it requires edge-runtime)
# ---------------------------------------------------------------------------
if has convex; then
  echo "Convex:"
  write_if_absent "vitest.config.ts" <<'EOF'
import { defineConfig } from 'vitest/config'

// Convex functions run in an edge-like runtime; convex-test needs it inlined.
export default defineConfig({
  test: {
    environment: 'edge-runtime',
    server: { deps: { inline: ['convex-test'] } },
  },
})
EOF
  write_if_absent "convex/example.test.ts" <<'EOF'
import { convexTest } from 'convex-test'
import { expect, test } from 'vitest'
import schema from './schema'
// import { api } from './_generated/api'

test('convex-test smoke', async () => {
  const t = convexTest(schema)
  // Example once you have functions:
  // await t.mutation(api.tasks.create, { text: 'hi' })
  // const tasks = await t.query(api.tasks.list, {})
  // expect(tasks).toHaveLength(1)
  expect(t).toBeDefined()
})
EOF
  add_install "npm i -D vitest convex-test @edge-runtime/vm"
fi

# ---------------------------------------------------------------------------
# TypeScript / Node (Vitest) when Convex did not already own vitest.config.
# Skipped for Expo/RN, which uses the jest-expo preset instead.
# ---------------------------------------------------------------------------
if has node && ! has convex && ! has expo; then
  echo "TypeScript / Node (Vitest):"
  if [ "$is_web_node" = "1" ] || pkg_has react; then
    write_if_absent "vitest.config.ts" <<'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    coverage: { provider: 'v8' },
  },
})
EOF
    write_if_absent "vitest.setup.ts" <<'EOF'
import '@testing-library/jest-dom/vitest'
EOF
    add_install "npm i -D vitest jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event"
  else
    write_if_absent "vitest.config.ts" <<'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: { environment: 'node', globals: true, coverage: { provider: 'v8' } },
})
EOF
    add_install "npm i -D vitest @vitest/coverage-v8"
  fi
  write_if_absent "src/__tests__/sample.test.ts" <<'EOF'
import { describe, it, expect } from 'vitest'

describe('sample', () => {
  it('adds', () => {
    expect(1 + 1).toBe(2)
  })
})
EOF
fi

# ---------------------------------------------------------------------------
# React Native / Expo (jest-expo + RTL; Maestro for e2e)
# ---------------------------------------------------------------------------
if has expo; then
  echo "Expo / React Native (jest-expo + Maestro):"
  write_if_absent "jest.config.js" <<'EOF'
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['@testing-library/react-native/extend-expect'],
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*|@react-navigation/.*))',
  ],
}
EOF
  write_if_absent "__tests__/example.test.tsx" <<'EOF'
import { render, screen } from '@testing-library/react-native'
import { Text } from 'react-native'

test('renders text', () => {
  render(<Text>Welcome</Text>)
  expect(screen.getByText('Welcome')).toBeOnTheScreen()
})
EOF
  write_if_absent ".maestro/smoke.yaml" <<'EOF'
# Maestro e2e flow. Docs: https://maestro.mobile.dev
# Set appId to your app id (from app.json/app.config: expo.ios.bundleIdentifier
# or expo.android.package). Run with: maestro test .maestro/smoke.yaml
appId: com.example.app
---
- launchApp
- assertVisible: "Welcome"
EOF
  add_install "npm i -D jest-expo jest @testing-library/react-native"
  add_install "# Maestro (e2e runner): curl -fsSL https://get.maestro.mobile.dev | bash"
fi

# ---------------------------------------------------------------------------
# Web e2e (Playwright)
# ---------------------------------------------------------------------------
if [ "$is_web_node" = "1" ]; then
  echo "Web e2e (Playwright):"
  write_if_absent "playwright.config.ts" <<'EOF'
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
})
EOF
  write_if_absent "e2e/example.spec.ts" <<'EOF'
import { test, expect } from '@playwright/test'

test('homepage renders and matches snapshot', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot()
})
EOF
  add_install "npm i -D @playwright/test && npx playwright install --with-deps"
fi

# ---------------------------------------------------------------------------
# Python (pytest)
# ---------------------------------------------------------------------------
if has python; then
  echo "Python (pytest):"
  write_if_absent "pytest.ini" <<'EOF'
[pytest]
testpaths = tests
addopts = -q
EOF
  write_if_absent "tests/test_sample.py" <<'EOF'
def test_sample():
    assert 1 + 1 == 2
EOF
  add_install "uv add --dev pytest coverage  # or: pip install pytest coverage"
fi

# ---------------------------------------------------------------------------
# Swift (guidance; scaffolding into an Xcode target is manual)
# ---------------------------------------------------------------------------
if has swift; then
  echo "Swift (Swift Testing + swift-snapshot-testing):"
  write_if_absent "Tests/ExampleTests.swift" <<'EOF'
import Testing

@Test func sample() async throws {
  #expect(1 + 1 == 2)
}
EOF
  echo "  note: add the test file to a test target in Xcode/Package.swift."
  echo "  note: for visual tests add pointfreeco/swift-snapshot-testing via SPM (test target only)."
  add_install "# SPM: add https://github.com/pointfreeco/swift-snapshot-testing to your test target"
fi

echo
echo "Next steps (install what you scaffolded):"
printf '%s\n' "$installs"
echo
echo "Then run your tests (e.g. npx vitest / npx playwright test / pytest / maestro test .maestro/smoke.yaml)."
echo "For agent-driven UI verification, run /verify-ui."

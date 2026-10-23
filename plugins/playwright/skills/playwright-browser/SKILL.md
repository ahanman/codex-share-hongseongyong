---
name: playwright-browser
description: Automate and inspect web pages with the connected Microsoft Playwright MCP server. Use when the user asks to use Playwright for browser interaction, local web app checks, screenshots, or testing a real user flow.
---

# Playwright browser

Use the Playwright MCP tools contributed by this plugin. This personal integration runs Microsoft's official `@playwright/mcp` package with the installed Chrome browser in headless mode.

- Navigate to the requested site and use its current accessibility snapshot to identify targets. Refresh the snapshot after navigation or material UI changes; element references can become stale.
- Use browser screenshots when layout or visual appearance is the subject of the check. Use console and network tools only when they help diagnose the observed problem.
- Follow the user's requested flow and report the behavior actually observed. A successful page load alone does not establish that a complete workflow passed.
- Browser sessions use Playwright's own profile, separate from the user's ordinary Chrome tabs. If a requested site needs authentication, use the site's normal sign-in flow; do not retrieve credentials or cookies from other browser profiles.
- Close the browser when a one-off check is finished unless the user needs the session retained.

Configuration and tool reference: https://github.com/microsoft/playwright-mcp

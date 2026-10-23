---
name: google-flow-browser
description: Use Google Flow, Google's image and video creation service, through a connected browser. Use for Google Flow projects, prompts, media generation, edits, and exports; this does not apply to Workspace Flows or Wispr Flow.
---

# Google Flow browser workflow

This personal skill uses existing browser tools. It does not install or expose an official Google Flow MCP server or a separate Google API.

## Open the correct session

- Open https://flow.google.com/ with the available connected Chrome/browser tools. The older https://labs.google/fx/tools/flow address may redirect there.
- Prefer the user's already authenticated Flow tab. Follow the browser tool's own session and interaction instructions. An available Playwright MCP session is another browser transport, but its separate profile may need a normal sign-in.
- Confirm the displayed account and access status before working. Do not export browser cookies, read tokens from profile files, or move authentication between profiles. If login requires the user's input, leave the normal login page ready for them.

## Work from the live page

- Identify the requested project and operation from the current page. Flow's host, controls, model options, and labels change; use current accessibility snapshots instead of fixed old selectors or undocumented endpoints.
- Read the visible model, duration, aspect ratio, output count, and credit cost relevant to the request. An install or connection check authorizes no media generation or credit spending. For a generation request, stay within the user's requested outputs and spending authorization; clarify any missing material cost limit before a charged action.
- Reuse supplied assets only for their intended task. Use normal browser upload and export controls. Keep account plan changes and purchases outside a media task unless requested.
- Observe the resulting status and output before reporting completion. If the service presents a challenge, rate limit, or access block, report it and use the normal user-assisted flow; do not disguise automation or bypass the block.

Official usage and current access requirements: https://support.google.com/flow/answer/16353333

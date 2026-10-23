---
name: blender-local
description: Create, inspect, and edit local Blender scenes, objects, materials, lighting, and renders through the installed Blender MCP. Use when the user requests work in Blender or a Blender project.
---

Use the plugin's Blender MCP tools to operate the local Blender application. This personal package uses the community `ahujasid/mcp-for-blender` server, not a Blender Foundation integration.

## Connection

- Call `get_scene_info` to confirm the current scene before editing. Blender must be open; its enabled add-on starts the bridge automatically on localhost port 9876.
- If Blender is closed, run the plugin's `scripts/start_blender.ps1`, then retry the scene check. It opens the installed Blender 5.2 LTS and avoids launching another copy when the bridge is already listening.
- If another Blender window owns port 9876, establish which scene the user wants before proceeding. Do not silently edit the wrong window.
- Install Blender and its matching MCP add-on on this computer. The launcher accepts `-BlenderPath` or the `BLENDER_EXECUTABLE` environment variable and otherwise searches PATH and common installation folders.

## Work

- Inspect relevant objects, dimensions, materials, and scene settings before modifying an existing project. Preserve unrelated scene content.
- Prefer focused edits and verify the resulting scene or viewport. Use the node-schema and bpy-reference tools when needed for version-specific APIs.
- Save to the user's requested location. For a new deliverable with no specified path, use the current task workspace and report its absolute path. Preserve an existing project when a separate output is appropriate.
- Safe mode is enabled for `execute_blender_code`; use normal Blender operations and built-in export tools. Do not disable safe mode to bypass a rejected operation. Explain the limitation if a requested operation needs broader access.
- Telemetry is disabled in the MCP environment. Configure the receiving computer's add-on preferences to disable telemetry and optional Poly Haven, Sketchfab, Poly Pizza, Hyper3D, and Hunyuan integrations as well. Local modeling and rendering do not need these services. Enable or use external asset/generation integrations only when the user's actual request calls for them and the relevant account/terms are established.

## Recovery

In Blender, the `MCP for Blender` sidebar controls the connection; Preferences > Add-ons contains its enable switch. Restart Blender after replacing the add-on. The MCP server is pinned at version 2.0.3; its add-on protocol is 9.


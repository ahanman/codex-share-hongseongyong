# Blender personal Codex plugin

This portable wrapper targets Blender 5.2.2 LTS and the community MCP for Blender 2.0.3. Install Blender, Python/uv, and the matching Blender MCP add-on on the receiving computer. This wrapper is a local personal plugin, not an official Blender Foundation plugin.

Configure the Blender MCP add-on to listen only on localhost:9876, then open Blender before using a new Codex task. Codex starts the pinned MCP server through `uvx` from `.mcp.json`; `uvx` must be on PATH and can download the Python 3.12 runtime. No duplicate global MCP entry is required. The optional `scripts/start_blender.ps1` launcher accepts `-BlenderPath` or `BLENDER_EXECUTABLE`.

The server environment disables telemetry and enables MCP script safe mode. Also disable telemetry and optional remote asset integrations in the add-on preferences on the receiving computer. The included `blender-local` skill describes scene inspection, editing, saving, and connection recovery. See `UPSTREAM.json` for the original pinned versions and download hash.

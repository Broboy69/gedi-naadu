# Gedi Nadu

A first-playable, Kerala-inspired Roblox town prototype built with Roblox Luau and Rojo. The environment is generated at runtime from inexpensive, anchored parts; no paid assets or external models are required.

## Project layout

- `default.project.json` — Rojo DataModel project mapping.
- `src/server/GenerateTown.server.lua` — builds the roads, sidewalks, town buildings, public-service buildings, landscaping, signs, lighting, and spawn plaza when the server starts.

## Sync into Roblox Studio

1. Install Rojo and its Roblox Studio plugin, and clone this repository or pull the latest branch on your Windows machine.
2. From the repository folder, run:

   ```powershell
   rojo serve default.project.json
   ```

3. Open a place in Roblox Studio, open the Rojo plugin, and connect it to the local Rojo server. Sync the project; the script appears under `ServerScriptService`.
4. Start a Play or Run session. The server script creates `Workspace.GediNaduGenerated` and places the spawn in Town Square.

The server generates the environment each time the server script runs. Re-running it removes and rebuilds only its generated folder. This repository has not been verified in Roblox Studio as part of this change.

## Scope

This prototype covers the town environment and a basic spawn point. It does **not** yet implement the game's strict whitelist/access-control system, roleplay systems, or persistent data. Those should be added as separate server-side systems before public release.

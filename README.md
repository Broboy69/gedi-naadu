# Gedi Nadu

A procedural Kerala-inspired Roblox roleplay town prototype built with Roblox Luau and Rojo. The environment uses built-in anchored Roblox parts only; there are no paid assets or external models.

## Project layout

- `default.project.json` — Rojo DataModel mapping. `src/server` is synced into `ServerScriptService`, including its nested ModuleScripts.
- `src/server/GenerateTown.server.lua` — preserves the generated-folder cleanup/rebuild flow and configures the town lighting.
- `src/server/Town/Geometry.lua` — shared part, orientation, material, and sign helpers.
- `src/server/Town/BuildingFactory.lua` — wall openings, facade details, interior layouts, stairs, roof forms, and building variants.
- `src/server/Town/Layout.lua` — street network, building placement, plaza, local landmarks, props, and spawn.

## Sync into Roblox Studio

1. Install Rojo and its Roblox Studio plugin. On Windows, fetch and check out the development branch:

   ```powershell
   git fetch origin
   git switch --track origin/arena/39d64a5f-gedi-naadu
   ```

   If you already have that local branch, use `git switch arena/39d64a5f-gedi-naadu` followed by `git pull`.
2. From the repository folder, run:

   ```powershell
   rojo serve default.project.json
   ```

3. Open a place in Roblox Studio, connect the Rojo plugin to the local server, and sync. The bootstrap script and its nested `Town` modules appear under `ServerScriptService`.
4. Start a Play or Run session. The server creates `Workspace.GediNaduGenerated`, including the Town Square spawn, traversable building interiors, and local destinations.

The server script removes and rebuilds only `Workspace.GediNaduGenerated` when it runs. This repository change has not been validated in Roblox Studio; inspect the generated map there before publishing.

## Scope

The town prototype includes cut wall openings, layered façades, varied roofs, balconies and verandas, simple roleplay interiors, shops, a hospital, a police station, roadside details, and a Kavu grove/bus stop. The game's strict whitelist/access-control system, roleplay mechanics, and persistent data are not implemented yet and should be added as separate server-side systems before public release.

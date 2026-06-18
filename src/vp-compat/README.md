# src/vp-compat: Civ V Access / Vox Populi (no-EUI) compatibility mod

## Sintesi (IT)

Questa cartella contiene il mod di compatibilità che fa partire lo stack di
accessibilità di Civ-V-Access sulla mappa principale di Vox Populi no-EUI.
È un mod Civ V (`.modinfo`), non un DLC. Richiede il DLC di Civ-V-Access più
Community Patch e Vox Populi. Vedi `docs/analysis/` per il razionale completo.

## What this is

A Civ V **mod** that boots the Civ-V-Access accessibility stack on the Vox
Populi no-EUI main map (Milestone 1: boot speech, accessible cursor,
keyboard-driven map interaction).

It works by overriding Vox Populi's `WorldView.lua` with a byte-verbatim copy
plus two appended `include` lines, so VP's map logic is preserved and the
accessibility boot runs in the WorldView context.

Full rationale, the rejected DLC approach, and the Milestone 2 plan are in:

- [docs/analysis/initial-recon.md](../../docs/analysis/initial-recon.md)
- [docs/analysis/implementation-strategy.md](../../docs/analysis/implementation-strategy.md)
- [docs/analysis/milestone2-readiness.md](../../docs/analysis/milestone2-readiness.md)

## Contents

- [CivVAccess_VoxPopuli.modinfo](CivVAccess_VoxPopuli.modinfo): the mod
  manifest. Mod id `b6f3bfdd-b0c5-4d20-b2bf-33d6a7ca9aad` (a fresh identity
  minted for this mod). Depends on Community Patch (min 149) and Vox Populi
  (min 17). Four `import="1"` overrides.
- [UI/InGame/WorldView.lua](UI/InGame/WorldView.lua): Vox Populi v17 (5.2.7)
  no-EUI WorldView.lua, byte-verbatim, then banner plus `include("CivVAccess_Boot")`
  and `include("CivVAccess_WorldViewKeys")`.
- [UI/FrontEnd/GameSetupScreen.lua](UI/FrontEnd/GameSetupScreen.lua): Vox Populi
  v17 (5.2.7) no-EUI GameSetupScreen.lua, byte-verbatim, then a pcall bridge
  to `include("CivVAccess_VP_GameSetupAccess")`.
- [UI/FrontEnd/SelectCivilization.lua](UI/FrontEnd/SelectCivilization.lua): Vox
  Populi v17 (5.2.7) no-EUI SelectCivilization.lua, byte-verbatim, then a pcall
  bridge to `include("CivVAccess_SelectCivilizationAccess")` (CVA DLC).
- [UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua](UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua):
  accessibility wrapper for the VP new-game setup screen.

## Prerequisites (runtime)

This mod does **not** contain the accessibility code itself. It boots the code
shipped by Civ-V-Access. All three must be installed and active:

1. **Civ-V-Access** (its fake-DLC payload + proxy), which provides
   `CivVAccess_Boot` and `CivVAccess_WorldViewKeys`. Installed as a DLC, not a
   mod, so it cannot be listed in this manifest's `<Dependencies>`; it is a
   hard runtime requirement.
2. **Community Patch** v149+ (declared dependency).
3. **Vox Populi** v17+ no-EUI (declared dependency).

EUI is out of scope: this override is based on VP's no-EUI WorldView.lua. With
EUI active, EUI's own WorldView.lua would be in play and this mod's assumptions
would not hold.

## Re-syncing WorldView.lua when Vox Populi updates

The override embeds a specific VP version. When VP ships a new WorldView.lua:

1. Replace everything above the `Civ V Access - Vox Populi` banner in
   [UI/InGame/WorldView.lua](UI/InGame/WorldView.lua) with the new VP file's
   full content.
2. Keep the banner and the two `include` lines at the bottom.
3. Recompute the file MD5 and update the `md5` attribute of the `<File>` entry
   in the manifest.
4. Re-run the validator below.

The banner records the source path, the VP version, and the source MD5 so
drift is detectable.

## Validate

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate-vp-compat.ps1
```

`[AUTO]` checks (XML, file resolution, MD5 integrity, import flag,
dependencies, Lua syntax) are proven by the script. `[MANUAL]` items can only
be confirmed in-game and are listed by the script, never auto-passed.

## Deploy

Installs the mod into your Civ V MODS directory:

```powershell
# Standard install (resolves My Documents automatically)
powershell -ExecutionPolicy Bypass -File tools/deploy.ps1

# Custom MODS path (e.g. non-standard install or testing)
powershell -ExecutionPolicy Bypass -File tools/deploy.ps1 -ModsDir "D:\Civ5\MODS"
```

The script:

- Copies `CivVAccess_VoxPopuli.modinfo` and `UI\InGame\WorldView.lua` into
  `<MODS>\civvaccess-voxpopuli\`.
- Derives the MODS path from `My Documents` (no hardcoded user name).
- Verifies MD5 of every deployed file against the source after copy.
- Rolls back to the previous state on any error.
- Is idempotent: re-running with unchanged sources logs `[Unchanged]` and exits 0.
- Logs progress to stderr in `[DEPLOY][LEVEL]` format; the summary goes to stdout.

Prerequisites before running the deploy:

- The [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) DLC must be
  installed separately (it is not deployed by this script).
- Community Patch and Vox Populi (no-EUI) must be installed and active in Civ V.

## Deployment status

Deploy script exists: `tools/deploy.ps1`. DEPLOY-1 closed.

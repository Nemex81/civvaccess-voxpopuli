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
  minted for this mod). Depends on Community Patch (min 150) and Vox Populi
  (min 17). One `import="1"` override.
- [UI/InGame/WorldView.lua](UI/InGame/WorldView.lua): Vox Populi v17's
  no-EUI WorldView.lua, byte-verbatim from line 1 to VP's last line, then an
  appended banner plus `include("CivVAccess_Boot")` and
  `include("CivVAccess_WorldViewKeys")`.

## Prerequisites (runtime)

This mod does **not** contain the accessibility code itself. It boots the code
shipped by Civ-V-Access. All three must be installed and active:

1. **Civ-V-Access** (its fake-DLC payload + proxy), which provides
   `CivVAccess_Boot` and `CivVAccess_WorldViewKeys`. Installed as a DLC, not a
   mod, so it cannot be listed in this manifest's `<Dependencies>`; it is a
   hard runtime requirement.
2. **Community Patch** v150+ (declared dependency).
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

## Deployment status

There is **no deploy script yet**. Installing into a real game requires copying
this folder into the Civ V `MODS` directory (and enabling it after Community
Patch and Vox Populi). Tracked in
[docs/backlog/deployment.md](../../docs/backlog/deployment.md).

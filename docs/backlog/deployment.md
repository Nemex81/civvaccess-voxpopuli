# Backlog: Deployment & repo hygiene / Deploy e igiene del repo

## Sintesi (IT)

Elementi noti non ancora affrontati, registrati per non perderli. Nessuno
blocca l'implementazione statica di Milestone 1; il primo blocca il test
in-game reale.

## DEPLOY-1: No deploy tooling yet

State: not-started. Priority: high (blocks real in-game testing).

The compat mod lives at `src/vp-compat/`. There is no script to install it
into a real Civ V install. Civ-V-Access uses `deploy.ps1` to copy its payload
into the game; this repo has no equivalent.

What is needed (to verify, not yet decided):

- The target install path for mods
  (typically `Documents/My Games/Sid Meier's Civilization 5/MODS/<ModName>/`).
- Whether the mod folder name must follow a `Name (v N)` convention like the
  VP mods, or whether the `.modinfo` id is sufficient.
- Load order: this mod must activate after Community Patch and Vox Populi
  (the declared dependencies should enforce ordering, but confirm in-game).
- The Civ-V-Access DLC must already be installed separately (it is a DLC, not
  a mod, and cannot be deployed by this mod's tooling).

Until this exists, installation is manual and the `[MANUAL]` checks in
`tools/validate-vp-compat.ps1` cannot be exercised.

## DEPLOY-2: README link drift in repo root

State: not-started. Priority: low (navigation only).

The root `README.md` links the milestone docs as
`docs/milestone1-map-layer.md` / `docs/milestone2-vp-screens.md`, but the
files actually live under `docs/design/`. The links are stale.

Not changed as part of Milestone 1 implementation to avoid scope creep; logged
here so it is not lost. Fix is a one-line path correction per link.

## DEPLOY-3: No CHANGELOG yet

State: resolved (CHANGELOG.md created under DEPLOY-1, 2026-06-16).

---

## VP-SETUP-ACCESS-1: GameSetupScreen accessibility wrapper

State: implemented (2026-06-17). Pending in-game validation (MANUAL items).

Task ID: VP-SETUP-ACCESS-1. Milestone 2, first screen.

Files created:
- `src/vp-compat/UI/FrontEnd/GameSetupScreen.lua` — VP v17 verbatim + bridge
- `src/vp-compat/UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua` — wrapper

Dependencies: Milestone 1 validated in-game (boot, cursor, map keys).

In-game validation required before this screen can be considered done:
see `[VP-SETUP-ACCESS-1]` items in `tools/validate-vp-compat.ps1`.

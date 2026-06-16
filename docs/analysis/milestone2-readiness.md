# Milestone 2 Readiness: VP-Rewritten Screens / Prontezza Milestone 2

## Sintesi (IT)

Milestone 2 **non** è ancora in implementazione. Dipende dalla validazione
in-game di Milestone 1. Questo documento registra la proprietà verificata
delle schermate VP no-EUI, il pattern di porting e un backlog per schermata.
Per ogni schermata la superficie reale degli hook va ancora verificata
leggendo il file VP e il wrapper CVA corrispondente: **non inventare**.

## Summary (EN)

Milestone 2 is **not** in implementation yet. It depends on in-game
validation of Milestone 1. This file records verified ownership of the VP
no-EUI screens, the porting pattern, and a per-screen backlog. For each
screen the real hook surface still has to be verified by reading the VP file
and the matching CVA wrapper: **do not invent**.

---

## The Milestone 2 collision

Both CVA and VP override the same in-game screens. CVA overrides them in its
DLC; VP overrides them as mod `import="1"` files. VP's mod imports win the
in-game VFS, so CVA's accessibility hooks on those screens are shadowed and
do not run under VP no-EUI.

The fix is the same pattern as Milestone 1's WorldView seat, applied per
screen:

1. Take VP's no-EUI version of the screen file as the base (verbatim).
2. Re-attach CVA's accessibility surface for that screen (the appended
   `include("CivVAccess_XAccess")` line, or the equivalent wrapper call).
3. Ship it as an additional `<File import="1">` entry in this mod, so our
   copy wins over VP's.

This must proceed **one screen at a time**, each validated before the next.

---

## Verified ownership (no-EUI)

All paths below are mod `import="1"` files. "VP owner" is the last mod in the
load chain that imports the stem; that copy is the active one.

- `CityView.lua`, VP: `(1) Community Patch/LUA/CityView.lua`. CVA counterpart:
  `Civ-V-Access/src/dlc/UI/InGame/CityView/CityView.lua`.
- `UnitPanel.lua`, VP: `(2) Vox Populi/LUA/UnitPanel.lua`.
- `TopPanel.lua`, VP: `(2) Vox Populi/LUA/TopPanel.lua`.
- `NotificationPanel.lua`, VP: `(2) Vox Populi/LUA/NotificationPanel.lua`.
- `TechTree.lua`, VP: present in VP's UI tree; CVA counterpart:
  `Civ-V-Access/src/dlc/UI/TechTree/TechTree.lua`.
- `CityBannerManager.lua`, VP: imported by `(1)` and `(2)`.
- `CityStateDiploPopup.lua`, VP: imported by `(1)` and `(2)`.
- `DiploCorner.lua`, VP: `(1) Community Patch/LUA/DiploCorner.lua`.
- `LeaderHeadRoot.lua`, VP: `(2) Vox Populi/LUA/LeaderHeadRoot.lua`.
- `PlotHelpManager.lua`, VP: imported by `(1)` (and in `(3a)` for EUI).
- `EnemyUnitPanel.lua`, VP: `(1) Community Patch/Core Files/Overrides/EnemyUnitPanel.lua`.

Note: several stems are imported by both `(1)` and `(2)`. The active copy is
whichever loads last (`(2)` after `(1)`). Confirm the winning copy per screen
before basing an override on it.

---

## Per-screen backlog (each item: verify before implementing)

For every screen, the following must be read and recorded before any code:

- the exact VP file that wins the VFS (which mod, which path, which version),
- the CVA wrapper/override for the same screen and the hook surface it
  expects (events, `LuaEvents`, control names, `ContextPtr` callbacks),
- whether VP renamed, removed, or kept each hook,
- the minimal adaptation (re-attach unchanged, update renamed refs, or shim a
  removed surface).

Readiness states: `not-started` (no per-screen research done yet).

- CityView: not-started. High value (city management). CVA wrapper exists.
- UnitPanel: not-started. High value (unit actions). VP-owned in `(2)`.
- TopPanel: not-started. Passive yields/stats announcements.
- NotificationPanel: not-started. High value (notifications).
- TechTree: not-started. CVA override exists; VP-owned too.
- PlotHelpManager: not-started. Hex tile tooltips.
- CityBannerManager: not-started. On-map city banners.
- CityStateDiploPopup: not-started. City-state diplomacy.
- DiploCorner / DiploList: not-started. Diplomacy entry points.
- LeaderHeadRoot: not-started. Leader/diplomacy screen.
- EnemyUnitPanel: not-started. Enemy unit inspection.

---

## Blockers / preconditions

- Milestone 1 must be validated in-game first (boot, cursor, map keys, no
  regression). Until then, M2 porting cannot be trusted to load at all.
- The cross-source include resolution and mod-vs-DLC VFS precedence assumed by
  Milestone 1 must hold; M2 relies on the same mechanism for every screen.
- Per-screen hook surfaces are **not** yet verified. No M2 screen should be
  implemented from assumption; read the VP file and the CVA wrapper first.

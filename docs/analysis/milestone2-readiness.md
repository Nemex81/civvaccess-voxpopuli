# Milestone 2 Readiness: VP-Rewritten Screens / Prontezza Milestone 2

## Sintesi (IT)

Milestone 2 è iniziato con una schermata stretta e verificata:
`GameSetupScreen` (setup nuova partita / “Imposta partita”). Il resto di
Milestone 2 dipende ancora dalla validazione in-game di Milestone 1 e va
affrontato una schermata alla volta. Questo documento registra la proprietà
verificata delle schermate VP no-EUI, il pattern di porting e un backlog per
schermata. Per ogni schermata la superficie reale degli hook va ancora
verificata leggendo il file VP e il wrapper CVA corrispondente: **non inventare**.

## Summary (EN)

Milestone 2 has started with one narrow verified screen: `GameSetupScreen`
(new-game setup / “Set up game”). The rest of Milestone 2 still depends on
Milestone 1 in-game validation and must proceed one screen at a time. This
file records verified ownership of the VP no-EUI screens, the porting pattern,
and a per-screen backlog. For each screen the real hook surface still has to
be verified by reading the VP file and the matching CVA wrapper: **do not
invent**.

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

### GameSetupScreen — implemented (VP-SETUP-ACCESS-1, 2026-06-17)

- **Ipotesi B confirmed**: VP overrides `GameSetupScreen.lua` with `import="1"`.
  VP file: `Community-Patch-DLL/(2) Vox Populi/Core Files/Overrides/GameSetupScreen.lua`.
  MD5 `01E57106E3DF3EB96388222C9BA34D1A`.
- **CVA reference**: `Civ-V-Access/src/dlc/UI/FrontEnd/CivVAccess_GameSetupScreenAccess.lua`.
  VP uses the **same** Controls.* and global function names as the base game,
  so the CVA pattern applies without renaming.
- **Files created**:
  - `src/vp-compat/UI/FrontEnd/GameSetupScreen.lua` — VP v17 verbatim + bridge
    include. MD5 `778BD07203D3309A15A3D08C9356024C`.
  - `src/vp-compat/UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua` — accessibility
    wrapper. MD5 `D85BCFF2B6CF188D07D3FF7B29D664D5`.
- **Controls covered** (buildItems, 12 items):
  CivilizationButton, EditButton, RemoveButton, MapTypeButton, ScenarioCheck
  (LoadScenarioBox visibility), MapSizeButton, DifficultyButton, GameSpeedButton,
  RandomizeButton, AdvancedButton, BackButton, StartButton.
- **Child Context coverage**: `SelectCivilization`, `SelectMapType`,
  `SelectMapSize`, `SelectDifficulty`, `SelectGameSpeed`, and `SetCivNames`
  have dedicated Civ-V-Access front-end wrappers. VP's parent screen opens
  those vanilla child Contexts; runtime confirmation remains a MANUAL item.
- **Two Contexts, one stem (modding flow)**: the same `GameSetupScreen` stem
  backs two front-end Contexts. `GameSetupScreen` is reached from Main Menu →
  Single Player; `ModdingGameSetupScreen` is reached from Mods → Next → Single
  Player → Play Map and is declared as a `<LuaContext FileName="Assets/UI/
  FrontEnd/GameSetup/GameSetupScreen" ID="ModdingGameSetupScreen">` inside
  `ModsSinglePlayer.xml`. With VP active, the only reachable path is the modding
  one. Our override carries the bridge `include`, and the wrapper installs
  context-agnostically (no `bIsModding` / `ContextPtr:GetID()` gate), so both
  Contexts are covered by the single `GameSetupScreen.lua` override. The mods-
  flow screens themselves (`ModsMenu`, `ModsSinglePlayer`) are not overridden
  by VP, so Civ-V-Access keeps covering them.
- **Controls NOT covered by this task** (not in VP GameSetupScreen; live in the
  AdvancedSetup popup): EraPullDown, MinorCivsSlider, MaxTurnsCheck,
  MaxTurnsEdit, AI player slots, victory conditions, and game options. The
  Advanced button should open the popup for sighted players, but the popup is
  not yet vocalized by this compatibility layer. Track as `VP-ADVANCEDSETUP-1`.
- **Hardcoded VP strings**: none. VP uses `Locale.ConvertTextKey` for all its UI
  text. `VP_TRANS` table is intentionally empty.
- **FALLBACK_STRINGS**:
  - `TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP`: en "Set up game" / it "Configura partita"
- **Blockers for in-game validation** (MANUAL items):
  - setup screen announces name on open
  - CivilizationButton announced correctly on screen open
  - keyboard navigation covers all 12 controls
  - map type / difficulty / speed buttons read current values
  - Start Game and Back buttons reachable via keyboard
  - Advanced button opens AdvancedSetup for sighted players, with no speech yet
  - no regression for sighted players
  - strings spoken in active language (it_IT/en_US)

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

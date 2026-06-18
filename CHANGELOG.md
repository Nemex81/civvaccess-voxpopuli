# Changelog

All notable changes to civvaccess-voxpopuli are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [Unreleased]

### Added

- SelectCivilization popup: spoken label for each civ now includes unique
  ability, unique unit, unique building, and unique improvement alongside
  leader and civ name. (VP-SELECTCIV-RICHLABEL-1)
- SelectCivilization popup: navigazione da tastiera con ↑/↓ e vocalizzazione
  di leader, civiltà e tratto unico per ogni voce. Seleziona con Invio.
  (VP-SELECT-CIV-1)
- `tools/deploy.ps1`: idempotent deploy script with MD5 verification and
  rollback for copying the mod into the Civ V MODS folder from any Windows
  Documents path. Supports `-ModsDir` override. Closes DEPLOY-1.
- `src/vp-compat/UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua`: accessibility
  wrapper for the VP no-EUI "Set up game" screen; keyboard-navigable spoken
  menu with 12 controls (civilization, map type, map size, difficulty, game
  speed, randomize, advanced, edit/remove civ name, scenario checkbox, back,
  start) announced in Italian and English. (VP-SETUP-ACCESS-1)
- `src/vp-compat/UI/FrontEnd/GameSetupScreen.lua`: VP v17 no-EUI verbatim copy
  with appended include bridge; overrides VP's VFS entry so the accessibility
  wrapper loads. (VP-SETUP-ACCESS-1)
- `test.ps1`: static test suite (14 checks: sentinel, BaseMenu.install call,
  hard guard, onShow locale, TickPump deferred, priorShowHide/priorInput,
  bridge include, 4 deploy files, 2 validator references, full AUTO suite via
  validate-vp-compat.ps1 delegation).

### Changed

- `tools/deploy.ps1`: added `UI/FrontEnd/GameSetupScreen.lua` and
  `UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua` to the deploy file list;
  script now copies all 4 mod files (modinfo, WorldView.lua, GameSetupScreen.lua,
  CivVAccess_VP_GameSetupAccess.lua) with existing MD5 verification, snapshot,
  and rollback behaviour unchanged. (VP-SETUP-ACCESS-1)
- `README.md` and `docs/analysis/milestone2-readiness.md`: documented the
  Vox Populi new-game setup coverage, child Context strategy, and the known
  AdvancedSetup popup limitation. (VP-SETUP-ACCESS-1)
- `docs/analysis/milestone2-readiness.md`: documented that the single
  `GameSetupScreen.lua` override covers both setup Contexts — the Main Menu
  path (`GameSetupScreen`) and the Mods path (`ModdingGameSetupScreen`,
  declared as a LuaContext in `ModsSinglePlayer.xml`). With Vox Populi active
  the Mods path is the only reachable one. (VP-SETUP-ACCESS-1)
- `tools/validate-vp-compat.ps1`: added an AUTO check that the setup wrapper
  installs context-agnostically (no `bIsModding` / `ContextPtr:GetID()` gate,
  so it covers both setup Contexts) and 3 MANUAL items for the
  Mods -> Next -> Single Player -> Play Map path. (VP-SETUP-ACCESS-1)
- `tools/validate-vp-compat.ps1`: added AUTO checks for deploy.ps1 presence
  and `-ModsDir` parameter declaration (Ciclo B, DEPLOY-1); added 8 AUTO checks
  for GameSetupScreen.lua and CivVAccess_VP_GameSetupAccess.lua (path, import
  flag, MD5, include stem, sentinel flag); added 8 MANUAL items for in-game
  validation of the setup screen; added 1 OUT-OF-SCOPE-M2 MANUAL item for
  AdvancedSetup popup. (VP-SETUP-ACCESS-1)

### Fixed

- `src/vp-compat/UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua` (PUNTO A):
  confirmed `OnAdvanced` is the exact callback name registered by VP for
  AdvancedButton — no rename required; item 10 activate is correct.
  (VP-SETUP-ACCESS-1-FIX)
- `src/vp-compat/UI/FrontEnd/CivVAccess_VP_GameSetupAccess.lua` (PUNTO B):
  replaced `labelFn = labelFromControl("StartButton")` with
  `textKey = "TXT_KEY_START_GAME"` for item 12; `GridButton:GetText()` is not
  documented in the Civ V Lua API and cannot be guaranteed at runtime. The WB
  scenario dynamic label (TXT_KEY_START_SCENARIO) is out of scope for M2 and
  tracked under VP-ADVANCEDSETUP-1. (VP-SETUP-ACCESS-1-FIX)
- `tools/validate-vp-compat.ps1` (PUNTO C): added `[OUT-OF-SCOPE-M2]` MANUAL
  item noting the AdvancedSetup popup is not yet vocalized, tracked as
  VP-ADVANCEDSETUP-1. (VP-SETUP-ACCESS-1-FIX)
- Configuring a game via Mods → Single Player → Play Map now announces the
  screen name and exposes all setup controls to keyboard navigation.
  (VP-SETUP-ACCESS-FIX)

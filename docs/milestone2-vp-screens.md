# Milestone 2 — VP-Rewritten Screens / Schermate Riscritte da VP

## EN — Objective

Port Civ-V-Access accessibility hooks to all UI screens rewritten by Vox Populi no-EUI, restoring TTS, navigation, and keyboard commands for each screen.

## IT — Obiettivo

Portare i hook di accessibilità di Civ-V-Access su tutte le schermate UI riscritte da Vox Populi no-EUI, ripristinando TTS, navigazione e comandi da tastiera per ogni schermata.

---

## Screens in scope / Schermate in scope

All files rewritten by VP in `(1) Community Patch/LUA/`:

- `CityView.lua` — City management screen
- `CityBannerManager.lua` — City banners on the map
- `CityStateDiploPopup.lua` — City-state diplomacy popup
- `DiploCorner.lua` / `DiploList.lua` — Diplomacy corner and leader list
- `LeaderHeadRoot.lua` — Leader screen
- `NotificationPanel.lua` — Notifications panel
- `PlotHelpManager.lua` — Hex tile tooltips
- `ProductionPopup.lua` — Production popup
- `TechPopup.lua` / `TechTree.lua` — Tech popup and tech tree
- `TopPanel.lua` — Top panel (resources and stats)
- `UnitPanel.lua` — Unit panel

---

## Approach / Approccio

**EN** For each screen, verify whether Civ-V-Access hooks (events, `LuaEvents`) still exist in the VP-rewritten version. If hooks are present but renamed, update references in the compat layer. If hooks are removed, implement a shim that re-exposes the expected surface. Each screen is a separate issue.

**IT** Per ogni schermata, verificare se gli hook di Civ-V-Access (eventi, `LuaEvents`) esistono ancora nella versione riscritta da VP. Se gli hook ci sono ma rinominati, aggiornare i riferimenti nel layer compat. Se rimossi, implementare uno shim che ri-esponga la superficie attesa. Ogni schermata è un'issue separata.

---

## Dependency / Dipendenza

Milestone 2 depends on Milestone 1 being complete and tested.

Milestone 2 dipende dal completamento e test di Milestone 1.

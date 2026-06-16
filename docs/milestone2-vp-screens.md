# Milestone 2 — VP-Rewritten Screens / Schermate Riscritte da VP

## EN — Objective

Port Civ-V-Access accessibility hooks to all UI screens rewritten by Vox Populi no-EUI, restoring TTS, navigation, and keyboard commands for each screen.

## IT — Obiettivo

Portare i hook di accessibilità di Civ-V-Access su tutte le schermate UI riscritte da Vox Populi no-EUI, ripristinando TTS, navigazione e comandi da tastiera per ogni schermata.

---

## Dependency / Dipendenza

Milestone 2 depends on Milestone 1 being complete and tested.

Milestone 2 dipende dal completamento e test di Milestone 1.

---

## Screens in scope / Schermate in scope

All files rewritten by VP in [`(1) Community Patch/LUA/`](https://github.com/CIVITAS-John/vox-populi/tree/master/(1)%20Community%20Patch/LUA):

- [`CityView.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/CityView.lua) — City management screen
- [`CityBannerManager.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/CityBannerManager.lua) — City banners on the map
- [`CityStateDiploPopup.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/CityStateDiploPopup.lua) — City-state diplomacy popup
- [`DiploCorner.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/DiploCorner.lua) / [`DiploList.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/DiploList.lua) — Diplomacy corner and leader list
- [`LeaderHeadRoot.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/LeaderHeadRoot.lua) — Leader screen
- [`NotificationPanel.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/NotificationPanel.lua) — Notifications panel
- [`PlotHelpManager.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/PlotHelpManager.lua) — Hex tile tooltips
- [`ProductionPopup.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/ProductionPopup.lua) — Production popup
- [`TechPopup.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/TechPopup.lua) / [`TechTree.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/TechTree.lua) — Tech popup and tech tree
- [`TopPanel.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/TopPanel.lua) — Top panel (resources and stats)
- [`UnitPanel.lua`](https://github.com/CIVITAS-John/vox-populi/blob/master/(1)%20Community%20Patch/LUA/UnitPanel.lua) — Unit panel

---

## Approach / Approccio

**EN** For each screen, verify whether Civ-V-Access hooks (events, `LuaEvents`) still exist in the VP-rewritten version. If hooks are present but renamed, update references in the compat layer. If hooks are removed, implement a shim that re-exposes the expected surface. Each screen is a separate issue.

**IT** Per ogni schermata, verificare se gli hook di Civ-V-Access (eventi, `LuaEvents`) esistono ancora nella versione riscritta da VP. Se gli hook ci sono ma rinominati, aggiornare i riferimenti nel layer compat. Se rimossi, implementare uno shim che ri-esponga la superficie attesa. Ogni schermata è un'issue separata.

---

## External References / Riferimenti Esterni

- **Civ-V-Access** — https://github.com/rashadnaqeeb/Civ-V-Access
- **Vox Populi (Community Patch Project)** — https://github.com/CIVITAS-John/vox-populi
- **VP no-EUI screens folder** — https://github.com/CIVITAS-John/vox-populi/tree/master/(1)%20Community%20Patch/LUA
- **VP EUI compat reference** — https://github.com/CIVITAS-John/vox-populi/tree/master/(3a)%20VP%20-%20EUI%20Compatibility%20Files

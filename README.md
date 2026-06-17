# civvaccess-voxpopuli

**EN** | Accessibility mod for Civilization V — Vox Populi (no-EUI), built on [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) tools. Renders the VP gameplay experience fully accessible to blind players using NVDA, JAWS, VoiceOver, or TalkBack.

**IT** | Mod di accessibilità per Civilization V — Vox Populi (no-EUI), costruita sugli strumenti di [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access). Rende l'esperienza di gioco VP completamente accessibile ai giocatori non vedenti che utilizzano NVDA, JAWS, VoiceOver o TalkBack.

---

## Requirements / Requisiti

**EN**
- Civilization V: Brave New World
- [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) — installed and active
- [Vox Populi (Community Patch Project)](https://github.com/CIVITAS-John/vox-populi) — no-EUI variant, installed and active

**IT**
- Civilization V: Brave New World
- [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) — installato e attivo
- [Vox Populi (Community Patch Project)](https://github.com/CIVITAS-John/vox-populi) — variante no-EUI, installato e attivo

---

## Project Milestones / Milestone del Progetto

### Milestone 1 — Map Accessibility Layer (Layer 1)

**EN** Inject the Civ-V-Access accessibility stack into the VP no-EUI `WorldView` context. Restores TTS, accessible cursor, and keyboard commands on the main game map.

**IT** Iniettare il sistema di accessibilità di Civ-V-Access nel Context `WorldView` di VP no-EUI. Ripristina TTS, cursore accessibile e comandi da tastiera sulla finestra principale della mappa.

See: [`docs/milestone1-map-layer.md`](docs/milestone1-map-layer.md)

### Milestone 2 — VP-Rewritten Screens (Layer 2)

**EN** Port Civ-V-Access accessibility to the VP-rewritten UI screens: `CityView`, `UnitPanel`, `TopPanel`, `NotificationPanel`, `TechTree`, and others.

**IT** Portare l'accessibilità di Civ-V-Access sulle schermate riscritte da VP: `CityView`, `UnitPanel`, `TopPanel`, `NotificationPanel`, `TechTree` e altre.

See: [`docs/milestone2-vp-screens.md`](docs/milestone2-vp-screens.md)

---

## Supported Screens / Schermate supportate

**EN**

- Main map: Milestone 1 boot and keyboard layer are statically validated; in-game checks remain tracked by `tools/validate-vp-compat.ps1`.
- Vox Populi no-EUI new-game setup (`GameSetupScreen`, shown as “Set up game” / “Imposta partita”): a same-Context bridge loads `CivVAccess_VP_GameSetupAccess.lua` and exposes a spoken keyboard menu for civilization, custom-name edit/remove, map type, scenario checkbox, map size, difficulty, game speed, randomize, advanced, back, and start.
- The setup wrapper hard-guards on the Civ-V-Access front-end chain (`BaseMenu`, `BaseMenuItems`, `SpeechPipeline`, `Log`). If that chain is unavailable, it exits before installing handlers so sighted players keep the original VP screen.

Known limit: the Advanced Setup popup opened by the Advanced button is not yet vocalized by this compatibility layer. It should still open for sighted players; accessibility work is tracked as `VP-ADVANCEDSETUP-1`.

**IT**

- Mappa principale: il boot e il layer tastiera del Milestone 1 sono validati staticamente; i controlli in-game restano tracciati da `tools/validate-vp-compat.ps1`.
- Setup nuova partita Vox Populi no-EUI (`GameSetupScreen`, “Set up game” / “Imposta partita”): un bridge nello stesso Context carica `CivVAccess_VP_GameSetupAccess.lua` e crea un menu parlato navigabile da tastiera per civiltà, modifica/annulla nome, tipo mappa, scenario, dimensione mappa, difficoltà, velocità, casuale, avanzate, indietro e avvia.
- Il wrapper del setup usa un hard guard sulla catena front-end di Civ-V-Access (`BaseMenu`, `BaseMenuItems`, `SpeechPipeline`, `Log`). Se la catena non è disponibile, esce prima di installare handler e lascia invariata la schermata VP per i giocatori vedenti.

Limite noto: il popup Impostazioni avanzate aperto dal pulsante Avanzate non è ancora vocalizzato da questo layer. Deve comunque aprirsi per i giocatori vedenti; il lavoro di accessibilità è tracciato come `VP-ADVANCEDSETUP-1`.

---

## Architecture / Architettura

**EN** This mod is a standalone compatibility layer. It does **not** modify Civ-V-Access or Vox Populi files. It follows the same pattern as VP's `(3a) VP - EUI Compatibility Files`.

**IT** Questa mod è un layer di compatibilità autonomo. Non modifica i file di Civ-V-Access né quelli di Vox Populi. Segue lo stesso pattern di `(3a) VP - EUI Compatibility Files` di VP.

---

## External References / Riferimenti Esterni

- **Civ-V-Access** (base accessibility mod / mod di accessibilità base)
  https://github.com/rashadnaqeeb/Civ-V-Access

- **Vox Populi (Community Patch Project)**
  https://github.com/CIVITAS-John/vox-populi

---

## License / Licenza

MIT — see [LICENSE](LICENSE)

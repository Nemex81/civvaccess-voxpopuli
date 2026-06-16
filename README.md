# civvaccess-voxpopuli

**EN** | Accessibility mod for Civilization V — Vox Populi (no-EUI), built on [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) tools. Renders the VP gameplay experience fully accessible to blind players using NVDA, JAWS, VoiceOver, or TalkBack.

**IT** | Mod di accessibilità per Civilization V — Vox Populi (no-EUI), costruita sugli strumenti di [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access). Rende l'esperienza di gioco VP completamente accessibile ai giocatori non vedenti che utilizzano NVDA, JAWS, VoiceOver o TalkBack.

---

## Requirements / Requisiti

**EN**
- Civilization V: Brave New World
- [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) installed and active
- Vox Populi (Community Patch Project) no-EUI installed and active

**IT**
- Civilization V: Brave New World
- [Civ-V-Access](https://github.com/rashadnaqeeb/Civ-V-Access) installato e attivo
- Vox Populi (Community Patch Project) no-EUI installato e attivo

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

## Architecture / Architettura

**EN** This mod is a standalone compatibility layer. It does **not** modify Civ-V-Access or Vox Populi files. It follows the same pattern as VP's `(3a) VP - EUI Compatibility Files`.

**IT** Questa mod è un layer di compatibilità autonomo. Non modifica i file di Civ-V-Access né quelli di Vox Populi. Segue lo stesso pattern di `(3a) VP - EUI Compatibility Files` di VP.

---

## License / Licenza

MIT — see [LICENSE](LICENSE)

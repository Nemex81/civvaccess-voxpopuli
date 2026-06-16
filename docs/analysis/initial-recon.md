# Initial Recon: Milestone 1 / Ricognizione Iniziale

## Sintesi (IT)

Ricognizione completa dei tre repository prima di scrivere codice. Questo
documento elenca i file letti, i fatti verificati, le assunzioni del design
doc che si sono rivelate **errate**, le domande aperte e i rischi.

Risultato chiave: il design doc di Milestone 1 si basa su una premessa
sbagliata. Vox Populi **sovrascrive** `WorldView.lua` (nel mod `(2) Vox
Populi`), quindi la strategia corretta è un **mod** di compatibilità (come
`(3a) VP - EUI Compatibility Files`), non un pacchetto DLC `.Civ5Pkg`.

## Summary (EN)

Full read-before-write recon across the three workspace repositories. This
file records the files actually read, the verified facts, the design-doc
assumptions that proved **false**, the open questions, and the risks.

Key result: the Milestone 1 design doc rests on a false premise. Vox Populi
**does** override `WorldView.lua` (in the `(2) Vox Populi` mod), so the
correct strategy is a compatibility **mod** (like `(3a) VP - EUI
Compatibility Files`), not a DLC `.Civ5Pkg` package.

---

## Files read

### civvaccess-voxpopuli (working repo)

- `README.md`
- `docs/todo.md` (empty)
- `docs/design/milestone1-map-layer.md`
- `docs/design/milestone2-vp-screens.md`
- `.github/copilot-instructions.md`
- `docs/plans/`, `docs/reports/`, `docs/todolist/` (all empty)
- No `src/` directory exists yet.

Note: `README.md` and the milestone docs link to `docs/milestone1-map-layer.md`,
but the files actually live under `docs/design/`. Minor doc-link drift.

### Civ-V-Access (read-only reference)

- `src/dlc/CivVAccess_0.Civ5Pkg`, `CivVAccess_1.Civ5Pkg`, `CivVAccess_2.Civ5Pkg`
- `src/dlc/UI/InGame/CivVAccess_Boot.lua`
- `src/dlc/UI/InGame/WorldView/WorldView.lua` (boot seat, full BNW copy + includes)
- `src/dlc/UI/InGame/CivVAccess_WorldViewKeys.lua`
- `stylua.toml`, `.luacheckrc`
- Directory listings of `src/dlc/UI/` and `src/dlc/UI/InGame/`.

### Community-Patch-DLL (read-only reference, Vox Populi)

- `Expansion2_VoxPopuli.Civ5Pkg`, `Expansion2_Base.Civ5Pkg` (root)
- `(1) Community Patch/(1) Community Patch (v 150).modinfo`
- `(2) Vox Populi/(2) Vox Populi (v 17).modinfo`
- `(3a) VP - EUI Compatibility Files/(3a) VP - EUI Compatibility Files (v 1).modinfo`
- `(2) Vox Populi/Core Files/Overrides/WorldView.lua` (the active no-EUI WorldView)
- Directory listings of `(1) Community Patch/Core Files/Overrides/`,
  `(2) Vox Populi/Core Files/Overrides/`, `UI_bc1/`.
- `.modinfo` EntryPoint survey across all VP mods.

---

## Verified facts

### Civ-V-Access (CVA) packaging

- Three sibling manifests share one GUID
  `{40A9DF7B-AE9F-48DB-ABB5-44AFE0420524}`.
- Priorities: `_0` = 050 (BaseGame), `_1` = 150 (Expansion1), `_2` = 250
  (Expansion2). Only `_2` carries the functional payload plus
  `<SteamApp>235580</SteamApp>` and `<Key>bf6d34a0074b7ad4b1d1716475f7f7fe</Key>`
  for multiplayer lobby visibility.
- `_0` and `_1` are CTD-prevention sentinels pointing at empty
  `UI/SkinProbeBase` / `UI/SkinProbeG` directories.
- `_2` `<GameplaySkin>` declares: `UI/InGame`, `UI/Options`, `UI/Shared`,
  `UI/TechTree`.

### CVA boot seat

- The boot seat is `UI/InGame/WorldView/WorldView.lua`: a **verbatim copy of
  BNW's** WorldView.lua with two lines appended at the bottom:
  `include("CivVAccess_Boot")` then `include("CivVAccess_WorldViewKeys")`.
- WorldView is chosen because it **re-initialises on load-game-from-game**,
  whereas TaskList (the original seat) does not. A fresh `LoadScreenClose`
  listener must be re-registered on every WorldView include.
- `CivVAccess_Boot.lua` is a long `include(...)` chain that loads every mod
  module, then defers in-game work to `Events.LoadScreenClose`.
- `CivVAccess_WorldViewKeys.lua` captures `basePriorInput = InputHandler`
  (a **global**) and re-registers a wrapper via `ContextPtr:SetInputHandler`
  that dispatches through HandlerStack first, falling through to the base
  handler on a miss. It is generic: it wraps whatever `InputHandler` global
  is live when it runs.

### Vox Populi (VP) packaging and WorldView

- VP ships as **Steam Workshop mods** with `.modinfo` manifests:
  `(1) Community Patch` (id `d1b6328c-ff44-4b0d-aad7-c657f83610cd`, v150),
  `(2) Vox Populi` (id `8411a7a8-dad3-4622-a18e-fcc18324c799`, v17), plus
  optional `(3a)`, `(4a)`, etc.
- `(2) Vox Populi` declares `<Dependencies>` on `(1) Community Patch`.
- VP **does** override `WorldView.lua`. Both `(1)` and `(2)` import it with
  `import="1"`:
  - `(1) Community Patch/Core Files/Overrides/WorldView.lua` (+ `.xml`)
  - `(2) Vox Populi/Core Files/Overrides/WorldView.lua`
- Because `(2)` depends on `(1)` and loads after it, `(2)`'s WorldView.lua is
  the **active** no-EUI version.
- `(2)`'s WorldView.lua is a **heavily modified** BNW derivative (header:
  "modified by bc1 from 1.0.3.144 brave new world code"; sub-visibility fix;
  Squads / Route Planner hooks). It is **not** a verbatim BNW copy. ~1258
  lines. It defines `function InputHandler( uiMsg, wParam, lParam )` as a
  **global** and registers it via `ContextPtr:SetInputHandler( InputHandler )`.
- VP's root `Expansion2_VoxPopuli.Civ5Pkg` / `Expansion2_Base.Civ5Pkg` use
  GUID `{6DA07636-4123-4018-B643-6575B4EC336B}` (BNW's Expansion2 identity)
  at Priority 200. These are the modpack/DLC build artifacts; the live UI
  overrides reach the game through the mod `import="1"` path above.

### Verified compat-layer reference: `(3a)`

- `(3a) VP - EUI Compatibility Files` is a **mod** that:
  - declares `<Dependencies>` on `(1)` (v150) and `(2)` (v17),
  - overrides VP/EUI UI `.lua`/`.xml` files via `import="1"`,
  - uses `<OnModActivated><UpdateDatabase>` for text/DB only.
- This is the canonical pattern for layering accessibility/compat changes on
  top of VP: a dependent mod whose imported files win the in-game VFS.

### EntryPoints

- `InGameUIAddin` EntryPoints are real and used by `(1) Community Patch`
  (Destination.lua, EventPopup.lua, ...) and `(4a) Squads for VP`
  (`UI/Squads.xml`). This is a verified way to add a **new** in-game context
  without overriding a file.

---

## Disproven assumptions (design doc corrections)

1. **"Vox Populi no-EUI does not override WorldView.lua."** FALSE. VP
   overrides it in `(1)` and `(2)`. The design doc checked `UI_bc1/Core/`,
   which is the **EUI** UI tree (`UI_bc1` ships `EUI_0/1/2.Civ5Pkg`), not the
   no-EUI path. The no-EUI override is under the mod folders'
   `Core Files/Overrides/`.

2. **"A new package with Priority > 250 re-declaring `UI/InGame/` will win."**
   UNSAFE / likely FALSE for a real VP install. VP's WorldView.lua reaches
   the game as a mod `import="1"` file, which overrides DLC-provided files in
   the in-game VFS. A DLC at any priority would be shadowed by VP's
   mod-imported WorldView.lua. The verified compat reference `(3a)` is a mod,
   not a DLC.

3. **"WorldView.lua containing only `include('CivVAccess_Boot')`."** UNSAFE.
   Overriding WorldView replaces the whole file. A stub would delete VP's map
   logic (camera, interface modes, path preview, Squads/Route Planner). The
   override must carry VP's full WorldView.lua content plus the appended
   includes, exactly as CVA carries BNW's full content.

---

## Open questions / items requiring in-game validation

> **DEPLOY-1 resolved.** `tools/deploy.ps1` was created with idempotent copy,
> MD5 post-copy verification, rollback, and `-ModsDir` override. Static checks
> pass (validator confirms deploy.ps1 exists and declares `-ModsDir`).
> In-game validation items below remain open until the maintainer runs the game.

- **Cross-source include resolution.** `include("CivVAccess_Boot")` must
  resolve from CVA's DLC VFS while called from a mod-imported WorldView.lua.
  This is expected (the in-game VFS indexes by bare stem across DLC + mods),
  but it is not provable by static inspection. Validate in-game via the boot
  probe line in `Lua.log`.
- **Mod-vs-DLC VFS precedence.** Strongly implied by `(3a)` overriding
  DLC-provided UI and by the observed "boot does not fire" symptom, but the
  precise precedence rule is not documented in these files. Validate that our
  mod's WorldView.lua wins over both VP's and CVA's.
- **Load order.** Our mod must load after `(2) Vox Populi`. Dependency
  declaration is expected to enforce this; confirm in-game.
- **VP module compatibility.** CVA modules target BNW. VP is BNW-based, but
  some CVA features may touch APIs VP changed. Milestone 1 covers boot +
  cursor + map keys; broader features belong to Milestone 2 validation.

---

## Risks

- **VP version coupling.** Our WorldView.lua is a copy of `(2) Vox Populi`
  v17 (md5 `7BE13F5850CCAE290717C9717AA8C0D2`). When VP updates WorldView.lua,
  our copy goes stale and must be re-synced, or the map will behave like the
  old VP version. Provenance is recorded in the file header so drift is
  detectable.
- **Silent boot failure.** If the include does not resolve or the mod does not
  win the VFS, boot fails silently with no speech. The boot probe logs to
  `Lua.log` only when `LoggingEnabled=1`; document this in the install notes.

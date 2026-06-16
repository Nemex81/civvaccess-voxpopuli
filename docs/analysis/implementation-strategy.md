# Implementation Strategy: Milestone 1 / Strategia di Implementazione

## Sintesi (IT)

Il layer di compatibilità è un **mod** di Civ V (file `.modinfo`), modellato
su `(3a) VP - EUI Compatibility Files`. Dipende da `(1) Community Patch` e
`(2) Vox Populi`. Sovrascrive `WorldView.lua` tramite `import="1"`: il
contenuto è la WorldView.lua no-EUI di VP **verbatim** più due `include`
appesi in fondo (`CivVAccess_Boot`, `CivVAccess_WorldViewKeys`). Caricandosi
dopo VP, la nostra WorldView.lua vince nel VFS e fa partire lo stack di
accessibilità di Civ-V-Access sulla mappa.

L'approccio DLC `.Civ5Pkg` del design doc è stato **respinto** con prove.

## Summary (EN)

The compatibility layer is a Civ V **mod** (`.modinfo`), modelled on `(3a)
VP - EUI Compatibility Files`. It depends on `(1) Community Patch` and `(2)
Vox Populi`. It overrides `WorldView.lua` via `import="1"`: the content is
VP's no-EUI WorldView.lua **verbatim** plus two appended `include` lines
(`CivVAccess_Boot`, `CivVAccess_WorldViewKeys`). Loading after VP, our
WorldView.lua wins the VFS and boots the Civ-V-Access accessibility stack on
the map.

The design doc's DLC `.Civ5Pkg` approach is **rejected** with evidence.

---

## Chosen architecture

### Package type: mod (`.modinfo`)

Mirror `(3a) VP - EUI Compatibility Files`:

- A `.modinfo` manifest with a freshly minted mod `id` (GUID) and version.
- `<Dependencies>` on:
  - `(1) Community Patch`, id `d1b6328c-ff44-4b0d-aad7-c657f83610cd`,
    minversion `150`.
  - `(2) Vox Populi`, id `8411a7a8-dad3-4622-a18e-fcc18324c799`,
    minversion `17`.
- One `<File import="1">` entry for the WorldView.lua override.
- `Supports` SinglePlayer / Multiplayer / HotSeat / Mac = 1, and the four
  `Reload*System` flags, matching `(3a)`.
- `AffectsSavedGames = 0` (UI-only).

### Injection: WorldView.lua override

- File: `src/vp-compat/UI/InGame/WorldView.lua`.
- Content: a **byte-verbatim copy** of
  `Community-Patch-DLL/(2) Vox Populi/Core Files/Overrides/WorldView.lua`
  (v17, source MD5 `7BE13F5850CCAE290717C9717AA8C0D2`) from line 1 to VP's
  last line, then, after VP's last line, a provenance + rationale banner
  followed by `include("CivVAccess_Boot")` and
  `include("CivVAccess_WorldViewKeys")`.
- Keeping the VP body byte-verbatim from line 1 (no top header) makes re-sync
  a clean diff: only the trailing banner + includes are ours.
- This is the exact CVA pattern, with VP's WorldView.lua as the base instead
  of BNW's. It preserves all of VP's map logic and adds the accessibility
  boot + the WorldView-context input wrap.

### Why the WorldView seat is required (not optional)

- `CivVAccess_Boot` must run on a context that re-initialises on
  load-game-from-game. WorldView does; TaskList does not. This is the seat CVA
  already settled on.
- `CivVAccess_WorldViewKeys` must run **in the WorldView context** to wrap
  WorldView's own `InputHandler`. WorldView's `DefaultMessageHandler` returns
  true for `VK_PRIOR` / `VK_NEXT` (and arrows / OEM_PLUS / OEM_MINUS), eating
  the scanner's PageUp/PageDown bindings before InGame ever sees them. Only a
  WorldView-context override can install this wrap.
- VP defines `function InputHandler(...)` as a **global**, so the wrap's
  `basePriorInput = InputHandler` capture resolves to VP's handler. Verified.

### How the include resolves

- `CivVAccess_Boot.lua` and `CivVAccess_WorldViewKeys.lua` live in CVA's DLC,
  contributed to the Expansion2 `<GameplaySkin>` `UI/InGame` directory. The
  in-game VFS indexes by **bare stem** across DLC and mods, so
  `include("CivVAccess_Boot")` resolves to CVA's file regardless of our mod
  being the caller. (Requires CVA to be installed and active; validate
  in-game.)

---

## Rejected: DLC `.Civ5Pkg` at Priority > 250 (design doc approach)

Rejected with evidence:

1. VP no-EUI reaches the game as **mod `import="1"`** files. Mod imports
   override DLC-provided UI files in the in-game VFS. A DLC package, at any
   priority, would be shadowed by VP's mod-imported WorldView.lua.
2. The design doc's premise ("VP does not override WorldView.lua") is false;
   VP overrides it in `(2) Vox Populi`.
3. The only verified compat-layer reference in the VP tree, `(3a)`, is a
   **mod**, not a DLC.
4. The observed symptom the design doc reports (boot does not fire with VP
   active) is consistent with VP-as-mods shadowing CVA's DLC WorldView.lua,
   and is **inconsistent** with VP installed as a Priority-200 DLC (CVA's 250
   would then win and boot would fire).

The minted mod `id` (GUID) is a new, self-owned identity for a new mod; it is
not an invented value that must match an existing package. This is the one
legitimate new identifier.

## Considered and rejected: `InGameUIAddin` bootstrap

`InGameUIAddin` is a verified pattern (used by `(1)` and `(4a)`) and would
avoid copying VP's WorldView.lua. Rejected for Milestone 1 because:

- An `InGameUIAddin` context is **not** WorldView, so it cannot wrap
  WorldView's `InputHandler`. The scanner keys WorldView eats would stay
  broken, failing the "keyboard commands respond" acceptance criterion.
- Its re-init behaviour on load-game-from-game is unverified; relying on it
  risks the exact class of bug CVA fixed by moving the seat to WorldView.

Recorded as a future option for net-new contexts that do not need to wrap
WorldView input.

---

## Allowed implementation paths

- Create `src/vp-compat/` with a `.modinfo` and the WorldView.lua override.
- Copy VP's WorldView.lua verbatim; append only a provenance/rationale banner
  and the two include lines, all after VP's last line (body stays
  byte-verbatim from line 1).
- Mirror `(3a)` and CVA manifest conventions exactly where applicable.

## Forbidden implementation paths

- Editing any file under `Civ-V-Access/` or `Community-Patch-DLL/`.
- Shipping a stub WorldView.lua that drops VP's map logic.
- Inventing a GUID/Priority/UISkin to force a DLC approach that the evidence
  says cannot win the VFS.
- Declaring runtime compatibility as "verified" on the basis of static
  inspection alone. In-game validation is required and is called out.

---

## Validation plan

Static (this repo, now):

- `.modinfo` is well-formed XML; dependency ids/versions match the real VP
  modinfos; the single `<File import="1">` path matches the on-disk file.
- WorldView.lua ends with the two include lines; the body matches VP v17
  byte-for-byte up to VP's last line, with only the appended banner and the
  two includes after it.

In-game (required, by the maintainer):

- With CVA + VP no-EUI active and this mod enabled, start a game. Confirm boot
  speech on `LoadScreenClose` and the `CivVAccess_Boot` probe line in
  `Lua.log` (needs `LoggingEnabled=1`).
- Confirm the accessible cursor initialises and map keys respond, including
  PageUp/PageDown scanner cycling.
- Confirm load-game-from-game re-fires boot (WorldView re-init).
- Confirm no regression for a sighted tester: camera pan/zoom and
  strategic-view toggle still work (fall-through on dispatch miss).

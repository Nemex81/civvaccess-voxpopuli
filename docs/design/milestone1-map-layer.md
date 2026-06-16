# Milestone 1 — Map Accessibility Layer / Layer Accessibilità Mappa

## EN — Objective

Create a standalone Civ5 mod package (`src/vp-compat/`) that injects the Civ-V-Access accessibility stack into the Vox Populi no-EUI `WorldView` Context, restoring TTS, the accessible cursor, and all keyboard commands on the main game map.

## IT — Obiettivo

Creare un pacchetto mod Civ5 autonomo (`src/vp-compat/`) che inietti il sistema di accessibilità di Civ-V-Access nel Context `WorldView` di Vox Populi no-EUI, ripristinando TTS, cursore accessibile e tutti i comandi da tastiera sulla finestra principale della mappa.

---

## Technical Background / Contesto Tecnico

**EN**
- Civ-V-Access injects via `WorldView.lua` → `include("CivVAccess_Boot")`, declared in `CivVAccess_2.Civ5Pkg` at Priority 250 under `Expansion2Primary` UISkin.
- Vox Populi no-EUI does **not** override `WorldView.lua` (absent from `UI_bc1/Core/` — confirmed by direct inspection of the VP repo).
- Despite this, VP's package loading order prevents `CivVAccess_Boot` from firing, leaving the map in sighted-only mode.
- Solution: a new package with Priority > 250 that re-declares `UI/InGame/` under `Expansion2Primary`, containing only `WorldView.lua` with `include("CivVAccess_Boot")`.

**IT**
- Civ-V-Access si inietta tramite `WorldView.lua` → `include("CivVAccess_Boot")`, dichiarato in `CivVAccess_2.Civ5Pkg` a Priority 250 sotto la UISkin `Expansion2Primary`.
- Vox Populi no-EUI **non** sovrascrive `WorldView.lua` (assente da `UI_bc1/Core/` — confermato per ispezione diretta del repo VP).
- Nonostante questo, l'ordine di caricamento dei package VP impedisce che `CivVAccess_Boot` scatti, lasciando la mappa in modalità solo visiva.
- Soluzione: un nuovo package con Priority > 250 che ri-dichiara `UI/InGame/` sotto `Expansion2Primary`, contenente solo `WorldView.lua` con `include("CivVAccess_Boot")`.

---

## Required file structure / Struttura file richiesta

```
src/vp-compat/
  CivVAccess_VP_0.Civ5Pkg
  CivVAccess_VP_1.Civ5Pkg
  CivVAccess_VP_2.Civ5Pkg
  UI/
    InGame/
      WorldView.lua
```

---

## Reference files to read / File di riferimento da leggere

Repo Civ-V-Access: https://github.com/rashadnaqeeb/Civ-V-Access

- [`src/dlc/CivVAccess_0.Civ5Pkg`](https://github.com/rashadnaqeeb/Civ-V-Access/blob/main/src/dlc/CivVAccess_0.Civ5Pkg) — BaseGame manifest model
- [`src/dlc/CivVAccess_2.Civ5Pkg`](https://github.com/rashadnaqeeb/Civ-V-Access/blob/main/src/dlc/CivVAccess_2.Civ5Pkg) — Expansion2 payload, Priority 250, declares `UI/InGame/`
- [`src/dlc/UI/InGame/CivVAccess_Boot.lua`](https://github.com/rashadnaqeeb/Civ-V-Access/blob/main/src/dlc/UI/InGame/CivVAccess_Boot.lua) — full boot chain
- [`src/dlc/UI/InGame/CivVAccess_EngineData.lua`](https://github.com/rashadnaqeeb/Civ-V-Access/blob/main/src/dlc/UI/InGame/CivVAccess_EngineData.lua) — engine fork probe

Repo Vox Populi: https://github.com/CIVITAS-John/vox-populi

- [`UI_bc1/Core/`](https://github.com/CIVITAS-John/vox-populi/tree/master/UI_bc1/Core) — confirm `WorldView.lua` absent
- [`(3a) VP - EUI Compatibility Files/`](https://github.com/CIVITAS-John/vox-populi/tree/master/(3a)%20VP%20-%20EUI%20Compatibility%20Files) — reference architecture for compat layers

---

## Acceptance criteria / Criteri di accettazione

- `src/vp-compat/` exists with three `.Civ5Pkg` files and `UI/InGame/WorldView.lua`.
- Boot speech fires on `LoadScreenClose` with VP no-EUI active.
- Accessible cursor initialises on the map.
- Keyboard commands respond.
- No regression on vanilla + Civ-V-Access.
- All Lua files pass lint (`stylua.toml`, `.luacheckrc` from Civ-V-Access conventions).

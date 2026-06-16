# Changelog

All notable changes to civvaccess-voxpopuli are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [Unreleased]

### Added

- `tools/deploy.ps1`: idempotent deploy script with MD5 verification and
  rollback for copying the mod into the Civ V MODS folder from any Windows
  Documents path. Supports `-ModsDir` override. Closes DEPLOY-1.
- `src/vp-compat/CivVAccess_VoxPopuli.modinfo`: compatibility mod manifest
  (Milestone 1). Depends on Community Patch (min 150) and Vox Populi (min 17).
  Overrides WorldView.lua via import=1 to boot the Civ V Access accessibility
  stack on the VP no-EUI main map.
- `src/vp-compat/UI/InGame/WorldView.lua`: VP v17 no-EUI WorldView verbatim
  copy with appended `include("CivVAccess_Boot")` and
  `include("CivVAccess_WorldViewKeys")`.
- `tools/validate-vp-compat.ps1`: static validator (XML, MD5, Lua syntax,
  deploy.ps1 presence). All 14 AUTO checks pass.
- `docs/analysis/`: initial-recon, implementation-strategy, milestone2-readiness.
- `docs/backlog/deployment.md`: backlog items for deploy tooling and
  repo-hygiene work.

# Changelog

All notable changes to civvaccess-voxpopuli are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [Unreleased]

### Added

- `tools/deploy.ps1`: idempotent deploy script with MD5 verification and
  rollback for copying the mod into the Civ V MODS folder from any Windows
  Documents path. Supports `-ModsDir` override. Closes DEPLOY-1.

### Changed

- `tools/validate-vp-compat.ps1`: added AUTO checks for deploy.ps1 presence
  and `-ModsDir` parameter declaration (Ciclo B, DEPLOY-1).

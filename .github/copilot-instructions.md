# Copilot Instructions for civvaccess-voxpopuli

## Project identity

`civvaccess-voxpopuli` is a standalone accessibility compatibility layer for
Sid Meier's Civilization V focused on making Vox Populi no-EUI accessible
to blind players by reusing verified patterns, runtime behavior, and UI
integration strategies from Civ-V-Access.

This repository is not a fork of Civ-V-Access.

This repository is not a fork of Vox Populi / Community Patch.

This repository is the only writable implementation target.

The project must remain a compatibility layer. Do not redesign or absorb
the original Civ-V-Access codebase. Do not patch Vox Populi in place.

Speech reliability is critical. If something fails silently or speaks stale
data, the blind player loses trust in the interface. Prefer explicit failure,
logging, diagnostics, and verified behavior over silent fallback.

---

## Local workspace layout

The expected VS Code multi-root workspace contains these local folders:

- `C:\Users\nemex\OneDrive\Documenti\GitHub\civvaccess-voxpopuli`
  - Main working repository
  - All code, docs, backlog, prompts, reports, tests, and changelog updates
    must be created or modified here

- `C:\Users\nemex\OneDrive\Documenti\GitHub\Civ-V-Access`
  - Read-only technical reference
  - Study this repo to understand manifests, DLC packaging, WorldView boot,
    input routing, handler stack, map cursor, plot reading, speech, scanner,
    logging, lint, tests, and architecture gotchas
  - Never edit files in this repository

- `C:\Users\nemex\OneDrive\Documenti\GitHub\Community-Patch-DLL`
  - Read-only technical reference for Vox Populi
  - Study this repo to identify no-EUI UI structure, rewritten screens,
    packaging conventions, hooks, compatibility points, and missing or
    replaced contexts
  - Never edit files in this repository

If a solution would require editing either reference repository, stop and
redesign the solution so it remains fully contained inside
`civvaccess-voxpopuli`.

---

## Mission and milestone order

The project has two milestones.

### Milestone 1

Implement and validate the accessibility layer for the main gameplay map in
Vox Populi no-EUI.

Primary goals:
- restore gameplay boot speech
- restore accessible map cursor behavior
- restore keyboard-driven interaction on the main map
- inject the accessibility runtime through a verified packaging and
  WorldView-compatible approach
- keep the implementation isolated inside this repository

### Milestone 2

Port accessibility to the Vox Populi rewritten screens, one screen at a time.

Typical candidates include:
- CityView
- UnitPanel
- TopPanel
- NotificationPanel
- PlotHelp
- ProductionPopup
- TechTree
- diplomacy screens
- any additional VP-owned UI discovered during analysis

Milestone 1 has priority over Milestone 2.

Do not begin broad screen-by-screen Milestone 2 implementation until
Milestone 1 is stable and validated, unless the current task explicitly
targets a narrow and well-verified screen.

---

## Mandatory operating rule

Never write or modify any file before reading, analyzing, and verifying the
relevant source files.

Research first. Always.

Do not guess:
- file paths
- package names
- GUID usage
- Priority ordering
- UISkin declarations
- include stems
- hook names
- event timing
- screen ownership
- load order
- compatibility points
- test strategy

Everything must be derived from files actually read in the local workspace.

If something is not verified, treat it as unknown, document it, and choose
the safest minimal path.

---

## Read-before-write protocol

Before making any code change, read and analyze the relevant files in all
three repositories.

### In `civvaccess-voxpopuli`

Read at minimum:
- `README.md`
- all files under `docs/`
- all files under `.github/` relevant to the task
- all files already present in `src/` that may be impacted
- `CHANGELOG.md` if present
- any prompt, report, backlog, or analysis file related to the target area

### In `Civ-V-Access`

Read the real source files needed to understand the behavior being reused.

At minimum, inspect the relevant package, boot, and runtime files, including
when present:
- `src/dlc/CivVAccess_0.Civ5Pkg`
- `src/dlc/CivVAccess_1.Civ5Pkg`
- `src/dlc/CivVAccess_2.Civ5Pkg`
- `src/dlc/UI/InGame/CivVAccess_Boot.lua`
- `src/dlc/UI/InGame/CivVAccess_EngineData.lua`
- `src/dlc/UI/InGame/CivVAccess_InputRouter.lua`
- `src/dlc/UI/InGame/CivVAccess_BaselineHandler.lua`
- `src/dlc/UI/InGame/CivVAccess_CursorCore.lua`
- `src/dlc/UI/InGame/CivVAccess_CursorActivate.lua`
- `src/dlc/UI/InGame/CivVAccess_PlotSectionsCore.lua`
- `src/dlc/UI/InGame/CivVAccess_PlotComposers.lua`
- `src/dlc/UI/InGame/CivVAccess_SpeechEngine.lua`
- `src/dlc/UI/InGame/CivVAccess_HandlerStack.lua`
- `stylua.toml` if present
- `.luacheckrc` if present
- test harness files if present
- any additional file referenced by the above and required to understand
  the target behavior

### In `Community-Patch-DLL`

Read the real Vox Populi files that affect the current task.

At minimum, inspect:
- the repository structure
- the no-EUI UI structure
- the gameplay UI folders
- package or compatibility patterns if present
- the real VP-owned files for the screen or context being targeted
- whether `WorldView.lua` is absent, present, replaced, or indirectly
  superseded by other ownership patterns
- the rewritten screen files involved in the task

If more files become relevant during analysis, read them before implementing.

---

## Analysis-first deliverables

Before implementation, create or update analysis files inside this repository.

Preferred locations:
- `docs/analysis/initial-recon.md`
- `docs/analysis/implementation-strategy.md`
- `docs/analysis/milestone2-readiness.md`

Use these files to capture:
- files read
- confirmed facts
- disproven assumptions
- open questions
- risks
- allowed implementation paths
- forbidden implementation paths
- rationale for the chosen strategy

Do not skip written analysis for non-trivial tasks.

---

## Implementation policy

Use the smallest verified implementation that can solve the task safely.

Preferred order of intervention:
1. analysis
2. documentation
3. package or manifest work
4. minimal compatibility entrypoints
5. minimal shims
6. minimal screen-specific adaptation

Avoid:
- speculative abstractions
- broad rewrites
- unnecessary code duplication from Civ-V-Access
- changes to reference repositories
- “cleanup” edits outside the target scope
- declaring compatibility before verifying it

If package files or Lua entrypoints are needed:
- mirror real patterns only after reading them
- keep the implementation minimal
- document why the file exists
- preserve compatibility-layer boundaries

---

## Accessibility and reliability rules

This project exists for blind players. Reliability beats cleverness.

### No silent failures

Never swallow a failure without recording it.

If code catches an error or enters a failure branch:
- log enough context to diagnose the issue
- avoid fake success
- avoid stale spoken data
- prefer a clearly diagnosed limitation over a silent broken path

### No stale state by default

Do not invent caches or long-lived mirrored state unless the behavior is
explicitly verified and justified.

If a value can go stale and affect speech output, re-read the underlying
source of truth where practical.

### No unverified speech changes

Do not change user-facing spoken behavior casually.

When adapting Civ-V-Access patterns:
- preserve information density
- avoid fluff
- avoid visual assumptions
- avoid truncating gameplay-relevant data
- prefer concise but complete spoken output

---

## Validation after every change

After every file modification, immediately:

1. Re-read the modified file
2. Check syntax and structural integrity
3. Verify names, includes, paths, and references
4. Confirm that architecture constraints are still respected
5. Check the change against the current milestone scope
6. Check for likely regression against existing docs and analysis

If validation fails:
- correct the issue
- re-validate
- do not continue until the current step is stable

---

## Mandatory review loops

After implementation of the current task, run two required review cycles.

### Cycle A — Revision of the changes

Repeat up to 10 attempts:
1. Review all modifications critically
2. Look for logic gaps, weak naming, incomplete docs, unsafe assumptions,
   drift from milestone scope, and unnecessary complexity
3. Apply only justified fixes
4. Re-validate
5. Stop only when revision validation passes

If the cycle does not pass after 10 attempts:
- stop the cycle
- create a diagnostic report under `docs/reports/`
- document attempts, blockers, safe state, and unresolved risks

### Cycle B — Revision, update, and test extension

Only after Cycle A passes.

Repeat up to 10 attempts:
1. Review the stabilized result again
2. Improve what can be improved without broadening scope
3. Extend tests, checks, or diagnostics where realistic
4. Re-validate everything
5. Stop only when final validation passes

If the cycle does not pass after 10 attempts:
- stop the cycle
- create a diagnostic report under `docs/reports/`
- document the attempted improvements, test extensions, regressions, and
  safe final state

---

## Testing policy

Do not pretend tests exist if they do not.

If this repository already contains tests, use and extend them.

If it does not:
- add only realistic checks consistent with the project
- distinguish clearly between automatic checks, static validation,
  and required manual verification
- never claim runtime behavior is verified if only static inspection
  was performed

When checking behavior inspired by Civ-V-Access:
- prefer real code paths
- avoid toy mocks when the real structure can be tested more honestly
- document coverage gaps explicitly

---

## Changelog and commit discipline

When a feature or bug fix is completed, update `CHANGELOG.md` under
`## [Unreleased]` if the repository uses a changelog.

Keep changelog entries terse, player-facing, and direct.

Write from the player’s perspective, not the developer’s perspective.

Do not include:
- internal symbol names
- file paths
- implementation detail
- verbose before/after explanations
- rationale padding

If a hotkey is the player-facing surface of the change, include it when
needed for clarity.

Commit messages should use:
- a short imperative subject line
- one blank line
- a wrapped body when needed

Do not produce run-on subject/body hybrids.

---

## Documentation policy

This repository is bilingual where appropriate.

Use English and Italian in high-level project docs when consistent with the
existing documentation.

Keep documentation screen-reader friendly:
- prefer headings and short paragraphs
- prefer lists over complex tables
- use explicit file paths
- separate facts from assumptions
- record blockers precisely

Update documentation whenever implementation changes project understanding.

Typical files to create or update:
- `README.md`
- `CHANGELOG.md`
- `docs/analysis/...`
- `docs/backlog/...`
- `docs/reports/...`
- `.github/prompts/...`

---

## Milestone 2 discipline

Milestone 2 must proceed one screen at a time.

For each targeted VP-owned screen:
1. read the current repo docs
2. read the matching Civ-V-Access source files
3. read the actual VP screen file
4. identify the expected hooks and surfaces
5. verify what still exists and what changed
6. choose the minimal safe adaptation
7. validate before moving to the next screen

If a screen cannot be implemented safely yet:
- do not guess
- document the blocker
- record the screen in backlog with:
  - file path
  - confirmed ownership
  - expected hook surface
  - actual hook surface
  - risk
  - readiness state

---

## Final output expectations

For every significant task, leave an auditable trail in the repository.

That trail should include, where appropriate:
- analysis
- strategy
- implementation
- validation notes
- review-cycle reports
- backlog updates
- documentation updates
- changelog updates

At the end of the task, provide a concise final summary that includes:
- files read
- files created
- files modified
- milestone status
- validations performed
- unresolved blockers
- recommended next steps

Do not declare completion before validation and review loops are done.

---

## External references

Reference repositories:
- Civ-V-Access
  - `https://github.com/rashadnaqeeb/Civ-V-Access`

- Vox Populi / Community Patch Project
  - `https://github.com/CIVITAS-John/vox-populi`

Use local workspace copies first when available.
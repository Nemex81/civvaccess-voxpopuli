<#
.SYNOPSIS
  Static validation for the civvaccess-voxpopuli compatibility mod.

.DESCRIPTION
  Repeatable, self-contained checks for src/vp-compat. Validates the mod
  manifest and the WorldView.lua override without launching the game.

  Check tiers (honest about what is and is not proven):
    [AUTO]   proven here: XML well-formedness, file resolution, MD5 integrity,
             import flag, declared dependencies, Lua syntax (if an interpreter
             is found).
    [SKIP]   could not run automatically (e.g. no Lua interpreter present);
             reported, never silently passed.
    [MANUAL] only verifiable in-game (boot fires, cursor, keys, load-from-game,
             cross-source include resolution, mod-vs-DLC VFS precedence).

  Exit code is non-zero if any [AUTO] check fails. [SKIP]/[MANUAL] never fail
  the run but are always printed.

.NOTES
  No network, no game launch. Mirrors the spirit of Civ-V-Access test.ps1.
#>
[CmdletBinding()]
param(
    # Optional path to a Lua 5.1 interpreter for the syntax check. If omitted,
    # the script probes PATH and the Civ-V-Access sibling repo, then SKIPs.
    [string]$LuaExe
)

$ErrorActionPreference = "Stop"
$repoRoot   = Split-Path -Parent $PSScriptRoot
$compatRoot = Join-Path $repoRoot "src\vp-compat"
$modinfo    = Join-Path $compatRoot "CivVAccess_VoxPopuli.modinfo"
$worldview  = Join-Path $compatRoot "UI\InGame\WorldView.lua"

# Verified Vox Populi identities this mod must depend on (see docs/analysis).
$expectedDeps = @{
    "d1b6328c-ff44-4b0d-aad7-c657f83610cd" = "(1) Community Patch"
    "8411a7a8-dad3-4622-a18e-fcc18324c799" = "(2) Vox Populi"
}

$fail = 0
function Pass($m) { Write-Host "[AUTO]  PASS  $m" -ForegroundColor Green }
function Fail($m) { Write-Host "[AUTO]  FAIL  $m" -ForegroundColor Red; $script:fail++ }
function Skip($m) { Write-Host "[SKIP]        $m" -ForegroundColor Yellow }
function Manual($m) { Write-Host "[MANUAL]      $m" -ForegroundColor Cyan }

Write-Host "=== civvaccess-voxpopuli static validation ===" -ForegroundColor White

# --- modinfo: presence + well-formedness ---------------------------------
if (-not (Test-Path -LiteralPath $modinfo)) { Fail "modinfo not found: $modinfo"; exit 1 }
try { [xml]$x = Get-Content -LiteralPath $modinfo -Raw; Pass "modinfo is well-formed XML" }
catch { Fail "modinfo is not well-formed XML: $_"; exit 1 }

# --- modinfo: mod id present ---------------------------------------------
$modId = $x.Mod.id
if ($modId -match '^[0-9a-fA-F-]{36}$') { Pass "mod id is a GUID ($modId)" }
else { Fail "mod id is missing or not a GUID ($modId)" }

# --- modinfo: dependencies match the verified VP identities --------------
$declaredDeps = @{}
foreach ($d in $x.Mod.Dependencies.Mod) { $declaredDeps[$d.id.ToLower()] = $d }
foreach ($id in $expectedDeps.Keys) {
    if ($declaredDeps.ContainsKey($id)) {
        Pass "depends on $($expectedDeps[$id]) ($id, minversion=$($declaredDeps[$id].minversion))"
    } else {
        Fail "missing dependency on $($expectedDeps[$id]) ($id)"
    }
}

# --- modinfo: WorldView File entry (path + import + md5) ------------------
$fileNode = $x.Mod.Files.File | Where-Object { $_.'#text' -match 'WorldView\.lua$' }
if (-not $fileNode) {
    Fail "no <File> entry for WorldView.lua in modinfo"
} else {
    $declaredPath = $fileNode.'#text'
    $onDisk = Join-Path $compatRoot ($declaredPath -replace '/', '\')
    if (Test-Path -LiteralPath $onDisk) { Pass "File path resolves on disk ($declaredPath)" }
    else { Fail "File path does not resolve on disk ($declaredPath)" }

    if ("$($fileNode.import)" -eq "1") { Pass "WorldView.lua import flag is 1 (overrides VFS)" }
    else { Fail "WorldView.lua import flag is '$($fileNode.import)' (expected 1)" }

    if (Test-Path -LiteralPath $onDisk) {
        $actualMd5 = (Get-FileHash -Algorithm MD5 -LiteralPath $onDisk).Hash
        if ($fileNode.md5 -and ($fileNode.md5.ToUpper() -eq $actualMd5.ToUpper())) {
            Pass "WorldView.lua MD5 matches manifest ($actualMd5)"
        } else {
            Fail "WorldView.lua MD5 mismatch (manifest=$($fileNode.md5) actual=$actualMd5)"
        }
    }
}

# --- WorldView.lua: boot includes present + last line --------------------
if (Test-Path -LiteralPath $worldview) {
    $wv = Get-Content -LiteralPath $worldview
    $hasBoot = ($wv | Select-String -SimpleMatch 'include("CivVAccess_Boot")').Count
    $hasKeys = ($wv | Select-String -SimpleMatch 'include("CivVAccess_WorldViewKeys")').Count
    $hasInput = ($wv | Select-String -SimpleMatch 'function InputHandler(').Count
    if ($hasBoot -eq 1) { Pass "exactly one include(`"CivVAccess_Boot`")" } else { Fail "include(`"CivVAccess_Boot`") count = $hasBoot (expected 1)" }
    if ($hasKeys -eq 1) { Pass "exactly one include(`"CivVAccess_WorldViewKeys`")" } else { Fail "include(`"CivVAccess_WorldViewKeys`") count = $hasKeys (expected 1)" }
    if ($hasInput -ge 1) { Pass "VP InputHandler present (count=$hasInput) - body intact" } else { Fail "VP InputHandler not found - body may be truncated" }
    $last = ($wv | Select-Object -Last 1)
    if ($last -match 'CivVAccess_WorldViewKeys') { Pass "file ends with the boot includes" }
    else { Fail "unexpected last line: $last" }
} else {
    Fail "WorldView.lua not found: $worldview"
}

# --- WorldView.lua: Lua 5.1 syntax (best-effort) -------------------------
if (-not $LuaExe) {
    $siblingLua = Join-Path (Split-Path $repoRoot) "Civ-V-Access\third_party\lua51\lua5.1.exe"
    foreach ($cand in @("lua5.1", "lua", $siblingLua)) {
        if (Test-Path -LiteralPath $cand) { $LuaExe = $cand; break }
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source) { $LuaExe = $cmd.Source; break }
    }
}
if ($LuaExe -and (Test-Path -LiteralPath $LuaExe) -and (Test-Path -LiteralPath $worldview)) {
    $out = & $LuaExe -e "local f,e=loadfile([[$worldview]]); if not f then io.write('ERR: '..tostring(e)) os.exit(1) end io.write('OK')" 2>&1
    if ($LASTEXITCODE -eq 0 -and "$out" -eq "OK") { Pass "WorldView.lua parses under Lua 5.1 ($LuaExe)" }
    else { Fail "WorldView.lua Lua 5.1 parse failed: $out" }
} else {
    Skip "Lua 5.1 syntax check (no interpreter found; pass -LuaExe <path> to enable)"
}

# --- In-game checks this script cannot perform ---------------------------
Manual "boot speech fires on LoadScreenClose (Lua.log probe, LoggingEnabled=1)"
Manual "accessible cursor initialises; map keys respond (incl. PageUp/PageDown scanner)"
Manual "load-game-from-game re-fires boot (WorldView re-init)"
Manual "include(`"CivVAccess_Boot`") resolves cross-source (mod -> CVA DLC VFS)"
Manual "this mod's WorldView.lua wins the VFS over VP's and CVA's"
Manual "no regression for sighted testers (camera pan/zoom, strategic view)"

Write-Host ""
if ($fail -eq 0) { Write-Host "RESULT: all [AUTO] checks passed." -ForegroundColor Green; exit 0 }
else { Write-Host "RESULT: $fail [AUTO] check(s) failed." -ForegroundColor Red; exit 1 }

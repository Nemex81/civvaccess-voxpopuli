<#
.SYNOPSIS
  Static test suite for civvaccess-voxpopuli.

.DESCRIPTION
  Runs two categories of checks:
    [STATIC] pure file-level assertions (presence, content, MD5 consistency)
             that do not require a game launch or Lua interpreter.
    [VALIDATE] delegates to tools/validate-vp-compat.ps1 for the full
               manifest / dependency / import-flag / MD5 / syntax suite.

  No Lua runtime is required. Runtime behavior (speech, keyboard navigation,
  VFS resolution) is covered by the [MANUAL] items in validate-vp-compat.ps1.

  Exit codes: 0 = all checks passed, 1 = one or more checks failed.

.NOTES
  Lua runtime tests are not yet implemented for civvaccess-voxpopuli because
  the wrapper (CivVAccess_VP_GameSetupAccess.lua) depends on the full
  Civ V Access front-end chain (BaseMenu, HandlerStack, SpeechPipeline, etc.)
  which requires the CVA DLC VFS context. Adding a Lua polyfill harness
  mirroring tests/run.lua from Civ-V-Access is tracked under a separate task.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$compatRoot = Join-Path $root "src\vp-compat"

$fail = 0

function Pass([string]$m) { Write-Host "[STATIC]  PASS  $m" -ForegroundColor Green }
function Fail([string]$m) { Write-Host "[STATIC]  FAIL  $m" -ForegroundColor Red; $script:fail++ }

Write-Host "=== civvaccess-voxpopuli test suite ===" -ForegroundColor White
Write-Host ""
Write-Host "--- STATIC: VPSetupAccess_Installed sentinel ---"

# Test 1: VPSetupAccess_Installed sentinel present and assigned true.
# The include bridge in GameSetupScreen.lua uses this to distinguish
# "wired" from "loaded-but-did-nothing (CVA not active)". If absent,
# the bridge logs a warning and the screen silently fails for blind players.
$wrapperPath = Join-Path $compatRoot "UI\FrontEnd\CivVAccess_VP_GameSetupAccess.lua"
if (Test-Path -LiteralPath $wrapperPath) {
    $content = Get-Content -LiteralPath $wrapperPath -Raw
    if ($content -match 'VPSetupAccess_Installed\s*=\s*true') {
        Pass "CivVAccess_VP_GameSetupAccess.lua sets VPSetupAccess_Installed = true"
    } else {
        Fail "CivVAccess_VP_GameSetupAccess.lua is missing VPSetupAccess_Installed sentinel"
    }
} else {
    Fail "CivVAccess_VP_GameSetupAccess.lua not found at: $wrapperPath"
}

Write-Host ""
Write-Host "--- STATIC: BaseMenu.install call ---"

# Test 2: BaseMenu.install(ContextPtr, ...) call present in wrapper.
# This is the hook that wires the keyboard-navigable spoken menu. If absent,
# no accessibility overlay is installed and the screen is silent.
if (Test-Path -LiteralPath $wrapperPath) {
    $content = Get-Content -LiteralPath $wrapperPath -Raw
    if ($content -match 'BaseMenu\.install\s*\(\s*ContextPtr') {
        Pass "CivVAccess_VP_GameSetupAccess.lua calls BaseMenu.install(ContextPtr, ...)"
    } else {
        Fail "CivVAccess_VP_GameSetupAccess.lua does not call BaseMenu.install(ContextPtr, ...)"
    }
}

Write-Host ""
Write-Host "--- STATIC: Hard guard (all four CVA modules checked) ---"

# Test 3: Hard guard checks all four required CVA front-end modules.
# If any of these is nil the CVA chain did not load; the guard must bail
# so VP keeps working for sighted players instead of throwing at runtime.
if (Test-Path -LiteralPath $wrapperPath) {
    $content = Get-Content -LiteralPath $wrapperPath -Raw
    $guardPattern = 'BaseMenu\s*==\s*nil.*BaseMenuItems\s*==\s*nil.*SpeechPipeline\s*==\s*nil.*Log\s*==\s*nil'
    if ($content -match '(?s)' + $guardPattern) {
        Pass "Hard guard checks BaseMenu, BaseMenuItems, SpeechPipeline, Log"
    } else {
        Fail "Hard guard is incomplete or missing (expected: BaseMenu, BaseMenuItems, SpeechPipeline, Log)"
    }
}

Write-Host ""
Write-Host "--- STATIC: applyLocaleStrings called in onShow ---"

# Test 4: applyLocaleStrings is called inside the onShow callback.
# Locale is not ready at include time in this Context; applyLocaleStrings
# re-runs the CVA overlay when the screen actually opens so the spoken
# screen name is correctly localized in all supported languages.
if (Test-Path -LiteralPath $wrapperPath) {
    $content = Get-Content -LiteralPath $wrapperPath -Raw
    if ($content -match '(?s)onShow\s*=\s*function.+?applyLocaleStrings') {
        Pass "applyLocaleStrings called inside onShow callback"
    } else {
        Fail "applyLocaleStrings not found inside onShow callback"
    }
}

Write-Host ""
Write-Host "--- STATIC: TickPump deferred applyLocaleStrings ---"

# Test 5: TickPump.runOnce called with applyLocaleStrings inside onShow.
# The deferred tick ensures locale state that updates after show-time boot
# (but before the first user interaction) is captured before speech fires.
if (Test-Path -LiteralPath $wrapperPath) {
    $content = Get-Content -LiteralPath $wrapperPath -Raw
    if ($content -match 'TickPump\.runOnce') {
        Pass "TickPump.runOnce used for deferred locale apply"
    } else {
        Fail "TickPump.runOnce not found (deferred applyLocaleStrings missing)"
    }
}

Write-Host ""
Write-Host "--- STATIC: priorShowHide and priorInput captured ---"

# Test 6: priorShowHide and priorInput captured from VP screen globals.
# BaseMenu.install chains these so VP's own ShowHide and Input handlers
# keep running underneath the accessibility overlay. Missing them would
# break VP's keyboard Esc and screen-update logic.
if (Test-Path -LiteralPath $wrapperPath) {
    $content = Get-Content -LiteralPath $wrapperPath -Raw
    if (($content -match 'priorShowHide\s*=\s*ShowHideHandler') -and ($content -match 'priorInput\s*=\s*InputHandler')) {
        Pass "priorShowHide = ShowHideHandler and priorInput = InputHandler captured"
    } else {
        Fail "priorShowHide or priorInput not captured from VP screen globals"
    }
}

Write-Host ""
Write-Host "--- STATIC: GameSetupScreen.lua bridge include present ---"

# Test 7: GameSetupScreen.lua (VP verbatim copy) has the bridge include.
# Without this line at the end of the VP file, the wrapper never loads.
$screenPath = Join-Path $compatRoot "UI\FrontEnd\GameSetupScreen.lua"
if (Test-Path -LiteralPath $screenPath) {
    $screenContent = Get-Content -LiteralPath $screenPath -Raw
    $count = ([regex]::Matches($screenContent, 'include\("CivVAccess_VP_GameSetupAccess"\)')).Count
    if ($count -eq 1) {
        Pass "GameSetupScreen.lua contains exactly one include(`"CivVAccess_VP_GameSetupAccess`")"
    } else {
        Fail "GameSetupScreen.lua include count for CivVAccess_VP_GameSetupAccess = $count (expected 1)"
    }
} else {
    Fail "GameSetupScreen.lua not found at: $screenPath"
}

Write-Host ""
Write-Host "--- STATIC: deploy.ps1 covers all 4 expected files ---"

# Test 8: deploy.ps1 $filesToDeploy contains all 4 expected files.
# A missing file means blind players cannot use the feature even after
# running the deploy script, with no error indication.
$deployPath = Join-Path $root "tools\deploy.ps1"
if (Test-Path -LiteralPath $deployPath) {
    $deployContent = Get-Content -LiteralPath $deployPath -Raw
    $expectedFiles = @(
        "CivVAccess_VoxPopuli.modinfo",
        "UI\InGame\WorldView.lua",
        "UI\FrontEnd\GameSetupScreen.lua",
        "UI\FrontEnd\CivVAccess_VP_GameSetupAccess.lua"
    )
    foreach ($f in $expectedFiles) {
        # Match the escaped path as it appears in the PowerShell string literal.
        if ($deployContent -match [regex]::Escape($f)) {
            Pass "deploy.ps1 includes file: $f"
        } else {
            Fail "deploy.ps1 is missing file: $f"
        }
    }
} else {
    Fail "tools/deploy.ps1 not found"
}

Write-Host ""
Write-Host "--- STATIC: validate-vp-compat.ps1 checks FrontEnd files ---"

# Test 9: validator checks both FrontEnd files by stem name.
# If these checks are absent, a deploy regression (missing FrontEnd file)
# would not be detected before a live game session.
$valPath = Join-Path $root "tools\validate-vp-compat.ps1"
if (Test-Path -LiteralPath $valPath) {
    $valContent = Get-Content -LiteralPath $valPath -Raw
    foreach ($stem in @("GameSetupScreen\.lua", "CivVAccess_VP_GameSetupAccess\.lua")) {
        if ($valContent -match $stem) {
            Pass "validate-vp-compat.ps1 references: $stem"
        } else {
            Fail "validate-vp-compat.ps1 missing reference to: $stem"
        }
    }
} else {
    Fail "tools/validate-vp-compat.ps1 not found"
}

Write-Host ""
Write-Host "--- VALIDATE: delegating to validate-vp-compat.ps1 ---"
Write-Host ""

# Test 10: Full manifest/dependency/import/MD5/syntax suite.
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\validate-vp-compat.ps1")
$validateExit = $LASTEXITCODE
if ($validateExit -eq 0) {
    Pass "validate-vp-compat.ps1 exited 0 (all [AUTO] checks passed)"
} else {
        Fail "validate-vp-compat.ps1 exited $validateExit ([AUTO] failures present - see above)"
}

Write-Host ""
$total = 10 + 4  # 10 main tests above + 4 deploy file checks

if ($fail -eq 0) {
    Write-Host "RESULT: all static checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT: $fail static check(s) failed." -ForegroundColor Red
    exit 1
}

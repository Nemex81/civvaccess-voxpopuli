# _resync.ps1 - Re-sync VP-sourced files with installed VP v17 (5.2.7)
# Run from repo root: powershell -ExecutionPolicy Bypass -File tools\_resync.ps1

$ErrorActionPreference = "Stop"

$modsBase = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "My Games\Sid Meier's Civilization 5\MODS"
$vpBase   = Join-Path $modsBase "(2) Vox Populi\Core Files\Overrides"
$src      = Join-Path $PSScriptRoot "..\src\vp-compat"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function HashMD5($path) { (Get-FileHash $path -Algorithm MD5).Hash }

# -----------------------------------------------------------------------
# 1. GameSetupScreen.lua  — VP verbatim + vp-compat bridge (no BOM)
# -----------------------------------------------------------------------
$vpGS    = Join-Path $vpBase "GameSetupScreen.lua"
$outGS   = Join-Path $src "UI\FrontEnd\GameSetupScreen.lua"

$vpContent = [System.IO.File]::ReadAllText($vpGS, [System.Text.Encoding]::UTF8)

$bridge = @"

-------------------------------------------------
-- vp-compat accessibility bridge
-- Loaded via pcall: never crashes the screen for sighted players.
-- If CVA front-end modules are not active, the wrapper hard-guards
-- itself and sets VPSetupAccess_Installed = false (no-op).
-------------------------------------------------
do
    local ok, err = pcall(function()
        include("CivVAccess_VP_GameSetupAccess")
    end)
    if not ok then
        print("[vp-compat] game setup access include failed: " .. tostring(err))
    elseif not VPSetupAccess_Installed then
        print("[vp-compat] game setup access include resolved "
            .. "but did not install (CVA not active or VFS miss)")
    end
end
"@

$gsNew = $vpContent.TrimEnd() + "`n" + $bridge
[System.IO.File]::WriteAllText($outGS, $gsNew, $utf8NoBom)
$gsMD5 = HashMD5 $outGS
Write-Host "[DONE] GameSetupScreen.lua  MD5=$gsMD5"
$bytes = [System.IO.File]::ReadAllBytes($outGS)
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Error "BOM still present in GameSetupScreen.lua!"
}

# -----------------------------------------------------------------------
# 2. WorldView.lua  — VP verbatim + banner + includes (no BOM)
# -----------------------------------------------------------------------
$vpWV  = Join-Path $vpBase "WorldView.lua"
$outWV = Join-Path $src "UI\InGame\WorldView.lua"

$vpWVContent = [System.IO.File]::ReadAllText($vpWV, [System.Text.Encoding]::UTF8)
$vpWVMD5     = HashMD5 $vpWV

$banner = @"

-- ==========================================================================
-- Civ V Access - Vox Populi (no-EUI) compatibility layer
-- --------------------------------------------------------------------------
-- Everything ABOVE this banner is a verbatim copy of Vox Populi's no-EUI
-- WorldView.lua, imported so this mod can append the accessibility boot
-- without losing VP's map logic (camera, interface modes, path preview,
-- Squads / Route Planner hooks).
--   Source: Community-Patch-DLL/(2) Vox Populi/Core Files/Overrides/WorldView.lua
--   VP version: (2) Vox Populi v17 (5.2.7)
--   Source MD5: $vpWVMD5
-- RE-SYNC: when Vox Populi updates WorldView.lua, replace everything above
-- this banner with the new VP version and keep the two includes below.
-- --------------------------------------------------------------------------
-- WorldView is the seat for both the in-game Boot (module loads,
-- LoadScreenClose wiring) and the early key-interception hook. Boot runs
-- first so its modules populate the WorldView Context's env before
-- WorldViewKeys installs its handler. WorldView (not TaskList) is used
-- because it re-initialises on load-game-from-game, keeping its env and
-- closures live. Both stems resolve from the Civ V Access DLC's UI/InGame
-- through the in-game VFS, which indexes includes by bare stem across DLC
-- and mods.
include("CivVAccess_Boot")
-- WorldView-Context input hook. Wraps the InputHandler registered above
-- (ContextPtr:SetInputHandler) so HandlerStack bindings intercept keys
-- before WorldView's DefaultMessageHandler consumes them (e.g. PageUp /
-- PageDown scanner cycling, which VP's handler eats via VK_PRIOR /
-- VK_NEXT). See CivVAccess_WorldViewKeys.lua.
include("CivVAccess_WorldViewKeys")
"@

$wvNew = $vpWVContent.TrimEnd() + "`n" + $banner
[System.IO.File]::WriteAllText($outWV, $wvNew, $utf8NoBom)
$wvMD5 = HashMD5 $outWV
Write-Host "[DONE] WorldView.lua        MD5=$wvMD5"

# -----------------------------------------------------------------------
# 3. Report new MD5s for modinfo update
# -----------------------------------------------------------------------
Write-Host ""
Write-Host "=== Update modinfo with these MD5s ==="
Write-Host "WorldView.lua               MD5: $wvMD5"
Write-Host "GameSetupScreen.lua         MD5: $gsMD5"
Write-Host ""
Write-Host "=== Also fix Community Patch minversion: 150 -> 149 ==="

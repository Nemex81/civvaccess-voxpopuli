# _build_select_civ.ps1
# Creates src/vp-compat/UI/FrontEnd/SelectCivilization.lua:
#   VP verbatim + banner (with correct source MD5) + pcall bridge to CVA access wrapper.
# Run from repo root: powershell -ExecutionPolicy Bypass -File tools\_build_select_civ.ps1

$ErrorActionPreference = "Stop"

$modsBase = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "My Games\Sid Meier's Civilization 5\MODS"
$vpSCPath = Join-Path $modsBase "(2) Vox Populi\Core Files\Overrides\SelectCivilization.lua"
$outPath  = Join-Path $PSScriptRoot "..\src\vp-compat\UI\FrontEnd\SelectCivilization.lua"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$vpContent = [System.IO.File]::ReadAllText($vpSCPath, [System.Text.Encoding]::UTF8)
$vpMD5     = (Get-FileHash $vpSCPath -Algorithm MD5).Hash

$banner = @"

-- ==========================================================================
-- Civ V Access - Vox Populi (no-EUI) SelectCivilization accessibility layer
-- --------------------------------------------------------------------------
-- Everything ABOVE this banner is a verbatim copy of Vox Populi's no-EUI
-- SelectCivilization.lua.
--   Source: (2) Vox Populi/Core Files/Overrides/SelectCivilization.lua
--   VP version: (2) Vox Populi v17 (5.2.7)
--   Source MD5: $vpMD5
-- RE-SYNC: when Vox Populi updates SelectCivilization.lua, replace everything
-- above this banner and recalculate MD5 in the modinfo.
-- --------------------------------------------------------------------------
-- Bridge: delegates to the CVA accessibility wrapper already shipped in the
-- CVA DLC for the FrontEnd context. CivVAccess_SelectCivilizationAccess is
-- compatible with VP's globals (ShowHideHandler, InputHandler,
-- CivilizationSelected, IsWBMap). pcall: sighted players unaffected if CVA
-- modules are unavailable.
do
    local ok, err = pcall(function()
        include("CivVAccess_SelectCivilizationAccess")
    end)
    if not ok then
        print("[vp-compat] SelectCivilization access include failed: " .. tostring(err))
    end
end
"@

$newContent = $vpContent.TrimEnd() + "`n" + $banner
[System.IO.File]::WriteAllText($outPath, $newContent, $utf8NoBom)

$outMD5 = (Get-FileHash $outPath -Algorithm MD5).Hash
$bytes  = [System.IO.File]::ReadAllBytes($outPath)
$hasBom = ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
if ($hasBom) { Write-Error "BOM present in output file!"; exit 1 }

Write-Host "[DONE] SelectCivilization.lua created"
Write-Host "       VP source MD5:  $vpMD5"
Write-Host "       Output file MD5: $outMD5"
Write-Host ""
Write-Host "=== Add to modinfo ==="
Write-Host "    <File md5=`"$outMD5`" import=`"1`">UI/FrontEnd/SelectCivilization.lua</File>"

# _check_wrapper.ps1
Set-Location "c:\Users\nemex\OneDrive\Documenti\GitHub\civvaccess-voxpopuli"
$f   = "src\vp-compat\UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua"
$lua = "c:\Users\nemex\OneDrive\Documenti\GitHub\Civ-V-Access\third_party\lua51\lua5.1.exe"
$result = & $lua -e "loadfile('$($f.Replace('\','/'))')()" 2>&1
if ($LASTEXITCODE -eq 0) { Write-Host "Lua syntax: PASS" } else { Write-Host "Lua syntax: FAIL"; $result }
$md5 = (Get-FileHash $f -Algorithm MD5).Hash
Write-Host "MD5: $md5"
$bytes = [System.IO.File]::ReadAllBytes($f)
Write-Host "BOM: $(($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF))"

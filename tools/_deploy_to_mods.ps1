# _deploy_to_mods.ps1
# Deploys new SelectCivilization files directly to MODS/vp-compat
# (the active deployment folder used by the game, named differently from deploy.ps1 default)
Set-Location "c:\Users\nemex\OneDrive\Documenti\GitHub\civvaccess-voxpopuli"
$ErrorActionPreference = "Stop"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$src  = "src\vp-compat"
$dest = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "My Games\Sid Meier's Civilization 5\MODS\vp-compat"

$files = @(
    @{ S = "CivVAccess_VoxPopuli.modinfo";                           D = "CivVAccess_VoxPopuli.modinfo" }
    @{ S = "UI\FrontEnd\SelectCivilization.lua";                     D = "UI\FrontEnd\SelectCivilization.lua" }
    @{ S = "UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua"; D = "UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua" }
)

foreach ($f in $files) {
    $srcPath  = Join-Path $src $f.S
    $destPath = Join-Path $dest $f.D
    $destDir  = Split-Path $destPath
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item -LiteralPath $srcPath -Destination $destPath -Force
    $srcMD5  = (Get-FileHash $srcPath  -Algorithm MD5).Hash
    $destMD5 = (Get-FileHash $destPath -Algorithm MD5).Hash
    $ok = $srcMD5 -eq $destMD5
    Write-Host "$($f.D)  $destMD5  OK=$ok"
}
Write-Host "Deploy to vp-compat complete."

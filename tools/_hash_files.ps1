# _hash_files.ps1
Set-Location "c:\Users\nemex\OneDrive\Documenti\GitHub\civvaccess-voxpopuli"
$r = "src\vp-compat"
$files = @(
    "UI\FrontEnd\SelectCivilization.lua",
    "UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua"
)
foreach ($f in $files) {
    $p = Join-Path $r $f
    $h = (Get-FileHash $p -Algorithm MD5).Hash
    $b = [System.IO.File]::ReadAllBytes($p)
    $bom = ($b[0] -eq 0xEF) -and ($b[1] -eq 0xBB) -and ($b[2] -eq 0xBF)
    Write-Host "$f  MD5=$h  BOM=$bom"
}

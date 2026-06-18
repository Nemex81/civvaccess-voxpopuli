# _do_commit.ps1
Set-Location "c:\Users\nemex\OneDrive\Documenti\GitHub\civvaccess-voxpopuli"
Write-Host "START"
$result = & git status --short 2>&1
Write-Host "STATUS: $result"
Write-Host "DONE"

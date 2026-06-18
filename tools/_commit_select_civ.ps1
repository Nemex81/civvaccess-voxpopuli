# _commit_select_civ.ps1
Set-Location "c:\Users\nemex\OneDrive\Documenti\GitHub\civvaccess-voxpopuli"
$ErrorActionPreference = "Stop"

# Write commit message to temp file to avoid shell quoting issues
$msgFile = [System.IO.Path]::GetTempFileName()
$msgContent = @'
Add SelectCivilization accessibility (VP-SELECT-CIV-1)

VP's SelectCivilization.lua overrides CVA's DLC version, breaking
keyboard navigation and speech in the civ-picker popup. Fix by
shipping src/vp-compat/UI/FrontEnd/SelectCivilization.lua: VP
v17 (5.2.7) verbatim (source MD5 843D7699FF75E54BD4DDB3C5FA02851F)
plus a pcall bridge to include("CivVAccess_SelectCivilizationAccess")
from the CVA DLC, which is already compatible with VP's globals.

- add src/vp-compat/UI/FrontEnd/SelectCivilization.lua (MD5 31EAE5FC)
- add UI/FrontEnd/SelectCivilization.lua to modinfo with import=1
- add tools/_build_select_civ.ps1 re-sync helper
- update README.md, CHANGELOG.md, milestone2-readiness.md

All [AUTO] checks in validate-vp-compat.ps1 still pass.
Release withheld: SelectCivilization runtime not yet confirmed in-game.
'@
[System.IO.File]::WriteAllText($msgFile, $msgContent)

git add src/vp-compat/UI/FrontEnd/SelectCivilization.lua
git add tools/_build_select_civ.ps1
git add CHANGELOG.md
git add docs/analysis/milestone2-readiness.md
git add src/vp-compat/CivVAccess_VoxPopuli.modinfo
git add src/vp-compat/README.md
git add tools/_resync.ps1

git status --short
git commit -F $msgFile
Remove-Item $msgFile
git log --oneline -3

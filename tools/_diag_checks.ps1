# _diag_checks.ps1
$f = "src\vp-compat\UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua"
$c = Get-Content $f -Raw
Write-Host "Content length: $($c.Length)"
Write-Host "B_loop match: $(($c -match '\"B\"\s*\.\.\s*i'))"
Write-Host "GetTip match: $(($c -match 'GetToolTipString'))"
Write-Host "L_UNIQUE match: $(($c -match 'L_UNIQUE'))"
Write-Host "no_append: $(($c -notmatch '_appendUnique'))"
# Show the relevant line
Select-String -Path $f -Pattern 'B.*\.\.' | Select-Object LineNumber, Line

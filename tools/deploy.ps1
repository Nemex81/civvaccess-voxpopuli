<#
.SYNOPSIS
  Deploys the civvaccess-voxpopuli compatibility mod to the Civ V MODS folder.

.DESCRIPTION
  Copies CivVAccess_VoxPopuli.modinfo, UI\InGame\WorldView.lua,
  UI\FrontEnd\GameSetupScreen.lua, and
  UI\FrontEnd\CivVAccess_VP_GameSetupAccess.lua from
  src\vp-compat\ into the Civ V MODS directory under the civvaccess-voxpopuli
  subfolder. Resolves the MODS path from Windows My Documents API to avoid
  hardcoding the user name.

  Before writing, snapshots any existing destination files for rollback.
  After writing, verifies the MD5 of each deployed file against the source.
  On any failure, rolls back the destination to its pre-deploy state.

  Logging goes to stderr in [DEPLOY][LEVEL] format.
  The final summary goes to stdout.
  Exit codes: 0 = success, 1 = failure.

.PARAMETER ModsDir
  Optional. Overrides the auto-derived MODS base directory. The mod subfolder
  (civvaccess-voxpopuli) is always appended to whatever path you supply.

.EXAMPLE
  .\tools\deploy.ps1
  Deploys to:
    <My Documents>\My Games\Sid Meier's Civilization 5\MODS\civvaccess-voxpopuli\

.EXAMPLE
  .\tools\deploy.ps1 -ModsDir "D:\Civ5\MODS"
  Deploys to D:\Civ5\MODS\civvaccess-voxpopuli\

.NOTES
  FILES READ DURING FASE 0 ANALYSIS:
    - tools/validate-vp-compat.ps1         : style and pattern reference
    - src/vp-compat/CivVAccess_VoxPopuli.modinfo : source structure verified
    - src/vp-compat/UI/InGame/WorldView.lua : presence and MD5 verified
    - README.md                            : project context
    - docs/analysis/initial-recon.md      : architectural decisions
    - .github/copilot-instructions.md     : operational constraints

  FACTS VERIFIED:
    - Source WorldView.lua MD5 = C6CA647B715CD966584EC4694674296F (matches modinfo)
        - Four files to deploy: CivVAccess_VoxPopuli.modinfo,
            UI\InGame\WorldView.lua, UI\FrontEnd\GameSetupScreen.lua, and
            UI\FrontEnd\CivVAccess_VP_GameSetupAccess.lua
    - MODS path derived via [Environment]::GetFolderPath('MyDocuments')

  [ASSUNZIONE] The Civ V MODS path is always under My Documents\My Games\
    Sid Meier's Civilization 5\MODS\. Non-standard installations must use -ModsDir.
  [ASSUNZIONE] The snapshot is saved to a temp directory on disk rather than
    "in a variable" because multiple large files cannot be reliably stored in
    memory across the copy/verify phases. The temp dir is cleaned up in finally.
  [ASSUNZIONE] The Civ-V-Access DLC is already installed separately; this script
    deploys only this compatibility mod, not CVA itself.

  RISKS:
    - Disk full during copy: caught in outer try/catch, rollback triggered.
    - Insufficient permissions: caught and reported; advise running as admin
      or checking folder ownership.
    - File locked by a running game: Copy-Item will throw; rollback is triggered.
      Close Civ V before deploying.
#>
[CmdletBinding()]
param(
    [string]$ModsDir
)

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$compatRoot = Join-Path $repoRoot "src\vp-compat"
$modSubDir  = "civvaccess-voxpopuli"

# Ordered list of files to deploy: source absolute path + destination relative path.
$filesToDeploy = @(
    [ordered]@{ Src = Join-Path $compatRoot "CivVAccess_VoxPopuli.modinfo";                              Rel = "CivVAccess_VoxPopuli.modinfo" }
    [ordered]@{ Src = Join-Path $compatRoot "UI\InGame\WorldView.lua";                                   Rel = "UI\InGame\WorldView.lua" }
    [ordered]@{ Src = Join-Path $compatRoot "UI\FrontEnd\GameSetupScreen.lua";                           Rel = "UI\FrontEnd\GameSetupScreen.lua" }
    [ordered]@{ Src = Join-Path $compatRoot "UI\FrontEnd\SelectCivilization.lua";                        Rel = "UI\FrontEnd\SelectCivilization.lua" }
    [ordered]@{ Src = Join-Path $compatRoot "UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua";    Rel = "UI\FrontEnd\CivVAccess_VP_SelectCivilizationAccess.lua" }
    [ordered]@{ Src = Join-Path $compatRoot "UI\FrontEnd\CivVAccess_VP_GameSetupAccess.lua";             Rel = "UI\FrontEnd\CivVAccess_VP_GameSetupAccess.lua" }
)

# Writes a structured log message to stderr so deploy progress is visible without
# polluting stdout, which is reserved for the final human-readable summary.
function Write-DeployLog {
    param([string]$Level, [string]$Msg)
    [Console]::Error.WriteLine("[DEPLOY][$Level] $Msg")
}

# Computes the MD5 hash of a file as an uppercase hex string for integrity checks.
function Get-FileMd5 {
    param([string]$Path)
    return (Get-FileHash -Algorithm MD5 -LiteralPath $Path).Hash.ToUpper()
}

# Verifies all source files are present before any destination write is attempted,
# preventing partial deploys from a missing or corrupt source tree.
function Assert-SourceFiles {
    Write-DeployLog "INFO" "Verifying source files in: $compatRoot"
    foreach ($f in $script:filesToDeploy) {
        if (-not (Test-Path -LiteralPath $f.Src)) {
            Write-DeployLog "ERROR" "Source file missing: $($f.Src)"
            throw "Source file missing: $($f.Src)"
        }
        Write-DeployLog "DEBUG" "Source OK: $($f.Rel) MD5=$(Get-FileMd5 $f.Src)"
    }
}

# Derives the full mod destination path from the Windows My Documents API to avoid
# hardcoding the user name; appends the mod subfolder so the function returns
# the ready-to-use deployment root.
function Resolve-ModsDir {
    if (-not [string]::IsNullOrWhiteSpace($script:ModsDir)) {
        $base = $script:ModsDir.TrimEnd('\', '/')
        Write-DeployLog "INFO" "Using caller-supplied MODS dir: $base"
    } else {
        $docs = [Environment]::GetFolderPath('MyDocuments')
        $base = Join-Path $docs "My Games\Sid Meier's Civilization 5\MODS"
        Write-DeployLog "INFO" "Derived MODS dir from My Documents: $base"
    }
    return Join-Path $base $script:modSubDir
}

# Saves a copy of any existing destination files to a temp dir before overwriting
# so the deploy can be fully rolled back if the copy or MD5 verification fails.
# Returns the temp dir path, or $null if the destination does not exist yet.
function Invoke-Snapshot {
    param([string]$DestRoot)
    if (-not (Test-Path -LiteralPath $DestRoot)) {
        Write-DeployLog "INFO" "Destination does not exist yet; no snapshot needed."
        return $null
    }
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) `
                         ("civvaccess-deploy-snap-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-DeployLog "INFO" "Snapshotting existing destination to: $tempDir"
    foreach ($f in $script:filesToDeploy) {
        $destFile = Join-Path $DestRoot $f.Rel
        if (Test-Path -LiteralPath $destFile) {
            $snapFile = Join-Path $tempDir $f.Rel
            $snapDir  = Split-Path $snapFile
            if (-not (Test-Path -LiteralPath $snapDir)) {
                New-Item -ItemType Directory -Path $snapDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $destFile -Destination $snapFile -Force
            Write-DeployLog "DEBUG" "Snapshot saved: $($f.Rel)"
        }
    }
    return $tempDir
}

# Restores destination files from the pre-deploy snapshot, leaving the install
# in the exact state it was before the deploy was attempted.
# $DestExistedBefore tells us whether to attempt a remove (new dest) or restore (existing dest)
# so we never delete a folder the user had before this deploy if snapshot failed.
function Invoke-Rollback {
    param([string]$DestRoot, [string]$SnapshotDir, [bool]$DestExistedBefore)
    Write-DeployLog "WARNING" "Rolling back deployment to previous state..."
    if (-not $DestExistedBefore) {
        # Destination was brand-new; undo by removing what we created (may not exist yet
        # if copy never started, in which case Remove-Item is a safe no-op).
        if (Test-Path -LiteralPath $DestRoot) {
            Remove-Item -LiteralPath $DestRoot -Recurse -Force -ErrorAction SilentlyContinue
            Write-DeployLog "INFO" "Rollback: removed newly-created destination $DestRoot"
        } else {
            Write-DeployLog "INFO" "Rollback: destination was never created; nothing to remove."
        }
        return
    }
    # Destination existed before; only restore if we have a snapshot.
    if ([string]::IsNullOrEmpty($SnapshotDir)) {
        Write-DeployLog "ERROR" "Rollback incomplete: destination existed before deploy but snapshot was not taken. Manual recovery may be needed."
        return
    }
    foreach ($f in $script:filesToDeploy) {
        $snapFile = Join-Path $SnapshotDir $f.Rel
        $destFile = Join-Path $DestRoot    $f.Rel
        $destDir  = Split-Path $destFile
        if (Test-Path -LiteralPath $snapFile) {
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $snapFile -Destination $destFile -Force
            Write-DeployLog "INFO" "Rollback: restored $($f.Rel)"
        } else {
            # File was not present before; remove our copy if it exists.
            if (Test-Path -LiteralPath $destFile) {
                Remove-Item -LiteralPath $destFile -Force -ErrorAction SilentlyContinue
                Write-DeployLog "INFO" "Rollback: removed $($f.Rel) (not present before this deploy)"
            }
        }
    }
}

# Copies source files to the destination, creating subdirectories as needed.
# Logs each file as "Installed" (new), "Updated" (changed MD5), or "Unchanged"
# (same MD5, idempotent run). Returns a results hashtable for the summary and
# the subsequent MD5 verification step.
function Copy-ModFiles {
    param([string]$DestRoot)
    $results = @{}
    foreach ($f in $script:filesToDeploy) {
        $destFile = Join-Path $DestRoot $f.Rel
        $destDir  = Split-Path $destFile
        $srcMd5   = Get-FileMd5 $f.Src
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Write-DeployLog "DEBUG" "Created directory: $destDir"
        }
        $wasPresent  = Test-Path -LiteralPath $destFile
        $existingMd5 = if ($wasPresent) { Get-FileMd5 $destFile } else { $null }
        if ($wasPresent -and $existingMd5 -eq $srcMd5) {
            $status = "Unchanged"
            Write-DeployLog "INFO" "Unchanged : $($f.Rel) (MD5=$srcMd5)"
        } else {
            Copy-Item -LiteralPath $f.Src -Destination $destFile -Force
            $status = if ($wasPresent) { "Updated" } else { "Installed" }
            Write-DeployLog "INFO" "$($status.PadRight(9)): $($f.Rel)"
        }
        $results[$f.Rel] = @{
            Src    = $f.Src
            Dest   = $destFile
            SrcMd5 = $srcMd5
            Status = $status
        }
    }
    return $results
}

# Re-reads each deployed file from disk and compares its MD5 against the source
# to confirm the write was not silently corrupted (e.g. disk error or filesystem fault).
function Confirm-DeployedFiles {
    param([hashtable]$CopyResults)
    $ok = $true
    foreach ($rel in $CopyResults.Keys) {
        $entry   = $CopyResults[$rel]
        $destMd5 = Get-FileMd5 $entry.Dest
        if ($destMd5 -ne $entry.SrcMd5) {
            Write-DeployLog "ERROR" "MD5 mismatch: $rel (src=$($entry.SrcMd5) dest=$destMd5)"
            $ok = $false
        } else {
            Write-DeployLog "DEBUG" "MD5 verified: $rel ($destMd5)"
        }
    }
    return $ok
}

# Prints the human-readable deploy summary to stdout so it is distinct from the
# stderr log and can be captured separately by callers or CI pipelines.
function Write-DeploySummary {
    param(
        [string]    $DestRoot,
        [hashtable] $CopyResults,
        [bool]      $Success,
        [string]    $ErrorMsg
    )
    $resultLabel = if ($Success) { "SUCCESS" } else { "FAILURE" }
    $resultColor = if ($Success) { "Green"   } else { "Red"     }
    $destDisplay = if ($DestRoot) { $DestRoot } else { "(not resolved)" }

    Write-Host ""
    Write-Host "=== civvaccess-voxpopuli deploy summary ===" -ForegroundColor White
    Write-Host "Destination : $destDisplay"
    Write-Host "Result      : $resultLabel" -ForegroundColor $resultColor
    if ($ErrorMsg) {
        Write-Host "Error       : $ErrorMsg" -ForegroundColor Red
    }
    if ($CopyResults -and $CopyResults.Count -gt 0) {
        Write-Host ""
        Write-Host "Files:"
        foreach ($rel in ($CopyResults.Keys | Sort-Object)) {
            $entry   = $CopyResults[$rel]
            $destMd5 = if (Test-Path -LiteralPath $entry.Dest) { Get-FileMd5 $entry.Dest } else { "(missing)" }
            Write-Host "  [$($entry.Status.PadRight(9))] $rel"
            Write-Host "    src  MD5 : $($entry.SrcMd5)"
            Write-Host "    dest MD5 : $destMd5"
        }
    }
    Write-Host ""
}

# ---- MAIN ----------------------------------------------------------------

$destRoot          = $null
$snapshotDir       = $null
$destExistedBefore = $false
$copyResults       = @{}
$success           = $false
$errorMsg          = $null

try {
    Write-DeployLog "INFO" "Deploy started."

    # Phase 1: Verify source files are present before touching the destination.
    Assert-SourceFiles

    # Phase 2: Resolve the destination directory (auto or -ModsDir override).
    $destRoot = Resolve-ModsDir
    Write-DeployLog "INFO" "Destination resolved: $destRoot"

    # Phase 3: Record whether the destination already exists before we touch it,
    # so Invoke-Rollback can decide between "remove new dir" vs "restore from snapshot".
    $destExistedBefore = Test-Path -LiteralPath $destRoot

    # Phase 4: Snapshot existing destination files so rollback is possible.
    $snapshotDir = Invoke-Snapshot -DestRoot $destRoot

    # Phase 5: Copy files, creating subdirectories as needed.
    $copyResults = Copy-ModFiles -DestRoot $destRoot

    # Phase 6: Verify MD5 of every deployed file matches its source.
    $verified = Confirm-DeployedFiles -CopyResults $copyResults
    if (-not $verified) {
        throw "MD5 verification failed after copy; see [DEPLOY][ERROR] lines above."
    }

    $success = $true
    Write-DeployLog "INFO" "Deploy completed successfully."
}
catch {
    $errorMsg = $_.Exception.Message
    Write-DeployLog "ERROR" "Deploy failed: $errorMsg"
    if ($destRoot) {
        try {
            Invoke-Rollback -DestRoot $destRoot -SnapshotDir $snapshotDir -DestExistedBefore $destExistedBefore
        } catch {
            Write-DeployLog "ERROR" "Rollback also failed: $($_.Exception.Message)"
        }
    }
}
finally {
    # Always remove the snapshot temp dir, whether the deploy succeeded or not.
    if ($snapshotDir -and (Test-Path -LiteralPath $snapshotDir)) {
        Remove-Item -LiteralPath $snapshotDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-DeployLog "DEBUG" "Snapshot temp dir cleaned up."
    }
}

Write-DeploySummary `
    -DestRoot    $destRoot `
    -CopyResults $copyResults `
    -Success     $success `
    -ErrorMsg    $errorMsg

exit $(if ($success) { 0 } else { 1 })

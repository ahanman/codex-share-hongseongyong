[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TargetRoot = (Join-Path $env:USERPROFILE '.agents\skills'),
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$taskRepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskManifest = Get-Content -LiteralPath (Join-Path $taskRepoRoot 'inventory\skills.json') -Raw | ConvertFrom-Json
$taskSkills = @($taskManifest.userSkills)
if ($taskManifest.schemaVersion -ne 1 -or $taskSkills.Count -ne $taskManifest.expectedUserSkillCount) {
    throw 'The skills manifest is invalid or incomplete.'
}
$taskTarget = [IO.Path]::GetFullPath($TargetRoot)
$taskSourcePrefix = [IO.Path]::GetFullPath((Join-Path $taskRepoRoot 'skills')) + [IO.Path]::DirectorySeparatorChar
$taskTargetPrefix = $taskTarget.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$taskNameSet = @{}

# Validate every source and its hash before changing the destination.
foreach ($taskSkill in $taskSkills) {
    if ($taskSkill.name -notmatch '^[a-z0-9][a-z0-9._-]*$' -or $taskNameSet.ContainsKey($taskSkill.name)) {
        throw 'The manifest contains an unsafe or duplicate skill name.'
    }
    $taskNameSet[$taskSkill.name] = $true
    $taskSource = [IO.Path]::GetFullPath((Join-Path $taskRepoRoot $taskSkill.repositoryPath))
    if (-not $taskSource.StartsWith($taskSourcePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A skill source leaves the repository skills directory.'
    }
    $taskSourceItem = Get-Item -LiteralPath $taskSource
    if (-not $taskSourceItem.PSIsContainer -or $taskSourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw ('A skill source is not a regular directory: ' + $taskSkill.name)
    }
    $taskSourceFiles = @(Get-ChildItem -LiteralPath $taskSource -Recurse -File -Force)
    $taskReparse = @(Get-ChildItem -LiteralPath $taskSource -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
    if ($taskReparse.Count -gt 0 -or $taskSourceFiles.Count -ne $taskSkill.fileCount -or @($taskSkill.files).Count -ne $taskSkill.fileCount) {
        throw ('A skill source has unexpected files or links: ' + $taskSkill.name)
    }
    $taskFilePrefix = $taskSource.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    foreach ($taskFile in @($taskSkill.files)) {
        $taskFilePath = [IO.Path]::GetFullPath((Join-Path $taskSource $taskFile.path))
        if (-not $taskFilePath.StartsWith($taskFilePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'A file path leaves its skill directory.'
        }
        if ((Get-FileHash -LiteralPath $taskFilePath -Algorithm SHA256).Hash -ne $taskFile.sha256) {
            throw ('A skill file failed its SHA-256 check: ' + $taskSkill.name + '/' + $taskFile.path)
        }
    }
}

$taskInstalled = 0
$taskSkipped = 0
$taskBackedUp = 0
$taskTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'
foreach ($taskSkill in $taskSkills) {
    $taskSource = [IO.Path]::GetFullPath((Join-Path $taskRepoRoot $taskSkill.repositoryPath))
    $taskDestination = [IO.Path]::GetFullPath((Join-Path $taskTarget $taskSkill.name))
    if (-not $taskDestination.StartsWith($taskTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A destination leaves the requested skills directory.'
    }
    $taskExists = Test-Path -LiteralPath $taskDestination
    if ($taskExists -and -not $Force) {
        $taskSkipped++
        continue
    }
    if ($taskExists -and ((Get-Item -LiteralPath $taskDestination -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw ('Refusing to replace a linked destination: ' + $taskSkill.name)
    }
    if ($DryRun) {
        Write-Output ('PREVIEW ' + $(if ($taskExists) { 'backup and replace ' } else { 'install ' }) + $taskSkill.name)
        $taskInstalled++
        if ($taskExists) { $taskBackedUp++ }
        continue
    }
    if (-not $PSCmdlet.ShouldProcess($taskDestination, 'Install skill (back up existing directory when -Force is specified)')) {
        continue
    }
    [IO.Directory]::CreateDirectory($taskTarget) | Out-Null
    $taskBackup = $null
    if ($taskExists) {
        $taskBackupRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Directory]::GetParent($taskTarget).FullName) ('skills-backups\' + $taskTimestamp)))
        $taskBackupPrefix = $taskBackupRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        $taskBackup = [IO.Path]::GetFullPath((Join-Path $taskBackupRoot $taskSkill.name))
        if (-not $taskBackup.StartsWith($taskBackupPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'A backup leaves its designated backup directory.'
        }
        [IO.Directory]::CreateDirectory($taskBackupRoot) | Out-Null
        Move-Item -LiteralPath $taskDestination -Destination $taskBackup
        $taskBackedUp++
    }
    try {
        Copy-Item -LiteralPath $taskSource -Destination $taskDestination -Recurse
        $taskInstalled++
    } catch {
        # Keep the backup for manual recovery if a partial copy exists.
        if ($taskBackup -and -not (Test-Path -LiteralPath $taskDestination)) {
            Move-Item -LiteralPath $taskBackup -Destination $taskDestination
        }
        throw
    }
}
[pscustomobject]@{
    Mode = $(if ($DryRun) { 'preview' } elseif ($WhatIfPreference) { 'whatif' } else { 'install' })
    Total = $taskSkills.Count
    InstalledOrPlanned = $taskInstalled
    SkippedExisting = $taskSkipped
    BackedUpOrPlanned = $taskBackedUp
    TargetRoot = $taskTarget
}

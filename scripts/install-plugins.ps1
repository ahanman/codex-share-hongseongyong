[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$IncludeOfficial,
    [switch]$SkipElevenLabs
)

$ErrorActionPreference = 'Stop'
$taskRepoRoot = Split-Path -Parent $PSScriptRoot
$taskManifest = Get-Content -LiteralPath (Join-Path $taskRepoRoot 'inventory/plugins.json') -Raw | ConvertFrom-Json
$taskFailures = [System.Collections.Generic.List[string]]::new()
$taskCriticalFailures = [System.Collections.Generic.List[string]]::new()
$taskPlanned = [System.Collections.Generic.List[string]]::new()
$taskBackupDone = $false
$taskCodexCommand = Get-Command codex -ErrorAction SilentlyContinue
if (-not $taskCodexCommand) {
    if ($DryRun) {
        Write-Output 'Preview: install Codex Desktop/CLI first. This script installs 6 shared personal plugins, optionally ElevenLabs, and optionally the 21 installed official plugins.'
        return
    }
    throw 'Codex CLI is required. Install/open Codex Desktop and ensure codex is on PATH.'
}

function Get-TaskInstalled {
    $taskRaw = & codex plugin list --json | Out-String
    if ($LASTEXITCODE -ne 0) { throw 'codex plugin list --json failed.' }
    $taskResult = $taskRaw | ConvertFrom-Json
    return @($taskResult.installed)
}

function Get-TaskMarketplaces {
    $taskRaw = & codex plugin marketplace list --json | Out-String
    if ($LASTEXITCODE -ne 0) { throw 'codex plugin marketplace list --json failed.' }
    return @(($taskRaw | ConvertFrom-Json).marketplaces)
}

function Save-TaskConfigBackup {
    if ($script:taskBackupDone -or $DryRun) { return }
    $taskCodexRoot = $env:CODEX_HOME
    if (-not $taskCodexRoot) { $taskCodexRoot = Join-Path $env:USERPROFILE '.codex' }
    $taskConfig = Join-Path $taskCodexRoot 'config.toml'
    if (Test-Path -LiteralPath $taskConfig) {
        $taskBackupDir = Join-Path $taskCodexRoot 'backups/hong-codex-share'
        New-Item -ItemType Directory -Force -Path $taskBackupDir | Out-Null
        $taskBackup = Join-Path $taskBackupDir ('config-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff') + '.toml')
        Copy-Item -LiteralPath $taskConfig -Destination $taskBackup
        Write-Output ('Configuration backup: ' + $taskBackup)
    }
    $script:taskBackupDone = $true
}

function Invoke-TaskCodex {
    param([string[]]$Arguments)
    $taskDescription = 'codex ' + ($Arguments -join ' ')
    $taskPlanned.Add($taskDescription)
    if ($DryRun) { Write-Host ('Preview: ' + $taskDescription); return $true }
    Save-TaskConfigBackup | Out-Host
    & codex @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        $taskFailures.Add($taskDescription)
        Write-Warning ('Command failed; inspect the Codex catalog/account and retry: ' + $taskDescription)
        return $false
    }
    return $true
}

$taskBefore = @(Get-TaskInstalled)
$taskInstalledIds = @{}
foreach ($taskPlugin in $taskBefore) { $taskInstalledIds[$taskPlugin.pluginId] = $true }
$taskMarkets = @(Get-TaskMarketplaces)
$taskExistingShare = @($taskMarkets | Where-Object { $_.name -eq 'hong-codex-share' })
$taskCanInstallShared = $true
if ($taskExistingShare.Count -gt 0) {
    $taskExistingRoot = [IO.Path]::GetFullPath($taskExistingShare[0].root).TrimEnd([char[]]@('\', '/'))
    $taskCurrentRoot = [IO.Path]::GetFullPath($taskRepoRoot).TrimEnd([char[]]@('\', '/'))
    if ($taskExistingRoot -ne $taskCurrentRoot) {
        $taskCanInstallShared = $false
        $taskFailures.Add('hong-codex-share marketplace already points to another checkout; left unchanged.')
        $taskCriticalFailures.Add('Shared marketplace points to another checkout.')
        Write-Warning 'hong-codex-share already uses another checkout. Keep that checkout or review the registration before replacing it.'
    }
} else {
    $taskCanInstallShared = Invoke-TaskCodex -Arguments @('plugin', 'marketplace', 'add', $taskRepoRoot)
    if (-not $taskCanInstallShared) { $taskCriticalFailures.Add('Could not register the shared marketplace.') }
}
if ($taskCanInstallShared) {
    foreach ($taskPlugin in @($taskManifest.plugins | Where-Object { $_.payloadIncluded })) {
        $taskSelector = $taskPlugin.reinstall.selector
        $taskExistingPlugin = @($taskBefore | Where-Object { $_.name -eq $taskPlugin.name })
        if ($taskInstalledIds.ContainsKey($taskSelector) -or $taskExistingPlugin.Count -gt 0) {
            Write-Output ('Already installed under an existing marketplace; kept: ' + $taskPlugin.name)
            continue
        }
        $taskInstalledShared = Invoke-TaskCodex -Arguments @('plugin', 'add', $taskSelector)
        if (-not $taskInstalledShared) { $taskCriticalFailures.Add('Could not install shared plugin: ' + $taskSelector) }
    }
}

if (-not $SkipElevenLabs) {
    $taskElevenLabs = @($taskMarkets | Where-Object { $_.name -eq 'elevenlabs' })
    $taskCanInstallElevenLabs = $true
    if ($taskElevenLabs.Count -eq 0) {
        $taskCanInstallElevenLabs = Invoke-TaskCodex -Arguments @('plugin', 'marketplace', 'add', 'https://github.com/elevenlabs/plugin.git', '--ref', 'c7eef3cbcf1ff3ef12066a4e8ea964749d8e94be')
    } elseif ($taskElevenLabs[0].marketplaceSource.source -notin @('https://github.com/elevenlabs/plugin.git', 'https://github.com/elevenlabs/plugin', 'elevenlabs/plugin')) {
        $taskCanInstallElevenLabs = $false
        $taskFailures.Add('Existing elevenlabs marketplace has a different source; left unchanged.')
        Write-Warning 'Existing elevenlabs marketplace has a different source; it was left unchanged.'
    }
    if ($taskCanInstallElevenLabs -and -not $taskInstalledIds.ContainsKey('elevenlabs@elevenlabs')) {
        $null = Invoke-TaskCodex -Arguments @('plugin', 'add', 'elevenlabs@elevenlabs')
    }
}

if ($IncludeOfficial) {
    foreach ($taskPlugin in @($taskManifest.plugins | Where-Object { $_.installed -and -not $_.payloadIncluded -and $_.marketplace -ne 'elevenlabs' })) {
        $taskSelector = $taskPlugin.reinstall.selector
        if ($taskInstalledIds.ContainsKey($taskSelector)) { Write-Output ('Already installed; kept: ' + $taskSelector); continue }
        $null = Invoke-TaskCodex -Arguments @('plugin', 'add', $taskSelector)
    }
} else {
    Write-Output 'Official Codex plugins/apps remain available through the receiving account catalog. Use -IncludeOfficial to attempt their recorded selectors.'
}

$taskAfter = @(Get-TaskInstalled)
$taskSummary = [ordered]@{
    dryRun = [bool]$DryRun
    success = ($taskFailures.Count -eq 0)
    localInstallSucceeded = ($taskCriticalFailures.Count -eq 0)
    before = @($taskBefore | ForEach-Object { [ordered]@{ pluginId = $_.pluginId; version = $_.version; enabled = $_.enabled } })
    after = @($taskAfter | ForEach-Object { [ordered]@{ pluginId = $_.pluginId; version = $_.version; enabled = $_.enabled } })
    plannedCommands = @($taskPlanned)
    failures = @($taskFailures)
    criticalFailures = @($taskCriticalFailures)
    accountAction = 'Sign in separately to ElevenLabs and every app/provider you use. No credentials or sessions are transferred.'
}
Write-Output ($taskSummary | ConvertTo-Json -Depth 6)
if ($taskFailures.Count -gt 0) { Write-Warning ('Some plugin commands require attention: ' + $taskFailures.Count) }
if ($taskCriticalFailures.Count -gt 0) {
    throw 'Shared local plugin installation failed. The JSON summary above identifies the failed operations; existing user configuration was preserved and backed up before any attempted changes.'
}

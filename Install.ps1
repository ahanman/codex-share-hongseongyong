[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipSkills,
    [switch]$SkipPlugins,
    [switch]$SkipMcp,
    [switch]$IncludeLocalMcp
)
$ErrorActionPreference = 'Stop'
$taskRepoRoot = $PSScriptRoot
& (Join-Path $taskRepoRoot 'scripts/verify-package.ps1')
if (-not $?) { throw 'Package verification failed.' }
if (-not $SkipSkills) {
    & (Join-Path $taskRepoRoot 'scripts/install-skills.ps1') -DryRun:$DryRun
    if (-not $?) { throw 'Skills installation failed.' }
}
if (-not $SkipPlugins) {
    & (Join-Path $taskRepoRoot 'scripts/install-plugins.ps1') -DryRun:$DryRun -IncludeOfficial
    if (-not $?) { throw 'Plugin installation failed.' }
}
if (-not $SkipMcp) {
    & (Join-Path $taskRepoRoot 'scripts/install-mcp.ps1') -DryRun:$DryRun -InstallLocalDependencies:$IncludeLocalMcp
    if (-not $?) { throw 'MCP installation failed.' }
}
if ($DryRun) {
    Write-Host 'Preview complete. No installation changes were applied.'
} else {
    Write-Host 'Installation steps complete. Review component warnings, reconnect your own app accounts, then restart Codex.'
}

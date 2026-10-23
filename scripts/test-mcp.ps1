# Non-destructive integration test. Keeps its synthetic fixture in the OS temp directory.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('codex-share-mcp-test-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$testConfig = Join-Path $testRoot 'config.toml'
$baseline = @'
model = "gpt-6.1-sol"

[mcp_servers.higgsfield]
url = "https://example.invalid/keep"
enabled = false

[custom_state]
keep = "sentinel"
'@ + "`n"
[IO.File]::WriteAllText($testConfig, $baseline, (New-Object Text.UTF8Encoding($false)))

function Invoke-IsolatedInstaller {
    param([string[]]$AdditionalArguments = @())
    $processInfo = New-Object Diagnostics.ProcessStartInfo
    $processInfo.FileName = (Get-Process -Id $PID).Path
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $installer = Join-Path $PSScriptRoot 'install-mcp.ps1'
    foreach ($argument in @('-NoProfile', '-File', $installer) + $AdditionalArguments) {
        $processInfo.ArgumentList.Add($argument)
    }
    $processInfo.EnvironmentVariables['CODEX_HOME'] = $testRoot
    $testProcess = [Diagnostics.Process]::Start($processInfo)
    try {
        $null = $testProcess.StandardOutput.ReadToEnd()
        $errors = $testProcess.StandardError.ReadToEnd()
        $testProcess.WaitForExit()
        if ($testProcess.ExitCode -ne 0) { throw "Isolated test failed: $errors" }
    } finally { $testProcess.Dispose() }
}

Invoke-IsolatedInstaller
$firstConfig = [IO.File]::ReadAllText($testConfig)
if (-not $firstConfig.StartsWith($baseline)) { throw 'Existing configuration was changed.' }
$backups = @(Get-ChildItem -LiteralPath $testRoot -File -Filter '*.backup-share-*')
if ($backups.Count -ne 1 -or [IO.File]::ReadAllText($backups[0].FullName) -ne $baseline) { throw 'The backup does not match the original fixture.' }
foreach ($name in @('elevenlabs', 'runway', 'artlist')) {
    if ([regex]::Matches($firstConfig, [regex]::Escape("[mcp_servers.$name]")).Count -ne 1) { throw "Missing or duplicate server: $name" }
}
Invoke-IsolatedInstaller
if ([IO.File]::ReadAllText($testConfig) -ne $firstConfig) { throw 'Repeated installation changed the configuration.' }
if (@(Get-ChildItem -LiteralPath $testRoot -File -Filter '*.backup-share-*').Count -ne 1) { throw 'Repeated installation made an unnecessary backup.' }
Invoke-IsolatedInstaller -AdditionalArguments @('-DryRun', '-InstallLocalDependencies')
if (Test-Path -LiteralPath (Join-Path $testRoot 'share-mcp')) { throw 'Dry run installed local files.' }
Write-Host 'PASS: additive remote registration, existing disabled entry preservation, unrelated configuration preservation, exact backup, repeated-run idempotence, and local dry-run isolation.'
Write-Host "Synthetic fixture retained at: $testRoot"

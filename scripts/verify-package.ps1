[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$taskPackageRoot = Split-Path -Parent $PSScriptRoot
$taskChecksumPath = Join-Path $taskPackageRoot 'SHA256SUMS'
if (-not (Test-Path -LiteralPath $taskChecksumPath -PathType Leaf)) { throw 'SHA256SUMS is missing.' }
$taskVerifiedCount = 0
foreach ($taskChecksumLine in Get-Content -LiteralPath $taskChecksumPath) {
    if ([string]::IsNullOrWhiteSpace($taskChecksumLine)) { continue }
    if ($taskChecksumLine -notmatch '^([0-9a-fA-F]{64})  (.+)$') { throw 'Malformed checksum record.' }
    $taskExpectedHash = $Matches[1]
    $taskRelativePath = $Matches[2]
    if ([IO.Path]::IsPathRooted($taskRelativePath) -or $taskRelativePath -match '(^|[\\/])\.\.([\\/]|$)') { throw 'Unsafe checksum path.' }
    $taskFilePath = Join-Path $taskPackageRoot $taskRelativePath
    if (-not (Test-Path -LiteralPath $taskFilePath -PathType Leaf)) { throw "Missing package file: $taskRelativePath" }
    $taskActualHash = (Get-FileHash -LiteralPath $taskFilePath -Algorithm SHA256).Hash
    if ($taskActualHash -ne $taskExpectedHash) { throw "Checksum mismatch: $taskRelativePath" }
    $taskVerifiedCount++
}
if ($taskVerifiedCount -eq 0) { throw 'No package files were verified.' }
Write-Host "Verified $taskVerifiedCount package files."

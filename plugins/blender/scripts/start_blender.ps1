param([string]$BlenderPath = $env:BLENDER_EXECUTABLE)

$ErrorActionPreference = 'Stop'
$taskClient = [System.Net.Sockets.TcpClient]::new()
try {
    $taskConnect = $taskClient.ConnectAsync('127.0.0.1', 9876)
    if ($taskConnect.Wait(750) -and $taskClient.Connected) {
        Write-Output 'Blender MCP is already listening on localhost:9876.'
        exit 0
    }
} catch {} finally { $taskClient.Dispose() }
$taskBlender = $BlenderPath
if (-not $taskBlender) {
    $taskCommand = Get-Command blender -ErrorAction SilentlyContinue
    if ($taskCommand) { $taskBlender = $taskCommand.Source }
}
if (-not $taskBlender) {
    $taskCandidates = @()
    foreach ($taskBase in @($env:ProgramFiles, (Join-Path $env:LOCALAPPDATA 'Programs'))) {
        if ($taskBase -and (Test-Path -LiteralPath $taskBase)) {
            $taskCandidates += Get-ChildItem -Path (Join-Path $taskBase 'Blender*\*\blender.exe') -File -ErrorAction SilentlyContinue
        }
    }
    if ($taskCandidates.Count -eq 1) { $taskBlender = $taskCandidates[0].FullName }
    elseif ($taskCandidates.Count -gt 1) { throw 'Several Blender installations were found. Pass -BlenderPath to select one.' }
}
if (-not $taskBlender -or -not (Test-Path -LiteralPath $taskBlender)) {
    throw 'Blender was not found. Install Blender, then pass -BlenderPath or set BLENDER_EXECUTABLE.'
}
$taskProcess = Start-Process -FilePath $taskBlender -WindowStyle Hidden -PassThru
Write-Output ('Started Blender process ' + $taskProcess.Id + '. The MCP add-on connects when the scene is ready.')

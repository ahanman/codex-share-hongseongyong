[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$InstallLocalDependencies,
    [string]$InstallRoot,
    [string]$GhidraInstallDir,
    [string]$JavaHomePath
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$upstreamCommit = 'be4f495bcabeb51ecd3f4221f026feca698a416f'
$codexExecutable = (Get-Command codex -ErrorAction Stop).Source
$targetCodexDirectory = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
if (-not $InstallRoot) { $InstallRoot = Join-Path $targetCodexDirectory 'share-mcp' }
$targetConfigPath = Join-Path $targetCodexDirectory 'config.toml'
$script:mcpBackupPath = $null
$remoteServers = [ordered]@{
    higgsfield = 'https://mcp.higgsfield.ai/mcp'
    elevenlabs = 'https://api.us.elevenlabs.io/v1/mcp'
    runway = 'https://mcp.runwayml.com/mcp'
    artlist = 'https://mcp.artlist.io/mcp'
}

function Invoke-Checked {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $Executable (exit $LASTEXITCODE)." }
}

function Get-McpNamesFromJson {
    param([string]$Json)
    $entries = @($Json | ConvertFrom-Json)
    @($entries | ForEach-Object { $_.name })
}

function Get-CurrentMcpNames {
    $json = & $codexExecutable mcp list --json 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Codex could not read the current configuration. Resolve that error before installing MCP entries.' }
    Get-McpNamesFromJson -Json ($json -join "`n")
}

function Test-CandidateConfig {
    param([string]$Content)
    $candidateDirectory = Join-Path ([IO.Path]::GetTempPath()) ('codex-mcp-check-' + [guid]::NewGuid().ToString('N'))
    $candidatePath = Join-Path $candidateDirectory 'config.toml'
    try {
        [IO.Directory]::CreateDirectory($candidateDirectory) | Out-Null
        [IO.File]::WriteAllText($candidatePath, $Content, (New-Object Text.UTF8Encoding($false)))
        $startInfo = New-Object Diagnostics.ProcessStartInfo
        $startInfo.FileName = $codexExecutable
        $startInfo.Arguments = 'mcp list --json'
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.EnvironmentVariables['CODEX_HOME'] = $candidateDirectory
        $process = [Diagnostics.Process]::Start($startInfo)
        try {
            $json = $process.StandardOutput.ReadToEnd()
            $null = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) { throw 'The candidate MCP configuration was rejected by Codex. The existing configuration was not changed.' }
            Get-McpNamesFromJson -Json $json
        } finally { $process.Dispose() }
    } finally {
        if (Test-Path -LiteralPath $candidatePath) { Remove-Item -LiteralPath $candidatePath -Force }
        # Nonrecursive cleanup cannot delete unrelated temporary files.
        try { [IO.Directory]::Delete($candidateDirectory, $false) } catch { }
    }
}

function Add-RemoteServers {
    if ($DryRun) {
        $existingNames = @(Get-CurrentMcpNames)
        foreach ($name in $remoteServers.Keys) {
            if ($existingNames -contains $name) { Write-Host "SKIP existing MCP: $name" }
            else { Write-Host "DRY RUN add remote MCP: $name ($($remoteServers[$name]))" }
        }
        return
    }
    [IO.Directory]::CreateDirectory($targetCodexDirectory) | Out-Null
    $configExisted = Test-Path -LiteralPath $targetConfigPath
    $configStream = [IO.File]::Open($targetConfigPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $originalBytes = New-Object byte[] ([int]$configStream.Length)
        $readCount = 0
        while ($readCount -lt $originalBytes.Length) {
            $readCount += $configStream.Read($originalBytes, $readCount, $originalBytes.Length - $readCount)
        }
        $originalContent = [Text.Encoding]::UTF8.GetString($originalBytes)
        $existingNames = @(Test-CandidateConfig -Content $originalContent)
        $additions = ''
        $addedNames = @()
        foreach ($name in $remoteServers.Keys) {
            if ($existingNames -contains $name) { Write-Host "SKIP existing MCP: $name"; continue }
            $additions += "`n[mcp_servers.$name]`nurl = `"$($remoteServers[$name])`"`nenabled = true`n"
            $addedNames += $name
        }
        if ($addedNames.Count -eq 0) { return }
        $null = @(Test-CandidateConfig -Content ($originalContent + $additions))
        if ($configExisted) {
            $script:mcpBackupPath = $targetConfigPath + '.backup-share-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            [IO.File]::WriteAllBytes($script:mcpBackupPath, $originalBytes)
            Write-Host "Configuration backup: $script:mcpBackupPath"
        }
        $appendBytes = (New-Object Text.UTF8Encoding($false)).GetBytes($additions)
        $configStream.Seek(0, [IO.SeekOrigin]::End) | Out-Null
        $configStream.Write($appendBytes, 0, $appendBytes.Length)
        $configStream.Flush()
        foreach ($name in $addedNames) { Write-Host "ADDED remote MCP: $name" }
    } finally { $configStream.Dispose() }
}

function Add-LocalServer {
    param([string]$Name, [string]$Command, [string[]]$CommandArguments, [string[]]$EnvironmentArguments = @())
    $existingNames = @(Get-CurrentMcpNames)
    if ($existingNames -contains $Name) { Write-Host "SKIP existing MCP: $Name"; return }
    if ($DryRun) { Write-Host "DRY RUN add local MCP: $Name"; return }
    if (-not $script:mcpBackupPath -and (Test-Path -LiteralPath $targetConfigPath)) {
        $script:mcpBackupPath = $targetConfigPath + '.backup-share-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        Copy-Item -LiteralPath $targetConfigPath -Destination $script:mcpBackupPath
        Write-Host "Configuration backup: $script:mcpBackupPath"
    }
    $arguments = @('mcp', 'add', $Name) + $EnvironmentArguments + @('--', $Command) + $CommandArguments
    Invoke-Checked -Executable $codexExecutable -Arguments $arguments
}

Add-RemoteServers

if ($InstallLocalDependencies) {
    $seedanceDirectory = Join-Path $InstallRoot 'seedance-direct'
    $arkDirectory = Join-Path $seedanceDirectory 'ark-mcp'
    $npmDirectory = Join-Path $InstallRoot 'npm-mcp'
    if (-not $DryRun) {
        $gitExecutable = (Get-Command git -ErrorAction Stop).Source
        $uvExecutable = (Get-Command uv -ErrorAction Stop).Source
        $npmExecutable = (Get-Command npm -ErrorAction Stop).Source
        $nodeExecutable = (Get-Command node -ErrorAction Stop).Source
        $nodeVersion = (& $nodeExecutable -p 'process.versions.node').Trim()
        $nodeParts = [version]$nodeVersion
        if (-not (($nodeParts.Major -eq 22 -and $nodeParts -ge [version]'22.19.0') -or ($nodeParts.Major -eq 24 -and $nodeParts -ge [version]'24.11.0') -or $nodeParts.Major -ge 26)) {
            throw 'REA requires Node 22.19+, 24.11+, or 26+. Install a supported Node version and run again.'
        }
        [IO.Directory]::CreateDirectory($seedanceDirectory) | Out-Null
        foreach ($filename in @('launch.py', 'credentials.py', 'setup-key.py', 'settings.example.env', 'UPSTREAM.md')) {
            $destination = Join-Path $seedanceDirectory $filename
            if (-not (Test-Path -LiteralPath $destination)) {
                Copy-Item -LiteralPath (Join-Path (Join-Path $repositoryRoot 'mcp\seedance-direct') $filename) -Destination $destination
            } else { Write-Host "SKIP existing Seedance file: $filename" }
        }
        if (-not (Test-Path -LiteralPath $arkDirectory)) {
            Invoke-Checked -Executable $gitExecutable -Arguments @('clone', '--no-checkout', 'https://github.com/byteplus-sa/ark-mcp.git', $arkDirectory)
            Invoke-Checked -Executable $gitExecutable -Arguments @('-C', $arkDirectory, 'checkout', '--detach', $upstreamCommit)
        } else {
            $existingCommit = & $gitExecutable -C $arkDirectory rev-parse HEAD 2>$null
            if ($LASTEXITCODE -ne 0 -or ($existingCommit -join '').Trim() -ne $upstreamCommit) { throw 'An existing Ark directory has a different commit. Choose another -InstallRoot; existing sources were not changed.' }
            $existingChanges = & $gitExecutable -C $arkDirectory status --porcelain 2>$null
            if ($LASTEXITCODE -ne 0 -or $existingChanges) { throw 'The existing Ark source has local changes. Choose another -InstallRoot.' }
        }
        Invoke-Checked -Executable $uvExecutable -Arguments @('sync', '--project', $arkDirectory, '--frozen', '--no-dev', '--python', '3.12')
        $seedancePython = Join-Path $arkDirectory '.venv\Scripts\python.exe'
        Invoke-Checked -Executable $uvExecutable -Arguments @('pip', 'install', '--python', $seedancePython, 'keyring==25.7.0')
        [IO.Directory]::CreateDirectory($npmDirectory) | Out-Null
        Invoke-Checked -Executable $npmExecutable -Arguments @('install', '--prefix', $npmDirectory, '--save-exact', '--ignore-scripts', '@sync.so/mcp-server@0.1.4', 'rea-agents@6.7.0')
    } else {
        $nodeExecutable = '<receiver node.exe>'
        $seedancePython = Join-Path $arkDirectory '.venv\Scripts\python.exe'
        Write-Host "DRY RUN install pinned Ark source, Python environment, keyring and npm packages under: $InstallRoot"
    }
    Add-LocalServer -Name 'seedance-direct' -Command $seedancePython -CommandArguments @((Join-Path $seedanceDirectory 'launch.py'))
    Add-LocalServer -Name 'sync' -Command $nodeExecutable -CommandArguments @((Join-Path $npmDirectory 'node_modules\@sync.so\mcp-server\dist\cli.js'), '--transport', 'stdio')
    $reaEnvironment = @()
    if ($GhidraInstallDir) { $reaEnvironment += @('--env', "GHIDRA_INSTALL_DIR=$GhidraInstallDir", '--env', 'REA_ANALYSIS_PROVIDER=ghidra') }
    if ($JavaHomePath) { $reaEnvironment += @('--env', "JAVA_HOME=$JavaHomePath") }
    Add-LocalServer -Name 'rea' -Command $nodeExecutable -CommandArguments @((Join-Path $npmDirectory 'node_modules\rea-agents\scripts\rea.mjs'), 'mcp') -EnvironmentArguments $reaEnvironment
    Write-Host "Seedance own-key setup: & '$seedancePython' '$(Join-Path $seedanceDirectory 'setup-key.py')'"
    Write-Host 'Sync uses receiver device login on first MCP launch when no own API key is configured.'
} else {
    Write-Host 'Local MCP dependencies were skipped. Use -InstallLocalDependencies to install Seedance, Sync and REA.'
}

Write-Host 'node_repl stays managed by the receiving Codex installation.'
Write-Host 'No service login was performed. Authenticate with your own service accounts, then restart Codex and open a new chat.'

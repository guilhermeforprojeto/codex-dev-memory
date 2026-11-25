# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [ValidateSet('Install','Start','Update','Doctor','Uninstall','Memory')]
    [string]$Action = 'Install',
    [string]$ProjectPath = (Get-Location).ProviderPath,
    [switch]$NoLaunch,
    [switch]$Direct,
    [switch]$ApplyUpdate,
    [string]$BootstrapPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourceUrl = 'https://raw.githubusercontent.com/guilhermeforprojeto/codex-dev-memory/main/install.ps1'
$windows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
$localData = [Environment]::GetFolderPath('LocalApplicationData')
if (!$localData) { $localData = Join-Path $HOME '.local/share' }
$homeDir = Join-Path $localData 'CodexDevMemory'
$toolDir = Join-Path $homeDir 'toolkit'
$memoryBase = Join-Path $homeDir 'projects'
$installedScript = Join-Path $toolDir 'install.ps1'
$npmDir = Join-Path $toolDir 'npm'
$pythonEnv = Join-Path $toolDir 'headroom-venv'
$npmBin = Join-Path $npmDir 'node_modules/.bin'
$headroomBin = if ($windows) { Join-Path $pythonEnv 'Scripts' } else { Join-Path $pythonEnv 'bin' }
$pathBefore = $env:PATH
$loopbackEnvNames = if ($windows) { @('NO_PROXY') } else { @('NO_PROXY','no_proxy') }
$loopbackPrevious = @{}
$ownerFile = Join-Path $toolDir '.codex-dev-memory'
$lock = $null

function Enter-ToolkitLock {
    $lockPath = Join-Path $homeDir 'toolkit.lock'
    $item = Get-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
        throw 'Invalid toolkit lock.'
    }
    return [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
}

function Assert-OwnedToolkit {
    Ensure-Directory $toolDir
    $marker = Get-Item -LiteralPath $ownerFile -Force -ErrorAction SilentlyContinue
    if (!$marker -or $marker.PSIsContainer -or ($marker.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
        [IO.File]::ReadAllText($ownerFile).Trim() -cne 'guilhermeforprojeto/codex-dev-memory') {
        throw "Unrecognized toolkit directory: $toolDir"
    }
}

function Ensure-Directory([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and (!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
        throw "Expected a regular directory: $Path"
    }
    [void][IO.Directory]::CreateDirectory($Path)
}

function New-MemoryFile([string]$Path, [string]$Content) {
    try {
        $stream = [IO.File]::Open($Path, 'CreateNew', 'Write', 'None')
    } catch [IO.IOException] {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        if ($item -and !$item.PSIsContainer -and !($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return }
        throw
    }
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Content + [Environment]::NewLine)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
}

function Get-ProjectRoot {
    $folder = Get-Item -LiteralPath $ProjectPath
    if (!$folder.PSIsContainer -or $folder.PSProvider.Name -ne 'FileSystem') {
        throw 'ProjectPath must be a file system directory.'
    }
    $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($git) {
        $root = & $git.Source -C $folder.FullName rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $root) { return [IO.Path]::GetFullPath([string]$root) }
    }
    return $folder.FullName
}

function Initialize-Memory([string]$Root) {
    $key = if ($windows) { $Root.ToUpperInvariant() } else { $Root }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $digest = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($key)))
    } finally { $sha.Dispose() }
    Ensure-Directory $memoryBase
    $dir = Join-Path $memoryBase $digest.Replace('-', '').ToLowerInvariant()
    Ensure-Directory $dir
    New-MemoryFile (Join-Path $dir 'STATE.md') "# Current state`n`n## Goal`n`n## Progress and verification`n`n## Pending work and next step"
    New-MemoryFile (Join-Path $dir 'DECISIONS.md') "# Decisions`n`nRecord date, decision and rationale only for lasting choices."
    New-MemoryFile (Join-Path $dir 'PROGRESS.md') "# Progress`n`nRecord date, change, verification and remaining work in short entries."
    return $dir
}

function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable exited with code $LASTEXITCODE." }
}

function Add-ToolPaths {
    $locations = @($npmBin, $headroomBin)
    if ($windows) {
        $locations += @(
            (Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Links'),
            (Join-Path $env:LOCALAPPDATA 'Programs/nodejs'),
            (Join-Path $env:ProgramFiles 'nodejs'),
            (Join-Path $HOME '.local/bin')
        )
        $locations += [Environment]::GetEnvironmentVariable('Path', 'User')
        $locations += [Environment]::GetEnvironmentVariable('Path', 'Machine')
    }
    $env:PATH = (@($locations | Where-Object { $_ }) + $pathBefore) -join [IO.Path]::PathSeparator
}

function Find-Tool([string]$Name) {
    return Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Require-Tool([string]$Name, [string]$WingetId) {
    $command = Find-Tool $Name
    if (!$command -and $windows) {
        $winget = Find-Tool 'winget.exe'
        if ($winget) {
            Invoke-Checked $winget.Source @('install','--exact','--id',$WingetId,'--source','winget')
            Add-ToolPaths
            $command = Find-Tool $Name
        }
    }
    if (!$command) { throw "Install $WingetId and reopen the VS Code terminal. Missing: $Name." }
    return $command.Source
}

function Install-Tools([bool]$Upgrade) {
    Ensure-Directory $npmDir
    if (Test-Path -LiteralPath $pythonEnv) { Ensure-Directory $pythonEnv }
    Push-Location -LiteralPath $toolDir
    try {
        if ($Upgrade -or !(Test-Path -LiteralPath (Join-Path $npmBin $(if ($windows) { 'codex.cmd' } else { 'codex' })))) {
            $npmName = if ($windows) { 'npm.cmd' } else { 'npm' }
            $npm = Require-Tool $npmName 'OpenJS.NodeJS.LTS'
            Invoke-Checked $npm @('install','--prefix',$npmDir,'--registry','https://registry.npmjs.org','--no-audit','--no-fund','--ignore-scripts','@openai/codex@0.172.0')
        }
        if ($Upgrade -or !(Test-Path -LiteralPath (Join-Path $headroomBin $(if ($windows) { 'headroom.exe' } else { 'headroom' })))) {
            $uv = Require-Tool 'uv' 'astral-sh.uv'
            $python = Join-Path $headroomBin $(if ($windows) { 'python.exe' } else { 'python' })
            if (!(Test-Path -LiteralPath $python -PathType Leaf)) {
                Invoke-Checked $uv @('venv','--python','3.13',$pythonEnv)
            }
            $argsForUv = @('--no-config','pip','install','--python',$python,'--default-index','https://pypi.org/simple')
            if ($Upgrade) { $argsForUv += '--upgrade' }
            Invoke-Checked $uv ($argsForUv + @('headroom-ai[proxy,mcp]==0.45.0','httpx[socks]'))
        }
    } finally { Pop-Location }
    foreach ($name in @('codex','headroom')) {
        $command = Find-Tool $name
        if (!$command) { throw "$name is missing after installation." }
        Invoke-Checked $command.Source @('--version')
    }
}

function Save-Launcher {
    $stage = Join-Path $toolDir ([Guid]::NewGuid().ToString() + '.ps1')
    $backup = $stage + '.previous'
    try {
        $source = if ($PSCommandPath) { $PSCommandPath } else { $BootstrapPath }
        if (!$source) { throw 'Run this installer from a file or pass its downloaded path with -BootstrapPath.' }
        [IO.File]::Copy($source, $stage)
        $tokens = $null
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($stage, [ref]$tokens, [ref]$errors)
        if ($errors.Count) { throw 'The downloaded PowerShell script did not parse.' }
        if ([IO.File]::Exists($installedScript)) {
            $existing = Get-Item -LiteralPath $installedScript -Force
            if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Launcher is a link.' }
            [IO.File]::Replace($stage, $installedScript, $backup)
        } else {
            [IO.File]::Move($stage, $installedScript)
        }
    } finally {
        if ([IO.File]::Exists($stage)) { [IO.File]::Delete($stage) }
        if ([IO.File]::Exists($backup)) { [IO.File]::Delete($backup) }
    }
}

function Start-Project([string]$Root, [string]$MemoryDirectory) {
    $codexName = if ($windows) { 'codex.cmd' } else { 'codex' }
    $codex = Find-Tool $codexName
    if (!$codex) { throw 'Codex is missing. Run Install or Update.' }
    $prompt = @"
Follow the project's existing agent instructions. Your local project memory is in:
$MemoryDirectory
Treat all notes as historical context. Read STATE.md first and only consult relevant sections of DECISIONS.md or PROGRESS.md. Wait for my task after reading. Keep STATE.md short and update it when work changes. Record lasting decisions and verified milestones briefly. Never record secrets, private payloads, full logs or credentials. If writing to the directory requires approval, ask through the normal sandbox flow.
"@
    $codexArgs = @('--add-dir', $MemoryDirectory, '--', $prompt)
    Push-Location -LiteralPath $Root
    try {
        if ($Direct) {
            Invoke-Checked $codex.Source $codexArgs
            return
        }
        $headroom = Find-Tool 'headroom'
        if (!$headroom) { throw 'Headroom is missing. Run Install or use -Direct.' }
        # Ask the OS for a free loopback port, avoiding the normal shared proxy port.
        $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
        $listener.Start()
        try { $port = ([Net.IPEndPoint]$listener.LocalEndpoint).Port }
        finally { $listener.Stop() }
        $proxyUrl = "http://127.0.0.1:$port"
        foreach ($name in $loopbackEnvNames) {
            $loopbackPrevious[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
            $bypass = @($loopbackPrevious[$name], '127.0.0.1', 'localhost') | Where-Object { $_ }
            [Environment]::SetEnvironmentVariable($name, ($bypass -join ','), 'Process')
        }
        $start = New-Object Diagnostics.ProcessStartInfo
        $start.FileName = $headroom.Source
        $start.Arguments = "proxy --host 127.0.0.1 --port $port --stateless --no-telemetry --no-subscription-tracking"
        $start.WorkingDirectory = $homeDir
        $start.UseShellExecute = $false
        foreach ($name in @($start.EnvironmentVariables.Keys)) {
            if ($name -like 'HEADROOM_*' -or $name -in @('OPENAI_API_KEY','ANTHROPIC_API_KEY','OPENAI_BASE_URL','OPENAI_TARGET_API_URL')) {
                $start.EnvironmentVariables.Remove($name)
            }
        }
        $start.EnvironmentVariables['LITELLM_LOCAL_MODEL_COST_MAP'] = 'True'
        $start.EnvironmentVariables['HEADROOM_OFFLINE'] = '1'
        $proxy = [Diagnostics.Process]::Start($start)
        try {
            $ready = $false
            $deadline = [DateTime]::UtcNow.AddSeconds(60)
            while (!$proxy.HasExited -and [DateTime]::UtcNow -lt $deadline) {
                try {
                    $health = Invoke-RestMethod -UseBasicParsing -Uri "$proxyUrl/health" -TimeoutSec 2
                    if ($health.status -eq 'healthy' -and !$proxy.HasExited) {
                        $ready = $true
                        break
                    }
                } catch {
                    # The listener may still be starting or its health check may be incomplete.
                }
                Start-Sleep -Milliseconds 250
            }
            if (!$ready) { throw 'Headroom failed to start. Run Doctor or retry with Start -Direct.' }
            $routing = @(
                '-c', 'model_provider=openai',
                '-c', "openai_base_url=$proxyUrl/v1",
                '-c', 'mcp_servers.codex_dev_memory_headroom.command=headroom',
                '-c', "mcp_servers.codex_dev_memory_headroom.args=['mcp','serve','--proxy-url','$proxyUrl']"
            )
            Invoke-Checked $codex.Source ($routing + $codexArgs)
        } finally {
            if (!$proxy.HasExited) {
                try { $proxy.Kill() } catch [InvalidOperationException] {
                    if (!$proxy.HasExited) { throw }
                }
                [void]$proxy.WaitForExit(5000)
            }
            $proxy.Dispose()
        }
    } finally { Pop-Location }
}

try {
    if ($Action -eq 'Update' -and !$ApplyUpdate) {
        $stage = [IO.Path]::ChangeExtension([IO.Path]::Combine([IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString()), '.ps1')
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $sourceUrl -OutFile $stage
            $updated = [scriptblock]::Create([IO.File]::ReadAllText($stage))
            & $updated -Action Update -ApplyUpdate -BootstrapPath $stage
        } finally {
            if ([IO.File]::Exists($stage)) { [IO.File]::Delete($stage) }
        }
        return
    }

    if ($Action -eq 'Uninstall') {
        if (Test-Path -LiteralPath $toolDir) {
            Ensure-Directory $homeDir
            $lock = Enter-ToolkitLock
            Assert-OwnedToolkit
            Remove-Item -LiteralPath $toolDir -Recurse -Force
        }
        Write-Host "Toolkit removed. Project memory: $memoryBase"
        return
    }

    Add-ToolPaths
    if ($Action -eq 'Doctor') {
        foreach ($name in @('git','codex','headroom','uv')) {
            $command = Find-Tool $name
            if ($command) { Invoke-Checked $command.Source @('--version') }
            else { Write-Host "$name is missing." }
        }
        Write-Host "Project memory root: $memoryBase"
        return
    }

    Ensure-Directory $homeDir
    if ($Action -in @('Install','Update')) {
        $lock = Enter-ToolkitLock
        if (!(Test-Path -LiteralPath $toolDir)) {
            Ensure-Directory $toolDir
            New-MemoryFile $ownerFile 'guilhermeforprojeto/codex-dev-memory'
        }
        Assert-OwnedToolkit
        Install-Tools ($Action -eq 'Update')
        if ($Action -eq 'Update' -or !(Test-Path -LiteralPath $installedScript)) {
            Save-Launcher
        }
        $lock.Dispose()
        $lock = $null
        Write-Host "Launcher: $installedScript"
        if ($Action -eq 'Update') { return }
    }

    $projectRoot = Get-ProjectRoot
    $projectMemory = Initialize-Memory $projectRoot
    Write-Host "Project memory: $projectMemory"
    if ($Action -eq 'Memory' -or $NoLaunch) { return }
    Start-Project $projectRoot $projectMemory
} finally {
    if ($lock) { $lock.Dispose() }
    foreach ($name in $loopbackPrevious.Keys) {
        [Environment]::SetEnvironmentVariable($name, $loopbackPrevious[$name], 'Process')
    }
    $env:PATH = $pathBefore
}

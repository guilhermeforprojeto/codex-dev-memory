param([string]$ProjectPath=(Get-Location).Path, [switch]$SkipDoctor)
. (Join-Path $PSScriptRoot 'scripts/common.ps1')
$ProgressPreference = 'SilentlyContinue'
if ($env:OS -ne 'Windows_NT') { throw 'This installer targets Windows. See developer instructions for Python tests on other systems.' }
if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -ne 'X64') { throw 'This release is validated for Windows x64 only.' }
$root = (Resolve-Path -LiteralPath $ProjectPath).Path
$data = Join-Path $root '.codex-dev-memory'
if (Test-Path -LiteralPath $data) {
    if ((Get-Item -LiteralPath $data -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Memory directory cannot be a link/junction.' }
}
New-Item -ItemType Directory -Force -Path $data | Out-Null
$toolsDir = Join-Path $data 'tools'
New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
function Get-VerifiedArchive([string]$Url,[string]$ChecksumUrl,[string]$Name,[string]$Destination) {
    $zip = Join-Path $toolsDir $Name
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $zip
    $checks = (Invoke-WebRequest -UseBasicParsing -Uri $ChecksumUrl).Content
    if ($checks -is [byte[]]) { $checks = [Text.Encoding]::UTF8.GetString($checks) }
    $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not ($checks -match "(?im)^$actual(?:\s+\*?$([regex]::Escape($Name)))?\s*$")) { throw "Checksum failed: $Name" }
    Expand-Archive -LiteralPath $zip -DestinationPath $Destination -Force
}
$uvCommand = Get-Command uv -ErrorAction SilentlyContinue
if ($uvCommand) { $uvExe = $uvCommand.Source }
else {
    $uvExe = Join-Path $toolsDir 'uv/uv.exe'
    if (-not (Test-Path -LiteralPath $uvExe)) {
        $uvBase = 'https://github.com/astral-sh/uv/releases/download/0.13.9'
        Get-VerifiedArchive "$uvBase/uv-x86_64-pc-windows-msvc.zip" "$uvBase/uv-x86_64-pc-windows-msvc.zip.sha256" 'uv-x86_64-pc-windows-msvc.zip' (Join-Path $toolsDir 'uv')
    }
}
$oldPath = $env:PATH
$oldPythonDir = $env:UV_PYTHON_INSTALL_DIR
$oldCache = $env:UV_CACHE_DIR
try {
    $env:UV_PYTHON_INSTALL_DIR = Join-Path $data 'python'
    if (-not $env:UV_CACHE_DIR) { $env:UV_CACHE_DIR = Join-Path $data 'uv-cache' }
    $codexCommand = Get-Command codex -ErrorAction SilentlyContinue
    if ($codexCommand) { $codexExe = $codexCommand.Source }
    elseif (Test-Path (Join-Path $toolsDir 'codex/node_modules/.bin/codex.cmd')) {
        $codexExe = Join-Path $toolsDir 'codex/node_modules/.bin/codex.cmd'
        $nodeDir = Join-Path $toolsDir 'node-v24.15.0-win-x64'
        if (Test-Path (Join-Path $nodeDir 'node.exe')) { $env:PATH = "$nodeDir;$env:PATH" }
    }
    else {
        $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
        if (-not $nodeCommand) {
            $nodeDir = Join-Path $toolsDir 'node-v24.15.0-win-x64'
            if (-not (Test-Path (Join-Path $nodeDir 'node.exe'))) {
                Get-VerifiedArchive 'https://nodejs.org/dist/v24.15.0/node-v24.15.0-win-x64.zip' 'https://nodejs.org/dist/v24.15.0/SHASUMS256.txt' 'node-v24.15.0-win-x64.zip' $toolsDir
            }
            $env:PATH = "$nodeDir;$env:PATH"
        }
        $npm = Get-Command npm.cmd -ErrorAction Stop
        $codexDir = Join-Path $toolsDir 'codex'
        & $npm.Source install --prefix $codexDir --no-audit --no-fund '@openai/codex'
        Assert-Exit 'Codex installation'
        $codexExe = Join-Path $codexDir 'node_modules/.bin/codex.cmd'
    }
    $runtime = Join-Path $data 'runtime'
    $python = Join-Path $runtime 'Scripts/python.exe'
    if (-not (Test-Path -LiteralPath $python)) {
        & $uvExe venv --python 3.12 $runtime
        Assert-Exit 'Python environment'
    }
    & $uvExe pip install --python $python --require-hashes -r (Join-Path $PSScriptRoot 'requirements.lock')
    Assert-Exit 'Pinned dependencies'
    $app = Join-Path $data 'app'
    if ([IO.Path]::GetFullPath($PSScriptRoot) -ne [IO.Path]::GetFullPath($app)) {
        # Preserve the previous implementation before an upgrade.
        if (Test-Path -LiteralPath $app) {
            $backup = Join-Path $data ('backups/app-' + (Get-Date -Format 'yyyyMMddTHHmmssffff'))
            Copy-Item -LiteralPath $app -Destination $backup -Recurse
        }
        New-Item -ItemType Directory -Force -Path $app | Out-Null
        foreach ($name in @('cdm','scripts','templates')) {
            $target = Join-Path $app $name
            New-Item -ItemType Directory -Force -Path $target | Out-Null
            Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot $name) -File |
                Where-Object { $_.Extension -in '.py','.ps1','.md' } |
                Copy-Item -Destination $target -Force
        }
        Get-ChildItem -LiteralPath $PSScriptRoot -File |
            Where-Object { $_.Extension -eq '.ps1' -or $_.Name -in 'pyproject.toml','requirements.lock','LICENSE' } |
            Copy-Item -Destination $app -Force
    }
    & $python (Join-Path $app 'scripts/cdm.py') --project $root init --download-models
    Assert-Exit 'Local models / memory initialization'
    Push-Location $app
    try { & $python -m cdm.setup install --project $root --source $app --python $python --codex $codexExe; Assert-Exit 'Project integration' }
    finally { Pop-Location }
    & $python (Join-Path $app 'scripts/cdm.py') --project $root checkpoint
    Assert-Exit 'Initial checkpoint'
    if (-not $SkipDoctor) { & (Join-Path $app 'doctor.ps1') -ProjectPath $root }
    Write-Host "Installed. Start: & '.\.codex-dev-memory\cdm.ps1' start"
    Write-Host 'No global Codex config, auth or Windows security policy was changed.'
    Write-Host 'Review/trust the project hooks in Codex to enable automatic checkpoint ingestion.'
} finally {
    $env:PATH = $oldPath
    $env:UV_PYTHON_INSTALL_DIR = $oldPythonDir
    $env:UV_CACHE_DIR = $oldCache
}

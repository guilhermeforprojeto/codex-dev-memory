param(
    [string]$InstallPath=(Join-Path $env:LOCALAPPDATA 'CodexDevMemoryCommand'),
    [string]$BinPath=(Join-Path $env:USERPROFILE '.local/bin'),
    [switch]$NoPath
)
$ErrorActionPreference='Stop'
$root = [IO.Path]::GetFullPath($InstallPath)
$bin = [IO.Path]::GetFullPath($BinPath)
$owner = Join-Path $root '.owner'
$identity = 'guilhermeforprojeto/codex-dev-memory/global-command'
foreach ($dir in @($root,$bin)) {
    if (Test-Path -LiteralPath $dir) {
        $item = Get-Item -LiteralPath $dir -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Expected a regular directory: $dir"
        }
    }
}
if ((Test-Path -LiteralPath $root) -and
    (-not (Test-Path -LiteralPath $owner) -or [IO.File]::ReadAllText($owner).Trim() -ne $identity)) {
    throw "Unrecognized command directory; existing files preserved: $root"
}
$shim = Join-Path $bin 'codex-memory.cmd'
if ((Test-Path -LiteralPath $shim) -and -not ([IO.File]::ReadAllText($shim).Contains(':: codex-dev-memory managed command'))) {
    throw "An unrelated codex-memory command already exists: $shim"
}
New-Item -ItemType Directory -Force -Path $root,$bin | Out-Null
[IO.File]::WriteAllText($owner,$identity)
$app = Join-Path $root 'app'
if (Test-Path -LiteralPath $app) {
    $backup = Join-Path $root ('backups/app-' + (Get-Date -Format 'yyyyMMddTHHmmssffff'))
    New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
    Copy-Item -LiteralPath $app -Destination $backup -Recurse
}
New-Item -ItemType Directory -Force -Path $app | Out-Null
foreach ($name in @('cdm','scripts','templates')) {
    $target = Join-Path $app $name
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot $name) -File |
        Where-Object { $_.Extension -in '.py','.ps1','.md' } | Copy-Item -Destination $target -Force
}
Get-ChildItem -LiteralPath $PSScriptRoot -File |
    Where-Object { $_.Extension -eq '.ps1' -or $_.Name -in 'requirements.lock','pyproject.toml','LICENSE' } |
    Copy-Item -Destination $app -Force
$entry = (Join-Path $app 'scripts/global-launch.ps1').Replace('%','%%')
$content = "@echo off`r`n:: codex-dev-memory managed command`r`npowershell.exe -NoLogo -NoProfile -File `"$entry`" %*`r`nexit /b %errorlevel%`r`n"
[IO.File]::WriteAllText($shim,$content,[Text.Encoding]::Default)
if (-not $NoPath) {
    [string]$userPath = [Environment]::GetEnvironmentVariable('Path','User')
    $entries = @($userPath -split ';' | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\','/') })
    if ($entries -notcontains $bin.TrimEnd('\','/')) {
        [IO.File]::WriteAllText((Join-Path $root ('path-before-' + (Get-Date -Format 'yyyyMMddTHHmmssffff') + '.txt')), [string]$userPath)
        [Environment]::SetEnvironmentVariable('Path',($userPath.TrimEnd(';') + ';' + $bin),'User')
    }
    if (($env:PATH -split ';') -notcontains $bin) { $env:PATH = "$bin;$env:PATH" }
}
Write-Host 'Pronto. Na pasta de qualquer projeto, execute: codex-memory'
Write-Host 'Se o terminal ja estava aberto e nao reconhecer o comando, reabra o terminal/VS Code.'

# The shim forwards all arguments without PowerShell parameter binding.
$ErrorActionPreference = 'Stop'
$source = Split-Path $PSScriptRoot -Parent
[string[]]$forward = @($args)
if ($forward.Count -gt 0 -and $forward[0] -in @('--help','help')) {
    Write-Host 'Codex com memoria local e Headroom'
    Write-Host 'Na pasta de qualquer projeto, execute: codex-memory'
    Write-Host 'A primeira execucao prepara o projeto. Depois, peca suas alteracoes normalmente.'
    Write-Host 'Outros comandos: codex-memory doctor | update | memory status | metrics | uninstall'
    Write-Host 'Retomar uma conversa: codex-memory resume --last'
    exit 0
}
$versionText = Get-Content (Join-Path $source 'cdm/__init__.py') -Raw
if ($versionText -notmatch '__version__\s*=\s*"([0-9.]+)"') { throw 'Invalid application version.' }
$version = $Matches[1]
if ($forward.Count -gt 0 -and $forward[0] -eq '--version') {
    Write-Output "codex-memory $version"
    exit 0
}
# Prefer the nearest initialized project or Git root, including from a subdirectory.
$root = (Get-Location).ProviderPath
$folder = Get-Item -LiteralPath $root
while ($null -ne $folder) {
    if ((Test-Path (Join-Path $folder.FullName '.codex-dev-memory/installation.json')) -or
        (Test-Path (Join-Path $folder.FullName '.git'))) {
        $root = $folder.FullName
        break
    }
    $folder = $folder.Parent
}
$action = 'start'
if ($forward.Count -gt 0 -and $forward[0] -in @('start','doctor','update','uninstall','memory','checkpoint','metrics')) {
    $action = $forward[0]
    $forward = @($forward | Select-Object -Skip 1)
}
$marker = Join-Path $root '.codex-dev-memory/installation.json'
function Prepare-Project {
    $log = Join-Path ([IO.Path]::GetTempPath()) ('codex-memory-install-' + [guid]::NewGuid().ToString('N') + '.log')
    # Separate OS streams avoid PowerShell 5.1 treating native progress on stderr as a failure.
    $installer = Join-Path $source 'install-project.ps1'
    $parameters = @('-NoLogo','-NoProfile','-File',('"' + $installer + '"'),'-ProjectPath',('"' + $root + '"'))
    $process = Start-Process -FilePath (Get-Command powershell.exe -ErrorAction Stop).Source -ArgumentList $parameters -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError ($log + '.err') -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Nao foi possivel preparar o projeto (codigo $($process.ExitCode)). Diagnostico: $log e $log.err"
    }
}
if (-not (Test-Path -LiteralPath $marker)) {
    if ($action -eq 'uninstall') { Write-Host 'Este projeto nao tem uma integracao instalada.'; exit 0 }
    Write-Host "Preparando memoria e Headroom neste projeto: $root"
    Write-Host 'Isso acontece na primeira execucao e pode levar alguns minutos.'
    Prepare-Project
} else {
    $installed = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
    if ($installed.version -and [version]$installed.version -lt [version]$version -and $action -ne 'uninstall') {
        Write-Host 'Atualizando a integracao local; sua memoria sera preservada.'
        Prepare-Project
    }
}
$installed = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
if ($action -eq 'start') { Write-Host 'Pronto. Codex com memoria e Headroom. Peca suas alteracoes normalmente.' }
& (Join-Path $installed.source 'cdm.ps1') -Action $action -ProjectPath $root -Arguments $forward
if (-not $?) { exit 1 }

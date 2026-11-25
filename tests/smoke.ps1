# SPDX-License-Identifier: MIT
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    throw 'Run this smoke test on Linux with PowerShell 7.'
}

$source = Join-Path (Split-Path $PSScriptRoot) 'install.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('cdm-smoke-' + [guid]::NewGuid())
$variables = @('XDG_DATA_HOME','CODEX_HOME','CDM_CAPTURE','CDM_EXPECTED_SOURCE','OPENAI_API_KEY')
$original = @{}
foreach ($name in $variables) { $original[$name] = [Environment]::GetEnvironmentVariable($name) }

function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ($Actual -cne $Expected) { throw "Failed: $Label" }
}

try {
    $env:XDG_DATA_HOME = Join-Path $root 'local-data'
    $env:CODEX_HOME = Join-Path $root 'codex'
    $env:CDM_CAPTURE = Join-Path $root 'capture'
    $env:CDM_EXPECTED_SOURCE = $source
    $env:OPENAI_API_KEY = 'fake-test-value'
    $project = Join-Path $root 'project with spaces'
    $subdir = Join-Path $project 'subdir'
    $other = Join-Path $root 'another project'
    foreach ($dir in @($subdir,$other,$env:XDG_DATA_HOME,$env:CODEX_HOME)) {
        [void][IO.Directory]::CreateDirectory($dir)
    }
    $config = Join-Path $env:CODEX_HOME 'config.toml'
    $rules = Join-Path $project 'AGENTS.md'
    [IO.File]::WriteAllText($config, 'model_provider = "openai"')
    [IO.File]::WriteAllText($rules, '# Existing instructions')
    & git -C $project init --quiet
    if ($LASTEXITCODE) { throw 'git init failed.' }

    $appHome = Join-Path $env:XDG_DATA_HOME 'CodexDevMemory'
    $tool = Join-Path $appHome 'toolkit'
    $launcher = Join-Path $tool 'install.ps1'
    $projects = Join-Path $appHome 'projects'
    $bootstrap = [scriptblock]::Create([IO.File]::ReadAllText($source))
    & $bootstrap -BootstrapPath $source -ProjectPath $subdir -NoLaunch
    Assert-Equal (Get-FileHash $launcher).Hash (Get-FileHash $source).Hash 'bootstrap saves identical launcher'
    $memory = (Get-ChildItem -LiteralPath $projects -Directory).FullName
    $state = Join-Path $memory 'STATE.md'
    [IO.File]::WriteAllText($state, '# Saved progress')
    & $launcher -Action Memory -ProjectPath $project
    Assert-Equal @(Get-ChildItem -LiteralPath $projects -Directory).Count 1 'same Git checkout'
    & $launcher -Action Memory -ProjectPath $other
    Assert-Equal @(Get-ChildItem -LiteralPath $projects -Directory).Count 2 'separate project'

    # Exercise Update through an intercepted GitHub download. Package tools run normally.
    function global:Invoke-WebRequest {
        param([switch]$UseBasicParsing, [string]$Uri, [string]$OutFile)
        Assert-Equal $Uri 'https://raw.githubusercontent.com/guilhermeforprojeto/codex-dev-memory/main/install.ps1' 'update origin'
        [IO.File]::Copy($env:CDM_EXPECTED_SOURCE, $OutFile)
    }
    try { & $launcher -Action Update }
    finally { Remove-Item Function:\Invoke-WebRequest }

    $bin = Join-Path $tool 'npm/node_modules/.bin/codex'
    Remove-Item -LiteralPath $bin
    @'
#!/bin/sh
set -eu
printf '%s\n' "$PWD" "$@" >"$CDM_CAPTURE"
for arg in "$@"; do
    case "$arg" in
        openai_base_url=*)
            url=${arg#openai_base_url=}
            url=${url%/v1}
            curl --noproxy '*' --fail --silent "$url/health" >"$CDM_CAPTURE.health"
            printf '%s' "$url" >"$CDM_CAPTURE.url"
            ;;
    esac
done
'@ | Set-Content -LiteralPath $bin -Encoding utf8NoBOM
    & chmod +x $bin
    & $launcher -Action Start -ProjectPath $subdir
    $transcript = [IO.File]::ReadAllText($env:CDM_CAPTURE)
    if (!$transcript.Contains($memory) -or !$transcript.Contains("mcp_servers.codex_dev_memory_headroom.args=")) {
        throw 'Missing scoped memory or MCP settings.'
    }
    $health = Get-Content -LiteralPath ($env:CDM_CAPTURE + '.health') -Raw | ConvertFrom-Json
    Assert-Equal $health.status 'healthy' 'real Headroom proxy started'
    $url = [IO.File]::ReadAllText($env:CDM_CAPTURE + '.url')
    & curl --noproxy '*' --silent --max-time 2 "$url/health"
    if (!$LASTEXITCODE) { throw 'Headroom was still listening after Codex exited.' }

    & $launcher -Action Start -ProjectPath $subdir -Direct
    if (Select-String -LiteralPath $env:CDM_CAPTURE -SimpleMatch 'openai_base_url') {
        throw 'Direct launch routed through Headroom.'
    }
    & $launcher -Action Uninstall
    Assert-Equal (Test-Path -LiteralPath $tool) $false 'toolkit removed'
    Assert-Equal ([IO.File]::ReadAllText($state)) '# Saved progress' 'memory preserved'
    Assert-Equal ([IO.File]::ReadAllText($config)) 'model_provider = "openai"' 'Codex config preserved'
    Assert-Equal ([IO.File]::ReadAllText($rules)) '# Existing instructions' 'project rules preserved'
    Assert-Equal $env:OPENAI_API_KEY 'fake-test-value' 'credential environment preserved'
    Write-Host 'Smoke test passed.'
} finally {
    foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $original[$name]) }
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}

param([string]$ProjectPath=(Get-Location).Path)
. (Join-Path $PSScriptRoot 'scripts/common.ps1')
$install = Get-Installation $ProjectPath
$oldPath = $env:PATH
$portableNode = Join-Path $install.project '.codex-dev-memory/tools/node-v24.15.0-win-x64'
if (Test-Path (Join-Path $portableNode 'node.exe')) { $env:PATH = "$portableNode;$env:PATH" }
try {
& $install.python (Join-Path $install.source 'scripts/cdm.py') --project $install.project init
Assert-Exit 'Headroom / SQLite / ONNX / tokenizer'
& $install.python -c "import importlib.metadata as m; print(m.version('headroom-ai'))"
Assert-Exit 'Headroom version'
& $install.codex --version
Assert-Exit 'Codex binary'
$savedErrorPreference = $ErrorActionPreference
try {
    # Codex writes successful login status to stderr. PS 5.1 must not treat
    # redirected native stderr as a terminating PowerShell exception.
    $ErrorActionPreference = 'Continue'
    $authLines = @(& $install.codex login status 2>&1)
    $auth = $LASTEXITCODE
} finally { $ErrorActionPreference = $savedErrorPreference }
$authLines | ForEach-Object { Write-Host $_.ToString() }
$launch = @(Get-CodexArgs $install) + @('mcp','get','codex_dev_memory','--json')
& $install.codex @launch
Assert-Exit 'Codex MCP configuration'
if ($auth -ne 0) { throw 'Codex is not authenticated. Run codex login.' }
Write-Host 'PASS: local runtime, memory, embeddings, tokenizer, Codex auth and MCP config.'
Write-Host 'Hook execution requires review/trust in Codex. Live model use is tested separately.'
} finally { $env:PATH = $oldPath }

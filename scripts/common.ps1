$ErrorActionPreference = 'Stop'
function Assert-Exit([string]$Step) {
    if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit $LASTEXITCODE)." }
}
function Get-Installation([string]$ProjectPath) {
    $root = (Resolve-Path -LiteralPath $ProjectPath).Path
    $path = Join-Path $root '.codex-dev-memory/installation.json'
    if (-not (Test-Path -LiteralPath $path)) { throw 'Run install-project.ps1 for this project first.' }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}
function Get-CodexArgs($Install) {
    # TOML literal strings survive native argument passing in both PS 5.1 and 7.
    function Literal([string]$Value) {
        $Value = $Value.Replace('\','/')
        if ($Value.Contains("'''")) { throw 'Three consecutive apostrophes in a path are unsupported.' }
        if ($Value.Contains("'")) { return "'''$Value'''" }
        return "'$Value'"
    }
    $python = Literal $Install.python
    $script = Literal (Join-Path $Install.source 'scripts/cdm.py')
    $project = Literal $Install.project
    $value = "mcp_servers.codex_dev_memory={command=$python,args=[$script,'--project',$project,'serve'],startup_timeout_sec=60,tool_timeout_sec=120}"
    return @('-C', $Install.project, '-c', $value)
}

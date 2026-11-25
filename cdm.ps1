param(
    [ValidateSet('start','doctor','update','uninstall','memory','checkpoint','metrics')]
    [string]$Action = 'start',
    [string]$ProjectPath = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments
)
. (Join-Path $PSScriptRoot 'scripts/common.ps1')
$Arguments = @($Arguments | Where-Object { $null -ne $_ })
$install = Get-Installation $ProjectPath
$oldPath = $env:PATH
$portableNode = Join-Path $install.project '.codex-dev-memory/tools/node-v24.15.0-win-x64'
if (Test-Path (Join-Path $portableNode 'node.exe')) { $env:PATH = "$portableNode;$env:PATH" }
try {
switch ($Action) {
    'start' {
        $launch = @(Get-CodexArgs $install) + @($Arguments)
        & $install.codex @launch
        Assert-Exit 'Codex'
    }
    'doctor' { & (Join-Path $PSScriptRoot 'doctor.ps1') -ProjectPath $ProjectPath }
    'update' { & (Join-Path $PSScriptRoot 'update.ps1') -ProjectPath $ProjectPath @Arguments }
    'uninstall' { & (Join-Path $PSScriptRoot 'uninstall.ps1') -ProjectPath $ProjectPath @Arguments }
    default {
        $cli = Join-Path $install.source 'scripts/cdm.py'
        $commands = if ($Action -eq 'memory') { @($Arguments) } else { @($Action) + @($Arguments) }
        & $install.python $cli --project $install.project @commands
        Assert-Exit 'Memory command'
    }
}
} finally { $env:PATH = $oldPath }

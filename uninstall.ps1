param([string]$ProjectPath=(Get-Location).Path, [switch]$PurgeData)
. (Join-Path $PSScriptRoot 'scripts/common.ps1')
$install = Get-Installation $ProjectPath
Push-Location $install.source
try { & $install.python -m cdm.setup uninstall --project $install.project; Assert-Exit 'Uninstall' }
finally { Pop-Location }
if ($PurgeData) {
    $answer = Read-Host 'Delete ALL local memory, artifacts, runtime and backups? Type DELETE'
    if ($answer -eq 'DELETE') {
        $root = (Resolve-Path -LiteralPath $ProjectPath).Path
        $target = Join-Path $root '.codex-dev-memory'
        $resolved = (Resolve-Path -LiteralPath $target).Path
        $item = Get-Item -LiteralPath $target -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing reparse-point deletion.' }
        if ([IO.Path]::GetFullPath($resolved) -ne [IO.Path]::GetFullPath($target) -or (Split-Path $resolved -Parent) -ne $root) { throw 'Unsafe deletion path.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
        Write-Host 'Project-local data removed.'
    }
}

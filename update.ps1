param([string]$ProjectPath=(Get-Location).Path, [string]$Version='v1.1.1', [string]$SourcePath)
$ErrorActionPreference='Stop'
if ($SourcePath) {
    # Explicit local source for developers; never auto-pull an unpinned branch.
    & (Join-Path (Resolve-Path -LiteralPath $SourcePath).Path 'install-project.ps1') -ProjectPath $ProjectPath
} else {
    & (Join-Path $PSScriptRoot 'bootstrap.ps1') -ProjectPath $ProjectPath -Version $Version
}

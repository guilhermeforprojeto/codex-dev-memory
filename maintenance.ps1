# SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Update','Doctor','Uninstall')]
    [string]$Action
)
$ErrorActionPreference = 'Stop'
$localData = [Environment]::GetFolderPath('LocalApplicationData')
if (!$localData) { $localData = Join-Path $HOME '.local/share' }
$entry = Join-Path $localData 'CodexDevMemory/toolkit/install.ps1'
if (!(Test-Path -LiteralPath $entry -PathType Leaf)) {
    throw 'Codex Dev Memory is missing. Run the installation command in README.md.'
}
& $entry -Action $Action

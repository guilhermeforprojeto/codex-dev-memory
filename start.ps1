param([string]$ProjectPath=(Get-Location).Path, [Parameter(ValueFromRemainingArguments=$true)][string[]]$CodexArgs)
& (Join-Path $PSScriptRoot 'cdm.ps1') -Action start -ProjectPath $ProjectPath -Arguments $CodexArgs

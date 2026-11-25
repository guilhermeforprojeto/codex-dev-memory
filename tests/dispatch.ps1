$ErrorActionPreference='Stop'
$source=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$temp=Join-Path ([IO.Path]::GetTempPath()) ('cdm-dispatch-'+[guid]::NewGuid().ToString('N'))
$app=Join-Path $temp '.codex-dev-memory/app'
New-Item -ItemType Directory -Force (Join-Path $app 'scripts') | Out-Null
Copy-Item (Join-Path $source 'cdm.ps1') $app
Copy-Item (Join-Path $source 'scripts/common.ps1') (Join-Path $app 'scripts/common.ps1')
@{project=$temp; source=$app; python='unused'; codex='unused'} | ConvertTo-Json | Set-Content (Join-Path $temp '.codex-dev-memory/installation.json')
@'
param([string]$ProjectPath,[string]$Version='DEFAULT_RELEASE')
if ($Version -ne 'DEFAULT_RELEASE') { throw "Default version overridden: [$Version]" }
Write-Output 'UPDATE_DISPATCH_PASS'
'@ | Set-Content (Join-Path $app 'update.ps1')
$result=& (Join-Path $app 'cdm.ps1') -Action update -ProjectPath $temp -Arguments $null
if ($result -ne 'UPDATE_DISPATCH_PASS') { throw 'Missing dispatch result' }
Write-Output $result

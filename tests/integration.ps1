param([string]$TestRoot=(Join-Path $PSScriptRoot '../work/integration'), [switch]$SkipDoctor)
$ErrorActionPreference='Stop'
$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
$testBase = (Resolve-Path $TestRoot).Path
function Assert([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Memory($Project,[string[]]$ArgsList) {
    $i = Get-Content (Join-Path $Project '.codex-dev-memory/installation.json') -Raw | ConvertFrom-Json
    $result = & $i.python (Join-Path $i.source 'scripts/cdm.py') --project $Project @ArgsList
    if ($LASTEXITCODE -ne 0) { throw 'Memory subprocess failed.' }
    return ($result | Out-String | ConvertFrom-Json)
}
$id = [guid]::NewGuid().ToString('N').Substring(0,8)
$empty = Join-Path $testBase "empty project $id"
$existing = Join-Path $testBase "existing project $id"
New-Item -ItemType Directory -Path $empty,$existing | Out-Null
$original = "# Existing project`r`nKeep these instructions intact.`r`n"
[IO.File]::WriteAllText((Join-Path $existing 'AGENTS.md'), $original, [Text.UTF8Encoding]::new($false))
$options = @{}
if ($SkipDoctor) { $options.SkipDoctor = $true }
& (Join-Path $source 'install-project.ps1') -ProjectPath $empty @options
& (Join-Path $source 'install-project.ps1') -ProjectPath $existing @options
$before = [IO.File]::ReadAllText((Join-Path $existing 'AGENTS.md'))
Assert ($before.StartsWith($original)) 'Existing AGENTS content changed.'
& (Join-Path $source 'install-project.ps1') -ProjectPath $existing @options
Assert ([IO.File]::ReadAllText((Join-Path $existing 'AGENTS.md')) -eq $before) 'Repeated install duplicated AGENTS.'
$saved = Memory $existing @('save','integration/decision','Use SQLite for local project state.','--category','decision')
$again = Memory $existing @('save','integration/decision','Use SQLite for local project state.','--category','decision')
Assert (-not $again.changed) 'Deduplication failed.'
$found = @(Memory $existing @('search','SQLite local project state'))
Assert ($found.id -contains $saved.id) 'Memory did not persist across processes.'
$other = @(Memory $empty @('search','SQLite local project state'))
Assert (-not ($other.id -contains $saved.id)) 'Cross-project data leak.'
$export = Join-Path $existing '.codex-dev-memory/integration-export.json'
Memory $existing @('export',$export) | Out-Null
Assert (Test-Path $export) 'Export missing.'
& (Join-Path $source 'update.ps1') -ProjectPath $existing -SourcePath $source
Assert (@(Memory $existing @('search','SQLite local project state')).id -contains $saved.id) 'Update lost memory.'
& (Join-Path $source 'uninstall.ps1') -ProjectPath $existing
Assert (Test-Path (Join-Path $existing '.codex-dev-memory/memory.db')) 'Uninstall deleted memory.'
Assert ([IO.File]::ReadAllText((Join-Path $existing 'AGENTS.md')).StartsWith($original)) 'Uninstall changed existing instructions.'
& (Join-Path $source 'install-project.ps1') -ProjectPath $existing @options
Assert (@(Memory $existing @('search','SQLite local project state')).id -contains $saved.id) 'Reinstall failed to recover retained memory.'
Memory $existing @('clear','--yes') | Out-Null
Assert (@(Memory $existing @('search','SQLite local project state')).Count -eq 0) 'Clear failed.'
$result = @{result='PASS'; empty=$empty; existing=$existing; checks=@('empty install','existing install','repeat install','AGENTS preservation','space paths','process persistence','isolation','export','local update','uninstall retention','reinstall','confirmed clear')}
$result | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $testBase "result-$id.json")
$result | ConvertTo-Json -Depth 5

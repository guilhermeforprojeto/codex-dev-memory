param([string]$ProjectPath=(Get-Location).Path, [string]$Version='v1.0.2')
$ErrorActionPreference='Stop'
if ($Version -notmatch '^v\d+\.\d+\.\d+$') { throw 'Use an explicit stable version, e.g. v1.0.0.' }
$root = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage = Join-Path ([IO.Path]::GetTempPath()) ('codex-dev-memory-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
$base = "https://github.com/guilhermeforprojeto/codex-dev-memory/releases/download/$Version"
$name = "codex-dev-memory-$Version.zip"
$zip = Join-Path $stage $name
Invoke-WebRequest -UseBasicParsing "$base/$name" -OutFile $zip
$manifest = (Invoke-WebRequest -UseBasicParsing "$base/SHA256SUMS").Content
if ($manifest -is [byte[]]) { $manifest = [Text.Encoding]::UTF8.GetString($manifest) }
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
if (-not ($manifest -match "(?im)^$hash\s+\*?$([regex]::Escape($name))\s*$")) { throw 'Release archive checksum mismatch.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($entry in $archive.Entries) {
        $dest = [IO.Path]::GetFullPath((Join-Path $stage $entry.FullName))
        if (-not $dest.StartsWith($stage + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe archive path.' }
    }
} finally { $archive.Dispose() }
Expand-Archive -LiteralPath $zip -DestinationPath $stage
& (Join-Path $stage 'codex-dev-memory/install-project.ps1') -ProjectPath $root
Write-Host "Verified release: $Version. Download retained at $stage"

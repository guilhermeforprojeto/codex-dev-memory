import json
import shutil
import subprocess
from pathlib import Path

import pytest

SOURCE = Path(__file__).parents[1]


def run(shell, script, *args, cwd=None):
    exe = shutil.which(shell)
    if not exe:
        pytest.skip(f'{shell} is unavailable')
    return subprocess.run([exe, '-NoProfile', '-File', str(script), *map(str, args)],
                          cwd=cwd, capture_output=True, text=True, timeout=40)


@pytest.mark.parametrize('shell', ['pwsh', 'powershell.exe'])
def test_global_routing_installs_once_and_preserves_arguments(tmp_path, shell):
    app = tmp_path/'app'
    (app/'scripts').mkdir(parents=True)
    (app/'cdm').mkdir()
    shutil.copy2(SOURCE/'scripts/global-launch.ps1', app/'scripts/global-launch.ps1')
    shutil.copy2(SOURCE/'cdm/__init__.py', app/'cdm/__init__.py')
    (app/'install-project.ps1').write_text('''param([string]$ProjectPath)
$data = Join-Path $ProjectPath '.codex-dev-memory'
New-Item -ItemType Directory -Force -Path $data | Out-Null
Add-Content (Join-Path $ProjectPath 'installs.txt') 'installed'
@{project=$ProjectPath;source=$PSScriptRoot;version='1.1.1'} | ConvertTo-Json | Set-Content (Join-Path $data 'installation.json')
''', encoding='utf-8')
    (app/'cdm.ps1').write_text('''param([string]$Action,[string]$ProjectPath,[string[]]$Arguments)
@{action=$Action;project=$ProjectPath;arguments=@($Arguments)} | ConvertTo-Json -Compress | Set-Content (Join-Path $ProjectPath 'capture.json')
''', encoding='utf-8')
    root = tmp_path/'project with spaces'
    sub = root/'src'
    sub.mkdir(parents=True)
    (root/'.git').mkdir()
    launcher = app/'scripts/global-launch.ps1'
    result = run(shell, launcher, 'start', 'change this file', '--no-alt-screen', cwd=sub)
    assert result.returncode == 0, result.stderr
    captured = json.loads((root/'capture.json').read_text(encoding='utf-8-sig'))
    assert captured == {'action': 'start', 'project': str(root),
                        'arguments': ['change this file', '--no-alt-screen']}
    result = run(shell, launcher, 'memory', 'status', cwd=sub)
    assert result.returncode == 0, result.stderr
    captured = json.loads((root/'capture.json').read_text(encoding='utf-8-sig'))
    assert captured['action'] == 'memory' and captured['arguments'] == ['status']
    assert (root/'installs.txt').read_text().splitlines() == ['installed']
    # A nested repository must not inherit the outer project's memory.
    nested = root/'nested'
    (nested/'.git').mkdir(parents=True)
    result = run(shell, launcher, 'resume', '--last', cwd=nested)
    assert result.returncode == 0, result.stderr
    assert (nested/'.codex-dev-memory/installation.json').exists()
    captured = json.loads((nested/'capture.json').read_text(encoding='utf-8-sig'))
    assert captured['arguments'] == ['resume', '--last']


@pytest.mark.parametrize('shell', ['pwsh', 'powershell.exe'])
def test_command_install_preserves_foreign_files_and_reinstalls(tmp_path, shell):
    dest, bin_dir = tmp_path/'command app', tmp_path/'bin'
    installer = SOURCE/'install-command.ps1'
    arguments = ['-InstallPath', dest, '-BinPath', bin_dir, '-NoPath']
    for _ in range(2):
        result = run(shell, installer, *arguments)
        assert result.returncode == 0, result.stderr
    assert (bin_dir/'codex-memory.cmd').exists()
    result = run(shell, dest/'app/scripts/global-launch.ps1', '--version')
    assert result.returncode == 0 and 'codex-memory 1.1.1' in result.stdout
    shim = bin_dir/'codex-memory.cmd'
    shim.write_text('foreign command', encoding='ascii')
    result = run(shell, installer, *arguments)
    assert result.returncode != 0
    assert shim.read_text() == 'foreign command'

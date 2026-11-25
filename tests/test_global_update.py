import json
import shutil
import subprocess
from pathlib import Path

import pytest

SOURCE = Path(__file__).parents[1]


@pytest.mark.parametrize('shell', ['pwsh', 'powershell.exe'])
def test_global_nested_updater_can_hash_release(tmp_path, shell):
    exe = shutil.which(shell)
    if not exe:
        pytest.skip(f'{shell} is unavailable')
    app = tmp_path/'app'
    (app/'scripts').mkdir(parents=True)
    (app/'cdm').mkdir()
    for name in ('cdm.ps1', 'scripts/common.ps1', 'scripts/global-launch.ps1', 'cdm/__init__.py'):
        shutil.copy2(SOURCE/name, app/name)
    (app/'update.ps1').write_text("param([string]$ProjectPath)\n& (Join-Path $PSScriptRoot 'bootstrap.ps1')\n")
    (app/'bootstrap.ps1').write_text("$hash = Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256\nif ($hash.Hash.Length -ne 64) { throw 'Invalid hash' }\nWrite-Output 'GLOBAL_UPDATE_HASH_PASS'\n")
    data = tmp_path/'.codex-dev-memory'
    data.mkdir()
    (data/'installation.json').write_text(json.dumps({
        'project': str(tmp_path), 'source': str(app), 'version': '99.0.0',
        'codex': 'unused', 'python': 'unused'}))
    result = subprocess.run([exe, '-NoProfile', '-File', str(app/'scripts/global-launch.ps1'), 'update'],
                            cwd=tmp_path, capture_output=True, text=True, timeout=30)
    assert result.returncode == 0, result.stderr
    assert 'GLOBAL_UPDATE_HASH_PASS' in result.stdout

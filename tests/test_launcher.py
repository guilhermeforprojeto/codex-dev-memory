import json
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

SOURCE = Path(__file__).parents[1]


@pytest.mark.parametrize('shell', ['pwsh', 'powershell.exe'])
@pytest.mark.parametrize('command,expected', [
    (['metrics'], 'samples'),
    (['checkpoint'], 'changed'),
    (['memory', 'status'], None),
])
def test_actual_powershell_launcher_single_subcommand(tmp_path, shell, command, expected):
    executable = shutil.which(shell)
    if executable is None:
        pytest.skip(f'{shell} is not installed')
    data = tmp_path/'.codex-dev-memory'
    data.mkdir()
    (data/'installation.json').write_text(json.dumps({
        'project': str(tmp_path), 'source': str(SOURCE),
        'python': sys.executable, 'codex': 'not-used-in-this-test',
    }), encoding='utf-8')
    # Exercise the generated outer launcher too, including its null array input.
    (data/'cdm.ps1').write_text('''param([string]$Action='start', [Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
& $env:CDM_TEST_LAUNCHER -Action $Action -ProjectPath (Split-Path $PSScriptRoot -Parent) -Arguments $Arguments
if (-not $?) { exit 1 }
''', encoding='utf-8')
    import os
    result = subprocess.run([executable, '-NoProfile', '-File', str(data/'cdm.ps1'), *command],
        capture_output=True, text=True, encoding='utf-8', timeout=45,
        env={**os.environ, 'CDM_TEST_LAUNCHER': str(SOURCE/'cdm.ps1')})
    assert result.returncode == 0, result.stderr
    value = json.loads(result.stdout)
    if expected:
        assert expected in value
    else:
        assert value == {}

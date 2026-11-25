import json
from pathlib import Path

import pytest

from cdm.setup import install, uninstall

SOURCE = Path(__file__).parents[1]


def test_existing_content_hooks_and_repeat_install(project):
    agents = project.root/'AGENTS.md'
    original = b'\xef\xbb\xbf# Existing instructions\r\nPreserve exactly.\r\n'
    agents.write_bytes(original)
    codex = project.root/'.codex'; codex.mkdir()
    existing_hook = {'hooks': {'Stop': [{'hooks': [{'type': 'command', 'command': 'echo existing'}]}]}, 'custom': True}
    (codex/'hooks.json').write_text(json.dumps(existing_hook))
    install(project.root, SOURCE, 'python.exe', 'codex.exe')
    one = agents.read_bytes()
    hooks = (codex/'hooks.json').read_bytes()
    install(project.root, SOURCE, 'python.exe', 'codex.exe')
    assert agents.read_bytes() == one
    assert (codex/'hooks.json').read_bytes() == hooks
    assert one.startswith(original)
    assert one.count(b'codex-dev-memory:begin') == 1
    assert list((project.data/'backups').glob('*/AGENTS.md'))
    uninstall(project.root)
    assert agents.read_bytes().startswith(original)
    restored = json.loads((codex/'hooks.json').read_text())
    assert restored == existing_hook
    assert (project.data/'checkpoint.md').exists()
    assert not (project.data/'installation.json').exists()
    assert '/.codex-dev-memory/' in (project.root/'.gitignore').read_text()


def test_invalid_hook_does_not_touch_agents(project):
    (project.root/'AGENTS.md').write_text('keep')
    (project.root/'.codex').mkdir()
    (project.root/'.codex/hooks.json').write_text('invalid JSON')
    with pytest.raises(ValueError):
        install(project.root, SOURCE, 'python.exe', 'codex.exe')
    assert (project.root/'AGENTS.md').read_text() == 'keep'


def test_no_global_configuration_changes(project, monkeypatch):
    fake_home = project.root/'user-home'; fake_home.mkdir()
    (fake_home/'config.toml').write_text('model="existing"')
    monkeypatch.setenv('CODEX_HOME', str(fake_home))
    install(project.root, SOURCE, 'python.exe', 'codex.exe')
    assert (fake_home/'config.toml').read_text() == 'model="existing"'
    assert not (fake_home/'auth.json').exists()

"""Idempotent project integration. Preserve unrelated bytes and JSON fields."""
import argparse
import base64
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

from .core import Project, atomic_json

START = '<!-- codex-dev-memory:begin -->'
END = '<!-- codex-dev-memory:end -->'
IGNORE_START = '# codex-dev-memory:begin'
IGNORE_END = '# codex-dev-memory:end'
HOOK_ID = 'Codex Dev Memory checkpoint'


def backup(project, path):
    if path.exists():
        project.checked_path(path)
        folder = project.data / 'backups' / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        folder.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, folder / path.name)


def edit_block(project, path, begin, end, block=None):
    old = path.read_bytes() if path.exists() else b''
    # UTF-8 including BOM and CRLF preserved outside our managed block.
    text = old.decode('utf-8')
    pattern = re.compile(re.escape(begin) + r'.*?' + re.escape(end), re.S)
    if text.count(begin) != text.count(end) or text.count(begin) > 1:
        raise ValueError(f'Malformed managed block in {path.name}; resolve manually.')
    match = pattern.search(text)
    if match:
        new = text[:match.start()] + (block or '') + text[match.end():]
    elif block:
        new = text + ('\n\n' if text and not text.endswith('\n\n') else '') + block + '\n'
    else:
        return
    if new.encode('utf-8') != old:
        backup(project, path)
        path.write_bytes(new.encode('utf-8'))


def hooks(project, python, script, uninstall=False):
    path = project.root / '.codex' / 'hooks.json'
    if path.parent.exists() and path.parent.resolve().parent != project.root:
        raise ValueError('.codex must be inside the project.')
    if not path.exists() and uninstall:
        return
    old = path.read_bytes() if path.exists() else b''
    doc = json.loads(old.decode('utf-8-sig')) if old else {'hooks': {}}
    if not isinstance(doc.get('hooks', {}), dict):
        raise ValueError('Invalid existing hooks.json schema.')
    events = doc.setdefault('hooks', {})
    command = '& ' + ' '.join("'" + str(x).replace("'", "''") + "'" for x in
                              (python, script, '--project', project.root, 'hook'))
    encoded = base64.b64encode(command.encode('utf-16-le')).decode()
    for event in ('Stop', 'PreCompact', 'SessionEnd'):
        groups = []
        for group in events.get(event, []):
            others = [h for h in group.get('hooks', []) if h.get('statusMessage') != HOOK_ID]
            if others:
                groups.append({**group, 'hooks': others})
        if not uninstall and event != 'SessionEnd':
            groups.append({'hooks': [{'type': 'command',
                                     'command': f'powershell.exe -NoProfile -EncodedCommand {encoded}',
                                     'timeout': 30, 'statusMessage': HOOK_ID}]})
        if groups:
            events[event] = groups
        else:
            events.pop(event, None)
    encoded_doc = (json.dumps(doc, ensure_ascii=False, indent=2) + '\n').encode()
    if old != encoded_doc:
        backup(project, path)
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(encoded_doc)


def install(root, source, python, codex):
    p = Project(root)
    # Validate all existing data before making edits.
    for name in ('AGENTS.md', '.gitignore', '.codex/hooks.json'):
        candidate = p.root / name
        if candidate.exists():
            p.checked_path(candidate)
            raw = candidate.read_text(encoding='utf-8-sig')
            if name.endswith('.json'):
                json.loads(raw)
            elif raw.count(START) != raw.count(END) or raw.count(START) > 1:
                raise ValueError('Malformed existing AGENTS block.')
    source = Path(source).resolve()
    edit_block(p, p.root/'AGENTS.md', START, END, (source/'templates/AGENTS.md').read_text(encoding='utf-8').strip())
    edit_block(p, p.root/'.gitignore', IGNORE_START, IGNORE_END,
               IGNORE_START + '\n/.codex-dev-memory/\n/.headroom/\n/.codex/hooks.json\n' + IGNORE_END)
    hooks(p, python, source/'scripts/cdm.py')
    checkpoint = p.data/'checkpoint.md'
    if not checkpoint.exists():
        shutil.copy2(source/'templates/ESTADO_PROJETO.md', checkpoint)
    from . import __version__
    atomic_json(p.data/'installation.json', {'version': __version__, 'python': str(python),
                'codex': str(codex), 'source': str(source), 'project': str(p.root)})
    # Launcher remains stable across releases. Runtime source stays ignored.
    launcher = "param([string]$Action='start', [Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)\n"
    launcher += "$ErrorActionPreference='Stop'\n& (Join-Path $PSScriptRoot 'app/cdm.ps1') -Action $Action -ProjectPath (Split-Path $PSScriptRoot -Parent) -Arguments $Arguments\n"
    (p.data/'cdm.ps1').write_text(launcher, encoding='utf-8-sig')


def uninstall(root):
    p = Project(root)
    edit_block(p, p.root/'AGENTS.md', START, END)
    # Keep ignore entries to protect retained data/backups from publication.
    hooks(p, '', '', uninstall=True)
    marker = p.data/'installation.json'
    if marker.exists():
        marker.rename(p.data/('uninstalled-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%f') + '.json'))
    print('Integration removed. Memory, runtime and backups retained in .codex-dev-memory/.')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['install', 'uninstall'])
    parser.add_argument('--project', required=True)
    parser.add_argument('--source')
    parser.add_argument('--python')
    parser.add_argument('--codex')
    args = parser.parse_args()
    if args.action == 'install':
        install(args.project, args.source, args.python, args.codex)
    else:
        uninstall(args.project)


if __name__ == '__main__':
    main()

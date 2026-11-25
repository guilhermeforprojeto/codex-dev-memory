"""Local-only storage policy. Headroom owns memory, embeddings and retrieval."""
from __future__ import annotations

import hashlib
import json
import os
import re
from itertools import groupby
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

from filelock import FileLock

CATEGORIES = ('objective', 'architecture', 'technology', 'decision', 'implemented',
              'pending', 'error', 'solution', 'test', 'file', 'next', 'preference', 'status')
SECRET = re.compile(
    r'-----BEGIN [A-Z ]*PRIVATE KEY-----|'
    r'\b(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16})\b|'
    r'(?i:bearer\s+[A-Za-z0-9._~+/-]{12,})|'
    r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|'
    r'(?i:["\x27]?(?:password|passwd|senha|api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|token|credential|secret)["\x27]?\s*[:=]\s*["\x27]?\S+)'
)


def safe_text(text: str, limit: int = 16000) -> str:
    if not isinstance(text, str) or not text.strip() or len(text) > limit:
        raise ValueError(f'Text must contain 1..{limit} characters.')
    if SECRET.search(text):
        raise ValueError('Possible credential detected; nothing stored. Remove the credential first.')
    return text.strip()


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def atomic_json(path: Path, value) -> None:
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    os.replace(tmp, path)


class Project:
    def __init__(self, root: str | Path):
        self.root = Path(root).resolve(strict=True)
        if not self.root.is_dir():
            raise ValueError('Project must be a directory.')
        self.data = self.root / '.codex-dev-memory'
        # Never follow a substituted data directory into another project.
        if self.data.is_symlink() or (self.data.exists() and self.data.resolve().parent != self.root):
            raise ValueError('Memory directory must be inside this project (no links/junctions).')
        self.data.mkdir(exist_ok=True)
        self.lock = FileLock(str(self.data / 'operation.lock'), timeout=60)
        self.state_path = self.data / 'index.json'

    def state(self):
        if self.state_path.exists():
            return json.loads(self.state_path.read_text(encoding='utf-8'))
        return {'keys': {}, 'files': {}, 'metrics': []}

    def configure(self, online=False):
        # Model assets only; project text is never sent to Hugging Face.
        os.environ['HF_HOME'] = str(self.data / 'models')
        os.environ['HF_HUB_OFFLINE'] = '0' if online else '1'
        os.environ['TRANSFORMERS_OFFLINE'] = '0' if online else '1'
        os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
        os.environ['DO_NOT_TRACK'] = '1'
        os.environ['LITELLM_LOCAL_MODEL_COST_MAP'] = 'True'
        os.environ['HEADROOM_WORKSPACE_DIR'] = str(self.data)
        os.environ['TIKTOKEN_CACHE_DIR'] = str(self.data / 'tokenizers')

    @asynccontextmanager
    async def backend(self, online=False):
        self.configure(online)
        from headroom.memory.backends.local import LocalBackend, LocalBackendConfig
        backend = LocalBackend(LocalBackendConfig(
            db_path=str(self.data / 'memory.db'), embedder_backend='onnx', cache_enabled=False))
        try:
            yield backend
        finally:
            await backend.close()

    async def initialize(self, online=False):
        with self.lock:
            async with self.backend(online) as b:
                # Exercise model loading and the real SQLite/vector backend.
                await b.search_memories('project', user_id='project', top_k=1)
            import tiktoken
            for name in ('cl100k_base', 'o200k_base'):
                tiktoken.get_encoding(name).encode('installation check')
            atomic_json(self.state_path, self.state())
        return {'ok': True, 'memory': str(self.data / 'memory.db'), 'search': 'local ONNX + SQLite-vec'}

    async def save(self, key: str, content: str, category='decision'):
        if not re.fullmatch(r'[a-zA-Z0-9_./-]{1,100}', key):
            raise ValueError('Key must use letters, digits, underscore, dot, slash or hyphen.')
        content = safe_text(content)
        safe_text(key)
        if category not in CATEGORIES:
            raise ValueError('Unknown category.')
        h = digest((category + '\n' + content).encode())
        with self.lock:
            state = self.state()
            entry = state['keys'].get(key)
            if entry and entry['hash'] == h:
                return {'id': entry['id'], 'changed': False}
            async with self.backend() as b:
                # Equal facts under different keys share the same Headroom record.
                duplicate = next((x for x in state['keys'].values() if x['hash'] == h), None)
                if duplicate:
                    mid = duplicate['id']
                else:
                    # Each logical key has one active record. Do not supersede a shared
                    # record: another key may still refer to its original fact.
                    m = await b.save_memory(content, user_id='project', importance=0.7,
                                            metadata={'category': category, 'key': key})
                    mid = m.id
                state['keys'][key] = {'id': mid, 'hash': h, 'category': category, 'updated': utc()}
                atomic_json(self.state_path, state)
                if entry and entry['id'] != mid and not any(x['id'] == entry['id'] for x in state['keys'].values()):
                    await b.delete_memory(entry['id'], user_id='project')
        return {'id': mid, 'changed': True}

    async def search(self, query: str, limit=5, mode='semantic'):
        query = safe_text(query, 1000)
        if not 1 <= limit <= 20:
            raise ValueError('limit must be 1..20')
        with self.lock:
            async with self.backend() as b:
                if mode == 'text':
                    # Literal terms; do not expose raw FTS operators to untrusted text.
                    words = re.findall(r'\w+', query, re.UNICODE)
                    if not words:
                        return []
                    result = await b.text_search(' OR '.join('"' + w + '"' for w in words),
                                                 user_id='project', limit=limit)
                elif mode == 'semantic':
                    result = await b.search_memories(query, user_id='project', top_k=limit,
                                                     include_related=False)
                else:
                    raise ValueError('mode must be semantic or text')
                active = {x['id'] for x in self.state()['keys'].values()}
                return [{'id': r.memory.id, 'content': r.memory.content,
                         'category': r.memory.metadata.get('category'), 'score': r.score}
                        for r in result if r.memory.id in active]

    async def records(self):
        with self.lock:
            async with self.backend() as b:
                rows = []
                for key, entry in self.state()['keys'].items():
                    m = await b.get_memory(entry['id'])
                    if m is not None:
                        rows.append({'key': key, 'category': entry['category'], 'content': m.content,
                                     'updated': entry['updated']})
                return rows

    async def checkpoint(self):
        path = self.data / 'checkpoint.md'
        if not path.exists():
            return {'changed': False, 'reason': 'No assisted checkpoint provided.'}
        self.checked_path(path)
        return await self.save('project/status', path.read_text(encoding='utf-8'), 'status')

    async def clear(self):
        with self.lock:
            async with self.backend() as b:
                count = await b.clear_user('project')
            state = self.state()
            state['keys'] = {}
            atomic_json(self.state_path, state)
        return {'deleted': count, 'scope': 'memory records only; artifacts/backups remain'}

    def checked_path(self, path):
        path = Path(path)
        path = (self.root / path).resolve(strict=True)
        if not path.is_relative_to(self.root) or not path.is_file():
            raise ValueError('File must resolve inside this project.')
        parts = {x.lower() for x in path.relative_to(self.root).parts}
        if parts & {'.git', '.ssh', '.aws', 'node_modules', 'models', 'runtime', 'backups'}:
            raise ValueError('This directory is excluded.')
        if path.name.lower().startswith('.env') or path.name.lower() in {'auth.json', 'credentials', 'credentials.json'} or path.suffix.lower() in {'.pem', '.key', '.pfx', '.p12'}:
            raise ValueError('Credential files are excluded.')
        if path.stat().st_size > 2_000_000:
            raise ValueError('File exceeds 2 MB; select a smaller log or excerpt.')
        return path

    def read(self, path, compress=False, force=False):
        path = self.checked_path(path)
        raw = path.read_bytes()
        text = raw.decode('utf-8-sig')
        safe_text(text, 2_000_000)
        sha = digest(raw)
        relative = path.relative_to(self.root).as_posix()
        with self.lock:
            state = self.state()
            previous = state['files'].get(relative)
            if not force and previous and previous['sha256'] == sha and previous['compressed'] == compress:
                return {'unchanged': True, 'sha256': sha, 'artifact': sha,
                        'hint': 'Reuse prior context only if still present; otherwise context_retrieve.'}
            self.configure()
            import tiktoken
            enc = tiktoken.get_encoding('cl100k_base')
            before = len(enc.encode(text))
            result_text, lossless, transforms = text, True, []
            if compress:
                if path.suffix.lower() not in {'.log', '.txt', '.json', '.jsonl', '.csv'}:
                    raise ValueError('Compression is for logs/data; source code is read verbatim.')
                from headroom import compress as hr_compress
                result = hr_compress([{'role': 'tool', 'tool_call_id': 'local-output', 'content': text}],
                                     model='gpt-4o', mode='agent', protect_recent=0,
                                     compress_system_messages=False)
                result_text = result.messages[0]['content']
                lossless = result.lossless
                transforms = result.transforms_applied
                if lossless is not True:
                    result_text = text
                    lossless = True
                    transforms = ['fallback-to-original']
            after = len(enc.encode(result_text))
            # Headroom's lossless verifier can restore repetitive plain logs to
            # their original. Complement that case with exact line-run encoding.
            # No line is discarded; counts and order round-trip byte-for-byte.
            if compress and path.suffix.lower() in {'.log', '.txt'}:
                runs = [{'repeat': sum(1 for _ in group), 'line': line}
                        for line, group in groupby(text.splitlines(keepends=True))]
                if any(x['repeat'] >= 3 for x in runs):
                    assert ''.join(x['line'] * x['repeat'] for x in runs) == text
                    packed = 'CDM lossless log runs (JSON; expand each line repeat times):\n' + json.dumps(runs, ensure_ascii=False)
                    if len(enc.encode(packed)) < after:
                        result_text = packed
                        after = len(enc.encode(packed))
                        transforms = ['cdm:exact_line_runs']
            if after > before:
                result_text, after, transforms = text, before, ['no-benefit-original']
            artifacts = self.data / 'artifacts'
            artifacts.mkdir(exist_ok=True)
            # Store exact bytes, not the trimmed safe_text return value.
            (artifacts / (sha + '.txt')).write_bytes(raw)
            state['files'][relative] = {'sha256': sha, 'compressed': compress}
            metric = {'at': utc(), 'input_tokens': before, 'output_tokens': after,
                      'saved_tokens': before - after, 'tokenizer': 'cl100k_base',
                      'lossless': lossless, 'transforms': transforms, 'artifact': sha}
            state['metrics'].append(metric)
            state['metrics'] = state['metrics'][-1000:]
            atomic_json(self.state_path, state)
            return {'content': result_text, 'artifact': sha, 'metrics': metric}

    def retrieve(self, artifact: str, offset=0, limit=16000):
        if not re.fullmatch('[a-f0-9]{64}', artifact) or offset < 0 or not 1 <= limit <= 100000:
            raise ValueError('Invalid artifact or range.')
        path = self.checked_path(self.data / 'artifacts' / (artifact + '.txt'))
        raw = path.read_bytes()
        if digest(raw) != artifact:
            raise ValueError('Artifact integrity check failed.')
        text = raw.decode('utf-8-sig')
        return {'content': text[offset:offset + limit], 'offset': offset,
                'next_offset': offset + limit if offset + limit < len(text) else None,
                'total_characters': len(text)}

    def metrics(self):
        with self.lock:
            rows = self.state()['metrics']
            before = sum(x['input_tokens'] for x in rows)
            after = sum(x['output_tokens'] for x in rows)
            return {'samples': len(rows), 'input_tokens': before, 'output_tokens': after,
                    'saved_tokens': before - after,
                    'saved_percent': round(100 * (before - after) / before, 2) if before else 0,
                    'tokenizer': 'cl100k_base', 'scope': 'last 1000 local payload operations, not billed usage',
                    'subscription_quota_savings': 'not measured'}

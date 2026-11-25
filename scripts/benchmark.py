"""Offline synthetic payload comparison; never a subscription-billing claim."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cdm.core import Project

p = Project(sys.argv[1])
samples = {
    'json': json.dumps([{'id': i, 'status': 'ok', 'service': 'build-worker',
                         'region': 'local', 'duration_ms': 42} for i in range(500)], indent=2),
    'log': '\n'.join('2026-11-25T00:00:00 INFO worker heartbeat status=ok' for _ in range(500))
           + '\n2026-11-25T00:00:01 FATAL build failed: missing required file\n',
}
results = {}
for name, text in samples.items():
    path = p.root/f'benchmark.{name if name == "json" else "log"}'
    path.write_bytes(text.encode())
    result = p.read(path, compress=True, force=True)
    assert p.retrieve(result['artifact'], limit=100000)['content'] == text
    if name == 'log':
        assert 'FATAL build failed: missing required file' in result['content']
    metric = result['metrics']
    results[name] = {k: v for k, v in metric.items() if k not in ('at','artifact')}
    results[name]['saved_percent'] = round(100 * metric['saved_tokens']/metric['input_tokens'], 2)
print(json.dumps({'samples': results, 'scope': 'local payload cl100k_base, not model billing or subscription quota'}, indent=2))

import argparse
import asyncio
import json
import sys
from pathlib import Path

from .core import CATEGORIES, Project


async def run(args):
    p = Project(args.project)
    if args.command == 'init':
        return await p.initialize(online=args.download_models)
    if args.command == 'save':
        return await p.save(args.key, args.content, args.category)
    if args.command == 'search':
        return await p.search(args.query, args.limit, args.mode)
    if args.command == 'status':
        with p.lock:
            return p.state()['keys']
    if args.command == 'checkpoint':
        return await p.checkpoint()
    if args.command == 'hook':
        # Do not ingest transcripts, user prompts, command lines or raw tool outputs.
        # The agent explicitly maintains this short, reviewed checkpoint instead.
        try:
            payload = json.loads(sys.stdin.read(1_000_000))
            if payload.get('hook_event_name') in ('Stop', 'PreCompact', 'SessionEnd'):
                await p.checkpoint()
            return {}
        except Exception:
            return {'systemMessage': 'Codex Dev Memory checkpoint failed; run doctor/checkpoint for details.'}
    if args.command == 'export':
        rows = await p.records()
        dest = Path(args.output).resolve()
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            raise ValueError('Export already exists; choose another filename.')
        dest.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
        return {'exported': len(rows), 'path': str(dest)}
    if args.command == 'clear':
        if not args.yes:
            if input('Delete all memory records for this project? Type DELETE: ') != 'DELETE':
                return {'cancelled': True}
        return await p.clear()
    if args.command == 'read':
        return p.read(args.path, args.compress, args.force)
    if args.command == 'retrieve':
        return p.retrieve(args.artifact, args.offset, args.limit)
    if args.command == 'metrics':
        return p.metrics()
    if args.command == 'serve':
        from .server import serve
        await serve(p)
        return None
    raise ValueError('Unknown command')


def main():
    parser = argparse.ArgumentParser(description='Codex Dev Memory — local Headroom integration')
    parser.add_argument('--project', default='.')
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('init').add_argument('--download-models', action='store_true')
    save = sub.add_parser('save')
    save.add_argument('key')
    save.add_argument('content')
    save.add_argument('--category', choices=CATEGORIES, default='decision')
    search = sub.add_parser('search')
    search.add_argument('query')
    search.add_argument('--limit', type=int, default=5)
    search.add_argument('--mode', choices=['semantic', 'text'], default='semantic')
    for name in ('status', 'checkpoint', 'hook', 'metrics', 'serve'):
        sub.add_parser(name)
    sub.add_parser('export').add_argument('output')
    sub.add_parser('clear').add_argument('--yes', action='store_true')
    read = sub.add_parser('read')
    read.add_argument('path')
    read.add_argument('--compress', action='store_true')
    read.add_argument('--force', action='store_true')
    retrieve = sub.add_parser('retrieve')
    retrieve.add_argument('artifact')
    retrieve.add_argument('--offset', type=int, default=0)
    retrieve.add_argument('--limit', type=int, default=16000)
    args = parser.parse_args()
    try:
        result = asyncio.run(run(args))
        if result is not None:
            print(json.dumps(result, ensure_ascii=False, indent=2))
    except Exception as exc:
        # Exceptions from our inputs are safe; avoid dumping third-party request data.
        message = str(exc) if isinstance(exc, (ValueError, FileNotFoundError)) else type(exc).__name__
        print('Codex Dev Memory: ' + message, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

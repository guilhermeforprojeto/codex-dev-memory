import asyncio
import json

import pytest

from cdm.core import Project


def test_native_persistence_search_update_dedup_and_isolation(project, tmp_path):
    async def exercise():
        first = await project.save('architecture', 'The database uses SQLite with local persistence.', 'architecture')
        second = await project.save('architecture', 'The database uses SQLite with local persistence.', 'architecture')
        alias = await project.save('db', 'The database uses SQLite with local persistence.', 'architecture')
        assert first['id'] == second['id'] == alias['id']
        assert not second['changed']
        reopened = Project(project.root)
        assert (await reopened.search('database storage'))[0]['id'] == first['id']
        assert (await reopened.search('SQLite', mode='text'))[0]['id'] == first['id']
        changed = await reopened.save('architecture', 'The database uses PostgreSQL.', 'architecture')
        assert changed['id'] != first['id']
        records = await reopened.records()
        assert {r['content'] for r in records} == {'The database uses SQLite with local persistence.', 'The database uses PostgreSQL.'}
        other_dir = tmp_path/'other project'; other_dir.mkdir()
        assert await Project(other_dir).search('database storage') == []
        await reopened.clear()
        assert await reopened.search('database storage') == []
    asyncio.run(exercise())


def test_checkpoint_idempotent_and_secrets_rejected(project):
    async def exercise():
        path = project.data/'checkpoint.md'
        path.write_text('Completed: implemented persistence. Next: test recovery.', encoding='utf-8')
        assert (await project.checkpoint())['changed']
        assert not (await project.checkpoint())['changed']
        path.write_text('password=not-a-real-password', encoding='utf-8')
        with pytest.raises(ValueError, match='credential'):
            await project.checkpoint()
        assert len(await project.records()) == 1
    asyncio.run(exercise())


@pytest.mark.parametrize('secret', [
    'sk-' + 'x'*30, 'ghp_' + 'a'*30, 'Bearer ' + 'x'*30,
    '-----BEGIN RSA PRIVATE KEY-----', 'senha: synthetic',
    '{"api_key":"synthetic"}', 'token = synthetic',
])
def test_secret_filter_before_storage(project, secret):
    with pytest.raises(ValueError, match='credential'):
        asyncio.run(project.save('unsafe', secret))
    assert not (project.data/'memory.db').exists()


def test_unknown_category_and_empty_content(project):
    with pytest.raises(ValueError):
        asyncio.run(project.save('key', ''))
    with pytest.raises(ValueError):
        asyncio.run(project.save('key', 'hello', 'unknown'))


def test_original_recovery_read_hash_and_token_metrics(project):
    path = project.root/'results.json'
    text = json.dumps([{'id': i, 'status': 'ok', 'region': 'local', 'latency': 42}
                       for i in range(300)], indent=2) + '\n'
    path.write_bytes(text.encode('utf-8'))
    result = project.read('results.json', compress=True)
    assert result['metrics']['lossless'] is True
    assert result['metrics']['output_tokens'] <= result['metrics']['input_tokens']
    assert project.retrieve(result['artifact'], limit=100000)['content'] == text
    assert project.read('results.json', compress=True)['unchanged']
    path.write_text(text + ' ', encoding='utf-8')
    assert 'content' in project.read('results.json', compress=True)
    assert project.metrics()['samples'] == 2
    # Tampered artifacts fail closed.
    (project.data/'artifacts'/(result['artifact']+'.txt')).write_text('changed')
    with pytest.raises(ValueError, match='integrity'):
        project.retrieve(result['artifact'])


def test_source_verbatim_and_path_boundaries(project, tmp_path):
    (project.root/'code.py').write_bytes(b'print("hello")\n')
    assert project.read('code.py')['content'] == 'print("hello")\n'
    with pytest.raises(ValueError, match='source code'):
        project.read('code.py', compress=True)
    (project.root/'.env').write_text('anything')
    with pytest.raises(ValueError, match='Credential'):
        project.read('.env')
    outside = tmp_path.parent/'outside.txt'; outside.write_text('outside')
    with pytest.raises(ValueError, match='inside'):
        project.read(outside)
    with pytest.raises(ValueError):
        project.retrieve('../escape')


def test_log_runs_preserve_errors_and_round_trip(project):
    text = ('INFO heartbeat\r\n' * 300) + 'FATAL exact error code=42\r\n' + ('INFO heartbeat\r\n' * 10)
    (project.root/'long.log').write_bytes(text.encode())
    result = project.read('long.log', compress=True)
    runs = json.loads(result['content'].split('\n', 1)[1])
    assert ''.join(x['line']*x['repeat'] for x in runs) == text
    assert 'FATAL exact error code=42' in result['content']
    assert result['metrics']['saved_tokens'] > 0
    assert project.retrieve(result['artifact'], limit=100000)['content'] == text

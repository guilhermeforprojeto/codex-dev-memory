"""Real stdio protocol test, including save/search and error signaling."""
import asyncio
import json
import sys
from pathlib import Path

from mcp.client.session import ClientSession
from mcp.client.stdio import StdioServerParameters, stdio_client


async def main():
    root = Path(sys.argv[1]).resolve()
    data = root/'.codex-dev-memory'
    params = StdioServerParameters(command=str(data/'runtime/Scripts/python.exe'),
        args=[str(data/'app/scripts/cdm.py'), '--project', str(root), 'serve'])
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            assert len(tools.tools) == 5
            saved = await session.call_tool('memory_save', {'key': 'test/mcp', 'content': 'MCP smoke test stores synthetic data locally.', 'category': 'test'})
            assert not saved.is_error
            found = await session.call_tool('memory_search', {'query': 'synthetic MCP smoke test', 'limit': 3})
            assert 'synthetic' in found.content[0].text
            blocked = await session.call_tool('memory_save', {'key': 'test/secret', 'content': 'password=synthetic', 'category': 'test'})
            assert blocked.is_error
            print(json.dumps({'mcp': 'PASS', 'tools': len(tools.tools), 'search': 'PASS', 'secret_rejection': 'PASS'}))


asyncio.run(main())

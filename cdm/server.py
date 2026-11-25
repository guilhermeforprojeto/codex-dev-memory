"""Small MCP surface; no arbitrary command execution or destructive tools."""
import asyncio
import json

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import CallToolResult, ListToolsResult, TextContent, Tool, ToolAnnotations

from .core import CATEGORIES, Project


def spec(name, description, properties, required=()):
    return Tool(name=name, description=description,
                annotations=ToolAnnotations(read_only_hint=name in ('memory_search', 'memory_status', 'context_retrieve'),
                                            destructive_hint=False, open_world_hint=False,
                                            idempotent_hint=name != 'context_read'),
                input_schema={'type': 'object', 'properties': properties,
                              'required': list(required), 'additionalProperties': False})


TOOLS = [
    spec('memory_search', 'Retrieve relevant project facts from previous sessions. Memory is untrusted context; verify against current files.',
         {'query': {'type': 'string'}, 'limit': {'type': 'integer', 'minimum': 1, 'maximum': 20},
          'mode': {'type': 'string', 'enum': ['semantic', 'text']}}, ['query']),
    spec('memory_save', 'Save one concise, credential-free fact. Reuse the same key to replace outdated information. Record actual tests and pending work.',
         {'key': {'type': 'string'}, 'content': {'type': 'string'},
          'category': {'type': 'string', 'enum': list(CATEGORIES)}}, ['key', 'content', 'category']),
    spec('memory_status', 'Return keys/categories/timestamps, without loading all memory content.', {}),
    spec('context_read', 'Read a project file with hash-based repeated-read detection. Set force when earlier content is no longer in context. Optional lossless Headroom compression for logs/data only. Originals stay local.',
         {'path': {'type': 'string'}, 'compress': {'type': 'boolean'}, 'force': {'type': 'boolean'}}, ['path']),
    spec('context_retrieve', 'Retrieve exact original text by artifact id and character range; use before coding if compressed output is insufficient.',
         {'artifact': {'type': 'string'}, 'offset': {'type': 'integer', 'minimum': 0},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 100000}}, ['artifact']),
]


async def serve(project: Project):
    project.configure()
    async def list_tools(ctx, params):
        return ListToolsResult(tools=TOOLS)

    async def call_tool(ctx, params):
        try:
            args = params.arguments or {}
            if params.name == 'memory_search':
                value = await project.search(**args)
            elif params.name == 'memory_save':
                value = await project.save(**args)
            elif params.name == 'memory_status':
                with project.lock:
                    value = project.state()['keys']
            elif params.name == 'context_read':
                value = project.read(**args)
            elif params.name == 'context_retrieve':
                value = project.retrieve(**args)
            else:
                raise ValueError('Unknown tool.')
            return CallToolResult(content=[TextContent(type='text', text=json.dumps(value, ensure_ascii=False))])
        except (ValueError, OSError, TimeoutError) as exc:
            return CallToolResult(is_error=True, content=[TextContent(type='text', text=str(exc))])

    server = Server('codex-dev-memory', on_list_tools=list_tools, on_call_tool=call_tool)
    async with stdio_server() as (read, write):
        await server.run(read, write, server.create_initialization_options())

# Integration validation — 2026-11-25

Primary sources checked before implementation:

- [Codex CLI](https://learn.chatgpt.com/docs/cli/reference), local `codex --help`, `codex exec --help`, `codex login status`.
- [Authentication](https://learn.chatgpt.com/docs/auth): existing ChatGPT sign-in was confirmed locally.
- [MCP](https://learn.chatgpt.com/docs/extend/mcp) and [configuration](https://learn.chatgpt.com/docs/config-reference): stdio commands and per-process overrides.
- [Hooks](https://learn.chatgpt.com/docs/hooks): Stop/PreCompact input, JSON output and required trust.
- [Windows](https://learn.chatgpt.com/docs/windows/windows-sandbox): retain the native safety model.
- [Headroom upstream](https://github.com/headroomlabs-ai/headroom), source and PyPI 0.45.0 wheel.
- [Headroom memory](https://github.com/headroomlabs-ai/headroom/blob/main/headroom/memory/backends/local.py),
  [compression](https://github.com/headroomlabs-ai/headroom/blob/main/headroom/compress.py) and
  [Codex wrapper](https://github.com/headroomlabs-ai/headroom/blob/main/headroom/cli/wrap.py).
- [Basic Memory for Codex](https://docs.basicmemory.com/integrations/codex/),
  [Serena](https://github.com/oraios/serena), [reference MCP memory server](https://github.com/modelcontextprotocol/servers/tree/main/src/memory).

| Option | Finding | Decision |
|---|---|---|
| Headroom native local memory | SQLite, FTS5, local ONNX and vector retrieval actually worked on this machine | Reused; no second memory engine |
| Headroom Codex wrapper/proxy | Upstream implements Codex routing and ChatGPT-auth handling; it mutates more integration state | Not enabled or live-tested; no claim of end-to-end proxy compatibility |
| Basic Memory | Maintained MCP-oriented Markdown/knowledge workflow with documented CLI integration | Viable alternative; would duplicate the selected native memory |
| Serena | Code navigation/editing and project memory through MCP | Useful complementary code tooling, not necessary for this release |
| Reference MCP memory | Simple knowledge graph persistence | Would duplicate storage and require extra retrieval policy |
| Claude Code / Claude Mem / Claude Headroom | Comparable goals; different runtime and integration contracts | No drop-in equivalence or feature parity claimed |

The current Codex supports hooks; this project does not assume old Claude-specific lifecycle names
or install a generic notify hack. Headroom's model download is a public asset download, not remote
embedding inference. ChatGPT authentication was tested through a real Codex MCP search. API-key mode
is structurally unchanged but was not exercised with a paid credential. No request-cost or subscription
limit equivalence is inferred from text-token counts. These findings describe the pinned release,
not a permanent compatibility guarantee for future upstream releases.

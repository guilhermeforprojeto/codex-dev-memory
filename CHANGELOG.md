# Changelog

## 1.1.0 — 2026-11-25

- Comando global `codex-memory`: prepara projetos novos automaticamente e abre o Codex com memória e Headroom.
- Reconhece a raiz do projeto a partir de subpastas e preserva a separação das memórias.
- README principal com início direto em português; novas instruções e checkpoints em português.
- Instalação global sem alterar o comando original do Codex, seus perfis ou sua autenticação.

## 1.0.2 — 2026-11-25

- Keep single memory subcommands as a string array when forwarding to Python, fixing checkpoint, metrics, and memory status through the PowerShell launcher.
- Exercise actual launcher subprocesses in both PowerShell 5.1 and 7; previous release assets remain unchanged.

## 1.0.1 — 2026-11-25

- Fix the PowerShell launcher passing a null positional argument to update, which replaced the default release version with an empty string.
- Add a regression test for the installed wrapper and preserve the published 1.0.0 archive; use 1.0.1 for new installations.

## 1.0.0 — 2026-11-25

- Project-local Headroom 0.45.0 memory with SQLite, ONNX semantic search and FTS5.
- Five MCP tools; credential-pattern rejection, logical-key deduplication, assisted checkpoints.
- Explicit lossless data compression, exact log-run encoding, SHA-256 originals and local token metrics.
- Windows installers with pinned dependency hashes, backups, diagnostics, update and reversible uninstall.
- Portuguese and English documentation, synthetic benchmarks and actual Windows validation.

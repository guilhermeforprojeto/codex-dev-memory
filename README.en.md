# Codex Dev Memory

Project-local persistent memory and selective context for **Codex CLI on Windows**, backed by
Headroom's native storage and retrieval. Uses existing ChatGPT sign-in; memory and compression
need no paid API account. [Português](README.md) · [Architecture](docs/ARCHITECTURE.md) · [Validation](docs/VALIDATION.md)

The initial `install.ps1` and `maintenance.ps1` are preserved. The new verified workflow uses
`install-project.ps1`. [Legacy compatibility and memory](docs/LEGACY.md).

## Purpose and components

Recall architecture, decisions, work in progress, failures, fixes, tests and next steps across
sessions without loading every record. Hash-aware reads avoid redundant context; original
outputs remain recoverable. Existing projects receive backed-up, idempotent instruction/hook edits.

| Comparable component | This project |
|---|---|
| Claude Code | Existing Codex CLI, permissions and authentication |
| Claude Mem | Headroom LocalBackend, MCP and assisted checkpoints |
| Claude Headroom | Explicit Headroom library compression of selected outputs |
| Persistent instructions | Concise managed AGENTS.md block |

This is an integration, not a drop-in replacement or a claim of full feature parity. Native
Headroom handles storage, vector/text retrieval and structured data compression. The adapter
adds lifecycle management, secret checks, stable-key deduplication, export and exact repeated-log encoding.

## Install with one command

Open your project in VS Code and paste into its PowerShell terminal. The bootstrap is downloaded,
checked against a pinned SHA-256, then executed locally; it verifies the release ZIP separately.
No in-memory remote-script evaluation or permanent execution-policy change is used.

```powershell
$p=Join-Path $env:TEMP 'cdm-bootstrap-v1.0.0.ps1'; Invoke-WebRequest -UseBasicParsing 'https://github.com/guilhermeforprojeto/codex-dev-memory/releases/download/v1.0.0/bootstrap.ps1' -OutFile $p; if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne '5f47af90d294668897b54de0bc19e1d9c451671f1a09c8105cf6f351b05a8c5e'){throw 'Invalid SHA-256'}; & $p
```

Targets Windows 11 x64 and PowerShell 5.1/7. Internet is needed for initial provisioning.
Reuses UV/Python 3.12 or provisions them without administrator privileges. Node/Codex are
installed only when absent. Python includes SQLite; Git/GitHub CLI are not runtime prerequisites.
Python dependencies have exact versions and hashes. Public embedding/tokenizer models download
once per project. Existing Codex credentials stay in their native location. Run `codex login` if needed.

Review project/hook trust if Codex asks; the installer does not silently approve hooks.
See [installation](docs/INSTALLATION.md) for details and restrictive environments.

## Commands

From the project's root:

```powershell
.\.codex-dev-memory\cdm.ps1 start
.\.codex-dev-memory\cdm.ps1 doctor
.\.codex-dev-memory\cdm.ps1 memory save architecture/database 'Use local SQLite.' --category architecture
.\.codex-dev-memory\cdm.ps1 memory search 'database decisions'
.\.codex-dev-memory\cdm.ps1 memory search SQLite --mode text
.\.codex-dev-memory\cdm.ps1 memory status
.\.codex-dev-memory\cdm.ps1 checkpoint
.\.codex-dev-memory\cdm.ps1 memory read build.log --compress
.\.codex-dev-memory\cdm.ps1 memory retrieve ARTIFACT_ID --offset 0 --limit 16000
.\.codex-dev-memory\cdm.ps1 metrics
.\.codex-dev-memory\cdm.ps1 memory export .\.codex-dev-memory\export.json
.\.codex-dev-memory\cdm.ps1 memory clear
.\.codex-dev-memory\cdm.ps1 update
.\.codex-dev-memory\cdm.ps1 uninstall
```

`start` forwards extra Codex arguments, e.g. `start resume --last`. Five MCP tools expose memory
search/save/status and context read/retrieve. After compaction, use `force` if an unchanged file
is no longer in context. The launcher does not configure the IDE extension or other clients.

Update uses a fixed release, not a moving branch: `& .\.codex-dev-memory\app\update.ps1 -Version vX.Y.Z`.
It leaves global Codex/model settings alone. Uninstall removes managed instructions/hooks and keeps
memory, runtime, backups and ignore rules. `& .\.codex-dev-memory\app\uninstall.ps1 -PurgeData`
also removes local data only after typing `DELETE`.

## Memory, privacy and measured results

State lives under **`<project>\.codex-dev-memory\`**: native SQLite/index databases, a logical-key
index, checkpoint, original artifacts, public model cache, runtime and backups. Projects have
separate databases. No resident service is needed for persistence. Process-restart persistence was
tested; a physical computer reboot was not. Re-run installation if moving the project.

The agent saves concise facts or maintains an assisted checkpoint. Official Stop/PreCompact hooks
can ingest it after trust; `checkpoint` is the explicit alternative. No full-transcript capture,
second LLM summarizer or automatic memory injection into every prompt is enabled.

Synthetic local `cl100k_base` measurements:

| Payload | Before | After | Reduction |
|---|---:|---:|---:|
| 500 structured JSON entries, Headroom lossless mode | 20,502 | 5,038 | 75.43% |
| 500 repeated log lines plus FATAL, exact line runs | 9,521 | 79 | 99.17% |

Original recovery and critical-error preservation were checked. These payload counts exclude
tool/schema overhead and provider caching; they do **not** establish billing or subscription-quota
savings. Nonrepetitive data may not compress. See [actual validation](docs/VALIDATION.md).

No model proxy or extra remote memory service is introduced. Codex sends selected memory/tool
results to its configured provider as normal context. Public assets download during provisioning;
embeddings run locally afterward. Secret detection is heuristic, never a substitute for keeping
credentials out. Local databases are not encrypted. Read [SECURITY.md](SECURITY.md) before exporting.

## Limitations and development

Real ChatGPT-authenticated Codex retrieval passed. Paid API-key mode remains native but was not
live-tested. Headroom's Codex proxy was researched, not enabled. Semantic quality across languages
and very large repositories is not comprehensively benchmarked; FTS5 keyword search is available.
Only UTF-8 files up to 2 MB are accepted. Source code is read verbatim. Compression is explicit;
it does not intercept every Codex shell command. Hooks do not bypass trust or guarantee that an
agent always writes a checkpoint. There is no promise of indefinite autonomous execution.

[Contributing](CONTRIBUTING.md) includes test commands; agents follow [AGENTS.md](AGENTS.md) and
update [ESTADO_PROJETO.md](ESTADO_PROJETO.md). See [research](docs/RESEARCH.md) for Basic Memory,
Serena and reference MCP alternatives, [memory](docs/MEMORY.md) for retention/deletion, and
[third-party notices](docs/THIRD_PARTY.md) for dependency licenses. Original code is MIT.

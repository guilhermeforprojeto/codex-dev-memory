# Memory / Memória

Use stable keys such as `architecture/database`, `decision/auth`, `pending/export`, `error/build`,
`solution/build`, `test/integration`, `file/entrypoint`, `next/release` and `preference/style`.
Categories: objective, architecture, technology, decision, implemented, pending, error, solution,
test, file, next, preference, status. Save a fact with its evidence and uncertainty when relevant.

Headroom owns the record database and search indexes. The small adapter index holds record IDs,
categories, hashes, timestamps and read/metric metadata. Identical key/content is a no-op; equal facts
across keys share one record. An updated key points to a new native record, deleting the old record
when no other key needs it. There is no unbounded journal of prior full transcripts.

`memory_search` defaults to five semantic results, at most twenty. `--mode text` uses FTS5/BM25
with literal terms. These are relevance results, not truth guarantees. `memory_status` returns
keys/metadata without all fact content. `memory export` is explicit and refuses to overwrite an
existing file. Exports may contain confidential facts; keep them outside Git.

Update `.codex-dev-memory/checkpoint.md` with completed work, actual tests, failures and next action.
Keep it below 16,000 characters. `checkpoint` saves it as `project/status`; unchanged content does not
duplicate. Hooks ingest this same file; they never inspect full transcripts. Agent-assisted summaries
cost only the normal Codex turn, with no additional API call from this application.

`context_read` accepts project-contained UTF-8 files up to 2 MB and rejects obvious credentials.
It archives original bytes by SHA-256 and returns text. If the file hash and mode are unchanged,
it returns a reference instead of repeated content. `force=true` retrieves content again when prior
context is gone. `context_retrieve` validates the artifact hash and returns a character range.
The original byte artifact remains on disk even when textual decoding removes a UTF-8 BOM.

`memory clear` asks for `DELETE`; `--yes` is explicit automation authorization. Clear affects native
memory records/indexes, not checkpoints, artifacts or backups. A later checkpoint can reintroduce
its content. Uninstall disables managed integration and retains data by default. Use confirmed
`-PurgeData` to remove the entire directory. Neither option is a forensic secure-erase utility.

Português: use chaves estáveis e fatos curtos; recuperar memória não substitui verificar o código.
Cada projeto possui banco independente. Para limpar de vez, considere também checkpoint,
artefatos, exportações e backups. Dados não são criptografados e não devem conter segredos.

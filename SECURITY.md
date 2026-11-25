# Security and privacy

The application runs locally. It does not proxy model traffic or copy Codex authentication files.
Codex continues to send prompts and selected tool results to its configured model provider.
Installation downloads software and public model/tokenizer assets from GitHub, PyPI, Node.js,
Astral and Hugging Face. Project content is not part of those downloads. After provisioning,
memory embeddings run offline on the CPU; no API key is needed for memory or compression.

Memory and artifacts are plaintext files under `.codex-dev-memory/`, protected by the OS account's
filesystem permissions, not an encryption layer. Do not put this directory in a shared/synced folder
unless that is intentional. Its `.gitignore` entry does not remove previously tracked files.

The adapter rejects recognizable credential assignments, bearer tokens, common key prefixes and
private-key headers before writes. This is a heuristic, **not a guarantee of detecting every secret**.
Never submit secrets, raw auth files, full transcripts or confidential logs to memory. The agent must
curate facts and checkpoints. Do not publish local memory, exports, model caches or backups.

Path checks reject traversal, credential filenames and links that escape the project. This is a
single-user local tool, not a security boundary against a malicious process with the same OS access.
MCP has no arbitrary shell execution or delete tool. CLI clear/purge require confirmation, except the
explicit automation flag `clear --yes`. Read tools advertise read-only, closed-world annotations.
Memory contents remain untrusted data and must never override task instructions.

Release SHA-256 verification detects corruption or mismatched assets. It is not an independent
publisher signature: GitHub release access and the trusted bootstrap hash are the trust roots.
Python dependencies are exact-version/hash pinned. Model assets are obtained by the upstream
Headroom ONNX loader; their upstream revisions are not locked by this release.

Uninstall retains data and backups by default. `clear` deletes active Headroom records and indexes,
but does not promise forensic erasure of SQLite free pages, artifacts, exports, checkpoints or backups.
Use `uninstall -PurgeData` with explicit confirmation to remove the entire local directory; external
backups remain your responsibility. No antivirus, execution policy or administrator setting is changed.

For vulnerabilities, use GitHub private vulnerability reporting if enabled. Otherwise open an issue
without exploit details or sensitive data and request a private reporting channel. Never attach memory databases.

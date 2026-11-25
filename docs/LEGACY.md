# Compatibility with the initial implementation

An initial implementation was published while the project-local release was being developed.
Its Git history is retained as the parent of this release. The original `install.ps1`,
`maintenance.ps1`, `tests/smoke.ps1` and LICENSE are preserved byte-for-byte; the original AGENTS.md
instructions remain at the start of the integrated file. No force-push or legacy-data deletion is used.

The new verified release bootstrap calls **`install-project.ps1`**. Its launcher is
`<project>/.codex-dev-memory/cdm.ps1`. The original `install.ps1 -Action ...` still controls the initial
profile-local toolkit and optional proxy. Its old direct/raw installation workflow is retained for
compatibility, not used or recommended by the new verified bootstrap. Existing installations are
not silently migrated or uninstalled; they can coexist but should not both be enabled in one session.

Legacy memory remains in `%LOCALAPPDATA%/CodexDevMemory/projects/<hash>/` as `STATE.md`,
`DECISIONS.md`, and `PROGRESS.md`. The new runtime never scans or uploads those files. To migrate,
review the notes, remove sensitive content and save selected facts with `memory save`; keep the
original notes until the new search results have been verified. There is no automatic schema import.

The original Linux-oriented smoke test remains available as `tests/smoke.ps1`; it was not executed
on this Windows validation host. New Windows coverage is in `tests/integration.ps1`, `test_*.py`
and `mcp_smoke.py`. Legacy proxy behavior has not been revalidated by the new release.

Português: o conteúdo inicial e seu histórico foram preservados. O instalador novo chama-se
`install-project.ps1`; `install.ps1` continua sendo a entrada anterior. As memórias antigas no
perfil do usuário não são alteradas. A migração de fatos é seletiva e assistida.

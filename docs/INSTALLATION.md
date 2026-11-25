# Instalação / Installation

Use the pinned one-command installer in either README from the intended project's root. It never
chooses a project by scanning your personal directories. A local checkout also works:

```powershell
& 'C:\path\to\codex-dev-memory\install-project.ps1' -ProjectPath (Get-Location).Path
```

Installation order: validate platform/path; locate or provision UV/Python; locate Codex (or provision
Node/Codex); install hash-pinned dependencies in a project venv; copy only application files;
initialize public model assets and memory; back up/integrate AGENTS/ignore/hooks; save a checkpoint;
run diagnostics. Authentication remains Codex's responsibility. A failed download or invalid existing
config stops with an error; rerun after fixing it. The installer is idempotent, not a system-wide
transaction: partial caches/venvs can remain after interruption.

The first installation downloads several hundred MB. Each project has an isolated runtime/model
directory. UV's cache can be shared explicitly through `UV_CACHE_DIR`. No administrator privileges,
global PATH modifications, antivirus exclusions or execution-policy changes are required.

PowerShell must permit local scripts under your existing organization policy. If policy blocks
execution, use your approved administrative process; this installer does not change that policy.
Windows ARM64, WSL and Linux/macOS installers are outside this release's validated matrix.

Start with `.\.codex-dev-memory\cdm.ps1 start`. Codex may ask you to trust the project and hooks;
review the generated files in `.codex/hooks.json`. Do not use a blanket hook-trust bypass.
An ordinary `codex` invocation does not receive this launcher's per-process MCP configuration.
No global `config.toml` or `auth.json` edits are required by the installer. The live test used Codex's
own explicit project trust command; that trust is distinct from the installer and from hook trust.

Updates target a named stable release and preserve memory. Close active sessions first. Before
replacing app code, the installer copies it to `backups/app-*`; before editing instructions/hooks,
it backs them up too. For recovery, keep the whole `.codex-dev-memory` folder while processes are
stopped, reinstall the prior known-good release and restore only reviewed project instruction files.
Do not blindly overwrite unrelated edits with an old backup.

Português: execute na raiz correta; a instalação é local e repetível. Downloads interrompidos podem
deixar caches parciais. Revise a confiança solicitada pelo Codex; não há desativação automática de
políticas. Feche sessões antes de atualizar/restaurar e preserve o diretório de memória completo.

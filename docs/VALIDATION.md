# Actual validation / Validação real

## Comando simples — v1.1.0

Correção 1.1.1: o teste público de atualização expôs a herança de `PSModulePath` do PowerShell 7
através do atalho `.cmd`, carregando o módulo Utility 7 no PowerShell 5.1 e deixando `Get-FileHash`
indisponível. O comando agora prioriza os módulos nativos do próprio host e importa Utility
explicitamente, apenas no seu processo. Dois testes adicionais exercitam esse caminho em PowerShell 5.1/7.
O CI da 1.1.0 passou em [45611386542](https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45611386542);
o teste público posterior motivou esta correção. A instalação pública 1.1.0 passou quando o
módulo foi importado explicitamente; a versão corrigida faz isso automaticamente.

Validado em 2026-11-25: `codex-memory` instalado no PATH já existente desta máquina;
nenhum perfil PowerShell ou configuração global do Codex foi alterado. O comando preparou
um projeto Git novo a partir de uma subpasta, iniciou o executável real do Codex com `start --version`,
gravou e recuperou memória e reutilizou a instalação no segundo início. A atualização automática
de um projeto 1.0.2 para 1.1.0 preservou a memória. Texto com acentos foi gravado e recuperado
corretamente pelo atalho do Windows PowerShell.

26 testes Python aprovados, incluindo quatro novos testes em PowerShell 5.1/7 para
instalação idempotente do comando, preservação de arquivos alheios, argumentos com espaços,
subpastas e repositórios aninhados. As 12 verificações do ciclo de instalação foram repetidas
com sucesso. Uma tentativa inicial de redirecionar a instalação no PowerShell 5.1 tratou a saída
de progresso do UV como erro; corrigida usando um subprocesso com stdout/stderr separados.
O fluxo real de atualização passou após a correção. O teste de interface TUI interativa não foi
repetido nesta versão; a recuperação real com ChatGPT/MCP foi validada na versão anterior abaixo.

O README principal agora apresenta o comando diário no topo, em português. As novas instruções
de agente e o modelo de checkpoint também estão em português. Os detalhes históricos seguem abaixo.

Date: 2026-11-25. Windows 11 x64; PowerShell 7.6.9 and Windows PowerShell 5.1;
Python 3.12.10; Headroom 0.45.0; MCP 2.3.0; existing Codex CLI 0.171.0-alpha.13.2
authenticated with ChatGPT. The user's production credentials were never exported into artifacts.

| Test | Result and scope |
|---|---|
| Native memory, semantic/FTS search, updates, exact dedup | PASS; actual Headroom/SQLite/ONNX, no mocked storage |
| Isolation and process persistence | PASS; two project directories, fresh Python processes |
| Secret patterns, invalid categories, traversal, original integrity | PASS; synthetic negative inputs |
| AGENTS preservation, existing hooks, idempotent merge | PASS; BOM/CRLF prefix and unrelated JSON fields retained |
| Automated Python suite | PASS: 22 tests in 1.0.2, including actual installed launcher subprocesses on PS 5.1/7; upstream datetime deprecation warnings only |
| Empty/existing/repeated install | PASS; real isolated runtimes with space-containing paths |
| Local update, uninstall retention, reinstall, export, confirmed clear | PASS; twelve lifecycle checks in integration.ps1 |
| Codex diagnostic/auth/MCP configuration | PASS with existing ChatGPT sign-in |
| MCP protocol | PASS; real stdio initialize/list/save/search and secret-error response |
| Live Codex retrieval | PASS; actual memory_search returned checkpoint text and next action |
| Hook handler/command | PASS with a synthetic Stop payload through the generated Windows command; saved sentinel was retrieved |
| Automatic hook trust in ordinary sessions | NOT VERIFIED; requires user review/trust in Codex; explicit checkpoint works |
| Windows PowerShell 5.1 diagnostic | PASS after fixing native argument quoting |
| VS Code integrated PowerShell terminal | PASS in an isolated Extension Host empty window with explicit project cwd; actual doctor command returned VSCODE_TERMINAL_PASS; workspace trust was not disabled |
| Missing UV/Node/Codex provisioning | PASS with isolated PATH and portable installs; existing global tools were left intact; provisioned Codex 0.172.0 reused ChatGPT authentication |
| Offline payload benchmark | PASS; full original recovery and FATAL preservation |
| Update launcher regression | PASS on PowerShell 5.1 and 7 in 1.0.1; null arguments no longer override the default version |
| Single-subcommand launcher regression | PASS in 1.0.2: actual checkpoint, metrics and memory status commands return valid JSON through the outer launcher on PS 5.1/7 |
| Physical reboot / GUI close-reopen | NOT RUN; durable files and cross-process persistence tested instead |
| Paid API authentication / Headroom model proxy | NOT RUN; neither is required for the chosen architecture |
| Windows ARM64 / Linux / macOS installer | NOT SUPPORTED by this release's Windows x64 installer |
| Model semantic quality in Portuguese / large-scale workloads | NOT benchmarked systematically |

Public bootstrap 1.0.0 installation passed with both SHA-256 checks. Its final remote-update test
found an empty positional argument overriding the release version; memory remained intact.
Version 1.0.1 corrects this and preserves the original assets. Release-commit CI for 1.0.0 passed:
[Windows run](https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45552214380).
**1.0.1 public installation and update: PASS.** The README command downloaded the published
bootstrap, verified its pinned hash, verified the release ZIP, installed into a path with spaces,
and passed doctor. The `cdm.ps1 update` shortcut then downloaded/reinstalled the same public
release successfully; a synthetic memory saved under 1.0.0 was still retrievable afterward
(`PUBLIC_RELEASE_101_INSTALL_UPDATE_PASS`). Main local installation was upgraded to 1.0.1 too.

**1.0.1 remote CI: PASS.** Both the
[release commit workflow](https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45552711377)
and [tag workflow](https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45552771967)
completed successfully, including native Python tests, PowerShell parsing and the update-dispatch regression.

The final management-command check then exposed PowerShell unwrapping a one-item array into a
scalar, causing checkpoint/metrics/status to be forwarded as characters. Version 1.0.2 explicitly
types the forwarding array and adds six real launcher subprocess tests. The installed 1.0.2
checkpoint, metrics and memory status commands passed on the development machine.

**1.0.2 public release: PASS.** The hash-verified public bootstrap installed the stable release
into the same path containing spaces. The public `update` command reinstalled 1.0.2 and returned
`PUBLIC_RELEASE_102_UPDATE_PERSISTENCE_PASS`; the synthetic record created under 1.0.0 was still
retrievable. Actual checkpoint, metrics and memory status calls also passed afterward.
The main local installation is now 1.0.2. Separately, all management wrappers passed against an
installed test project, including save/search/export, confirmed clear and uninstall.

**1.0.2 remote CI: PASS.** The
[release commit workflow](https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45553457560)
passed all 22 Python tests, PowerShell parsing and the update-dispatch regression before the
release was published. Versions 1.0.0 and 1.0.1 remain available as superseded prereleases;
their published assets were not replaced.

## Reproducible payload benchmark

Run `python scripts/benchmark.py <installed-test-project>`. The script creates synthetic JSON/log
files; do not point it at a folder containing files named `benchmark.json` or `benchmark.log`.

| Payload | Input tokens | Output tokens | Saved | Reduction |
|---|---:|---:|---:|---:|
| 500 JSON objects | 20,502 | 5,038 | 15,464 | 75.43% |
| 500 repeated INFO lines + one FATAL | 9,521 | 79 | 9,442 | 99.17% |

Tokenizer: `cl100k_base`, local content only. JSON uses Headroom's verified lossless mode.
The log uses the adapter's exact line runs after native lossless mode yielded no savings.
The original raw artifact SHA-256 and recovered text were checked; the FATAL text remained present.
This is not a representative corpus, a billed model-token comparison or a subscription quota test.
MCP tool schemas and instruction overhead can offset savings on small tasks.

## Failures observed and resolved

- The restricted execution sandbox could not load/run some Python/native operations reliably;
  the authorized native tests were rerun outside it. Initial hanging attempts are not passes.
- Initial tests wrote CRLF on Windows but expected LF; fixtures now specify exact bytes and
  separately cover CRLF round trips. The implementation preserved the original correctly.
- Unannotated MCP tools triggered Codex approval in noninteractive mode. Accurate read-only,
  non-destructive, closed-world annotations fixed the live search without disabling approvals.
- `--trust` cannot be combined with `--ignore-user-config` in this CLI. The live test used
  supported project trust and existing config. Failed attempts did not retrieve facts.
- SessionEnd's three-second timeout is too short for cold model startup; it was removed.
- Windows PowerShell 5.1 strips some native double-quote arguments. TOML literal strings and
  single-quoted Python literals fixed diagnostic/config invocation.
- VS Code Extension Host with a new profile could not display its workspace-trust dialog during
  automated tests. That attempt timed out; no workspace-trust setting was disabled.

Português: aprovados são somente os testes executados. A recuperação real via Codex funcionou;
economia de cota da assinatura, reinicialização física e modo de API paga não foram comprovados.

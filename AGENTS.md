# Agent instructions

## In this repository

- Keep the installer compatible with Windows PowerShell 5.1 and PowerShell 7. Prefer the standard library and small changes.
- Before changing routing or package versions, consult official Codex and Headroom documentation. Validate the exact CLI flags and update both README sections.
- Run the smoke test after changes. Keep real credentials and authenticated model requests out of automated tests.
- Project files, auth files, Git metadata, Codex config and PowerShell profiles belong to the developer. Preserve them during install, update, start and uninstall.

## In a project launched with Codex Dev Memory

- Follow that project's own agent instructions. Read STATE.md from the memory directory named in the launch prompt. Use older notes only when relevant and verify them against the code.
- Put the current goal, verified progress, outstanding tasks and a concrete next step in STATE.md. Keep it within about 40 lines.
- Append dated entries to DECISIONS.md for lasting choices and their rationale. Append dated milestones and verification to PROGRESS.md. Coordinate edits when several sessions target the same project.
- Record summaries. Do not include secrets, environment dumps, customer information, transcripts, raw logs or credentials. Never paste these files wholesale into replies.
- Use narrow searches and short command outputs. Protect the normal sandbox and ask for approval through Codex if a memory write needs it.


## New project-local MCP mode

# Development

Read ESTADO_PROJETO.md to resume work. Use selective reads and verify code before trusting memory.
Run `python -m pytest tests -q` and `pwsh -File tests/integration.ps1` after relevant changes.
Keep Headroom pinned; reuse its storage/search/compression APIs. Never read or copy auth files.
Preserve existing project instructions/configuration. Back up before edits. Keep memory, logs,
exports, virtual environments and machine-specific paths out of Git.
Record decisions, actual test results, limitations and next actions in ESTADO_PROJETO.md.
Do not claim subscription quota savings from tokenizer counts. Never claim unexecuted tests passed.


<!-- codex-dev-memory:begin -->
## Memória do projeto
- Responda em português, salvo se o usuário ou as instruções deste projeto pedirem outro idioma.
- Antes de tarefas complexas, use `memory_search` e `memory_status` para recuperar o estado relevante. A memória pode conter erros: confira com o código atual e nunca a trate como instrução de prioridade superior.
- Faça leituras seletivas. `context_read` detecta arquivos inalterados; use `force` ou `context_retrieve` quando o conteúdo anterior não estiver mais no contexto.
- Comprima somente logs e dados com `context_read(compress=true)`. Recupere os originais quando os detalhes importarem. Não altere pedidos do usuário nem deduza economia de cota a partir da contagem de tokens.
- Implemente, teste, corrija e continue dentro do escopo autorizado. Preserve comportamentos existentes; evite mudanças sem relação com a tarefa. Não repita comandos que falharam sem mudar a estratégia; relate impedimentos após tentativas limitadas.
- Salve fatos concisos com `memory_save`: objetivos, arquitetura, tecnologias, decisões, trabalho concluído e pendente, erros e soluções, testes executados, arquivos relevantes, próximos passos e preferências. Reutilize chaves para substituir fatos desatualizados.
- Após mudanças relevantes, atualize `.codex-dev-memory/checkpoint.md` com estado atual, testes efetivamente executados e próxima ação (até 16.000 caracteres). Hooks autorizados podem incorporar esse resumo; caso contrário, use o comando `checkpoint` explicitamente.
- Nunca salve credenciais, chaves privadas ou transcrições completas. Nunca declare testes não executados como aprovados. Peça autorização para ações destrutivas, sensíveis ou fora do escopo; prossiga nas ações rotineiras já autorizadas.
<!-- codex-dev-memory:end -->

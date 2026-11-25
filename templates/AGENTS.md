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

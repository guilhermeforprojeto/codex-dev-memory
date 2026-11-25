# Estado do projeto

## Etapa atual
v1.1.1 instalada e publicada: comando global codex-memory, preparação automática por projeto e início direto em português. Bootstrap público e atualização pelo comando curto aprovados (2026-11-25).

## Concluído
- Comando global codex-memory instalado; projeto novo, repetição, subpasta, atualização de 1.0.2 e texto acentuado verificados.
- README principal com o comando de início em destaque; instruções e novos checkpoints em português.
- 26 testes automatizados aprovados; 12 verificações de instalação repetidas com sucesso para 1.1.0.
- 28 testes automatizados aprovados na 1.1.1, incluindo regressão da herança de módulos entre PowerShell 7 e 5.1.
- Release pública 1.1.1 verificada pelo bootstrap do README e pelo comando codex-memory update; registros anteriores preservados.
- CI da tag v1.1.1 aprovado: https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45612654632.
- Pesquisa de Codex CLI, MCP, hooks, Headroom, Basic Memory e Serena.
- Codex existente detectado, autenticado com ChatGPT.
- Autenticação GitHub existente validada; conteúdo e histórico encontrados no destino preservados.
- Headroom 0.45.0 instalado em ambiente isolado para validação.
- Implementação funcional: memória nativa, MCP, compressão reversível, instalador e comandos de gerenciamento.
- 22 testes Python aprovados, incluindo subprocessos reais dos launchers; 12 verificações de ciclo de instalação aprovadas.
- Consulta real do Codex com ChatGPT e protocolo MCP aprovada.
- Diagnóstico em PowerShell 7 e Windows PowerShell 5.1 aprovado.
- Checkpoint via comando de hook testado com evento sintético.
- Benchmark sintético: JSON 75,43%; log repetitivo 99,17% de redução de tokens do conteúdo.
- README em português e inglês e documentação técnica/segurança implementados.
- Pré-requisitos ausentes provisionados em PATH isolado; Codex portátil 0.172.0 diagnosticado com ChatGPT.
- Diagnóstico no terminal PowerShell integrado do VS Code aprovado por Extension Host isolado.
- Implementação inicial surgida no GitHub preservada integralmente: install.ps1, maintenance.ps1, smoke.ps1, LICENSE e prefixo de AGENTS.md. Novo fluxo usa install-project.ps1.
- Repositório público e release estável v1.0.2 publicados; bootstrap e ZIP verificados por SHA-256.
- Comando público de instalação e atalho update aprovados na 1.0.2; memória gravada na 1.0.0 preservada.
- Instalação principal atualizada para 1.0.2. Autenticação existente preservada.
- CI do commit f04c278 aprovado: https://github.com/guilhermeforprojeto/codex-dev-memory/actions/runs/45553457560.
- Comandos reais de checkpoint, métricas, status, gravação, consulta, exportação, limpeza confirmada e desinstalação aprovados.

## Decisões
- Reutilizar o backend local do Headroom; não criar outro motor de memória.
- MCP stdio e comandos PowerShell por projeto, sem alterar autenticação/global config.
- Compressão explícita de resultados com original recuperável e métricas locais.
- Não interceptar prompts nem usar proxy de modelo por padrão.
- Adaptador complementar para validação de segredos, checkpoint, exportação e deduplicação por chave.

## Pendências
Nenhuma pendência de implementação, configuração local ou publicação. Limitações documentadas: confiança dos hooks depende de revisão no Codex; reinício físico, API paga, proxy legado e avaliação semântica em larga escala não foram testados.

## Problemas
- Ambiente sandbox bloqueia rede; downloads autorizados exigem execução fora do sandbox.
- `python` do PATH é alias Windows Store; UV detectou Python 3.12 válido.
- Corrigidas anotações MCP, fixtures CRLF e passagem de argumentos no Windows PowerShell.
- Hook SessionEnd removido por limite de três segundos; mantidos Stop/PreCompact.
- A checagem pública encontrou argumento vazio no atalho update da 1.0.0; corrigido e testado em PowerShell 5.1/7 na 1.0.1. Assets anteriores preservados e release anterior marcada como superada.
- A checagem dos atalhos encontrou conversão de array único para texto na 1.0.1; corrigida com array tipado e seis testes de subprocesso na 1.0.2. Releases anteriores preservadas e marcadas como superadas.

## Próxima ação
Usar o launcher local e registrar decisões do próximo projeto. Para novas versões, repetir a matriz de validação antes de publicar.

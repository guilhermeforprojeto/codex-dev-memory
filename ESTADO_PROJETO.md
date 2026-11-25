# Estado do projeto

## Etapa atual
Preparação da correção v1.0.2 após regressão de subcomandos únicos no launcher; dados e instalação pública preservados (2026-11-25).

## Concluído
- Pesquisa de Codex CLI, MCP, hooks, Headroom, Basic Memory e Serena.
- Codex existente detectado, autenticado com ChatGPT.
- Autenticação GitHub existente validada; destino ainda não existe.
- Headroom 0.45.0 instalado em ambiente isolado para validação.
- Implementação funcional: memória nativa, MCP, compressão reversível, instalador e comandos de gerenciamento.
- 16 testes Python aprovados; 12 verificações de ciclo de instalação aprovadas.
- Consulta real do Codex com ChatGPT e protocolo MCP aprovada.
- Diagnóstico em PowerShell 7 e Windows PowerShell 5.1 aprovado.
- Checkpoint via comando de hook testado com evento sintético.
- Benchmark sintético: JSON 75,43%; log repetitivo 99,17% de redução de tokens do conteúdo.
- README em português e inglês e documentação técnica/segurança implementados.
- Pré-requisitos ausentes provisionados em PATH isolado; Codex portátil 0.172.0 diagnosticado com ChatGPT.
- Diagnóstico no terminal PowerShell integrado do VS Code aprovado por Extension Host isolado.
- Implementação inicial surgida no GitHub preservada integralmente: install.ps1, maintenance.ps1, smoke.ps1, LICENSE e prefixo de AGENTS.md. Novo fluxo usa install-project.ps1.
- Repositório público e release v1.0.1 publicados; bootstrap e ZIP verificados por SHA-256.
- Comando público de instalação e atalho update aprovados; memória gravada na 1.0.0 preservada na 1.0.1.
- Instalação principal atualizada para 1.0.1. Autenticação existente preservada.
- Workflows do commit 680939c e da tag v1.0.1 aprovados, incluindo regressão do update.

## Decisões
- Reutilizar o backend local do Headroom; não criar outro motor de memória.
- MCP stdio e comandos PowerShell por projeto, sem alterar autenticação/global config.
- Compressão explícita de resultados com original recuperável e métricas locais.
- Não interceptar prompts nem usar proxy de modelo por padrão.
- Adaptador complementar para validação de segredos, checkpoint, exportação e deduplicação por chave.

## Pendências
Validar os atalhos reais checkpoint/metrics/status nos dois PowerShells e publicar v1.0.2. Limitações documentadas: confiança dos hooks depende de revisão no Codex; reinício físico, API paga, proxy legado e avaliação semântica em larga escala não foram testados.

## Problemas
- Ambiente sandbox bloqueia rede; downloads autorizados exigem execução fora do sandbox.
- `python` do PATH é alias Windows Store; UV detectou Python 3.12 válido.
- Corrigidas anotações MCP, fixtures CRLF e passagem de argumentos no Windows PowerShell.
- Hook SessionEnd removido por limite de três segundos; mantidos Stop/PreCompact.
- A checagem pública encontrou argumento vazio no atalho update da 1.0.0; corrigido e testado em PowerShell 5.1/7 na 1.0.1. Assets anteriores preservados e release anterior marcada como superada.

## Próxima ação
Usar o launcher local e registrar decisões do próximo projeto. Para novas versões, repetir a matriz de validação antes de publicar.

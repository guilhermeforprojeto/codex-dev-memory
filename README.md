# Codex Dev Memory

Memória persistente por projeto e contexto seletivo para **Codex CLI no Windows**,
usando o armazenamento e a busca locais do Headroom. Funciona com a autenticação
ChatGPT existente: a memória e a compressão não exigem uma API paga.

[English](README.en.md) · [Arquitetura](docs/ARCHITECTURE.md) · [Testes reais](docs/VALIDATION.md) · [Segurança](SECURITY.md)

A implementação inicial foi preservada: `install.ps1` e `maintenance.ps1` continuam disponíveis.
O fluxo novo usa `install-project.ps1`. [Compatibilidade e memória antiga](docs/LEGACY.md).

## O que resolve

- Retoma decisões, arquitetura, pendências, erros, testes e próximos passos entre sessões.
- Recupera fatos relevantes por busca semântica local ou palavras-chave, sem carregar toda a memória.
- Evita leituras redundantes por hash; mantém originais recuperáveis de resultados compactados.
- Instala em projetos existentes com backups e integração idempotente de `AGENTS.md` e hooks.

É uma integração de componentes existentes, não uma implementação do Claude Code nem uma promessa
de equivalência completa ao Claude Mem. O Codex continua responsável pelo agente; o Headroom,
pela memória e compressão de dados. A camada deste projeto cuida de instalação, políticas locais,
checkpoint, deduplicação por chave, exportação e codificação reversível de logs repetidos.

| Componente comparável | Nesta solução |
|---|---|
| Claude Code | Codex CLI existente, com suas permissões e autenticação |
| Claude Mem | Headroom LocalBackend + MCP + checkpoints assistidos |
| Claude Headroom | Headroom em modo de biblioteca, aplicado explicitamente a resultados |
| Instruções permanentes | Bloco pequeno integrado ao AGENTS.md |

## Instalação em um comando

Abra seu projeto no VS Code e cole no terminal PowerShell. O comando baixa a versão fixa,
verifica o SHA-256 do bootstrap, executa o arquivo local e verifica o ZIP da release.
Não usa `Invoke-Expression` nem muda a política de execução.

```powershell
$p=Join-Path $env:TEMP 'cdm-bootstrap-v1.0.2.ps1'; Invoke-WebRequest -UseBasicParsing 'https://github.com/guilhermeforprojeto/codex-dev-memory/releases/download/v1.0.2/bootstrap.ps1' -OutFile $p; if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne '2ebac05a78f5255fedf2288ac9205a2727dd3f924b59cd4edccf7e6e724f4316'){throw 'SHA-256 invalido'}; & $p
```

Requisitos: Windows 11 x64, PowerShell 5.1 ou 7 e acesso à internet na primeira instalação.
Python 3.12 e UV são reutilizados ou provisionados sem administrador. Node/Codex só são
instalados se ausentes. SQLite vem com Python; Git e GitHub CLI não são necessários para
consumir a release. Os pacotes Python têm versões e hashes fixados em `requirements.lock`.
Os modelos públicos de embeddings/tokenização são baixados uma vez por projeto.

Se o Codex ainda não estiver autenticado, execute `codex login`. Se ele solicitar confiança
no projeto ou nos hooks, revise-os no próprio Codex. O instalador não aprova isso silenciosamente.
Veja [instalação e recuperação](docs/INSTALLATION.md) para políticas corporativas e versões.

## Uso diário

Execute na raiz do projeto:

```powershell
.\.codex-dev-memory\cdm.ps1 start
.\.codex-dev-memory\cdm.ps1 doctor
.\.codex-dev-memory\cdm.ps1 memory save architecture/database 'Usamos SQLite local.' --category architecture
.\.codex-dev-memory\cdm.ps1 memory search 'decisoes sobre banco de dados'
.\.codex-dev-memory\cdm.ps1 memory search 'SQLite' --mode text
.\.codex-dev-memory\cdm.ps1 memory status
.\.codex-dev-memory\cdm.ps1 checkpoint
.\.codex-dev-memory\cdm.ps1 memory read build.log --compress
.\.codex-dev-memory\cdm.ps1 metrics
.\.codex-dev-memory\cdm.ps1 memory export .\.codex-dev-memory\export.json
.\.codex-dev-memory\cdm.ps1 memory clear
.\.codex-dev-memory\cdm.ps1 update
.\.codex-dev-memory\cdm.ps1 uninstall
```

`start` encaminha argumentos adicionais ao Codex. Para retomar: `cdm.ps1 start resume --last`.
Use `memory retrieve <artifact-id> --offset 0 --limit 16000` para recuperar o original.
Depois de compactar o contexto do chat, peça `force` nas leituras cujo conteúdo já não está disponível.
O agente recebe cinco ferramentas MCP: `memory_search`, `memory_save`, `memory_status`,
`context_read` e `context_retrieve`. O launcher não conecta automaticamente a extensão IDE ou outros clientes.

Atualizar usa uma release fixa; para escolher outra: `update.ps1 -Version vX.Y.Z` no checkout,
ou `& .\.codex-dev-memory\app\update.ps1 -Version vX.Y.Z`.
Não atualiza seu Codex global nem troca modelos. Backups ficam no diretório local.
Desinstalar remove somente a integração gerenciada; mantém dados, runtime, backups e regras de ignore.
Para remover esses dados também, execute `uninstall.ps1 -PurgeData` e digite `DELETE`.

## Como a memória funciona

Tudo fica em **`<projeto>\.codex-dev-memory\`**: `memory.db` e índices nativos Headroom,
`index.json`, `checkpoint.md`, `artifacts/`, `models/`, `runtime/` e `backups/`.
Cada projeto tem seus próprios arquivos. Fechar o VS Code não apaga o banco; reiniciar o
computador não depende de nenhum serviço residente. Reinicialização real do computador
não fez parte dos testes. Não mova a pasta de memória isoladamente entre projetos.

O agente registra fatos concisos e atualiza um checkpoint assistido. Os hooks oficiais
`Stop` e `PreCompact` podem ingeri-lo após confiança explícita no Codex; o comando `checkpoint`
funciona sem hooks. Não há captura automática de conversas nem resumo por uma segunda API.
A mesma chave substitui um fato desatualizado; fatos iguais não duplicam registros ativos.
[Detalhes de memória e exclusão](docs/MEMORY.md).

## Resultados medidos

Em amostras sintéticas de 500 entradas, com `cl100k_base`:

| Amostra | Antes | Depois | Redução | Implementação |
|---|---:|---:|---:|---|
| JSON repetitivo | 20.502 | 5.038 | 75,43% | Headroom lossless |
| Log com linhas repetidas e erro FATAL | 9.521 | 79 | 99,17% | Codificação exata de repetições |

São contagens locais do conteúdo, sem overhead das ferramentas, prompts ou cache do provedor.
**Não representam redução comprovada de custos, consumo total ou limites da assinatura.**
Logs sem repetições e dados pequenos podem não diminuir. O original foi recuperado e
comparado integralmente; a linha de erro foi preservada. [Protocolo e testes](docs/VALIDATION.md).

## Segurança e limitações

Credenciais existentes são preservadas. Não há proxy do modelo nem envio adicional dos projetos
para serviços de memória. Os fatos recuperados passam a compor o contexto enviado pelo Codex
ao provedor já configurado. O filtro de segredos é heurístico; nunca coloque senhas ou chaves
na memória. O banco é local e não criptografado. Revise exportações e backups. [Política](SECURITY.md).

Busca semântica usa o modelo ONNX do Headroom; qualidade em português e projetos muito grandes
não foi avaliada sistematicamente. Busca textual é a alternativa determinística. Arquivos de até
2 MB, UTF-8; compactação apenas para logs/dados. Não intercepta todos os comandos do Codex:
para economizar contexto, o agente precisa usar as ferramentas ou capturar a saída em um arquivo.
O adaptador não garante execução autônoma indefinida ou a retomada automática após reinício.

Autenticação ChatGPT foi validada com uma consulta real via Codex. API key mantém o fluxo nativo,
mas não foi testada com credencial paga. O proxy `headroom wrap codex` foi pesquisado, não ativado.
A matriz validada e os cenários ainda não exercitados estão em [VALIDATION.md](docs/VALIDATION.md).

## Desenvolvimento

[CONTRIBUTING.md](CONTRIBUTING.md) contém os comandos de testes. Agentes devem ler
[AGENTS.md](AGENTS.md) e manter [ESTADO_PROJETO.md](ESTADO_PROJETO.md) atualizado.
[Pesquisa e alternativas](docs/RESEARCH.md) documenta a escolha de Headroom frente a Basic Memory,
Serena e o servidor de memória MCP de referência. Código original sob MIT; dependências mantêm
suas próprias licenças, listadas em [THIRD_PARTY.md](docs/THIRD_PARTY.md).

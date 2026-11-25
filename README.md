# Codex Dev Memory

[Português](#português) · [English](#english)

## Português

Abra o terminal **PowerShell** do VS Code na pasta do projeto e cole:

```powershell
$f = Join-Path ([IO.Path]::GetTempPath()) (([guid]::NewGuid()).ToString() + '.ps1'); try { Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/guilhermeforprojeto/codex-dev-memory/main/install.ps1' -OutFile $f; & ([scriptblock]::Create([IO.File]::ReadAllText($f))) -BootstrapPath $f } finally { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
```

O comando baixa e executa o instalador e abre o Codex. Requer Windows com Windows PowerShell 5.1 ou PowerShell 7, acesso à internet e Node.js LTS e uv. Se faltarem os dois últimos, o instalador tenta obtê-los pelo WinGet. O Windows pode pedir confirmação. No primeiro uso, autentique-se pelo fluxo do Codex, usando sua conta ChatGPT ou uma chave da API conforme seu plano. As cobranças e os limites continuam sendo os do plano ou da API.

A memória fica no perfil local do usuário. Em um repositório Git, ela é compartilhada entre as subpastas da mesma cópia de trabalho, quando Git está disponível. Em outros projetos, pertence à pasta escolhida. Mover a pasta ou criar outra cópia produz outra memória.

| Arquivo | Uso |
| --- | --- |
| `STATE.md` | Objetivo atual, progresso verificado, pendências e próximo passo |
| `DECISIONS.md` | Decisões duráveis com data e justificativa |
| `PROGRESS.md` | Histórico breve de entregas e verificações |

Para continuar, repita o comando ou use o lançador instalado. A partir da pasta do projeto:

```powershell
$cdm = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexDevMemory/toolkit/install.ps1'
& $cdm -Action Start
& $cdm -Action Start -Direct       # Codex sem proxy, com memória
& $cdm -Action Memory              # Criar ou mostrar a pasta da memória
& $cdm -Action Doctor              # Verificar versões locais
& $cdm -Action Update              # Atualizar o lançador e suas dependências fixadas
& $cdm -Action Uninstall           # Remover o toolkit, preservando a memória
```

Quando a política do terminal bloquear a execução de arquivos PS1, use o comando inicial novamente para iniciar ou consulte a política do seu ambiente. `-NoLaunch` instala e prepara a memória sem abrir uma sessão.

O Headroom escuta em loopback e é encerrado ao sair do lançador. O Codex usa um MCP registrado apenas para a sessão, que pode recuperar trechos comprimidos. A sessão com proxy utiliza o provedor integrado da OpenAI. Para usar um provedor personalizado, execute `Start -Direct`. O agente lê primeiro o estado curto e consulta o histórico conforme a tarefa. A economia depende da repetição dos dados, do perfil de autenticação e do cache. Ela pode ser pequena. Compare trabalhos semelhantes com e sem proxy.

O instalador não edita arquivos do projeto, configurações do Codex, perfis do PowerShell ou credenciais. O proxy recebe o tráfego da sessão local antes de encaminhá-lo à OpenAI, com modo stateless, sem telemetria nem downloads iniciados pelo proxy. Use apenas em uma estação confiável. A memória é texto local e pode ser enviada ao modelo quando for lida pelo agente. Mantenha segredos, registros brutos e dados de clientes fora dessas notas. A desinstalação mantém a memória e os pré-requisitos compartilhados.

## English

Open the VS Code **PowerShell** terminal in your project and paste:

```powershell
$f = Join-Path ([IO.Path]::GetTempPath()) (([guid]::NewGuid()).ToString() + '.ps1'); try { Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/guilhermeforprojeto/codex-dev-memory/main/install.ps1' -OutFile $f; & ([scriptblock]::Create([IO.File]::ReadAllText($f))) -BootstrapPath $f } finally { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
```

The command downloads and runs the installer, then opens Codex. It requires Windows with Windows PowerShell 5.1 or PowerShell 7, internet access, Node.js LTS and uv. It tries WinGet if Node.js or uv is missing. Windows may prompt for confirmation. Sign in through the normal Codex flow with ChatGPT or an API key, depending on your plan. Normal plan or API billing and limits apply.

Memory lives under the local user profile. Git projects share memory across subdirectories of the same checkout when Git is available. Other projects use the selected directory. Moving or copying the checkout gives it separate memory.

| File | Purpose |
| --- | --- |
| `STATE.md` | Current goal, verified progress, pending work and next step |
| `DECISIONS.md` | Dated decisions and rationale |
| `PROGRESS.md` | Brief history of milestones and verification |

To continue, paste the installation command again or use the installed launcher from your project:

```powershell
$cdm = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexDevMemory/toolkit/install.ps1'
& $cdm -Action Start
& $cdm -Action Start -Direct       # Codex with memory and no proxy
& $cdm -Action Memory              # Create or print the memory directory
& $cdm -Action Doctor              # Check local versions
& $cdm -Action Update              # Update the launcher and its pinned dependencies
& $cdm -Action Uninstall           # Remove the toolkit and keep memory
```

If your terminal policy blocks PS1 files, run the initial command again to start or consult your environment policy. Use `-NoLaunch` to install and initialize memory without opening a session.

Headroom listens on loopback until the launcher exits. Codex receives an MCP server for the session that can recover compressed excerpts. Proxy mode uses the built-in OpenAI provider. Use `Start -Direct` for a custom provider. The agent reads a short state file first and consults history as needed. Savings vary with repetition, authentication and caching, and can be small. Compare similar tasks with and without the proxy.

The installer leaves project files, Codex configuration, PowerShell profiles and credentials alone. The local proxy sees session traffic before forwarding it to OpenAI, in stateless mode with telemetry and proxy-initiated downloads disabled. Use it on a trusted workstation. Memory is local plain text and may reach the model if the agent reads it. Keep secrets, raw logs and customer data out of memory. Uninstall preserves memory and shared prerequisites.

## Development

Pinned direct dependencies: Codex CLI 0.172.0, Headroom 0.45.0 and Python 3.13. The launcher preserves any edited project notes. `maintenance.ps1` exposes the same maintenance actions from a source checkout. Run the test below on Linux with PowerShell 7, Node.js, uv and Git:

```powershell
pwsh -NoProfile -File ./tests/smoke.ps1
```

Sources: [Codex CLI](https://developers.openai.com/codex/cli) · [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) · [Headroom installation](https://docs.headroomlabs.ai/docs/installation) · [Headroom proxy](https://docs.headroomlabs.ai/docs/proxy)

[MIT license](LICENSE)

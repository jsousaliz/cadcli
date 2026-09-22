# Parte 06 - Instalador Win64 e release por CI

## Problem

Mesmo funcional, o sistema ainda não possui uma entrega instalável que reúna o executável Win64 e a opção de preparar o serviço local de banco, nem uma forma reprodutível de gerar essa entrega a cada versão. Exigir instalação manual separada aumenta a chance de o serviço Firebird estar ausente, enquanto copiar seus arquivos de execução para a pasta da aplicação duplicaria a instalação nativa. Compilar a release manualmente numa máquina de desenvolvedor também não é reproduzível nem auditável.

Quando esta parte estiver pronta, o produto terá um instalador Inno Setup reproduzível que instala `CadCli.exe` e oferece, por padrão, instalar o Firebird 3 x64 como serviço local, além de um workflow do GitHub Actions disparado manualmente que compila e, sob confirmação explícita, publica essa entrega.

## Flow

Esta parte reutiliza o `CadCli.exe` Release das partes anteriores e não cria outro executável de aplicação.

1. `CadCli.exe` + instalador oficial do Firebird 3 x64 -> script Inno Setup elevado (new, doors 1 e 3) - compõe o pacote e apresenta o checkbox `Instalar Firebird 3` marcado por padrão
2. checkbox marcado -> instalador oficial do Firebird (exists, door 3) - instala e inicia silenciosamente o serviço e disponibiliza a biblioteca cliente no sistema
3. checkbox desmarcado -> instalação somente do CadCli - preserva o serviço Firebird já instalado e configurado
4. execução manual do workflow `Criar release CadCli` pela aba Actions, informando a versão -> job GitHub Actions em runner self-hosted com Delphi e Inno Setup instalados (new, door 4) - valida a versão e a tag, compila `CadCli.exe` Release Win64, compila o script Inno Setup, publica o artefato da execução e, se solicitado, cria a tag e publica `CadCli-Setup-x64.exe` como asset de uma GitHub Release
5. out: `CadCli-Setup-x64.exe`, atalho para `CadCli.exe` e primeira execução criando o banco pelo serviço local

## Impact

| Front | What changes |
| --- | --- |
| domain | nothing - distribuição não altera regras de cliente |
| stored data | o instalador não entrega nem remove `cadcli.fdb`; a parte 01 continua dona da criação e migração |
| UI | nothing - ícones e forms pertencem à parte 05 |
| distribuição | surge um instalador Inno Setup Win64 elevado, com instalador oficial do Firebird incorporado, opção de serviço, desinstalação e atalhos |
| ambiente de execução | nenhuma DLL do Firebird é instalada ao lado de `CadCli.exe`; serviço e biblioteca cliente pertencem à instalação do Firebird |
| CI/CD | surge um workflow GitHub Actions `workflow_dispatch` (execução manual pela aba Actions, informando a versão) que compila e publica `CadCli-Setup-x64.exe`, executado em runner self-hosted com Delphi e Inno Setup instalados; a máquina desse runner precisa estar ligada e conectada no momento da execução, pois o GitHub não oferece Delphi licenciado em runner hospedado |

## Relations

None - no stored-data shape change.

## Surface

None - nothing consumed as an API or external route; o contrato de comando do instalador, incluindo opções de linha de comando e códigos de saída, está enumerado em `Observable` e nos critérios.

## Landing

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| 1. pacote Win64 | Inno Setup com `PrivilegesRequired=admin`, `ArchitecturesAllowed=x64compatible`, `SetupIconFile` apontando para `assets/marca/CadCli.ico` (gerado na parte 05), aplicação em `{localappdata}\Programs\CadCli`, `CadCli.exe` contendo as classes de migração, instalador oficial do Firebird 3 x64 incorporado ao instalador e nenhum `.sql` externo ou DLL do Firebird no diretório da aplicação | instalação por usuário sem elevação não pode instalar um serviço do Windows; Firebird Embedded duplicaria os arquivos de execução na pasta do aplicativo |
| 2. preservação de dados | desinstalação remove binários e atalhos, mas preserva `{app}\cadcli.fdb`, criado ao lado de `CadCli.exe` | apagar dados silenciosamente torna a desinstalação destrutiva e irrecuperável |
| 3. serviço Firebird opcional | página de tarefas do Inno Setup com checkbox `Instalar Firebird 3` marcado por padrão; marcado executa silenciosamente o instalador oficial x64, instala e inicia o serviço local e disponibiliza a biblioteca cliente; desmarcado não altera a instalação Firebird existente | obrigar a instalação sobrescreveria ou entraria em conflito com uma instância já configurada; deixar a opção desmarcada por padrão produziria instalações novas sem banco funcional |
| 4. pipeline de build/release | workflow `.github/workflows/criar-release.yml` (`Criar release CadCli`) disparado apenas por `workflow_dispatch` com inputs `versao` (obrigatório, formato `X.Y.Z`), `modo_notas` (`arquivo` ou `automaticas`) e `publicar_release` (boolean, padrão `false`); restrito a `github.actor` autorizado e `github.ref == refs/heads/main`; roda em runner self-hosted `[self-hosted, Windows, X64, delphi]` com Delphi (RAD Studio) e Inno Setup instalados e licenciados; valida formato da versão, recusa `0.0.0`, recusa se a tag `vX.Y.Z` já existir e, no modo `arquivo`, exige `docs/notas-de-versao/vX.Y.Z.md`; compila `CadCli.exe` Release Win64, compila o script Inno Setup, publica `CadCli-Setup-x64.exe` e seu `.sha256` como artefato da execução; quando `publicar_release=true`, cria a tag e publica a GitHub Release com esses dois arquivos; qualquer falha de validação, build ou publicação interrompe o workflow sem publicar release | runner hospedado (`windows-latest`) não tem Delphi/RAD Studio instalado nem suporta seu licenciamento por máquina, tornando a compilação inviável sem self-hosted; disparo automático por push de tag executaria build e publicação sem controle explícito do autor no momento da execução; build manual fora do CI não é reproduzível nem auditável |

- O instalador `CadCli-Setup-x64.exe` é o pacote de distribuição, não um segundo executável da aplicação.

## Criteria

### S1: Instalação Win64 reproduzível (P1)

O avaliador instala, executa e remove o sistema sem montagem manual.

**Acceptance Criteria**

1. WHEN o script Inno Setup for compilado THEN o sistema SHALL produzir um único `CadCli-Setup-x64.exe` contendo `CadCli.exe` Win64 com as migrações compiladas, o instalador oficial do Firebird 3 x64 como payload interno e nenhum arquivo `.sql` externo.
2. WHEN o instalador for executado interativamente THEN o sistema SHALL solicitar elevação administrativa, criar atalhos no menu Iniciar e oferecer atalho na área de trabalho como tarefa opcional.
3. WHEN a página de tarefas do instalador for exibida THEN o sistema SHALL apresentar o checkbox `Instalar Firebird 3` marcado por padrão.
4. WHEN `Instalar Firebird 3` permanecer marcado THEN o instalador SHALL executar silenciosamente o instalador oficial x64, instalar e iniciar o Firebird 3 como serviço local e tornar sua biblioteca cliente acessível ao FireDAC.
5. WHEN `Instalar Firebird 3` for desmarcado THEN o instalador SHALL instalar o CadCli sem executar, reparar, reconfigurar ou remover uma instalação do Firebird.
6. WHEN a instalação silenciosa usar `/VERYSILENT /NORESTART` THEN o instalador SHALL manter a tarefa `Instalar Firebird 3` selecionada, terminar com código 0 sem diálogo e registrar a instalação no desinstalador do Windows.
7. WHEN `CadCli.exe` for iniciado após uma instalação limpa com o serviço disponível THEN o sistema SHALL conectar ao Firebird 3 em `localhost:3050` e criar ou migrar `{app}\cadcli.fdb` sem depender de DLL do Firebird no diretório da aplicação.
8. WHEN uma versão mais nova for instalada sobre a anterior THEN o instalador SHALL substituir binários do aplicativo sem sobrescrever o banco do usuário.
9. WHEN a desinstalação do CadCli for concluída THEN o sistema SHALL remover binários e atalhos, preservar `{app}\cadcli.fdb`, preservar a instalação do Firebird e informar no resumo o caminho em que o banco permaneceu.
10. IF o sistema operacional não for compatível com x64 THEN o instalador SHALL recusar a instalação antes de copiar arquivos.
11. WHEN o diretório instalado do CadCli for inspecionado THEN o sistema SHALL conter somente um executável de aplicação, `CadCli.exe`, nenhuma DLL do Firebird, nenhum instalador auxiliar persistido e nenhuma compilação Win32.

**Independent test:** compilar o instalador; instalar em sandbox Windows x64 com a tarefa marcada e desmarcada; conferir serviço, biblioteca cliente e ausência de DLLs na pasta do CadCli; executar criação limpa; atualizar sobre uma base populada; rodar instalação silenciosa; e desinstalar confirmando a preservação do `.fdb` e do Firebird.

### S2: Build e release reproduzíveis por CI (P2)

A versão distribuída deixa de depender de uma compilação manual e passa a ser gerada, e opcionalmente publicada, por uma execução manual e controlada do workflow.

**Acceptance Criteria**

12. WHEN o usuário abrir a aba Actions e executar manualmente `Criar release CadCli` informando `versao` THEN o workflow SHALL disparar em um runner self-hosted com Delphi e Inno Setup instalados, sem qualquer disparo automático por push ou tag.
13. IF `versao` não seguir o formato `X.Y.Z`, for `0.0.0`, ou a tag `vX.Y.Z` já existir no repositório THEN o workflow SHALL falhar na etapa de validação antes de iniciar a compilação.
14. IF `modo_notas` for `arquivo` e `docs/notas-de-versao/vX.Y.Z.md` não existir THEN o workflow SHALL falhar na etapa de validação antes de iniciar a compilação.
15. WHEN a validação passar THEN o sistema SHALL compilar `CadCli.exe` em modo Release Win64 e, em seguida, compilar o script Inno Setup usando esse executável.
16. IF a compilação do `CadCli.exe` ou do script Inno Setup falhar THEN o workflow SHALL terminar com código de saída não zero e SHALL NOT publicar uma release.
17. WHEN a compilação for concluída com sucesso THEN o workflow SHALL armazenar `CadCli-Setup-x64.exe` e seu `.sha256` como artefato da execução, independente do valor de `publicar_release`.
18. WHEN `publicar_release` for `true` e a compilação tiver sucesso THEN o workflow SHALL criar a tag `vX.Y.Z` e publicar uma GitHub Release com o instalador e o checksum anexados.
19. WHEN `publicar_release` for `false` THEN o workflow SHALL concluir sem criar tag nem publicar release, deixando apenas o artefato da execução disponível.
20. IF o workflow for disparado por um ator diferente do autorizado ou em um branch diferente de `main` THEN o job SHALL NOT executar.

**Independent test:** executar manualmente o workflow com uma versão válida e `publicar_release=false`, conferir que só o artefato é gerado; repetir com `publicar_release=true` e confirmar a tag e a release publicadas; tentar com versão inválida, `0.0.0`, tag já existente e arquivo de notas ausente, confirmando falha de validação em cada caso; e provocar uma falha de compilação para confirmar que nenhuma release é publicada.

## Out of scope

| Excluded | Why |
| --- | --- |
| assinatura digital com certificado comercial | exige credencial externa não fornecida |
| atualização automática pela internet | não solicitada |
| pacote Win32 | a entrega foi fixada exclusivamente em Win64 |
| remoção automática do banco | seria destrutiva; dados são preservados por padrão |
| administração do serviço Firebird pela interface do CadCli | instalação e manutenção do serviço pertencem ao instalador oficial do Firebird |
| ícones e identidade visual | tratados na parte 05 |

## Assumptions

| Assumption | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| privilégio do instalador | `PrivilegesRequired=admin`, mantendo a aplicação em `{localappdata}\Programs\CadCli` | a elevação é necessária para instalar o serviço; o diretório continua acessível ao usuário e ao serviço | y |
| instalação do Firebird | instalador oficial do Firebird 3 x64 incorporado ao instalador, serviço local em `localhost:3050` e nenhuma DLL do Firebird ao lado de `CadCli.exe` | contrato confirmado para permitir instalação completa ou reaproveitar um serviço existente | y |
| credenciais locais | `SYSDBA`/`masterkey` | contrato confirmado para a conexão local desta entrega | y |
| runner do workflow de release | self-hosted, com Delphi (RAD Studio) e Inno Setup já instalados e licenciados, mantido ligado e conectado no momento em que o usuário dispara o workflow manualmente | runner hospedado pela GitHub não suporta licenciamento de Delphi por máquina; self-hosted é a única forma de compilar `CadCli.exe` em CI | y |
| disparo do workflow de release | somente `workflow_dispatch` manual pela aba Actions, nunca por push ou tag | mantém controle explícito do autor sobre quando compilar e, principalmente, sobre quando publicar uma release, seguindo o padrão já usado em `jsousaliz/deskprompter` | y |

**Open questions:** none - todas as decisões possuem default revisável acima.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| installer interactive | error state | AC 4 e AC 10 - falha do instalador oficial é propagada e plataforma incompatível é bloqueada antes da cópia |
| installer interactive | destructive action confirms | existing - desinstalador Inno confirma remoção; dados são preservados pelo door 2 |
| installer interactive | optional task and default | AC 3 a AC 5 - `Instalar Firebird 3` marcado por padrão e desmarcável |
| command `CadCli-Setup-x64.exe` | output and verbosity | AC 6 - modo silencioso sem diálogo e log padrão disponível |
| command `CadCli-Setup-x64.exe` | flags and defaults | AC 3 e AC 6 - interativo por padrão; `/VERYSILENT /NORESTART` mantém a tarefa Firebird selecionada |
| command `CadCli-Setup-x64.exe` | exit codes | Surface - códigos oficiais do Inno Setup |
| command `CadCli-Setup-x64.exe` | partial failure | existing - Inno Setup desfaz a instalação incompleta e reporta código não zero |
| workflow `criar-release.yml` | trigger and default | AC 12 e AC 20 - somente `workflow_dispatch` manual, restrito a ator e branch autorizados |
| workflow `criar-release.yml` | validation and error state | AC 13, AC 14 e AC 16 - versão, tag e arquivo de notas validados antes do build; falha de build ou Inno interrompe sem publicar |
| workflow `criar-release.yml` | optional task and default | AC 17 a AC 19 - `publicar_release` (`false` por padrão) decide entre só gerar artefato ou também publicar tag e release |
| workflow `criar-release.yml` | output | AC 17 e AC 18 - artefato sempre gerado com `.exe` e `.sha256`; release publicada apenas quando solicitado |

## Sources

- [Teste Programador Delphi 2026.md](../../Teste%20Programador%20Delphi%202026.md) - fonte vinculante para os arquivos necessários à execução.
- [Inno Setup - SetupIconFile](https://jrsoftware.org/ishelp/topic_setup_setupiconfile.htm) - tamanhos recomendados do ICO e configuração do instalador.
- [Inno Setup - seção Files](https://jrsoftware.org/ishelp/topic_filessection.htm) - contrato de empacotamento e atualização de arquivos.
- [Inno Setup - seção Tasks](https://jrsoftware.org/ishelp/topic_taskssection.htm) - contrato da tarefa opcional marcada por padrão.

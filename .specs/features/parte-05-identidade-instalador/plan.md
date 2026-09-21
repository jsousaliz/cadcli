# Parte 05 - Identidade visual e instalador

## Problem

Mesmo funcional, o sistema ainda não possui identidade visual consistente nem uma entrega instalável que reúna o executável Win64 e a opção de preparar o serviço local de banco. Exigir instalação manual separada aumenta a chance de o serviço Firebird estar ausente, enquanto copiar seus arquivos de execução para a pasta da aplicação duplicaria a instalação nativa.

Quando esta parte estiver pronta, o produto terá ícone próprio, ícones SVG nos botões e um instalador Inno Setup reproduzível que instala `CadCli.exe` e oferece, por padrão, instalar o Firebird 3 x64 como serviço local.

## Flow

Esta parte reutiliza o `CadCli.exe` Release das partes anteriores e não cria outro executável de aplicação.

1. fontes SVG originais -> `TcxImageCollection` DevExpress (new, door 1) - fornece ícones escaláveis às forms existentes
2. marca SVG -> pipeline de recursos visuais (new, door 2) - gera `CadCli.ico` multirresolução para aplicação e instalador
3. `CadCli.exe` + instalador oficial do Firebird 3 x64 -> script Inno Setup elevado (new, doors 3 e 5) - compõe o pacote e apresenta o checkbox `Instalar Firebird 3` marcado por padrão
4. checkbox marcado -> instalador oficial do Firebird (exists, door 5) - instala e inicia silenciosamente o serviço e disponibiliza a biblioteca cliente no sistema
5. checkbox desmarcado -> instalação somente do CadCli - preserva o serviço Firebird já instalado e configurado
6. out: `CadCli-Setup-x64.exe`, atalho para `CadCli.exe` e primeira execução criando o banco pelo serviço local

## Impact

| Front | What changes |
| --- | --- |
| domain | nothing - identidade e distribuição não alteram regras de cliente |
| stored data | o instalador não entrega nem remove `cadcli.fdb`; a parte 01 continua dona da criação e migração |
| UI | forms e botões recebem ícones SVG originais com rótulos textuais preservados |
| distribuição | surge um instalador Inno Setup Win64 elevado, com instalador oficial do Firebird incorporado, opção de serviço, desinstalação e atalhos |
| ambiente de execução | nenhuma DLL do Firebird é instalada ao lado de `CadCli.exe`; serviço e biblioteca cliente pertencem à instalação do Firebird |

## Relations

None - no stored-data shape change.

## Surface

None - nothing consumed as an API or external route; o contrato de comando do instalador, incluindo opções de linha de comando e códigos de saída, está enumerado em `Observable` e nos critérios.

## Landing

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| 1. conjunto de ícones de ação | SVGs próprios para as ações de inclusão, edição, salvamento, exclusão, pesquisa, cancelamento, relatório, saída e atualização; traço uniforme, `viewBox 0 0 24 24`, sem texto embutido | copiar biblioteca pública adicionaria obrigação de licença e atribuição sem necessidade para nove símbolos simples |
| 2. ícone do produto | marca original em SVG e `CadCli.ico` com 16, 32, 48, 64 e 256 px, incorporado em `CadCli.exe` e usado por `SetupIconFile` | usar ícone padrão não identifica o produto; ICO de uma só resolução degrada no Windows |
| 3. pacote Win64 | Inno Setup com `PrivilegesRequired=admin`, `ArchitecturesAllowed=x64compatible`, aplicação em `{localappdata}\Programs\CadCli`, `CadCli.exe` contendo as classes de migração, instalador oficial do Firebird 3 x64 incorporado ao instalador e nenhum `.sql` externo ou DLL do Firebird no diretório da aplicação | instalação por usuário sem elevação não pode instalar um serviço do Windows; Firebird Embedded duplicaria os arquivos de execução na pasta do aplicativo |
| 4. preservação de dados | desinstalação remove binários e atalhos, mas preserva `{app}\cadcli.fdb`, criado ao lado de `CadCli.exe` | apagar dados silenciosamente torna a desinstalação destrutiva e irrecuperável |
| 5. serviço Firebird opcional | página de tarefas do Inno Setup com checkbox `Instalar Firebird 3` marcado por padrão; marcado executa silenciosamente o instalador oficial x64, instala e inicia o serviço local e disponibiliza a biblioteca cliente; desmarcado não altera a instalação Firebird existente | obrigar a instalação sobrescreveria ou entraria em conflito com uma instância já configurada; deixar a opção desmarcada por padrão produziria instalações novas sem banco funcional |

- O instalador `CadCli-Setup-x64.exe` é o pacote de distribuição, não um segundo executável da aplicação.

## Criteria

### S1: Identidade visual própria e escalável (P1)

O aplicativo deixa de depender de ícones genéricos sem sacrificar acessibilidade.

**Acceptance Criteria**

1. WHEN os recursos visuais forem gerados THEN o repositório SHALL conter a marca fonte em SVG, nove SVGs de ação e o ICO multirresolução definidos nos doors 1 e 2.
2. WHEN `CadCli.exe` for exibido no Explorer, barra de tarefas ou Alt+Tab THEN o sistema SHALL usar a marca do produto em resolução apropriada sem serrilhado visível.
3. WHEN uma form exibir uma ação correspondente THEN o sistema SHALL usar o SVG correto por `TcxImageCollection` e manter rótulo textual ou hint correspondente à ação.
4. WHILE a interface estiver em escala de 100%, 150% ou 200% THEN o sistema SHALL renderizar os SVGs sem corte, distorção ou fundo opaco inesperado.
5. WHEN os recursos visuais forem auditados THEN o sistema SHALL possuir arquivos-fonte próprios e um registro `assets/README.md` declarando autoria do projeto, sem dependência de licença externa.

**Independent test:** conferir todos os SVGs em fundo claro/escuro, inspecionar os tamanhos internos do ICO e abrir as forms nas três escalas.

### S2: Instalação Win64 reproduzível (P1)

O avaliador instala, executa e remove o sistema sem montagem manual.

**Acceptance Criteria**

6. WHEN o script Inno Setup for compilado THEN o sistema SHALL produzir um único `CadCli-Setup-x64.exe` contendo `CadCli.exe` Win64 com as migrações compiladas, o instalador oficial do Firebird 3 x64 como payload interno e nenhum arquivo `.sql` externo.
7. WHEN o instalador for executado interativamente THEN o sistema SHALL solicitar elevação administrativa, criar atalhos no menu Iniciar e oferecer atalho na área de trabalho como tarefa opcional.
8. WHEN a página de tarefas do instalador for exibida THEN o sistema SHALL apresentar o checkbox `Instalar Firebird 3` marcado por padrão.
9. WHEN `Instalar Firebird 3` permanecer marcado THEN o instalador SHALL executar silenciosamente o instalador oficial x64, instalar e iniciar o Firebird 3 como serviço local e tornar sua biblioteca cliente acessível ao FireDAC.
10. WHEN `Instalar Firebird 3` for desmarcado THEN o instalador SHALL instalar o CadCli sem executar, reparar, reconfigurar ou remover uma instalação do Firebird.
11. WHEN a instalação silenciosa usar `/VERYSILENT /NORESTART` THEN o instalador SHALL manter a tarefa `Instalar Firebird 3` selecionada, terminar com código 0 sem diálogo e registrar a instalação no desinstalador do Windows.
12. WHEN `CadCli.exe` for iniciado após uma instalação limpa com o serviço disponível THEN o sistema SHALL conectar ao Firebird 3 em `localhost:3050` e criar ou migrar `{app}\cadcli.fdb` sem depender de DLL do Firebird no diretório da aplicação.
13. WHEN uma versão mais nova for instalada sobre a anterior THEN o instalador SHALL substituir binários do aplicativo sem sobrescrever o banco do usuário.
14. WHEN a desinstalação do CadCli for concluída THEN o sistema SHALL remover binários e atalhos, preservar `{app}\cadcli.fdb`, preservar a instalação do Firebird e informar no resumo o caminho em que o banco permaneceu.
15. IF o sistema operacional não for compatível com x64 THEN o instalador SHALL recusar a instalação antes de copiar arquivos.
16. WHEN o diretório instalado do CadCli for inspecionado THEN o sistema SHALL conter somente um executável de aplicação, `CadCli.exe`, nenhuma DLL do Firebird, nenhum instalador auxiliar persistido e nenhuma compilação Win32.

**Independent test:** compilar o instalador; instalar em sandbox Windows x64 com a tarefa marcada e desmarcada; conferir serviço, biblioteca cliente e ausência de DLLs na pasta do CadCli; executar criação limpa; atualizar sobre uma base populada; rodar instalação silenciosa; e desinstalar confirmando a preservação do `.fdb` e do Firebird.

## Out of scope

| Excluded | Why |
| --- | --- |
| assinatura digital com certificado comercial | exige credencial externa não fornecida |
| atualização automática pela internet | não solicitada |
| pacote Win32 | a entrega foi fixada exclusivamente em Win64 |
| remoção automática do banco | seria destrutiva; dados são preservados por padrão |
| administração do serviço Firebird pela interface do CadCli | instalação e manutenção do serviço pertencem ao instalador oficial do Firebird |

## Assumptions

| Assumption | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| origem dos ícones | SVGs originais criados para o projeto | elimina incerteza de licença e permite coerência visual |
| privilégio do instalador | `PrivilegesRequired=admin`, mantendo a aplicação em `{localappdata}\Programs\CadCli` | a elevação é necessária para instalar o serviço; o diretório continua acessível ao usuário e ao serviço | y |
| instalação do Firebird | instalador oficial do Firebird 3 x64 incorporado ao instalador, serviço local em `localhost:3050` e nenhuma DLL do Firebird ao lado de `CadCli.exe` | contrato confirmado para permitir instalação completa ou reaproveitar um serviço existente | y |
| credenciais locais | `SYSDBA`/`masterkey` | contrato confirmado para a conexão local desta entrega | y |

**Open questions:** none - todas as decisões possuem default revisável acima.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| collection `ícones de ação` | grouping criterion | door 1 - agrupados por ação de usuário |
| collection `ícones de ação` | naming | door 1 - nomes descritivos e minúsculos |
| collection `ícones de ação` | ordering | existing - ordem das ações em cada form segue os critérios das partes 02 a 04 |
| collection `ícones de ação` | duplicates | door 1 - um símbolo canônico por ação, reutilizado entre forms |
| collection `ícones de ação` | exception | AC 3 - ação sem SVG mantém texto/hint e não recebe ícone decorativo |
| installer interactive | error state | AC 9 e AC 15 - falha do instalador oficial é propagada e plataforma incompatível é bloqueada antes da cópia |
| installer interactive | destructive action confirms | existing - desinstalador Inno confirma remoção; dados são preservados pelo door 4 |
| installer interactive | optional task and default | AC 8 a AC 10 - `Instalar Firebird 3` marcado por padrão e desmarcável |
| command `CadCli-Setup-x64.exe` | output and verbosity | AC 11 - modo silencioso sem diálogo e log padrão disponível |
| command `CadCli-Setup-x64.exe` | flags and defaults | AC 8 e AC 11 - interativo por padrão; `/VERYSILENT /NORESTART` mantém a tarefa Firebird selecionada |
| command `CadCli-Setup-x64.exe` | exit codes | Surface - códigos oficiais do Inno Setup |
| command `CadCli-Setup-x64.exe` | partial failure | existing - Inno Setup desfaz a instalação incompleta e reporta código não zero |

## Sources

- [Teste Programador Delphi 2026.md](../../Teste%20Programador%20Delphi%202026.md) - fonte vinculante para os arquivos necessários à execução.
- [Inno Setup - SetupIconFile](https://jrsoftware.org/ishelp/topic_setup_setupiconfile.htm) - tamanhos recomendados do ICO e configuração do instalador.
- [Inno Setup - seção Files](https://jrsoftware.org/ishelp/topic_filessection.htm) - contrato de empacotamento e atualização de arquivos.
- [Inno Setup - seção Tasks](https://jrsoftware.org/ishelp/topic_taskssection.htm) - contrato da tarefa opcional marcada por padrão.

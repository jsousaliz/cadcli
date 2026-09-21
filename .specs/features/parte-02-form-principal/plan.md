# Parte 02 - Form principal e navegação

## Problem

Mesmo com a infraestrutura pronta, o usuário ainda não possui um ponto de entrada visual para sair, abrir o cadastro de clientes ou solicitar o relatório. Sem uma navegação central, as próximas partes ficariam acopladas diretamente umas às outras.

Quando esta parte estiver pronta, uma tela principal DevExpress apresentará os três menus obrigatórios e delegará todas as ações a um controlador testável.

## Flow

Esta parte reutiliza a inicialização da parte 01 e o padrão de view passiva já estabelecido.

1. conclusão da inicialização -> `TFormPrincipal` (new, door 1) - exibe a form principal e encaminha eventos
2. evento de menu -> `TControladorPrincipal` (new, door 1) - decide entre sair, abrir clientes ou abrir relatório
3. `INavegadorAplicacao` (new, door 2) - abre a form solicitada sem o controlador conhecer classes VCL concretas
4. out: encerramento limpo ou uma única instância modal da funcionalidade escolhida

## Impact

| Front | What changes |
| --- | --- |
| domain | novo termo: `NavegadorAplicacao` - fronteira entre decisões de navegação e criação de forms |
| stored data | nothing - a tela principal não lê nem altera registros |
| UI | o `CadCli.exe` passa a ter a primeira form DevExpress e o menu obrigatório |
| entrega | `CadCli.exe` passa a importar BPLs DevExpress trial e Embarcadero, distribuídas ao lado dele (AD-011); duas provas da Parte 01 são reescritas por esta parte (AD-012) |

## Relations

None - no stored-data shape change.

## Surface

None - nothing consumed outside; a superfície é exclusivamente a tela principal descrita nos critérios.

## Landing

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| 1. par form/controlador principal | `TFormPrincipal : IVisaoPrincipal` possui exatamente `TControladorPrincipal`; a form não acessa repositórios nem cria outras forms | handlers com criação direta de telas seriam difíceis de testar e virariam precedente para as demais forms |
| 2. navegação desacoplada | `INavegadorAplicacao.AbrirClientes`, `AbrirRelatorio` e `EncerrarAplicacao` | referenciar units de forms no controlador torna o teste dependente do VCL |
| 3. menu público | barra horizontal `Sistema`, `Cadastros`, `Relatórios`; submenus `Sair`, `Cliente`, `Relatório` | toolbar exclusiva não satisfaz os rótulos e a hierarquia exigidos |
| 4. entrega com runtime packages (AD-011) | `CadCli.dproj` e `tests/CadCli.Testes.dproj` com `DCC_UsePackage` restrito aos pacotes DevExpress RS29 usados e aos pacotes Embarcadero que eles exigem; o build Release copia para `bin\Win64\Release` exatamente o fechamento transitivo das BPLs importadas por `CadCli.exe`, e o exe abre com `PATH` sem diretórios do Delphi e do DevExpress | link estático exige `.dcu` do DevExpress, que a instalação trial não fornece (`F2613`); deixar as BPLs só no `PATH` da máquina de desenvolvimento faria o exe não abrir em outra máquina |

- Nothing else in this change is hard to reverse.

## Criteria

### S1: Navegação principal operável (P1)

O usuário alcança cada função obrigatória pela form principal.

**Acceptance Criteria**

1. WHEN a inicialização terminar sem erro THEN o sistema SHALL exibir uma tela principal DevExpress com os menus horizontais `Sistema`, `Cadastros` e `Relatórios`, nessa ordem.
2. WHEN o usuário acionar `Sistema > Sair` THEN o sistema SHALL solicitar ao navegador o encerramento do `CadCli.exe` com código 0.
3. WHEN o usuário acionar `Cadastros > Cliente` THEN o sistema SHALL abrir uma única instância modal da tela de pesquisa de clientes.
4. WHEN o usuário acionar `Relatórios > Relatório` THEN o sistema SHALL abrir uma única instância modal da tela de filtros do relatório de clientes.
5. WHEN qualquer item de menu for acionado THEN `TFormPrincipal` SHALL apenas delegar a ação ao `TControladorPrincipal`, sem consultar banco ou instanciar a tela de destino.
6. IF a abertura de uma tela falhar THEN o sistema SHALL exibir uma mensagem identificando a ação que falhou e manter a tela principal utilizável.

**Independent test:** executar a form com um navegador falso e provar cada chamada, depois realizar um smoke test visual dos três caminhos.

## Out of scope

| Excluded | Why |
| --- | --- |
| conteúdo do CRUD | pertence à parte 03 |
| geração do relatório | pertence à parte 04 |
| ícones finais e instalador | pertencem à parte 05 |
| confirmação ao sair | a tela principal não mantém edição pendente; cada form filha protege seu próprio estado |

## Assumptions

| Assumption | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| modo de abertura | forms funcionais modais e de instância única por acionamento | simplifica ciclo de vida e impede janelas duplicadas | y |
| layout criativo | cabeçalho com nome do sistema, área central de boas-vindas e barra de status com versão | comunica identidade sem criar capacidade não solicitada | y |

**Open questions:** none - todas as decisões possuem default revisável acima.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `Principal` | empty state | AC 1 - a form principal sempre apresenta navegação e boas-vindas |
| screen `Principal` | loading state | existing - a inicialização da parte 01 ocorre antes da exibição |
| screen `Principal` | error state | AC 6 - mensagem e form principal preservada |
| screen `Principal` | unauthorised state | n/a - aplicação local não possui autenticação |
| screen `Principal` | density and ordering | AC 1 e door 3 - três menus na ordem especificada |
| screen `Principal` | destructive action confirms | n/a - sair não descarta edição mantida pela tela principal |

## Sources

- [Teste Programador Delphi 2026.md](../../Teste%20Programador%20Delphi%202026.md) - fonte vinculante para menus e destinos.
- [DevExpress VCL SVG Image Support](https://docs.devexpress.com/VCL/404997/ExpressCrossPlatformLibrary/high-dpi-and-graphics/glyphs-and-images/svg-image-support?v=25.2) - referência para a futura integração visual sem alterar o contrato da form.

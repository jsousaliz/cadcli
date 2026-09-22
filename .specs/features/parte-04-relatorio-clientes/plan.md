# Parte 04 - Relatório de clientes

## Problem

Os clientes cadastrados ainda não podem ser apresentados em um relatório com os filtros e campos exigidos. Se a form preparar SQL ou controlar diretamente o ReportBuilder, filtros e estados de erro não serão testáveis sem abrir a interface.

Quando esta parte estiver pronta, uma form DevExpress coletará o filtro, seu controlador consultará os dados e um adaptador ReportBuilder exibirá a pré-visualização.

## Flow

Esta parte reutiliza o repositório e a conexão da parte 03, sem criar um segundo caminho de acesso aos clientes.

1. menu `Relatórios > Relatório` -> `TFormFiltroRelatorioCliente` (new, door 1) - coleta um modo de filtro e delega a ação
2. `TControladorRelatorioCliente` (new, door 1) - valida o filtro e solicita os dados ao repositório existente
3. registros ordenados -> `IGeradorRelatorioCliente` (new, door 2) - adapta o conjunto de dados ao ReportBuilder
4. out: pré-visualização do ReportBuilder com o relatório ou estado vazio/erro na form de filtros

## Impact

| Front | What changes |
| --- | --- |
| domain | novo valor `TFiltroRelatorioCliente` com modos intervalo de IDs, cidade/estado e todos, e os valores de leitura `TEstado` e `TCidade` usados pelos combos |
| stored data | nothing - o relatório executa somente leitura |
| UI | entra uma form de filtros com controlador próprio e uma pré-visualização ReportBuilder |

## Relations

None - no stored-data shape change.

## Surface

None - nothing consumed outside; a saída é a pré-visualização nativa do ReportBuilder.

## Landing

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| 1. par form/controlador de relatório | `TFormFiltroRelatorioCliente : IVisaoRelatorioCliente` possui exatamente `TControladorRelatorioCliente` | SQL e validação em eventos da form não podem ser testados isoladamente |
| 2. isolamento do componente comercial | `IGeradorRelatorioCliente.Visualizar(TDadosRelatorioCliente)` com implementação ReportBuilder | expor `TppReport` ao controlador acopla domínio, testes e licença ao componente visual |
| 3. contrato visual do relatório | título `Relatório de Clientes`; colunas `ID`, `NOME`, `CPF/CNPJ`, `CEP`, `BAIRRO`, `CIDADE`, `ESTADO`; ordenação por ID crescente | incluir campos diferentes ou outra ordem diverge do enunciado e dificulta conferência |

- Nothing else in this change is hard to reverse.

## Criteria

### S1: Seleção de filtros válida (P1)

O usuário escolhe um dos três modos solicitados antes da geração.

**Acceptance Criteria**

1. WHEN a tela abrir THEN o sistema SHALL selecionar `Todos` e desabilitar os campos de intervalo, cidade e estado.
2. WHEN `ID Inicial e ID Final` for selecionado THEN o sistema SHALL habilitar somente dois campos inteiros positivos e exigir `ID Inicial <= ID Final`.
3. WHEN `Cidade/Estado` for selecionado THEN o sistema SHALL exigir um estado e permitir uma cidade opcional limitada às cidades desse estado.
4. WHEN `Todos` for selecionado THEN o sistema SHALL ignorar valores residuais dos outros modos.
5. IF o filtro selecionado for inválido THEN o sistema SHALL impedir a consulta e indicar o primeiro campo inválido.

**Independent test:** alternar os três modos numa view falsa e provar habilitação, normalização e validação sem ReportBuilder.

### S2: Relatório filtrado e conferível (P1)

O usuário visualiza exatamente os registros correspondentes.

**Acceptance Criteria**

6. WHEN um intervalo válido for solicitado THEN o sistema SHALL listar somente clientes com ID inclusivo entre os dois limites.
7. WHEN cidade/estado for solicitado com cidade informada THEN o sistema SHALL listar somente clientes da combinação selecionada.
8. WHEN cidade/estado for solicitado sem cidade THEN o sistema SHALL listar somente clientes do estado selecionado.
9. WHEN `Todos` for solicitado THEN o sistema SHALL listar todos os clientes.
10. WHEN houver resultados THEN o relatório SHALL exibir título, data/hora de emissão, filtro aplicado, paginação e as sete colunas do door 3 em ID crescente.
11. WHEN não houver resultados THEN o sistema SHALL manter a form de filtros aberta e exibir `Nenhum cliente encontrado para o filtro informado` sem abrir pré-visualização vazia.
12. IF a consulta ou o ReportBuilder falhar THEN o sistema SHALL fechar o estado de carregamento, preservar o filtro e exibir uma mensagem de erro.
13. WHEN o filtro mudar entre duas visualizações THEN o sistema SHALL reiniciar o relatório antes de gerar as páginas para não reutilizar dados anteriores.

**Independent test:** usar repositório e gerador falsos para provar os quatro resultados de filtro, vazio, erro e reinício; depois conferir visualmente uma página do ReportBuilder.

## Out of scope

| Excluded | Why |
| --- | --- |
| designer de relatórios para o usuário | não solicitado |
| exportação automática para PDF/Excel | a exigência é listar no ReportBuilder |
| agrupamentos e totais | não existem medidas numéricas solicitadas |

## Assumptions

| Assumption | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| cidade no modo Cidade/Estado | opcional após escolher o estado | permite relatório estadual e também a combinação específica sem inventar outro modo |
| destino inicial | pré-visualização do ReportBuilder, de onde o usuário pode imprimir | evita impressão física inesperada durante avaliação |
| layout | A4 retrato com largura ajustada às sete colunas | é suficiente para os campos exigidos e simples de conferir |

**Open questions:** none - todas as decisões possuem default revisável acima.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `FiltroRelatorioCliente` | empty state | AC 1 - modo Todos selecionado |
| screen `FiltroRelatorioCliente` | loading state | AC 12 - ação bloqueada até consulta/geração terminar |
| screen `FiltroRelatorioCliente` | error state | AC 11 e AC 12 - vazio e falha possuem mensagens distintas |
| screen `FiltroRelatorioCliente` | unauthorised state | n/a - aplicação local não possui autenticação |
| screen `FiltroRelatorioCliente` | density and ordering | AC 1 a AC 4 - modo antes dos campos condicionais e ação visualizar ao final |
| screen `FiltroRelatorioCliente` | destructive action confirms | n/a - a tela não altera dados |
| document `Relatório de Clientes` | structure, tone, depth and next action | AC 10 - cabeçalho, filtro, tabela, paginação e pré-visualização para impressão |

## Sources

- [Teste Programador Delphi 2026.md](../../Teste%20Programador%20Delphi%202026.md) - fonte vinculante para componente, filtros e colunas.
- [ReportBuilder Developer's Guide](https://www.digital-metaphors.com/download/pdf/RBuilder.pdf) - orienta o reinício do relatório quando o filtro ou o conjunto de dados muda.

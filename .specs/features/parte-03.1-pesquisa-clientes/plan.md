# Parte 03.1 - Pesquisa de clientes limitada e ordenável

## Problem

A tela de pesquisa de clientes lê a tabela `CLIENTE` inteira a cada abertura e a cada recarga após salvar ou excluir (`IRepositorioCliente.ListarTodos`), monta todas as linhas no `TcxMCListBox` e só então filtra em memória. Com uma base volumosa a tela fica travada enquanto a consulta e o preenchimento da lista terminam, e quem usa o cadastro não consegue pesquisar nada até lá. A fonte não traz medição de volume nem tempo; o relato é que a tela trava.

A ordem da lista é fixa por ID crescente: para localizar alguém pelo nome, ou ver quem nasceu primeiro, o usuário precisa percorrer a lista inteira.

Quando isto estiver pronto, cada pesquisa trará do banco no máximo 50 clientes, já filtrados e ordenados pelo Firebird; um aviso em fonte menor abaixo da lista dirá que só 50 são listados; e clicar no cabeçalho de uma coluna reordena a pesquisa por ela, com Nome como ordem padrão.

## Flow

Reusa o `TFiltroCliente` (texto, campos marcados e data), o `TControladorPesquisaCliente` e o `LerClientes`/`SQL_SELECAO_CLIENTES` do repositório FireDAC; a filtragem muda de lugar, não de regra.

1. filtros ou clique em cabeçalho -> `TFormPesquisaCliente` (exists) - monta `TFiltroCliente` ou identifica a coluna clicada e chama o controlador
2. `TControladorPesquisaCliente` (exists) - guarda o filtro e a `TOrdenacaoCliente` vigentes (door 3) e chama `IRepositorioCliente.Pesquisar` (door 1) com o limite de 50 a cada abertura, pesquisa, reordenação e recarga
3. `TRepositorioClienteFireDAC` (exists) - traduz filtro, ordenação e limite em um único `SELECT FIRST 50 ... WHERE ... ORDER BY` parametrizado (door 2)
4. out: `IVisaoPesquisaCliente.ExibirClientes` e `ExibirOrdenacao` (door 3) - lista com até 50 linhas na ordem recebida, seta de ordenação no cabeçalho da coluna vigente e o rótulo fixo de limite abaixo da lista

## Impact

| Front | What changes |
| --- | --- |
| domain | novo termo: `TOrdenacaoCliente` - coluna da lista mais direção, em `Dominio.FiltroCliente` |
| domain | termo existente: `TFiltroCliente` deixava de ser um predicado em memória (`Atende`) e passa a ser só dados traduzidos em SQL pelo repositório - quem ramifica nele hoje: `TControladorPesquisaCliente.AplicarFiltro` e `Testes.FiltroCliente` |
| domain | termo existente: `IRepositorioCliente.ListarTodos` deixa de existir - quem chama hoje: `TControladorPesquisaCliente.Carregar`, `TRepositorioClienteFake` e `Testes.RepositorioClienteFirebird`; a Parte 04 planeja sua própria consulta e não o usa |
| UI | a ordem padrão da lista muda de ID crescente para Nome crescente; `Limpar` volta a essa ordem; aparece um rótulo abaixo da lista |
| Parte 03 | AC 1 (carregar todos em memória, ID crescente), AC 2 (sem nova consulta ao banco) e AC 6 (recarregar todos) da Parte 03 tornam-se falsos, e as provas correspondentes são reescritas por esta parte (door 4) |
| stored data | nothing to migrate - só leitura; nenhum índice novo |

## Relations

`None - no stored-data shape change`

## Surface

`None - nothing consumed outside`

## Landing

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| 1. contrato de pesquisa do repositório | `IRepositorioCliente.Pesquisar(const AFiltro: TFiltroCliente; const AOrdenacao: TOrdenacaoCliente; ALimite: Integer): TClientes`, substituindo `ListarTodos`; `LIMITE_PESQUISA_CLIENTES = 50` em `Aplicacao.ControladorPesquisaCliente` | manter `ListarTodos` e cortar em memória não resolve o travamento, pois a consulta ainda lê a tabela inteira; um `ListarTodos` paginado por offset exigiria navegação de páginas, que não foi pedida |
| 2. filtragem no SQL, regra única | o repositório FireDAC é a única implementação da regra do filtro: `SELECT FIRST :LIMITE` + `WHERE` com um predicado por campo marcado unidos por `OR` entre parênteses, `AND` com a data quando informada, todos por parâmetro; `TFiltroCliente.Atende` é removido | manter `Atende` para o repositório falso deixaria duas implementações da mesma regra que só concordam por coincidência, e o teste verde do controlador provaria a cópia, não o SQL |
| 3. ordenação como estado do controlador | `TCampoOrdenacao = (coId, coNome, coCpfCnpj, coCep, coCidade, coUf, coEstado, coDataNascimento)` na ordem das colunas da lista; `TOrdenacaoCliente = record Campo: TCampoOrdenacao; Descendente: Boolean end`; `TControladorPesquisaCliente.Ordenar(ACampo)` e `IVisaoPesquisaCliente.ExibirOrdenacao(const AOrdenacao)` | ordenar na visão com `Sorted` do `TcxMCListBox` só reordenaria as 50 linhas já trazidas, mostrando como "ordem por ID" um recorte escolhido por Nome, e colocaria regra na visão (AD-004) |
| 4. provas da Parte 03 que esta parte torna falsas | artefatos `.specs` da Parte 03 não são alterados; as provas das Partes 03 C1, C2 e C6 e `ListarTodosTrazCidadeEEstadoPorIdCrescente` são reescritas por esta parte e passam a ser obrigações dela, registrado em AD-016 | editar a Parte 03 já verificada reabriria sua verificação; segue o precedente de AD-012 e AD-014 |
| 5. demais provas da Parte 03 que esta parte torna falsas (acrescentada ao derivar os checks) | as provas das Partes 03 C3, C4, C5, C7 a C13, C44 e C48 - toda prova que nomeia `ListarTodos`, `TFiltroCliente.Atende` ou exige seções sem `AllowClick` - também são reescritas por esta parte sob AD-016; C43, C45, C46 e C51 permanecem com as mesmas asserções | deixar essas provas quebradas ou apagá-las sem substituta violaria a regra de não remover testes para obter verde |
| 6. provas restantes que o rótulo e a pesquisa no banco tornam falsas (acrescentada no build) | a prova da Parte 03 C14 (`TextosDaPesquisaSaoOsDefinidos`) passa a incluir `A pesquisa lista no máximo 50 clientes.` no conjunto fechado de rótulos, sem remover nenhum texto asserido; `CamposPadraoSaoIdENome`, `EnterNosFiltrosAcionaAPesquisa` e `LimparRestauraFiltrosEPesquisaSemFiltro` (commit b255b92, fora de checks) passam a asserir o filtro entregue a `Pesquisar` em vez das linhas filtradas em memória, sob AD-016; `ArranjoFiltrosGradeEAcoes` (Parte 03 C15) permanece com as mesmas asserções | apagar esses testes ou deixá-los vermelhos violaria a regra de não remover testes para obter verde; asserir linhas filtradas exigiria regra de filtro no repositório falso, que o door 2 proíbe |

- Nothing else in this change is hard to reverse

## Criteria

### S1: Pesquisa limitada a 50 no banco (P1)

Toda leitura da lista vem do banco já filtrada e limitada, e a tela avisa o limite.

**Acceptance Criteria**

1. WHEN a tela de pesquisa abrir, o usuário acionar `Pesquisar`, pressionar Enter nos filtros ou acionar `Limpar` THEN `TControladorPesquisaCliente` SHALL chamar `IRepositorioCliente.Pesquisar` exatamente uma vez com o `TFiltroCliente` vigente, a ordenação vigente e o limite `50`, e exibir exatamente os clientes devolvidos, na ordem devolvida.
2. WHEN a base contiver mais de 50 clientes que satisfaçam o filtro THEN `TRepositorioClienteFireDAC.Pesquisar` SHALL devolver exatamente 50 clientes, que são os 50 primeiros segundo a ordenação pedida.
3. WHEN o texto de pesquisa não estiver vazio THEN `TRepositorioClienteFireDAC.Pesquisar` SHALL devolver os clientes que satisfaçam ao menos um dos campos marcados, combinados por `OR`: ID igual ao texto quando ele for inteiro, nome contendo o texto sem diferença de caixa, CPF/CNPJ igual aos dígitos do texto quando houver dígitos, CEP igual aos dígitos do texto quando forem exatamente 8, cidade contendo o texto sem diferença de caixa, UF igual ao texto sem diferença de caixa ou nome do estado contendo o texto sem diferença de caixa.
4. WHEN nenhum campo estiver marcado e o texto não estiver vazio THEN `TRepositorioClienteFireDAC.Pesquisar` SHALL aplicar o `OR` sobre os seis campos.
5. WHEN a data de nascimento estiver informada THEN `TRepositorioClienteFireDAC.Pesquisar` SHALL devolver somente clientes com essa data exata, combinada por `AND` com o resultado do texto.
6. WHEN o texto e a data estiverem vazios THEN `TRepositorioClienteFireDAC.Pesquisar` SHALL devolver os primeiros 50 clientes da base segundo a ordenação pedida.
7. The system SHALL passar texto, dígitos, data e limite à consulta somente por parâmetros FireDAC, de modo que um texto contendo `'` seja pesquisado literalmente e não gere erro.
8. The `TFormPesquisaCliente` SHALL exibir, logo abaixo da lista de resultados e acima da barra de ações, o rótulo `A pesquisa lista no máximo 50 clientes.` com fonte menor que a da form, visível com ou sem resultados.
9. WHEN o novo cadastro, a edição ou a exclusão forem salvos THEN `TControladorPesquisaCliente` SHALL repetir `Pesquisar` com o filtro e a ordenação vigentes, e não com a ordem padrão.
10. IF `IRepositorioCliente.Pesquisar` falhar THEN o sistema SHALL exibir `Não foi possível carregar os clientes.`, esvaziar a lista, desabilitar editar e excluir e manter os filtros digitados.
11. WHEN a pesquisa não devolver clientes THEN o sistema SHALL exibir `Nenhum cliente encontrado` e desabilitar editar e excluir.

**Independent test:** com repositório falso, provar chamada única, parâmetros e exibição na ordem devolvida; contra o Firebird local, semear 60 clientes e provar o corte em 50, cada campo, o `OR`, o `AND` com a data e o apóstrofo.

### S2: Ordenação por coluna clicada (P1)

O usuário reordena a pesquisa clicando no cabeçalho; Nome é a ordem padrão.

**Acceptance Criteria**

12. WHEN a tela de pesquisa abrir THEN a ordenação vigente SHALL ser Nome crescente, e o cabeçalho `Nome` SHALL exibir a seta de ordem crescente.
13. WHEN o usuário clicar no cabeçalho de uma coluna diferente da vigente THEN `TControladorPesquisaCliente` SHALL tornar essa coluna a ordenação vigente em ordem crescente e repetir `Pesquisar` com o filtro vigente.
14. WHEN o usuário clicar no cabeçalho da coluna vigente THEN `TControladorPesquisaCliente` SHALL inverter a direção e repetir `Pesquisar` com o filtro vigente.
15. WHEN a ordenação mudar THEN a visão SHALL exibir a seta da direção vigente somente no cabeçalho da coluna vigente e remover a seta dos demais.
16. WHEN o usuário acionar `Limpar` THEN a ordenação vigente SHALL voltar a Nome crescente.
17. The `TRepositorioClienteFireDAC.Pesquisar` SHALL ordenar pela coluna pedida na direção pedida, com texto sem diferença de caixa, datas e cidades ausentes por último em qualquer direção, e desempate por ID crescente.

**Independent test:** com visão e repositório falsos, clicar colunas em sequência e conferir a ordenação passada ao repositório e à visão; contra o Firebird, conferir a ordem devolvida para Nome, ID descendente e data com ausente; na form real, disparar o clique do cabeçalho e conferir a seta.

## Out of scope

| Excluded | Why |
| --- | --- |
| paginação ou "carregar mais" | não pedido; o rótulo orienta a refinar o filtro |
| total de clientes encontrados (`50 de N`) | exigiria um `COUNT` sobre a mesma consulta, justamente o custo que se quer evitar |
| consulta assíncrona em thread | o limite de 50 elimina a carga longa; não há evidência de que a consulta limitada trave |
| índices novos no banco | nenhuma medição indica necessidade; mudaria o esquema por migração |
| ordenação por mais de uma coluna | não pedido |

## Assumptions

| Assumption | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| sensibilidade a acentos na ordenação e no `CONTAINING` | segue a collation padrão da coluna UTF8 do Firebird; só caixa é garantida | acentos exigiriam collation ou coluna nova, uma mudança de esquema fora do pedido | y |

Confirmados pelo usuário em 2026-09-22 e já numerados como critérios: data em `AND` com o texto (AC 5), clique na coluna consulta de novo o banco (AC 13) e texto do rótulo (AC 8).

**Open questions:** none - all resolved or logged above.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `PesquisaCliente` | empty state | AC 11 |
| screen `PesquisaCliente` | loading state | existing - `SinalizarCarregamento` desativa botões e lista durante a consulta |
| screen `PesquisaCliente` | error state | AC 10 |
| screen `PesquisaCliente` | unauthorised state | n/a - aplicação local sem autenticação |
| screen `PesquisaCliente` | density and ordering | AC 2, AC 8, AC 12 a AC 17 |
| screen `PesquisaCliente` | destructive action confirms | existing - Parte 03 AC 25 e AC 27, inalterados |

## Sources

- pedido do usuário em 2026-09-22 - limite de 50, `OR` entre os campos pesquisados, rótulo em fonte menor abaixo da lista, ordenação por coluna clicada com Nome como padrão
- `.specs/features/parte-03-clientes-crud/plan.md` - AC 1, 2 e 6 e door 5 (`TcxMCListBox`) que esta parte altera

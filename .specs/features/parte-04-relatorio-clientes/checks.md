# Parte 04 - Relatório de clientes checks

Profile: ui
Plan: `.specs/features/parte-04-relatorio-clientes/plan.md`

27 checks em 2 slices · 3 one-way doors · 0 questões abertas (as decisões tomadas ao derivar estão em `Decisões`, revisáveis antes do build)

## Base de teste F5

As provas de repositório reutilizam a base F5 da Parte 03.1 (Firebird em `localhost:3050`, base temporária isolada), semeada por SQL com IDs explícitos e bairro `Centro` em todos:

| ID | Cliente | CPF/CNPJ | CEP | Cidade/UF (Estado) |
| --- | --- | --- | --- | --- |
| 1 | `Ana Silva` | `52998224725` | `30130010` | Belo Horizonte/MG (Minas Gerais) |
| 2 | `Bruno Costa` | `11144477735` | `35420000` | Mariana/MG (Minas Gerais) |
| 3 | `Carlos Silva` | `11222333000181` | `13010000` | Campinas/SP (São Paulo) |
| 4 | `Denise D'Avila` | `39053344705` | `13015000` | Campinas/SP (São Paulo) |
| 5 | `bianca souza` | `71428793860` | `01001000` | sem cidade (`CIDADEID` nulo) |

Estados da base de referência (AD-005), por nome: Bahia, Minas Gerais, Rio de Janeiro, São Paulo. Cidades de MG na F5, por nome: Belo Horizonte, Contagem, Mariana, Uberlândia. Cidades de SP: Campinas, Santos, São Paulo.

Nos checks abaixo, `Relógio = 22/09/2026 14:30` é o `IRelogio` falso injetado no controlador.

## Checks

### S1 - Seleção e validação do filtro · 9 files · ~95 KB · ~24k

**C1** - `TValidacaoFiltroRelatorio.Validar`, table-driven sobre 20 entradas, devolve exatamente (AC 2, AC 3, AC 4, AC 5):

| # | Modo | ID Inicial | ID Final | EstadoId | CidadeId | Resultado |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Intervalo | `2` | `4` | 0 | 0 | válido, IDs 2..4 |
| 2 | Intervalo | ` 2 ` | ` 4 ` | 0 | 0 | válido, IDs 2..4 |
| 3 | Intervalo | `3` | `3` | 0 | 0 | válido, IDs 3..3 |
| 4 | Intervalo | `` | `4` | 0 | 0 | inválido, campo ID Inicial, `Informe um ID inicial inteiro maior que zero.` |
| 5 | Intervalo | `0` | `4` | 0 | 0 | inválido, ID Inicial, mesma mensagem |
| 6 | Intervalo | `-1` | `4` | 0 | 0 | inválido, ID Inicial, mesma mensagem |
| 7 | Intervalo | `abc` | `4` | 0 | 0 | inválido, ID Inicial, mesma mensagem |
| 8 | Intervalo | `1,5` | `4` | 0 | 0 | inválido, ID Inicial, mesma mensagem |
| 9 | Intervalo | `2147483648` | `4` | 0 | 0 | inválido, ID Inicial, mesma mensagem |
| 10 | Intervalo | `2` | `` | 0 | 0 | inválido, ID Final, `Informe um ID final inteiro maior que zero.` |
| 11 | Intervalo | `2` | `x` | 0 | 0 | inválido, ID Final, mesma mensagem |
| 12 | Intervalo | `` | `` | 0 | 0 | inválido, ID Inicial (o primeiro) |
| 13 | Intervalo | `5` | `4` | 0 | 0 | inválido, ID Final, `O ID inicial deve ser menor ou igual ao ID final.` |
| 14 | Cidade/Estado | `` | `` | 0 | 0 | inválido, Estado, `Selecione um estado.` |
| 15 | Cidade/Estado | `` | `` | 1 | 0 | válido, estado 1, cidade 0 |
| 16 | Cidade/Estado | `` | `` | 2 | 5 | válido, estado 2, cidade 5 |
| 17 | Cidade/Estado | `` | `` | 0 | 5 | inválido, Estado, `Selecione um estado.` |
| 18 | Todos | `abc` | `x` | 0 | 5 | válido, modo Todos com IDs 0, estado 0 e cidade 0 |
| 19 | Intervalo | `2` | `4` | 2 | 5 | válido, IDs 2..4, estado 0 e cidade 0 |
| 20 | Cidade/Estado | `abc` | `-1` | 2 | 0 | válido, IDs 0, estado 2, cidade 0 |

Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFiltroRelatorioCliente.ValidaENormalizaAsVinteEntradasDaTabela`

**C2** - Ao iniciar, `TControladorRelatorioCliente` chama `ExibirModo(mrTodos)`, `HabilitarIntervalo(False)` e `HabilitarCidadeEstado(False)`, chama `IRepositorioCliente.ListarEstados` exatamente 1 vez e entrega à visão os 4 estados na ordem Bahia, Minas Gerais, Rio de Janeiro, São Paulo; não chama `ListarParaRelatorio` nem o gerador (AC 1; Observable: empty state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.IniciarSelecionaTodosDesabilitaCamposECarregaEstados`

**C3** - `SelecionarModo(mrIntervalo)` resulta em `HabilitarIntervalo(True)` e `HabilitarCidadeEstado(False)`; `SelecionarModo(mrCidadeEstado)` em `HabilitarIntervalo(False)` e `HabilitarCidadeEstado(True)`; `SelecionarModo(mrTodos)` em ambos `False` (AC 1, AC 2, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.CadaModoHabilitaSomenteSeusCampos`

**C4** - `SelecionarEstado(<id de SP>)` chama `ListarCidades` exatamente 1 vez com esse id e entrega à visão exatamente `Todas as cidades`, `Campinas`, `Santos`, `São Paulo`, com `Todas as cidades` selecionada; `SelecionarEstado(0)` entrega somente `Todas as cidades` sem chamar `ListarCidades` (AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.EstadoSelecionadoLimitaCidadesAsDesseEstado`

**C5** - Para cada entrada inválida das linhas 4, 10, 13 e 14 de C1, `Visualizar` chama `FocarCampo` exatamente 1 vez com, respectivamente, `cfIdInicial`, `cfIdFinal`, `cfIdFinal`, `cfEstado`, chama `ExibirAviso` exatamente 1 vez com a mensagem de C1, e não chama `ListarParaRelatorio`, o gerador nem `SinalizarCarregamento` (AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.FiltroInvalidoFocaPrimeiroCampoSemConsultar`

**C6** - Quando `ListarEstados` lança exceção, `Iniciar` não a propaga, chama `ExibirErro` exatamente 1 vez com `Não foi possível carregar os estados e cidades.` sem o texto da exceção, e em seguida `Visualizar` com o modo Todos chama `ListarParaRelatorio` exatamente 1 vez (Swept: dependency failure)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.FalhaAoCarregarEstadosMantemModoTodosUtilizavel`

**C7** - Em um `TFormFiltroRelatorioCliente` real com controlador real e repositório falso, recém-aberto: o grupo de modos tem `Todos` selecionado e os editores `ID Inicial`, `ID Final`, `Estado` e `Cidade` têm `Enabled = False`; ao selecionar `ID Inicial e ID Final`, só os dois editores de ID ficam habilitados; ao selecionar `Cidade/Estado`, só `Estado` e `Cidade`; ao voltar a `Todos`, nenhum; o combo `Estado` tem os 4 itens de C2 e, ao escolher `São Paulo`, o combo `Cidade` passa a ter exatamente os 4 itens de C4 (AC 1, AC 2, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormFiltroRelatorioCliente.ModosHabilitamCamposEEstadoFiltraCidades`

**C8** - Em um `TFormFiltroRelatorioCliente` real, com `ID Inicial e ID Final` selecionado, `ID Inicial` = `abc` e `ID Final` = `4`, clicar `Visualizar` deixa `ActiveControl` no editor `ID Inicial`, apresenta o aviso exatamente 1 vez e não chama o gerador; com `Cidade/Estado` selecionado e nenhum estado, deixa `ActiveControl` no combo `Estado` (AC 5; L-004)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormFiltroRelatorioCliente.FiltroInvalidoFocaOEditorNaFormReal`

**C9** - Em um `TFormFiltroRelatorioCliente` real, exibido: `Caption = 'Relatório de Clientes'`; o grupo de modos tem legenda `Filtro` e exatamente os itens `ID Inicial e ID Final`, `Cidade/Estado`, `Todos`, nessa ordem; os rótulos dos editores são `ID Inicial`, `ID Final`, `Estado` e `Cidade`; os botões são `Visualizar` e `Fechar`, e `Fechar` tem `ModalResult = mrCancel`; `grupo.Top + grupo.Height <= editorIdInicial.Top`, `editorIdInicial.Top + editorIdInicial.Height <= comboEstado.Top`, `comboCidade.Top + comboCidade.Height <= botaoVisualizar.Top`; `TabOrder` crescente em grupo, `ID Inicial`, `ID Final`, `Estado`, `Cidade`, `Visualizar`, `Fechar`; todos os controles são DevExpress (`TcxRadioGroup`, `TcxTextEdit`, `TcxComboBox`, `TcxLabel`, `TcxButton`) (Observable: density and ordering)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormFiltroRelatorioCliente.TextosEArranjoDaTelaDeFiltro`

**C10** - `Aplicacao.ControladorRelatorioCliente.pas` e `Dominio.FiltroRelatorioCliente.pas` não citam no `uses` nenhuma unit `Vcl.*`, `FireDAC.*`, `cx*`, `dx*` nem `pp*`; `Visao.FormFiltroRelatorioCliente.pas` não cita `FireDAC.*` nem `pp*`, declara `TFormFiltroRelatorioCliente = class(TForm, IVisaoRelatorioCliente)` e cria exatamente um `TControladorRelatorioCliente`; nenhum fonte em `src\` fora de `Infraestrutura.GeradorRelatorioClienteReportBuilder.pas` cita `ppReport`, `ppDB`, `ppDBJIT` ou `ppCtrls` (door 1; door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaRelatorioCliente.ControladorSemVclEReportBuilderSoNoAdaptador`

### S2 - Consulta, geração e pré-visualização · 12 files · ~145 KB · ~36k

**C11** - Na base F5, `ListarParaRelatorio` com modo intervalo, table-driven, devolve exatamente estes IDs: 2..4 -> 2, 3, 4; 1..1 -> 1; 4..9 -> 5, 4 (`bianca souza` antes de `Denise D'Avila`); 6..9 -> nenhum (AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.RelatorioPorIntervaloIncluiOsDoisLimites`

**C12** - Na base F5, `ListarParaRelatorio` com modo cidade/estado, table-driven, devolve exatamente: Campinas/SP -> 3, 4; Mariana/MG -> 2; Santos/SP -> nenhum; MG sem cidade -> 1, 2; SP sem cidade -> 3, 4; RJ sem cidade -> nenhum (AC 7, AC 8)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.RelatorioPorCidadeEstadoFiltraACombinacaoOuOEstado`

**C13** - Com 60 clientes inseridos na ordem de ID 60 até 1 e nomes `Cliente 01` a `Cliente 60` acompanhando o ID, `ListarParaRelatorio` com modo Todos devolve exatamente 60 clientes com IDs 1 a 60, ou seja pelo nome e não pela ordem de inserção; na base F5, devolve 1, 5, 2, 3, 4 (Ana, bianca, Bruno, Carlos, Denise), e o cliente 3 traz bairro `Centro`, cidade `Campinas`, UF `SP` e estado `São Paulo`, e o cliente 5 traz cidade, UF e estado vazios (AC 9; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.RelatorioTodosSemLimiteEmOrdemDeNome`

**C14** - Na base F5, `ListarEstados` devolve exatamente Bahia, Minas Gerais, Rio de Janeiro, São Paulo com as UFs BA, MG, RJ, SP; `ListarCidades(<id de MG>)` devolve exatamente Belo Horizonte, Contagem, Mariana, Uberlândia; `ListarCidades(<id de SP>)` devolve exatamente Campinas, Santos, São Paulo (AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.ListaEstadosECidadesDoEstadoPorNome`

**C15** - Com filtro válido e o repositório falso devolvendo os IDs 8, 1, 5 nessa ordem, `Visualizar` chama `ListarParaRelatorio` exatamente 1 vez com o filtro normalizado de C1 e `IGeradorRelatorioCliente.Visualizar` exatamente 1 vez com `TDadosRelatorioCliente` contendo os 3 clientes na ordem 8, 1, 5, `Emissao = 22/09/2026 14:30` e, table-driven sobre 4 filtros, a descrição: Todos -> `Filtro: Todos`; IDs 2..4 -> `Filtro: ID Inicial 2 e ID Final 4`; MG sem cidade -> `Filtro: Estado MG`; Campinas/SP -> `Filtro: Cidade Campinas/SP`; em cada um, a visão recebe `SinalizarCarregamento(True)` antes da consulta e `SinalizarCarregamento(False)` depois do gerador (AC 6, AC 7, AC 8, AC 9, AC 10; Observable: loading state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.VisualizarConsultaUmaVezEEntregaDadosAoGerador`

**C16** - Com o repositório devolvendo 0 clientes, `Visualizar` não chama o gerador, chama `ExibirAviso` exatamente 1 vez com `Nenhum cliente encontrado para o filtro informado`, chama `SinalizarCarregamento(False)` e não chama `Fechar` nem `ExibirModo` (AC 11; Observable: error state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.SemResultadoAvisaSemAbrirPreVisualizacao`

**C17** - Quando `ListarParaRelatorio` lança exceção, `Visualizar` não a propaga, não chama o gerador e chama `ExibirErro` exatamente 1 vez com `Não foi possível consultar os clientes do relatório.`; quando o gerador lança exceção, chama `ExibirErro` exatamente 1 vez com `Não foi possível gerar o relatório de clientes.`; nos dois casos nenhuma mensagem contém o texto da exceção, `SinalizarCarregamento(False)` é a última chamada de carregamento, `ExibirModo` e `Habilitar*` não são chamados de novo, e um segundo `Visualizar` com o repositório restabelecido chama o gerador exatamente 1 vez (AC 12; Observable: error state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorRelatorioCliente.FalhaNaConsultaOuNoGeradorExibeErroEPreservaFiltro`

**C18** - Em um `TFormFiltroRelatorioCliente` real cujo gerador falso lança exceção, depois de selecionar `ID Inicial e ID Final` com `2` e `4` e clicar `Visualizar`: o modo continua `ID Inicial e ID Final`, os editores mantêm `2` e `4`, o botão `Visualizar` volta a `Enabled = True` e o erro é apresentado exatamente 1 vez (AC 12)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormFiltroRelatorioCliente.FalhaNaGeracaoMantemFiltroEReabilitaVisualizar`

**C19** - `TGeradorRelatorioClienteReportBuilder`, com destino `dtReportTextFile`, gera para 3 clientes (IDs 1, 3, 5 da F5, filtro `Filtro: Todos`, emissão 22/09/2026 14:30) um arquivo que contém `Relatório de Clientes`, `Emitido em 22/09/2026 14:30`, `Filtro: Todos` e `Página 1 de 1`; contém, nessa ordem numa mesma linha, `ID`, `NOME`, `CPF/CNPJ`, `CEP`, `BAIRRO`, `CIDADE`, `ESTADO`; e contém as linhas dos IDs 1, 3, 5 nessa ordem, a do ID 3 com `Carlos Silva`, `11.222.333/0001-81`, `13010-000`, `Centro`, `Campinas`, `SP`, e a do ID 5 sem cidade nem UF, sem erro (AC 10; door 3; Observable: document)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesGeradorRelatorioClienteReportBuilder.PaginaUnicaTemCabecalhoColunasELinhasEmOrdem`

**C20** - Com 120 clientes de IDs 1 a 120, o arquivo `dtReportTextFile` tem `AbsolutePageCount = N >= 2`, contém `Página k de N` para cada k de 1 a N, contém a linha de cabeçalho das 7 colunas N vezes, e cada ID de 1 a 120 aparece exatamente uma vez, em ordem crescente (AC 10; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesGeradorRelatorioClienteReportBuilder.VariasPaginasNumeradasComCabecalhoRepetido`

**C21** - Na mesma instância do gerador, depois de `Visualizar` com os IDs 1, 3, 5 e `Filtro: Todos`, um segundo `Visualizar` com os IDs 2, 4 e `Filtro: Estado MG` produz um arquivo que contém `Filtro: Estado MG`, as linhas dos IDs 2 e 4, `Página 1 de 1`, e não contém `Filtro: Todos` nem as linhas dos IDs 1, 3 e 5 (AC 13)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesGeradorRelatorioClienteReportBuilder.SegundaVisualizacaoReiniciaORelatorio`

**C22** - Com o destino de produção, `Visualizar` com 3 clientes exibe exatamente 1 form `TppPrintPreview` modal, e depois de fechá-la nenhuma `TppPrintPreview` permanece em `Screen.Forms`; o gerador de produção não abre diálogo de impressão (AC 10; Assumptions: destino inicial)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesGeradorRelatorioClienteReportBuilder.DestinoDeProducaoAbrePreVisualizacaoModal`

**C23** - Em um `TFormFiltroRelatorioCliente` real com controlador real, repositório falso devolvendo 3 clientes e gerador falso: com `Todos`, clicar `Visualizar` chama o gerador exatamente 1 vez; durante a chamada, `Visualizar` tem `Enabled = False`; depois dela, `Enabled = True` (AC 9, AC 12; Observable: loading state; L-004)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormFiltroRelatorioCliente.VisualizarDesabilitaAcaoDuranteGeracao`

**C24** - `ComporNavegador(form principal, conexão da base F5).AbrirRelatorio` exibe exatamente 1 `TFormFiltroRelatorioCliente` modal com `Todos` selecionado e o combo `Estado` com 4 itens, e ao fechá-la a form é liberada (Flow 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.RelatorioAbreFiltroRealSobreABase`

**C25** - `.specs/STATE.md` contém a linha `AD-017` com status `active`, e a prova reescrita da Parte 02 C23 (`DestinoSemTelaRegistradaFalhaSemCriarForm`) usa um `TNavegadorAplicacao` sem telas registradas e continua asserindo `ENavegacaoSemTela`, nenhuma form criada e a mensagem `Não foi possível abrir o relatório de clientes.` (AD-010, AD-014)
Proof: `powershell -NoProfile -Command "if (Select-String -Path .specs/STATE.md -Pattern '^\| AD-017 \|.*\| active \|' -Quiet) { exit 0 } else { exit 1 }"`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.DestinoSemTelaRegistradaFalhaSemCriarForm`

**C26** - Com o ReportBuilder linkado estaticamente, `CadCli.dproj` não lista pacote `rb*` nem `pp*` em `DCC_UsePackage`, e a prova de entrega da Parte 02 continua verde: a pasta de release contém exatamente o fechamento de BPLs de AD-011 (AGENTS: Plataforma e entrega)
Proof: `powershell -NoProfile -Command "if (Select-String -Path CadCli.dproj -Pattern '<DCC_UsePackage>[^<]*\b(rb|pp)[A-Za-z0-9]*' -Quiet) { exit 1 } else { exit 0 }"`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar`

**C27** - `IRepositorioCliente` declara `ListarParaRelatorio(const AFiltro: TFiltroRelatorioCliente): TClientes`, `ListarEstados: TEstados` e `ListarCidades(AEstadoId: Integer): TCidades`; `IGeradorRelatorioCliente` declara exatamente um método, `Visualizar(const ADados: TDadosRelatorioCliente)`; o SQL de `ListarParaRelatorio` em `Infraestrutura.RepositorioClienteFireDAC.pas` termina em `ORDER BY UPPER(C.NOME), C.ID` e não contém `FIRST` (Flow 2; door 2; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaRelatorioCliente.ContratosDoRepositorioEDoGerador`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| modos de filtro (3) | ID Inicial e ID Final C1/C3/C7/C11/C15 · Cidade/Estado C1/C3/C7/C12/C15 · Todos C1/C2/C3/C7/C13/C15 | - |
| rejeições da validação (9) | vazio C1 · zero C1 · negativo C1 · não numérico C1 · decimal C1 · acima de `MaxInt` C1 · inicial maior que final C1 · estado ausente C1 · cidade sem estado C1 | - |
| campo indicado no inválido (3) | ID Inicial C1/C5/C8 · ID Final C1/C5 · Estado C1/C5/C8 | - |
| normalização de resíduos (3) | Todos ignora IDs, estado e cidade C1 · intervalo ignora estado e cidade C1 · cidade/estado ignora IDs C1 | - |
| limites do intervalo (4) | inicial incluso C11 · final incluso C11 · inicial igual ao final C11/C1 · faixa sem clientes C11 | - |
| cidade/estado (4) | combinação com clientes C12 · combinação sem clientes C12 · estado com clientes C12 · estado sem clientes C12 | - |
| Todos (3) | sem limite C13 · ordem por nome independente da inserção C13 · cliente sem cidade incluído C13/C19 | - |
| desfechos de `Visualizar` (5) | sucesso C15/C23 · vazio C16 · inválido C5/C8 · falha na consulta C17 · falha no gerador C17/C18 | - |
| descrição do filtro aplicado (4) | Todos C15/C19 · intervalo C15 · estado C15/C21 · cidade C15 | - |
| elementos do AC 10 (6) | título C19 · emissão C19 · filtro aplicado C19 · paginação C19/C20 · sete colunas C19/C20 · ordem por nome C13 · ordem recebida preservada C20 | - |
| colunas do door 3 (7) | `ID` C19 · `NOME` C19 · `CPF/CNPJ` C19 · `CEP` C19 · `BAIRRO` C19 · `CIDADE` C19 · `ESTADO` C19 | - |
| geração repetida (2) | reinício entre filtros C21 · mesma instância não mistura dados C21 | - |
| destinos do gerador (2) | produção pré-visualização modal C22 · teste `dtReportTextFile` C19/C20/C21 | - |
| screen `FiltroRelatorioCliente` - estados aplicáveis do `Observable` (4) | empty C2/C7 · loading C15/C23 · error C16/C17/C18 · density and ordering C9 | - |
| document `Relatório de Clientes` - structure (1) | cabeçalho, filtro, tabela e paginação C19/C20 | - |
| screen `FiltroRelatorioCliente` - textos (20) | `Relatório de Clientes` C9 · `Filtro` C9 · `ID Inicial e ID Final` C9 · `Cidade/Estado` C9 · `Todos` C9 · `ID Inicial` C9 · `ID Final` C9 · `Estado` C9 · `Cidade` C9 · `Todas as cidades` C4/C7 · `Visualizar` C9 · `Fechar` C9 · `Informe um ID inicial inteiro maior que zero.` C1/C5 · `Informe um ID final inteiro maior que zero.` C1/C5 · `O ID inicial deve ser menor ou igual ao ID final.` C1/C5 · `Selecione um estado.` C1/C5 · `Nenhum cliente encontrado para o filtro informado` C16 · `Não foi possível carregar os estados e cidades.` C6 · `Não foi possível consultar os clientes do relatório.` C17 · `Não foi possível gerar o relatório de clientes.` C17/C18 | - |
| screen `FiltroRelatorioCliente` - arranjo (4) | modos acima dos IDs C9 · IDs acima de estado/cidade C9 · estado/cidade acima dos botões C9 · ordem de tabulação C9 | - |
| one-way doors de `Landing` (3) | par form/controlador C7/C10 · isolamento do ReportBuilder C10/C27 · contrato visual C13/C19/C20/C27 | - |
| startup config: registro da tela de relatório (2 assemblies) | `ComporNavegador` de produção C24 · navegador sem registro nos testes C25 | - |

- `Relations` e `Surface` são `None` no plano: nenhuma entidade nem rota exige join. O estado `unauthorised` e `destructive action confirms` do `Observable` são `n/a` no plano e ficam fora do join.
- C1, C11, C12 e C15 são table-driven: cada linha tem sua asserção e o teste assere o número de linhas (20, 4, 6 e 4).
- C11-C14 e C24 exigem o serviço Firebird 3 em `localhost:3050` e usam base temporária isolada.
- C2-C6, C15-C17 provam as decisões do controlador no próprio nível, com fakes; C7, C8, C18 e C23 provam a ligação da form real e não substituem as provas de controlador.
- C19-C21 observam o ReportBuilder pelo dispositivo `dtReportTextFile` (`TppReportTextFileDevice`, confirmado em `ppFilDev.dcu`); C22 prova o destino de produção separadamente, porque as outras três não passam pela pré-visualização.

## Test policy

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Regra de domínio pura (`TValidacaoFiltroRelatorio`) | uma prova unitária table-driven | uma linha asserida por rejeição, por campo indicado e por normalização |
| Adaptador de persistência que traduz o filtro (`ListarParaRelatorio`, `ListarEstados`, `ListarCidades`) | uma prova de integração em base temporária no Firebird local | um caso asserido por modo, por limite do intervalo e por combinação com e sem resultado |
| Controlador que decide sem cruzar fronteira (`TControladorRelatorioCliente`) | uma prova unitária por desfecho, com visão, repositório, gerador e relógio falsos | cada modo, cada desfecho de `Visualizar`, cada descrição de filtro, a falha de carga |
| Adaptador do componente comercial (`TGeradorRelatorioClienteReportBuilder`) | prova pelo dispositivo de texto do ReportBuilder e uma pela pré-visualização real | cada elemento do AC 10, paginação com mais de uma página, reinício |
| View passiva (`TFormFiltroRelatorioCliente`) | uma prova com a form real, controlador real e dependências falsas | ligação de cada modo, do estado, de `Visualizar`, textos e arranjo |

Evidence:

- `Dominio.FiltroRelatorioCliente.pas` (novo): 3 modos, 9 rejeições, 3 normalizações -> decide.
- `Aplicacao.ControladorRelatorioCliente.pas` (novo): 5 desfechos de `Visualizar`, 3 modos de habilitação, 4 descrições -> decide.
- `Infraestrutura.GeradorRelatorioClienteReportBuilder.pas` (novo): monta o layout e reinicia; condicional só no destino -> adaptador, provado pela saída observável.
- `Visao.FormFiltroRelatorioCliente.pas` (novo): traduz eventos e estado sem regra -> view passiva.
- Closest analogue: `Testes.ControladorPesquisaCliente.pas` (fakes), `Testes.FormsClientes.pas` (form real) e `Testes.RepositorioClienteFirebird.pas` (table-driven sobre a F5).

Cost: 27 checks, 29 provas em 4 fixtures novas e 3 existentes.

## Swept

- validation: C1, C5, C8 - IDs vazios, zero, negativos, não numéricos, decimais, acima de `MaxInt`, invertidos e estado ausente
- failure modes: C16, C17, C18
- idempotency: C21 - visualizar de novo gera o mesmo relatório para o novo filtro sem reaproveitar páginas; nenhuma escrita
- authorization: n/a - aplicação local sem autenticação (Observable: unauthorised)
- concurrency: C15, C23 - `Visualizar` fica desabilitado durante a consulta e a geração, então não há segunda geração em andamento na mesma tela
- data lifecycle: n/a - o relatório só lê; nenhuma escrita nem migração
- dependency failure: C6, C17 - Firebird indisponível ao carregar estados ou ao consultar; ReportBuilder falhando ao gerar
- state transitions: C3, C4, C7 - Todos <-> intervalo <-> cidade/estado; troca de estado reinicia a cidade para `Todas as cidades`
- observability: C6, C17 - mensagens fixas sem texto de exceção nem SQL; nenhum requisito de log

## Decisões

Tomadas ao derivar os checks; nenhuma é one-way door, todas revisáveis antes do build.

- O repositório existente ganha `ListarParaRelatorio`, `ListarEstados` e `ListarCidades` (Flow 2: "repositório existente"); não há segundo repositório.
- `TDadosRelatorioCliente` = clientes, descrição do filtro e data/hora de emissão; a emissão vem de `IRelogio` (AGENTS: relógio injetável), não de `vtPrintDateTime`.
- A coluna `ESTADO` mostra a UF, para caber nas sete colunas em A4 retrato; CPF/CNPJ e CEP saem formatados como na pesquisa (`FormatarCpfCnpj`, `FormatarCep`).
- Em ID Inicial maior que ID Final, o campo indicado é `ID Final`.
- O combo `Cidade` começa com `Todas as cidades`, que representa a cidade opcional; trocar o estado volta a essa opção.
- Os modos seguem a ordem do enunciado (`ID Inicial e ID Final`, `Cidade/Estado`, `Todos`), com `Todos` selecionado na abertura.
- Os testes do gerador usam o dispositivo `dtReportTextFile`; se ele não emitir o conteúdo dos rótulos e das variáveis de sistema, isso é stop-and-ask, não troca de asserção.
- AD-017 (a registrar no build): a Parte 04 registra a tela real de relatório em `ComporNavegador`; a prova da Parte 02 C23 passa a usar um navegador sem telas registradas, com as mesmas asserções, e vira obrigação desta parte (precedente AD-014).

## Handoff

- Arquivos existentes tocados (`wc -c`): `Aplicacao.RepositorioCliente.pas` 0,6 KB + `Infraestrutura.RepositorioClienteFireDAC.pas` 12,6 KB + `Visao.ComposicaoAplicacao.pas` 1,9 KB + `Suporte.FakesClientes.pas` 16,6 KB + `Testes.RepositorioClienteFirebird.pas` 23,5 KB + `Testes.NavegadorAplicacao.pas` 10,5 KB + `CadCli.Testes.dpr` 8,5 KB + `.dproj` 7,8 KB + `CadCli.dpr` 4,2 KB + `CadCli.dproj` 9,9 KB + `STATE.md` 7,4 KB = 103,5 KB; analogues lidos (`ControladorPesquisaCliente` 6,6 KB, `FormPesquisaCliente` 10,5 KB) = 17,1 KB; novos estimados ~120 KB (domínio 5, controlador 10, form 15, gerador 15, testes 75); total ~240 KB / 4 = ~60k tokens, abaixo do budget de 150k - one builder.
- S1 ~24k entra em domínio, controlador e form; S2 ~36k acrescenta repositório e gerador e compartilha o controlador; nenhum corte faz sentido.
- Mechanism: one builder - o escopo cabe no orçamento.
- Branch: `feat/parte-04-relatorio-clientes`.
- Pré-requisitos: serviço Firebird 3 em `localhost:3050`; build como na Parte 03 (`rsvars.bat` + `MSBuild.exe` Debug do `tests\CadCli.Testes.dproj`); ReportBuilder 23 Win64 em `$(BDS)\RBuilder\Lib\Win64` (dcus, link estático); aviso trial do DevExpress por AD-013. Risco: se o ReportBuilder trial abrir aviso próprio, o runner trava como no AD-013 - stop-and-ask.

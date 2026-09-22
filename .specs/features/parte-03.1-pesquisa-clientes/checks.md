# Parte 03.1 - Pesquisa de clientes limitada e ordenável checks

Profile: ui
Plan: `.specs/features/parte-03.1-pesquisa-clientes/plan.md`

26 checks em 2 slices · 5 one-way doors · 0 questões abertas (suposições confirmadas pelo usuário em 2026-09-22; door 5 acrescentado ao derivar os checks)

## Base de teste F5

As provas de repositório (Firebird em `localhost:3050`, base temporária isolada como na Parte 03) semeiam por SQL, nesta ordem de inserção e portanto em ID crescente:

| Cliente | CPF/CNPJ | CEP | Cidade/UF (Estado) | Nascimento |
| --- | --- | --- | --- | --- |
| `Ana Silva` | `52998224725` | `30130010` | Belo Horizonte/MG (Minas Gerais) | 15/03/1990 |
| `Bruno Costa` | `11144477735` | `35420000` | Mariana/MG (Minas Gerais) | 20/07/1985 |
| `Carlos Silva` | `11222333000181` | `13010000` | Campinas/SP (São Paulo) | 15/03/1990 |
| `Denise D'Avila` | `39053344705` | `13015000` | Campinas/SP (São Paulo) | 01/01/2000 |
| `bianca souza` | `71428793860` | `01001000` | sem cidade (`CIDADEID` nulo) | nula |

Nos checks abaixo, os clientes são referidos pelo primeiro nome.

## Checks

### S1 - Pesquisa limitada a 50 no banco · 13 files · ~140 KB · ~35k

**C1** - Ao abrir a pesquisa, `TControladorPesquisaCliente` chama `IRepositorioCliente.Pesquisar` exatamente 1 vez com `Texto = ''`, `Campos = []`, `DataNascimento = ''`, ordenação `coNome` crescente e limite `50`; com o repositório falso devolvendo os IDs 8, 1 e 5 nessa ordem, a visão recebe exatamente 3 clientes na ordem 8, 1, 5 (AC 1, AC 12; door 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.AberturaPesquisaUmaVezPorNomeComLimiteEExibeNaOrdemDevolvida`

**C2** - Depois da abertura, `Pesquisar` com `Texto = 'silva'`, `Campos = [cpNome, cpCidade]` e `DataNascimento = '15/03/1990'` gera exatamente 1 chamada nova a `IRepositorioCliente.Pesquisar` com esses três valores, a ordenação vigente e o limite `50`; 3 pesquisas seguidas geram exatamente 3 chamadas; em cada uma, a visão recebe `SinalizarCarregamento(True)` antes da chamada ao repositório e `SinalizarCarregamento(False)` depois dela (AC 1; Observable: loading state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.PesquisarRepassaFiltroOrdenacaoELimiteUmaVezPorAcao`

**C3** - O repositório falso devolve a lista configurada sem filtrar nem reordenar: com filtro `Texto = 'zzz'` e 3 clientes configurados, devolve os 3; nenhuma unit de teste chama uma regra de filtro em memória (door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.RepositorioFalsoNaoFiltraNemOrdena`

**C4** - Com 60 clientes `Cliente 01` a `Cliente 60` e filtro vazio, `TRepositorioClienteFireDAC.Pesquisar(filtro vazio, Nome crescente, 50)` devolve exatamente 50 clientes, o primeiro `Cliente 01` e o último `Cliente 50`; com Nome decrescente devolve 50, o primeiro `Cliente 60` e o último `Cliente 11`; com limite 50 sobre a base F5 devolve os 5 (AC 2, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.PesquisaSemFiltroDevolveOsPrimeiros50PelaOrdenacao`

**C5** - Na base F5, table-driven com um único campo marcado por caso, `Pesquisar` devolve exatamente: ID com o ID de Ana -> Ana; ID `abc` -> nenhum, sem exceção; nome `SIL` -> Ana e Carlos; nome `  SIL  ` -> Ana e Carlos; CPF/CNPJ `529.982.247-25` -> Ana; CPF/CNPJ `529982247` -> nenhum; CEP `30130-010` -> Ana; CEP `3013001` -> nenhum; cidade `campi` -> Carlos e Denise; estado `mg` -> Ana e Bruno; estado `paulo` -> Carlos e Denise (AC 3; door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.CadaCampoMarcadoAceitaERejeitaOsCasosDaTabela`

**C6** - Na base F5, texto `ana`: com `Campos = [cpNome]` devolve exatamente Ana; com `[cpCidade]` exatamente Bruno (Mariana); com `[cpNome, cpCidade]` exatamente Ana e Bruno (AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.CamposMarcadosCombinamPorOr`

**C7** - Na base F5, com `Campos = []`: texto `ana` devolve exatamente Ana e Bruno; e, table-driven sobre os 6 valores de C5 que encontram alguém (ID de Ana, `SIL`, `529.982.247-25`, `30130-010`, `campi`, `mg`), cada resultado contém os clientes que o mesmo valor encontra com só o seu campo marcado (AC 4)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.NenhumCampoMarcadoPesquisaNosSeisCampos`

**C8** - Na base F5: texto vazio e data `15/03/1990` -> exatamente Ana e Carlos; texto `silva` em `[cpNome]` e data `15/03/1990` -> Ana e Carlos; texto `costa` em `[cpNome]` e data `15/03/1990` -> nenhum; texto `ana` em `[cpNome, cpCidade]` e data `20/07/1985` -> exatamente Bruno (AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.DataCombinaPorAndComOTexto`

**C9** - Na base F5, texto `d'avila` em `[cpNome]` devolve exatamente Denise sem exceção, e texto `' OR 1=1 --` com `Campos = []` devolve 0 clientes sem exceção (AC 7)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.TextoComApostrofoEPesquisadoPorParametro`

**C10** - `TFormPesquisaCliente` exibe um `TcxLabel` com texto exatamente `A pesquisa lista no máximo 50 clientes.`, `Font.Size` menor que o `Font.Size` da form, visível tanto com 0 quanto com 3 clientes exibidos; com a form exibida, `ListaClientes.Top + ListaClientes.Height <= rótulo.Top` e `rótulo.Top + rótulo.Height <= BarraAcoes.Top` (AC 8)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.RotuloDeLimiteAbaixoDaListaEmFonteMenor`

**C11** - Com filtro vigente `Texto = 'silva'`, `Campos = [cpNome]` e ordenação vigente `coCidade` crescente: `Novo` salvo, `Editar` salvo e `Excluir` confirmado geram, cada um, exatamente 1 chamada nova a `Pesquisar` com esse filtro, `coCidade` crescente e limite `50`; `Novo` e `Editar` não salvos não geram chamada nova (AC 9)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.RecargaAposSalvarOuExcluirRepeteFiltroEOrdenacaoVigentes`

**C12** - Quando `Pesquisar` do repositório lança exceção, o controlador não a propaga, chama `ExibirErro` exatamente 1 vez com `Não foi possível carregar os clientes.` sem o texto da exceção, entrega 0 clientes à visão, desabilita `Editar` e `Excluir` e chama `SinalizarCarregamento(False)`; depois de uma pesquisa bem-sucedida de 3 clientes seguida de uma que falha, `Excluir` não abre confirmação (AC 10; Observable: error state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.FalhaNaPesquisaExibeErroEsvaziaEDesabilitaAcoes`

**C13** - Em um `TFormPesquisaCliente` real cujo repositório falha na segunda pesquisa, depois de digitar `silva`, marcar somente `Cidade` e informar `15/03/1990`, o editor mantém `silva`, o combo mantém somente `Cidade` marcado, a data mantém `15/03/1990`, a lista fica com 0 linhas e a mensagem de erro é apresentada exatamente 1 vez (AC 10)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.FalhaNaCargaMantemFiltrosEEsvaziaGrade`

**C14** - Com o repositório devolvendo 0 clientes, o controlador entrega 0 clientes, `ExibirSemResultado('Nenhum cliente encontrado')` e `Editar`/`Excluir` desabilitados; devolvendo 1 cliente, `Editar`/`Excluir` ficam habilitados e `ExibirSemResultado` não é chamado (AC 11; Observable: empty state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.SemResultadoExibeMensagemEDesabilitaAcoes`

**C15** - Em um `TFormPesquisaCliente` real com controlador real e repositório falso, depois da abertura: digitar `silva`, marcar somente `Nome` e `Cidade`, informar `15/03/1990` e clicar `Pesquisar` gera exatamente 1 chamada com `Texto = 'silva'`, `Campos = [cpNome, cpCidade]`, `DataNascimento = '15/03/1990'` e limite `50`; Enter no editor de pesquisa gera exatamente 1 chamada com os mesmos valores; `Limpar` gera exatamente 1 chamada com `Texto = ''`, `Campos = [cpId, cpNome]` e `DataNascimento = ''` (AC 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.PesquisarEnterELimparConsultamORepositorioComOFiltroDaTela`

**C16** - Em um `TFormPesquisaCliente` real, com o repositório falso devolvendo os IDs 8, 1 e 5 nessa ordem, a lista exibe exatamente 3 linhas cujo ID é 8, 1, 5, e `IdSelecionado` da segunda linha é `1` (AC 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.ListaExibeClientesNaOrdemDevolvida`

**C24** - Na base F5, o Carlos devolvido por `Pesquisar` traz cidade `Campinas`, UF `SP` e estado `São Paulo`, e a bianca traz cidade, UF e estado vazios (AC 1; substitui `ListarTodosTrazCidadeEEstadoPorIdCrescente` da Parte 03)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.PesquisaTrazCidadeUfEEstadoDoCliente`

**C25** - Nenhum fonte em `src\` contém `ListarTodos` nem `Atende`; `Aplicacao.ControladorPesquisaCliente.pas` declara `LIMITE_PESQUISA_CLIENTES = 50`; `Aplicacao.RepositorioCliente.pas` declara `function Pesquisar(const AFiltro: TFiltroCliente; const AOrdenacao: TOrdenacaoCliente; ALimite: Integer): TClientes`; `Visao.FormPesquisaCliente.pas` não contém `Sort` fora do tratamento da seta de cabeçalho (`SortOrder`) (door 1; door 2; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaClientes.PesquisaSoPeloRepositorioSemFiltroEmMemoria`

**C26** - `.specs/STATE.md` contém a linha `AD-016` com status `active`, e as provas da Parte 03 que permanecem com as mesmas asserções passam: C43, C45, C46 e C51; e a prova reescrita da Parte 03 C44 registra, para a exclusão confirmada do ID 7, exatamente a sequência `Confirmacao|Iniciar|Excluir:7|Confirmar|Pesquisar` (door 4; door 5)
Proof: `powershell -NoProfile -Command "if (Select-String -Path .specs/STATE.md -Pattern '^\| AD-016 \|.*\| active \|' -Quiet) { exit 0 } else { exit 1 }"`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.ExclusaoPedeConfirmacaoComIdENome,TTestesControladorPesquisaCliente.IdsProtegidosNaoAbremTransacao,TTestesControladorPesquisaCliente.FalhaNaExclusaoReverteEMantemRegistro,TTestesControladorPesquisaCliente.ExclusaoConfirmadaExcluiEmTransacaoERecarrega,TTestesNavegadorAplicacao.ClientesAbrePesquisaRealSobreABase`

### S2 - Ordenação por coluna clicada · 8 files · ~100 KB · ~25k

**C17** - Ao abrir, o controlador chama `IVisaoPesquisaCliente.ExibirOrdenacao` com `coNome` crescente antes de exibir os clientes, e a chamada ao repositório usa `coNome` crescente (AC 12)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.AberturaExibeOrdenacaoPadraoPorNomeCrescente`

**C18** - Com filtro vigente `Texto = 'silva'` e ordenação `coNome` crescente, `Ordenar(coCidade)` gera exatamente 1 chamada a `Pesquisar` com `Texto = 'silva'`, `coCidade` crescente e limite `50`, e `ExibirOrdenacao` recebe `coCidade` crescente (AC 13)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.OrdenarPorOutraColunaPesquisaEmOrdemCrescente`

**C19** - Partindo de `coNome` crescente, a sequência `Ordenar(coNome)`, `Ordenar(coNome)`, `Ordenar(coNome)`, `Ordenar(coCidade)` produz, nessa ordem, as ordenações passadas ao repositório e a `ExibirOrdenacao`: Nome decrescente, Nome crescente, Nome decrescente, Cidade crescente (AC 13, AC 14)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.OrdenarPelaColunaVigenteInverteADirecao`

**C20** - Depois de ordenar por Cidade decrescente, acionar `Limpar` gera exatamente 1 chamada a `Pesquisar` com `coNome` crescente e `ExibirOrdenacao` com `coNome` crescente; na form real, depois de clicar duas vezes no cabeçalho `Cidade`, clicar `Limpar` deixa a seção `Nome` com seta crescente e a seção `Cidade` sem seta (AC 16)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.LimparRestauraOrdenacaoPorNomeCrescente`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.LimparVoltaOrdenacaoParaNomeCrescente`

**C21** - Em um `TFormPesquisaCliente` real, table-driven sobre as 8 seções do cabeçalho (`ID`, `Nome`, `CPF/CNPJ`, `CEP`, `Cidade`, `UF`, `Estado`, `Data de nascimento`): clicar na seção de índice i gera 1 chamada a `Pesquisar` com `TCampoOrdenacao(i)` e deixa a seção i com `SortOrder = soAscending` e as outras 7 com `soNone`; clicar de novo na mesma seção gera 1 chamada decrescente e deixa a seção i com `soDescending` (para `Nome`, o primeiro clique inverte para decrescente, porque já é a vigente) (AC 13, AC 14, AC 15; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.CliqueNoCabecalhoOrdenaEMarcaASetaDaColuna`

**C22** - Em um `TFormPesquisaCliente` real recém-aberto, a seção `Nome` tem `SortOrder = soAscending`, as outras 7 têm `soNone`, as 8 seções têm `AllowClick = True` e `ListaClientes.Sorted = False` (AC 12; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.AberturaMarcaNomeCrescenteECabecalhosClicaveis`

**C23** - Na base F5 com filtro vazio e limite 50, table-driven sobre 8 colunas x 2 direções, `Pesquisar` devolve exatamente estas sequências (ausentes por último nas duas direções, empate por ID crescente, texto sem diferença de caixa) (AC 17):

| Coluna | Crescente | Decrescente |
| --- | --- | --- |
| ID | Ana, Bruno, Carlos, Denise, bianca | bianca, Denise, Carlos, Bruno, Ana |
| Nome | Ana, bianca, Bruno, Carlos, Denise | Denise, Carlos, Bruno, bianca, Ana |
| CPF/CNPJ | Bruno, Carlos, Denise, Ana, bianca | bianca, Ana, Denise, Carlos, Bruno |
| CEP | bianca, Carlos, Denise, Ana, Bruno | Bruno, Ana, Denise, Carlos, bianca |
| Cidade | Ana, Carlos, Denise, Bruno, bianca | Bruno, Carlos, Denise, Ana, bianca |
| UF | Ana, Bruno, Carlos, Denise, bianca | Carlos, Denise, Ana, Bruno, bianca |
| Estado | Ana, Bruno, Carlos, Denise, bianca | Carlos, Denise, Ana, Bruno, bianca |
| Data de nascimento | Bruno, Ana, Carlos, Denise, bianca | Denise, Ana, Carlos, Bruno, bianca |

Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.OrdenaPorCadaColunaNasDuasDirecoesComAusentesPorUltimo`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| campos do `OR` - AC 3 (6) | ID C5/C7 · nome C5/C7 · CPF/CNPJ C5/C7 · CEP C5/C7 · cidade C5/C7 · estado C5/C7 | - |
| rejeições de formato no texto (5) | ID não inteiro C5 · CPF/CNPJ parcial C5 · CEP com 7 dígitos C5 · apóstrofo C9 · texto de injeção C9 | - |
| combinações do filtro (5) | `OR` entre marcados C6 · nenhum marcado = seis campos C7 · `AND` com a data C8 · texto e data vazios = primeiros 50 C4 · texto aparado C5 | - |
| limite de 50 (3) | mais de 50 corta em 50 C4 · menos de 50 devolve todos C4 · o controlador sempre passa 50 C1/C2/C11/C18 | - |
| gatilhos de pesquisa (6) | abertura C1 · `Pesquisar` C2/C15 · Enter C15 · `Limpar` C15/C20 · clique no cabeçalho C18/C21 · recarga C11 | - |
| recargas do AC 9 (5) | novo salvo C11 · novo não salvo C11 · edição salva C11 · edição não salva C11 · exclusão confirmada C11 | - |
| colunas de ordenação - door 3 (8) | ID C21/C23 · Nome C21/C23 · CPF/CNPJ C21/C23 · CEP C21/C23 · Cidade C21/C23 · UF C21/C23 · Estado C21/C23 · Data de nascimento C21/C23 | - |
| direções (2) | crescente C23/C21 · decrescente C23/C21 | - |
| regras de ordem do AC 17 (3) | ausentes por último C23 · empate por ID crescente C23 · texto sem diferença de caixa C23 | - |
| transições da ordenação (4) | padrão Nome crescente na abertura C17/C22 · outra coluna -> crescente C18/C21 · mesma coluna inverte C19/C21 · `Limpar` -> Nome crescente C20 | - |
| setas do cabeçalho do AC 15 (3) | crescente na vigente C21/C22 · decrescente na vigente C21 · nenhuma nas outras C21/C22/C20 | - |
| screen `PesquisaCliente` - estados aplicáveis do `Observable` (5) | empty C14 · loading C2 · error C12/C13 · density and ordering C10/C21/C22/C23 · destructive action confirms C26 | - |
| screen `PesquisaCliente` - textos novos ou alterados (3) | rótulo de limite C10 · nenhum cliente encontrado C14 · erro de carga C12 | - |
| screen `PesquisaCliente` - arranjo (3) | lista acima do rótulo C10 · rótulo acima da barra de ações C10 · fonte do rótulo menor que a da form C10 | - |
| one-way doors de `Landing` (5) | contrato `Pesquisar` C1/C2/C25 · filtragem só no SQL C3/C5/C6/C7/C8/C9/C25 · ordenação no controlador C17/C18/C19/C21/C25 · provas da Parte 03 do door 4 C1/C2/C5/C24/C26 · demais provas da Parte 03 C26 | - |

- `Relations` e `Surface` são `None`: nenhuma entidade nem rota exige join. O estado `unauthorised` do `Observable` é `n/a` no plano e fica fora do join.
- C5 e C23 são table-driven: cada linha da tabela tem sua asserção e o teste assere o número de linhas (11 casos em C5, 16 em C23).
- C4-C9, C23 e C24 exigem o serviço Firebird 3 em `localhost:3050` e usam base temporária isolada.
- C1, C2, C11, C12, C14 e C17-C20 provam as decisões do controlador no próprio nível, com fakes; C13, C15, C16 e C20-C22 provam a ligação da form real ao controlador e não substituem as provas de controlador.

## Test policy

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Adaptador de persistência que decide a tradução do filtro e da ordem (`TRepositorioClienteFireDAC.Pesquisar`) | uma prova de integração em base temporária no Firebird local | um caso asserido por campo do `OR`, por rejeição de formato, por combinação e por coluna x direção |
| Controlador que decide sem cruzar fronteira (`TControladorPesquisaCliente`) | uma prova unitária por desfecho, com visão, repositório, navegador e confirmação falsos | cada gatilho de pesquisa, cada transição de ordenação, cada recarga, vazio e falha |
| View passiva (`TFormPesquisaCliente`) | uma prova com a form real, controlador real e repositório falso | ligação de cada gatilho, cada seção do cabeçalho, setas, rótulo e arranjo |
| Repositório falso de teste | nenhuma regra própria (door 2) | devolve a lista configurada, provado por C3 |

Evidence:

- `Infraestrutura.RepositorioClienteFireDAC.pas`: passa a decidir 6 predicados, 3 rejeições de formato, 1 `AND` e 8 colunas x 2 direções -> decide na fronteira; hoje não tem regra além de CRUD.
- `Aplicacao.ControladorPesquisaCliente.pas`: decide a transição da ordenação (3 regras) e a recarga (5 desfechos) -> decide.
- `Visao.FormPesquisaCliente.pas`: traduz índice de seção em `TCampoOrdenacao` e ordenação em setas, sem condicional de regra -> view passiva.
- Closest analogue: `tests/Unitarios/Testes.RepositorioClienteFirebird.pas` (`ResolveEstadoECidadeNosTresCasos`, table-driven em base temporária) e `Testes.ControladorPesquisaCliente.pas` (fakes).

Cost: 26 checks, 27 provas em 4 fixtures existentes; `Testes.FiltroCliente.pas` sai do runner junto com `TFiltroCliente.Atende`, e suas obrigações passam a C5-C8.

## Swept

- validation: C5, C9 - ID não inteiro, CPF/CNPJ parcial, CEP sem 8 dígitos, apóstrofo e injeção não geram erro
- failure modes: C12, C13
- idempotency: n/a - a pesquisa só lê; repeti-la não altera a base
- authorization: n/a - aplicação local sem autenticação (Observable: unauthorised)
- concurrency: C2 - `SinalizarCarregamento(True)` desativa lista e botões durante a consulta síncrona, então não há segunda pesquisa em andamento na mesma tela
- data lifecycle: n/a - nenhuma escrita nem migração nesta parte
- dependency failure: C12, C13 - Firebird indisponível na pesquisa
- state transitions: C17, C18, C19, C20 - padrão -> coluna crescente -> decrescente -> crescente; `Limpar` -> padrão
- observability: C12 - mensagem fixa ao usuário sem texto de exceção nem SQL; nenhum requisito de log nesta parte

## Decisões

- O texto de pesquisa é aparado antes da consulta (comportamento atual de `TFiltroCliente.Atende`, mantido em C5).
- O rótulo de limite é um `TcxLabel`, seguindo a regra de controles DevExpress.
- `Limpar` restaura `Campos = [cpId, cpNome]` (comportamento atual, commit b255b92) e a ordenação padrão.
- O clique no cabeçalho usa `OnSectionClick` do `TcxMCListBox` e a seta usa `TcxHeaderSection.SortOrder` (confirmado no `cxLibraryRS29.dcp` e pelo usuário em 2026-09-22).

## Handoff

- Arquivos existentes tocados (`wc -c`): `Dominio.FiltroCliente.pas` 2,4 KB + `Aplicacao.RepositorioCliente.pas` 0,5 KB + `Aplicacao.ControladorPesquisaCliente.pas` 6,2 KB + `Infraestrutura.RepositorioClienteFireDAC.pas` 8,5 KB + `Visao.FormPesquisaCliente.pas` 8,5 KB + `.dfm` 4,3 KB + `Suporte.FakesClientes.pas` 15,2 KB + `Testes.ControladorPesquisaCliente.pas` 15,1 KB + `Testes.FormsClientes.pas` 40,3 KB + `Testes.FiltroCliente.pas` 4,6 KB (removido) + `Testes.RepositorioClienteFirebird.pas` 11,7 KB + `CadCli.Testes.dpr` 8,7 KB + `.dproj` 7,9 KB + `STATE.md` 6,8 KB = 140,6 KB; acréscimos estimados ~40 KB; total ~180 KB / 4 = ~45k tokens, abaixo do budget de 150k - one builder.
- S1 ~35k e S2 ~25k compartilham os mesmos arquivos; nenhum corte faz sentido.
- Mechanism: one builder - o escopo cabe no orçamento.
- Branch: `feat/parte-03.1-pesquisa-clientes` (atual).
- Pré-requisitos: serviço Firebird 3 em `localhost:3050`; build como na Parte 03 (`rsvars.bat` + `MSBuild.exe` Debug do `tests\CadCli.Testes.dproj`); aviso trial tratado por AD-013; fontes Delphi em UTF-8 com BOM.

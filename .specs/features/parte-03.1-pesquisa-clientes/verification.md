# Parte 03.1 - Pesquisa de clientes limitada e ordenável verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 76f1716..ed559b9 (`feat/parte-03.1-pesquisa-clientes`, HEAD = ed559b9; correção da rodada 1 em 007ebf4..ed559b9)
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

A rodada 1 (HEAD 007ebf4) terminou em FAIL por uma lacuna de cobertura: a regra "texto sem diferença de caixa" do AC 17 não estava provada para Cidade e Estado. A correção ed559b9 muda 2 arquivos:

- `tests/Unitarios/Testes.RepositorioClienteFirebird.pas`: C23 ganha um sexto cliente, `Eva Lima`, com cidade `macapá` e estado `amapá`, ambos em minúsculas, e 4 asserções novas (`:546-552`).
- `src/Visao/Visao.FormPesquisaCliente.pas`: saem os 2 comentários `//`, e os manipuladores `SetaAlterada`/`SetaMudando` passam a se chamar `ManterLinhasNaOrdemDoBanco`/`PermitirSetaSomentePeloControlador` (`:160-173`). O comportamento não muda.

Nesta rodada as 3 lacunas da rodada 1 estão fechadas:

1. **AC 17, caixa em Cidade e Estado.** Está provado. Os mutantes que tiram `UPPER` de `CI.NOME` e de `E.NOME` foram mortos, cada um por uma asserção nova diferente.
2. **Comentários.** Não há comentários em nenhum fonte alterado pela feature (busca abaixo).
3. **Ambiente.** `src/Visao/__recovery/` existe, mas está vazio: `Get-ChildItem` não lista arquivos e `git status --porcelain --ignored` não mostra o diretório. O arquivo `Visao.FormCadastroCliente.pas`, que deixava a suíte da árvore real vermelha, não existe mais.

**Escopo desta rodada**, conforme o verify.md "Re-verifying after a fix":

- **Verificado agora:**
  - todas as provas, rodadas de novo em HEAD ed559b9;
  - as citações dos 2 arquivos tocados;
  - a linha de Coverage do AC 17 sobre caixa;
  - a linha de Test policy que estava não atendida;
  - faltas injetadas nas superfícies tocadas;
  - a busca de comentários.
- **Carregado de 007ebf4:** Binding sources (a correção não toca a interface nem o `.dfm`), as citações de arquivos não tocados e as demais linhas de Coverage e de Test policy.

**Observação que não bloqueia o gate.** O texto de C23 em `checks.md` e a tabela da base F5 não mencionam a Eva nem as 4 sequências novas. O claim de C23 já exige "texto sem diferença de caixa", e a prova agora o assere. O artefato de checks só ficou menos preciso que a prova.

**Outra observação de ambiente.** O `CadCli.exe` Release da árvore real estava em execução (PID 23932, processo do usuário, que não foi encerrado) e travou `bin\Win64\Release\CadCli.exe` na compilação Release da árvore real (`F2039`). Por isso a suíte completa rodou no worktree limpo em HEAD, onde as 3 configurações compilaram.

## Binding sources

*carried from 007ebf4.* A correção não toca `Visao.FormPesquisaCliente.dfm` nem a interface. Em `Visao.FormPesquisaCliente.pas`, só renomeia 2 manipuladores privados e tira 2 comentários. Por isso o passo 1 não se repete.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| Pedido do usuário de 2026-09-22, como registrado em `plan.md` (Sources, linha 122; Assumptions, linha 105) | sim - lido em `plan.md` (carried from 007ebf4) | nenhuma. Limite de 50: C4, C1/C2/C11/C18. `OR`: C6/C7. Rótulo em fonte menor abaixo da lista: C10. Clique na coluna: C21, C18/C19. Nome padrão: C17/C22. Data em `AND`: C8 | - |
| `.specs/features/parte-03-clientes-crud/plan.md` - AC 1, 2, 6 e door 5 (`TcxMCListBox`) | sim - linhas 32, 56, 68-73 (carried from 007ebf4) | nenhuma. A substituição do door 5 é declarada (Landing doors 3-5, AD-016). C22 assere `AllowClick = True` e `Sorted = False`. O restante continua valendo: `Testes.FormsClientes.pas:453-454`, C16 e Parte 03 C14 | - |

A enumeração da tela `TFormPesquisaCliente` foi feita na rodada 1 e é carregada de 007ebf4:

- 4 regiões: `PainelFiltros`, `ListaClientes`, `RotuloLimite` e `BarraAcoes`.
- 1 sobreposição: `PanelSemResultado`.
- Textos fechados por `TextosDaPesquisaSaoOsDefinidos`.
- Setas asseridas por C20, C21 e C22.

O `.dfm` não mudou em 007ebf4..ed559b9 (`git diff --stat` lista só os 2 arquivos acima).

## Checks

*verified at ed559b9.* Todas as provas rodaram em uma única invocação do runner na árvore real em HEAD ed559b9. O runner foi compilado em Debug nesta rodada. A execução usou `Start-Process` com `-PassThru` e watchdog de 300 s, e levou 14 s.

A invocação recebeu 37 nomes totalmente qualificados e distintos (`Split(',').Count = 37`, `Sort-Object -Unique = 37`):

- os 30 testes nomeados pelos checks;
- `TextoLongoNaoGeraErro` e `TextosDaPesquisaSaoOsDefinidos`;
- os 3 testes reescritos pelo door 6 (`CamposPadraoSaoIdENome`, `EnterNosFiltrosAcionaAPesquisa` e `LimparRestauraFiltrosEPesquisaSemFiltro`);
- `ArranjoFiltrosGradeEAcoes` (Parte 03 C15).

Saída: `Tests Found: 37`, `Passed: 37`, `Failed: 0`, `Errored: 0`, código de saída `0`. O console logger é silencioso e não lista cada teste. Como são 37 nomes exatos e distintos e `Found = 37`, cada nome encontrou exatamente 1 teste. O runner roda com `FailsOnNoAsserts := True`.

A existência de cada teste foi confirmada por `grep -rn "procedure T*.<nome>;"` em `tests/Unitarios`, e todos os 37 têm linha própria:

- C23: `Testes.RepositorioClienteFirebird.pas:495`
- C24: `:556`
- C51: `Testes.NavegadorAplicacao.pas:280`

A prova de shell de C26 rodou em seguida com saída `0`.

Citações: `Testes.RepositorioClienteFirebird.pas` foi reconferido nesta rodada, e só as linhas depois de `:520` se moveram. Os demais arquivos de teste não mudaram em 007ebf4..ed559b9, e suas citações são as da rodada 1.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | abertura: 1 `Pesquisar` com filtro vazio, `coNome` crescente e limite 50; exibe 8,1,5 | lote ed559b9, 37/37, exit 0 | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:155` - `Assert.AreEqual(1, FRepositorioObjeto.ChamadasPesquisar, ...)`; `:156-160` - `''`, `[]`, `''`, `'coNome crescente'`, `50`; `:162` - `Assert.AreEqual('8,1,5', FVisaoObjeto.IdsExibidos, ...)` | PASS |
| C2 | 1 chamada por ação com filtro, ordenação e 50; carregamento antes e depois | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:187-192` - `2`, `'silva'`, `[cpNome, cpCidade]`, `'15/03/1990'`, `'coNome crescente'`, `50`; `:196` - `4`; `:206-209` - 'Carregamento:True&#124;Pesquisar&#124;Carregamento:False' x3 | PASS |
| C3 | fake devolve a lista configurada; nenhum teste chama `.Atende(` | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:219-220` - `Assert.AreEqual(3, Integer(Length(...Pesquisar(FiltroNome('zzz'), ...))))`; `:222` - `'8,1,5'`; `:227` - `Assert.IsFalse(ContainsText(TFile.ReadAllText(LArquivo), LRegra), ...)` | PASS |
| C4 | 60 clientes cortados em 50; F5 devolve 5 | lote ed559b9, 37/37 | `tests/Unitarios/Testes.RepositorioClienteFirebird.pas:372-374` - `50`, `'Cliente 01'`, `'Cliente 50'`; `:377-379` - `50`, `'Cliente 60'`, `'Cliente 11'`; `:384` - `Assert.AreEqual(5, ..., 'Menos de 50 devolve todos.')` (linhas reconferidas em ed559b9) | PASS |
| C5 | 11 casos por campo | lote ed559b9, 37/37 | `Testes.RepositorioClienteFirebird.pas:395` - `CASOS: array[0..10]`; `:417` - `Assert.AreEqual(LCaso.Esperados, PesquisarNomes(Filtro(LCaso.Valor, [LCaso.Campo])), ...)`; `:421` - `Assert.AreEqual(11, LVerificados)` | PASS |
| C6 | `ana`: Nome=Ana, Cidade=Bruno, ambos=Ana,Bruno | lote ed559b9, 37/37 | `Testes.RepositorioClienteFirebird.pas:427-429` - `'Ana'`, `'Bruno'`, `Assert.AreEqual('Ana,Bruno', PesquisarNomes(Filtro('ana', [cpNome, cpCidade])))` | PASS |
| C7 | nenhum marcado = seis campos | lote ed559b9, 37/37 | `Testes.RepositorioClienteFirebird.pas:454` - `Assert.AreEqual('Ana,Bruno', PesquisarNomes(Filtro('ana', [])))`; `:462` - `Assert.IsTrue(MatchStr(LNome, LTodos), ...)`; `:466` - `Assert.AreEqual(6, LVerificados)` | PASS |
| C8 | data em `AND` com o texto | lote ed559b9, 37/37 | `Testes.RepositorioClienteFirebird.pas:472-475` - `'Ana,Carlos'`, `'Ana,Carlos'`, `''`, `Assert.AreEqual('Bruno', PesquisarNomes(Filtro('ana', [cpNome, cpCidade], '20/07/1985')))` | PASS |
| C9 | apóstrofo e injeção por parâmetro | lote ed559b9, 37/37 | `Testes.RepositorioClienteFirebird.pas:481` - `Assert.AreEqual('Denise', PesquisarNomes(Filtro('d''avila', [cpNome])))`; `:482` - `Assert.AreEqual('', PesquisarNomes(Filtro(''' OR 1=1 --', [])))`; `:483` - `Contar('CLIENTE') = 5` | PASS |
| C10 | rótulo `TcxLabel`, texto exato, fonte menor, visível com 0 e 3, entre lista e barra | lote ed559b9, 37/37 | `tests/Unitarios/Testes.FormsClientes.pas:308-310` - `'TcxLabel'`, `Assert.AreEqual('A pesquisa lista no máximo 50 clientes.', FForm.RotuloLimite.Caption)`, `Style.Font.Size < FForm.Font.Size`; `:313`, `:318` - visível; `:320` e `:322` - arranjo | PASS |
| C11 | recarga repete filtro, `coCidade` crescente e 50; não salvo não pesquisa | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:235-239` - `'silva'`, `[cpNome]`, `'coCidade crescente'`, `50`; `:256`, `:263` - `Assert.AreEqual(LChamadas, ...ChamadasPesquisar, ...)`; `:269`, `:275`, `:282` - `AssegurarChamadaVigente` | PASS |
| C12 | falha: erro fixo, 0 clientes, ações desabilitadas, carregamento desligado | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:290-296` - `1`, `'Não foi possível carregar os clientes.'`, sem `'masterkey'`, `0` exibidos, `IsFalse(AcoesHabilitadas)`, `IsFalse(Carregando)`; `:318` - `Assert.AreEqual(0, FConfirmacaoObjeto.Mensagens.Count, ...)` | PASS |
| C13 | form real: falha mantém filtros e esvazia a lista | lote ed559b9, 37/37 | `Testes.FormsClientes.pas:531-536` - `Mensagens.Count = 1`, texto de erro, `Items.Count = 0`, `'silva'`, `[cpCidade]`, `EncodeDate(1990, 3, 15)` | PASS |
| C14 | vazio: mensagem e ações desabilitadas; com 1 cliente, o contrário | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:328-330` - `Assert.AreEqual('Nenhum cliente encontrado', FVisaoObjeto.SemResultado.Text.Trim)`; `:334-336` - `SemResultado.Count = 0`, `IsTrue(AcoesHabilitadas)` | PASS |
| C15 | form real: Pesquisar, Enter e Limpar consultam com o filtro da tela | lote ed559b9, 37/37 | `Testes.FormsClientes.pas:334-338` - `LChamadas + 1`, `'silva'`, `[cpNome, cpCidade]`, `'15/03/1990'`, `50` (aplicado em `:350` e `:355`); `:359-362` - `''`, `[cpId, cpNome]`, `''` | PASS |
| C16 | form real: lista 8,1,5; `IdSelecionado` da 2ª linha = 1 | lote ed559b9, 37/37 | `Testes.FormsClientes.pas:380-381` - `Assert.AreEqual('8,1,5', IdsDaLista(FForm), ...)`; `:383` - `Assert.AreEqual(1, FForm.IdSelecionado, ...)` | PASS |
| C17 | abertura exibe `coNome` crescente antes dos clientes | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:344-345` - `'coNome crescente'`; `:347` - `IndexOf('ExibirOrdenacao') < IndexOf('ExibirClientes')`; `:349` - repositório `'coNome crescente'` | PASS |
| C18 | outra coluna: 1 chamada `coCidade` crescente com filtro mantido | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:360-366` - `3`, `'silva'`, `[cpNome]`, `'coCidade crescente'`, `50`, visão `'coCidade crescente'` | PASS |
| C19 | Nome, Nome, Nome, Cidade = desc, asc, desc, Cidade asc | lote ed559b9, 37/37 | `Testes.ControladorPesquisaCliente.pas:371` - ESPERADO = 'coNome decrescente&#124;coNome crescente&#124;coNome decrescente&#124;coCidade crescente'; `:380`, `:382` - `Assert.AreEqual(ESPERADO, DescreverTodas(...), ...)` | PASS |
| C20 | Limpar volta a `coNome` crescente; na form, seta Nome asc e Cidade sem seta | lote ed559b9, 37/37 (2 provas) | `Testes.ControladorPesquisaCliente.pas:396-399` - `4`, `'coNome crescente'` x2; `Testes.FormsClientes.pas:393` - `Assert.AreEqual(SetasSomente(Ord(coNome), 'asc'), Setas(FForm), ...)` | PASS |
| C21 | 8 seções: clique pesquisa com `TCampoOrdenacao(i)`, seta só na i; 2º clique inverte | lote ed559b9, 37/37 | `Testes.FormsClientes.pas:426-431` - `LChamadas + 1`, `UltimaOrdenacao.Campo = LCampo`, `Assert.AreEqual(SetasSomente(Ord(LCampo), LPrimeira), Setas(FForm), ...)`; `:435-439` - 2º clique; `:445` - `Assert.AreEqual(8, LVerificados)` | PASS |
| C22 | abertura: Nome asc, 8 `AllowClick`, `Sorted = False` | lote ed559b9, 37/37 | `Testes.FormsClientes.pas:455` - `SetasSomente(Ord(coNome), 'asc')`; `:457` - `Assert.IsTrue(...HeaderSections[I].AllowClick, ...)`; `:459` - `Assert.IsFalse(FForm.ListaClientes.Sorted, ...)` | PASS |
| C23 | 8 colunas x 2 direções na F5; ausentes por último; empate por ID; texto sem diferença de caixa | lote ed559b9, 37/37 | `tests/Unitarios/Testes.RepositorioClienteFirebird.pas:503-519` - tabela idêntica à do check; `:530` e `:533` - `Assert.AreEqual(LCaso.Crescente/LCaso.Decrescente, PrimeirosNomes(FRepositorio.Pesquisar(...)))`; `:537` - `Assert.AreEqual(16, LVerificados)`. Caixa em Cidade e Estado, novo em ed559b9, com `Eva Lima` em `macapá`/`amapá`: `:546` - `Assert.AreEqual('Ana,Carlos,Denise,Eva,Bruno,bianca', ... Ordenacao(coCidade) ...)`; `:548` - `'Bruno,Eva,Carlos,Denise,Ana,bianca'` (Cidade desc); `:550` - `'Eva,Ana,Bruno,Carlos,Denise,bianca'` (Estado asc); `:552` - `'Carlos,Denise,Ana,Bruno,Eva,bianca'` (Estado desc). Conferi à mão: com `UPPER`, `MACAPÁ` fica entre `CAMPINAS` e `MARIANA`, e `AMAPÁ` fica antes de `MINAS GERAIS`; sem `UPPER`, as minúsculas vão para o fim | PASS |
| C24 | Carlos com Campinas/SP/São Paulo; bianca vazia | lote ed559b9, 37/37 | `Testes.RepositorioClienteFirebird.pas:563-565` - `'Campinas'`, `'SP'`, `'São Paulo'`; `:568-570` - `''` x3 (linhas reconferidas em ed559b9; eram `:545-552`) | PASS |
| C25 | sem `ListarTodos`/`Atende` em `src`; limite 50; assinatura do door 1; sem `Sort` fora de `SortOrder` | lote ed559b9, 37/37 | `Testes.FormsClientes.pas:1183-1184` - `Assert.IsFalse(ContainsStr(LTexto, 'ListarTodos'/'Atende'), ...)`; `:1189-1193` - `'LIMITE_PESQUISA_CLIENTES = 50;'` e a assinatura; `:1196` - `Assert.IsFalse(ContainsText(StringReplace(LTexto, 'SortOrder', '', [rfReplaceAll]), 'Sort'), ...)`. Os nomes novos `ManterLinhasNaOrdemDoBanco` e `PermitirSetaSomentePeloControlador` não contêm `Sort`, e a prova passou | PASS |
| C26 | AD-016 ativo; C43, C45, C46 e C51 inalterados e verdes; C44 com ...&#124;Pesquisar | shell exit 0; lote ed559b9, 37/37 | `.specs/STATE.md:22` - &#124; AD-016 &#124; ... &#124; active &#124; 2026-09-22 &#124;; `Testes.ControladorPesquisaCliente.pas:435` - Assert.AreEqual('Confirmacao&#124;Iniciar&#124;Excluir:7&#124;Confirmar&#124;Pesquisar', ...); `:412` (C43), `:468-472` (C45), `:493-497` (C46); `tests/Unitarios/Testes.NavegadorAplicacao.pas:306`, `:309` (C51) | PASS |

**Busca de comentários** (lacuna 2 da rodada 1, *verified at ed559b9*). Para cada `.pas`/`.dpr`/`.dfm` de `git diff --name-only 76f1716..HEAD` que ainda existe, rodei `grep -nE '//|\{[^$]|\(\*'`, excluindo `//` dentro de literal. Sobraram só estes acertos:

- 2 GUIDs de interface: `Aplicacao.ControladorPesquisaCliente.pas:16` e `Aplicacao.RepositorioCliente.pas:11`.
- 3 nomes de form no `uses` do `.dpr`: `tests/CadCli.Testes.dpr:62`, `:69` e `:70`.
- 3 `COUNT(*)` em SQL: `Testes.RepositorioClienteFirebird.pas:130`, `:196` e `:268`.

Nenhum desses acertos é comentário. `src/Visao/Visao.FormPesquisaCliente.pas:164-173` agora tem corpos sem comentário. `Testes.FiltroCliente.pas` foi removido pela feature.

## Coverage

*verified at ed559b9* para a linha de caixa do AC 17. As outras linhas são *carried from 007ebf4*: a correção não altera `src/Infraestrutura`, `src/Aplicacao` nem `src/Dominio`, e o diff em `Visao.FormPesquisaCliente.pas` só renomeia manipuladores, sem novo ramo ou membro.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| campos do `OR` - AC 3 (6 campos, 7 predicados) | plan AC 3; `PredicadosDoTexto` (`src/Infraestrutura/Infraestrutura.RepositorioClienteFireDAC.pas:224-237`) (carried from 007ebf4) | ID, nome, CPF/CNPJ, CEP, cidade, UF (`'mg'`), nome do estado (`'paulo'`): C5 `Testes.RepositorioClienteFirebird.pas:417`; os 6 valores também em C7 `:462` | - |
| rejeições de formato - AC 3 e AC 7 (5) | plan (carried from 007ebf4) | ID não inteiro C5 · CPF/CNPJ parcial C5 · CEP com 7 dígitos C5 · apóstrofo C9 · injeção C9 | - |
| combinações - AC 4, 5, 6 (5) | plan (carried from 007ebf4) | `OR` C6 · nenhum marcado C7 · `AND` com a data C8 · vazio = primeiros 50 C4 · texto aparado C5 | - |
| limite de 50 (3) | plan AC 2 e AC 6; `Aplicacao.ControladorPesquisaCliente.pas:103`, `:153` (carried from 007ebf4) | corte C4 · menos de 50 C4 · controlador passa 50 C1/C2/C11/C18 | - |
| gatilhos de pesquisa (6) | plan; handlers `Visao.FormPesquisaCliente.pas:175-203` (linhas refeitas em ed559b9: `CabecalhoClicado:175`, `FormShow:181`, `BotaoPesquisarClick:186`, `FiltroKeyPress:191`, `BotaoLimparClick:199`) | abertura C1 · Pesquisar C2/C15 · Enter C15 · Limpar C15/C20 · cabeçalho C18/C21 · recarga C11 | - |
| recargas do AC 9 (5) | plan AC 9; `Aplicacao.ControladorPesquisaCliente.pas:181-185`, `:269` (carried from 007ebf4) | novo e edição, salvos e não salvos, e exclusão confirmada: C11 | - |
| colunas de ordenação x direções (8 x 2) | door 3; `COLUNAS_ORDENACAO` (`Infraestrutura.RepositorioClienteFireDAC.pas:63-64`) (carried from 007ebf4) | 16 sequências C23 (`:530`, `:533`); 8 seções x 2 cliques C21 | - |
| AC 17: ausentes por último (4 colunas anuláveis) | `NULLS LAST` (`Infraestrutura.RepositorioClienteFireDAC.pas:283`) (carried from 007ebf4) | Cidade, UF, Estado e Data com bianca por último nas 2 direções: C23 `:503-519`; e de novo em `:546-552` | - |
| AC 17: desempate por ID (4 colunas com empate na F5) | `, C.ID ASC` (`:283`) (carried from 007ebf4) | Cidade, UF, Estado e Data nas 2 direções: C23 | - |
| AC 17: texto sem diferença de caixa (3 colunas de texto com `UPPER`) | plan AC 17; `COLUNAS_ORDENACAO` (`src/Infraestrutura/Infraestrutura.RepositorioClienteFireDAC.pas:63-64`: `UPPER(C.NOME)`, `UPPER(CI.NOME)`, `UPPER(E.NOME)`); *verified at ed559b9* | Nome: C23 `Testes.RepositorioClienteFirebird.pas:506` (`Ana,bianca,Bruno`). Cidade: `Testes.RepositorioClienteFirebird.pas:546` (asc) e `:548` (desc), com `macapá`. Estado: `:550` (asc) e `:552` (desc), com `amapá`. Os mutantes sem `UPPER` em `CI.NOME` e em `E.NOME` foram mortos (Faults injected). As colunas sem `UPPER` não são de texto livre: ID, CPF/CNPJ, CEP e Data são numéricas ou datas, e UF é sigla em maiúsculas | - |
| transições da ordenação (4) | plan AC 12-16; `Aplicacao.ControladorPesquisaCliente.pas:213-227` (carried from 007ebf4) | padrão C17/C22 · outra coluna C18/C21 · mesma coluna inverte C19/C21 · Limpar C20 | - |
| setas do AC 15 (3) | plan AC 15; `ExibirOrdenacao` (`Visao.FormPesquisaCliente.pas:305-321`, refeito em ed559b9; era `:307-323`) | crescente C21/C22 · decrescente C21 · nenhuma nas outras C20/C21/C22 | - |
| estados do `Observable` (5 aplicáveis) | plan Observable (carried from 007ebf4) | empty C14 · loading C2 · error C12/C13 · density and ordering C10/C21/C22/C23 · destructive confirms C26 | - |
| textos novos ou alterados (3) | plan AC 8, 10, 11 (carried from 007ebf4) | rótulo C10 · vazio C14 · erro C12 | - |
| arranjo do rótulo (3) | plan AC 8 (carried from 007ebf4) | abaixo da lista C10 · acima da barra C10 · fonte menor C10 | - |
| one-way doors (6) | plan Landing (carried from 007ebf4) | door 1: C1/C2/C25 · door 2: C3/C5-C9/C25 · door 3: C17-C19/C21/C25 · door 4: C1/C2/C24/C26 · door 5: C26 · door 6: `TextosDaPesquisaSaoOsDefinidos` e os 3 testes de b255b92, rodados no lote | - |

A varredura de conjuntos sem linha é *carried from 007ebf4*:

- `Relations` e `Surface` são `None`.
- O ramo "texto maior que a coluna" é provado por `TextoLongoNaoGeraErro` (`Testes.RepositorioClienteFirebird.pas:489-491`, linha reconferida), que rodou no lote.
- O ramo "data que não é lida" (`Infraestrutura.RepositorioClienteFireDAC.pas:275-276`) continua sem prova. Fica como observação: a form nunca produz esse caso, e o plano não é a autoridade desse ramo.

## Test policy rows

*verified at ed559b9* para a linha do adaptador (não atendida na rodada 1) e para a linha da view (classifica um arquivo tocado). As outras 2 linhas são *carried from 007ebf4*.

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Adaptador de persistência (`TRepositorioClienteFireDAC.Pesquisar`) | `src/Infraestrutura/Infraestrutura.RepositorioClienteFireDAC.pas` | integração em base temporária do Firebird local: C4-C9, C23, C24 | sim - há caso asserido por campo do `OR` (C5), por rejeição de formato (C5/C9), por combinação (C4, C6-C8) e por coluna x direção (C23, 16 sequências); a regra de caixa agora tem caso em Nome, Cidade e Estado (`Testes.RepositorioClienteFirebird.pas:506`, `:546-552`) |
| Controlador sem fronteira (`TControladorPesquisaCliente`) | `src/Aplicacao/Aplicacao.ControladorPesquisaCliente.pas` | unitária com fakes, por desfecho | sim - gatilhos C1/C2/C18/C20, transições C17-C20, recargas C11, vazio C14, erro C12 (carried from 007ebf4) |
| View passiva (`TFormPesquisaCliente`) | `src/Visao/Visao.FormPesquisaCliente.pas` + `.dfm` | form real, controlador real, repositório falso | sim - gatilhos C15/C21, 8 seções C21, setas C20-C22, rótulo e arranjo C10, erro de carga C13, ordem C16; os 2 manipuladores renomeados continuam sem condicional de regra (`:164-173`), e as faltas M3 e M4 mostram que ambos são asseridos |
| Repositório falso de teste | `tests/Suporte/Suporte.FakesClientes.pas` | sem regra própria | sim - `Pesquisar` só registra a chamada e devolve a cópia configurada; C3 prova (carried from 007ebf4) |

## Faults injected

*verified at ed559b9* para as 4 faltas desta rodada. As 5 faltas da rodada 1 são *carried from 007ebf4*: as superfícies delas não foram tocadas pela correção, e todas foram mortas naquela rodada. São elas:

- `OR` -> `AND` em `:271`, morta por C6;
- limite + 1 em `:290`, morta por C4;
- mesma coluna sempre decrescente, em `Aplicacao.ControladorPesquisaCliente.pas:218`, morta por C19;
- recarga na ordem padrão, morta por C11;
- `SETAS` trocadas, morta por C22.

**Procedimento desta rodada:**

1. Baseline do `git status --porcelain` da árvore real: `?? .specs/features/parte-03.1-pesquisa-clientes/verification.md`.
2. Criei o worktree com `git worktree add --detach <scratchpad>\wt HEAD` (ed559b9).
3. No worktree, compilei `CadCli.dproj` Debug e Release e `tests\CadCli.Testes.dproj` Debug. Os 3 saíram com código 0.
4. Rodei a suíte completa sem mutação: 124/124, código de saída 0.
5. Cada mutante foi aplicado, compilado (Debug dos testes, exit 0), rodado com watchdog e revertido com `git checkout -- .`.
6. No fim, `git worktree remove --force`. `git worktree list` mostra só a árvore real, e o porcelain da árvore real é igual à baseline (`equal=True`).

| Mutation | Location | Killed |
| --- | --- | --- |
| M1: `'UPPER(CI.NOME)'` -> `'CI.NOME'` (Cidade sem regra de caixa) | `src/Infraestrutura/Infraestrutura.RepositorioClienteFireDAC.pas:64` | yes - C23 `OrdenaPorCadaColunaNasDuasDirecoesComAusentesPorUltimo` exit 1: `Expected [Ana,Carlos,Denise,Eva,Bruno,bianca] but got [Ana,Carlos,Denise,Bruno,Eva,bianca] Cidade crescente sem diferença de caixa.` (`Testes.RepositorioClienteFirebird.pas:546`) |
| M2: `'UPPER(E.NOME)'` -> `'E.NOME'` (Estado sem regra de caixa) | `src/Infraestrutura/Infraestrutura.RepositorioClienteFireDAC.pas:64` | yes - C23 exit 1: `Expected [Eva,Ana,Bruno,Carlos,Denise,bianca] but got [Ana,Bruno,Carlos,Denise,Eva,bianca] Estado crescente sem diferença de caixa.` (`:550`) |
| M3: `APermitir := FExibindoOrdenacao` -> `APermitir := True` (o clique nativo inverte a seta) | `src/Visao/Visao.FormPesquisaCliente.pas:172` (`PermitirSetaSomentePeloControlador`) | yes - C21 `CliqueNoCabecalhoOrdenaEMarcaASetaDaColuna` exit 1: `Expected [asc,-,-,-,-,-,-,-] but got [desc,-,-,-,-,-,-,-] Seta após o primeiro clique na seção 0` |
| M4: sem a ligação `OnSectionChangedSortOrder := ManterLinhasNaOrdemDoBanco` (a lista reordena sozinha) | `src/Visao/Visao.FormPesquisaCliente.pas:160` | yes - 2 de 4 provas de form falharam: C16 `ListaExibeClientesNaOrdemDevolvida` (`Expected [8,1,5] but got [5,8,1]`) e C21 (`Expected [1,10,15,150,23] but got [23,150,15,10,1] A lista não reordena as linhas sozinha.`) |

Com isso, 9 mutantes foram injetados nas 2 rodadas, e todos foram mortos. As 4 asserções novas de ed559b9 foram exercitadas por M1 e M2, que caíram em asserções diferentes (`:546` e `:550`).

## Gate

- **Árvore real, HEAD ed559b9, lote das provas:** `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:<37 testes>`. Resultado: 37 passed, 0 failed, exit 0.
- **Árvore real, prova de shell de C26:** `powershell -NoProfile -Command "if (Select-String -Path .specs/STATE.md -Pattern '^\| AD-016 \|.*\| active \|' -Quiet) { exit 0 } else { exit 1 }"`. Resultado: exit 0.
- **Worktree limpo em HEAD ed559b9, suíte completa** (`CadCli.dproj` Debug e Release + runner Debug): `CadCli.Testes.exe`. Resultado: 124 passed, 0 failed, exit 0.
- **Árvore real, compilação Release:** falhou com `F2039` porque `bin\Win64\Release\CadCli.exe` estava travado pela instância do app que o usuário deixou aberta. Isso é ambiente, não defeito da feature. A suíte completa por isso rodou no worktree.

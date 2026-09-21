# Parte 02 - Form principal e navegação verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 35344fb..f3a79db (`feat/parte-02-form-principal`, HEAD = f3a79db); fix under review fd2eb1c..f3a79db
**Round**: 3 - scoped
**Verifier**: independent sub-agent (author != verifier)

O fix fecha o achado do round 2. A prova de C27 agora lê o título e a mensagem no diálogo que `ApresentarErro` exibe de fato. A leitura acontece em `Application.OnIdle` durante o `ShowModal`, sobre o `TMessageForm` visível e com `fsModal` (`tests/Unitarios/Testes.FormPrincipal.pas:370-392`). O teste também passou a asserir que o diálogo é exibido exatamente uma vez. O mutante sobrevivente do round 2, `CriarDialogo(AMensagem)` -> `CriarDialogo('Erro.')`, agora é morto. As outras três superfícies do apresentador (título no diálogo exibido, liberação, modalidade/exibição) também foram reinjetadas e mortas. As 29 provas passaram em uma única invocação em f3a79db, e a suíte completa passou 54/54.

Escopo deste round, conforme "Re-verifying after a fix": `git diff --stat fd2eb1c..f3a79db` mostra só `tests/Unitarios/Testes.FormPrincipal.pas` (+42/-9). Nenhum arquivo de `src`, nenhum `.dpr`/`.dproj` e nenhum `checks.md` mudou. As provas foram reexecutadas em full em f3a79db. As citações de `Testes.FormPrincipal.pas` foram refeitas, porque as linhas se deslocaram +5 com os campos privados novos da fixture. As falhas foram reinjetadas em `src/Visao/Visao.ApresentadorErro.pas`, nas superfícies que C27 reivindica. As linhas não-PASS do round 2 (C27, coverage `falhas de abertura`, `Test policy` do apresentador) foram rejulgadas. O passo 1 não foi refeito, porque o fix não tocou a interface. O resto é `carried from fd2eb1c` (ou da origem que o round 2 já registrava).

## Binding sources

Carried from fd2eb1c. O fix não tocou `src/` nem nenhuma DFM, portanto não tocou a interface.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| `.specs/Teste Programador Delphi 2026.md`, Item 1 (menus e destinos) - carried from 21d51de | sim (round 1, lido na íntegra) | nenhuma: 3 menus = C12; `Sair`/`Cliente`/`Relatório` = C13; "Sair ... irá fechar o sistema" = C1/C11/C14/C21; clientes/relatório para as Partes 03/04 por AD-010 (C8-C10, C23) | - |
| tela `Principal`, enumerada pela DFM `src/Visao/Visao.FormPrincipal.dfm` + `AGENTS.md` Idioma - carried from fd2eb1c | sim (round 2; `Visao.ApresentadorErro.pas` relido em f3a79db, sem alteração desde fd2eb1c) | nenhuma: o título do diálogo é `CadCli` (`Visao.ApresentadorErro.pas:21,31`) | - |

Enumeração do estado de erro (diálogo de `TApresentadorErroDialogo`). As linhas de código foram carried from fd2eb1c. As citações das provas foram verified at f3a79db:

| Elemento | Código | Check |
| --- | --- | --- |
| título `CadCli` | `Result.Caption := TITULO_DIALOGO_ERRO` (`Visao.ApresentadorErro.pas:31`) | C27, no diálogo exibido (`Testes.FormPrincipal.pas:364`, lido em :383) e no da fábrica (:324) |
| mensagem fixa da ação | `CreateMessageDialog(AMensagem, mtError, [mbOK])` (:30), chamado em `ApresentarErro` com `AMensagem` (:38) | C4/C5 (texto no controlador), C27 no diálogo exibido (:365, lido em :384-386) |
| modal, exibido uma vez, liberado ao fechar | `ShowModal` / `Free` (:40, :42) | C27 (:363 exibido 1x como modal, :367 liberação) |
| ícone de erro, botão `OK` | `mtError`, `[mbOK]` | sem check próprio; as fontes não decidem nenhum dos dois (carried from 21d51de) |

O smoke test interativo (Independent test do plano) continua **com o usuário**, porque o Verifier não tem uma tela para operar. Esperado: `Cadastros > Cliente` e `Relatórios > Relatório` mostram, cada um, um diálogo de erro com título `CadCli` e a mensagem da ação, e a form principal continua utilizável. `Sistema > Sair` fecha o app, e o aviso trial do DevExpress aparece antes da form principal (AD-013). Não rodei o `bin\Win64\Release\CadCli.exe` no lugar.

## Checks

Build em f3a79db: `build.bat` (Release/Win64 de `CadCli.dproj`, cujo post-build copiou as 13 BPLs, + Debug/Win64 de `tests\CadCli.Testes.dproj`), exit 0. Nenhum `*.fdb` em `bin\Win64\Release` antes nem depois das provas.

As 29 provas distintas de `checks.md` (27 checks; C22 tem 3 provas; os nomes foram extraídos com `grep -o 'run:[A-Za-z0-9_.]*' checks.md | sort -u`, 29 linhas) rodaram em **uma** invocação: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:<os 29 nomes, separados por vírgula>`. Resultado: exit 0, `Tests Found : 29 / Passed : 29 / Failed : 0 / Errored : 0`. Tests Found é igual ao número de nomes distintos. O round 2 já mostrou que o filtro é exato (carried from fd2eb1c). Neste round, a prova de C27 rodou isolada, com `Tests Found : 1 / Passed : 1`.

Suíte completa sem filtro: exit 0, 54/54, igual aos 54 atributos `[Test]` em `tests/Unitarios`. O fix não acrescentou testes.

As citações de `tests/Unitarios/Testes.FormPrincipal.pas` (C12-C20, C27) foram verified at f3a79db, com deslocamento de +5 linhas. As citações dos demais arquivos de teste, que o fix não tocou, são carried from 21d51de. O resultado de todas as provas é de f3a79db.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | Sair -> Encerrar 1x, outros 0 | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:83` - `Assert.AreEqual(1, FNavegadorObjeto.ChamadasEncerrar)`; :84-85 zeros | PASS |
| C2 | Cliente -> AbrirClientes 1x, outros 0 | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:91` - `Assert.AreEqual(1, FNavegadorObjeto.ChamadasClientes)`; :92-93 | PASS |
| C3 | Relatório -> AbrirRelatorio 1x, outros 0 | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:99` - `Assert.AreEqual(1, FNavegadorObjeto.ChamadasRelatorio)`; :100-101 | PASS |
| C4 | falha clientes: não propaga, 1 erro com texto fixo, Relatório seguinte 1x | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:107` WillNotRaiseAny; :112 `AreEqual(1, Erros.Count)`; :113 `AreEqual('Não foi possível abrir o cadastro de clientes.', Erros[0])`; :115 | PASS |
| C5 | falha relatório: idem, Cliente seguinte 1x | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:121`; :126; :127 `AreEqual('Não foi possível abrir o relatório de clientes.', Erros[0])`; :129 | PASS |
| C6 | mensagem não repassa `SYSDBA masterkey Password=x` | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:148` `AreEqual(ESPERADAS[I], Erros[I])`; :149-151 `IsFalse(Contains(...))` | PASS |
| C7 | controlador/visão/navegador sem VCL/DevExpress/FireDAC/forms | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:234` `IsFalse(StartsText(LPrefixo, LReferencia))`; :236; :255 `AreEqual(LFormsAntes, Screen.FormCount)` | PASS |
| C8 | AbrirClientes: 1 instância modal, form principal desabilitada, liberada | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.NavegadorAplicacao.pas:143` `AreEqual(1, Criadas)`; :145 `IsTrue(ModalDuranteExibicao)`; :146; :148 `AreEqual(0, Vivas)`; :149 | PASS |
| C9 | AbrirRelatorio: idem | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.NavegadorAplicacao.pas:163`; :165; :166; :168; :169 | PASS |
| C10 | 2 acionamentos -> 2 instâncias, máx. 1 viva | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.NavegadorAplicacao.pas:182` `AreEqual(2, Criadas)`; :185 `AreEqual(1, MaximoVivas)` | PASS |
| C11 | Encerrar fecha a form principal, ExitCode 0 | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.NavegadorAplicacao.pas:200` `AreEqual(1, Fechamentos)`; :201; :202 `AreEqual(0, ExitCode)` | PASS |
| C12 | 1 TdxBar IsMainMenu no topo; `Sistema`,`Cadastros`,`Relatórios` esquerda->direita | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:90` `AreEqual(1, Integer(Length(LBarras)))`; :126 `IsTrue(LMenu.DockingStyle = dsTop)`; :127 `AreEqual(3, LMenu.ItemLinks.Count)`; :129 `AreEqual(ESPERADAS[I], Legenda(SubItem(LMenu, I).Caption))`; :134 `ItemRect.Left >`; :136 mesmo `Top` | PASS |
| C13 | cada menu com exatamente 1 link: Sair/Cliente/Relatório | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:154` `AreEqual(1, LSubItem.ItemLinks.Count)`; :156 `AreEqual(ESPERADOS[I], Legenda(LSubItem.ItemLinks[0].Item.Caption))` | PASS |
| C14 | Click nos itens da form real -> 1 chamada cada, nenhuma form | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:166-168`, :170-172, :174-176 contagens 1/0/0, 1/1/0, 1/1/1; :177 `AreEqual(LFormsComFormPrincipal, Screen.FormCount)` | PASS |
| C15 | unit da form sem dados/outras forms; 1 campo de controlador | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:277`; :279; :287 `AreEqual(1, LCamposControlador)` | PASS |
| C16 | TFormPrincipal é a única IVisaoPrincipal | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.ControladorPrincipal.pas:298` `IsTrue(Supports(TFormPrincipal, IVisaoPrincipal))`; :307; :310 | PASS |
| C17 | só controles/componentes `dx`/`cx` | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:226` `IsTrue(UnitDevExpress(LComponente.ClassType))`; :202 controles; :230 `AreEqual(0, LProibidos)`; :231 `IsTrue(LVerificados >= 11)` | PASS |
| C18 | textos da form principal + `Versão <FileVersion>` | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:264` `AreNotEqual('1.0.0.0', LVersao)`; :266 `AreEqual('CadCli', FForm.Caption)`; :267 cabeçalho; :268 boas-vindas; :270 `AreEqual(1, Panels.Count)`; :271 `AreEqual('Versão ' + LVersao, Panels[0].Text)` | PASS |
| C19 | arranjo menu/alTop/alClient/alBottom e ordem vertical | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:279` dsTop; :280 `Align = alTop`; :281 `alClient`; :282 `alBottom`; :286 menu acima do cabeçalho; :290 `RotuloCabecalho.Top < RotuloBoasVindas.Top`; :292 `RotuloBoasVindas.Top < BarraStatus.Top` | PASS |
| C20 | form real, falha em clientes: 1 mensagem, form principal utilizável, Relatório 1x | batch em f3a79db exit 0 | `tests/Unitarios/Testes.FormPrincipal.pas:302` `AreEqual(1, Mensagens.Count)`; :303 texto; :304 `IsTrue(FForm.Visible)`; :305 `IsTrue(IsWindowEnabled(FForm.Handle))`; :307 `AreEqual(1, ChamadasRelatorio)` | PASS |
| C27 | apresentador do exe: diálogo modal com título exatamente `CadCli` e o texto recebido exatamente como mensagem, liberado ao fechar | batch em f3a79db exit 0; isolada exit 0 (1/1) (def `tests/Unitarios/Testes.FormPrincipal.pas:311`) | diálogo **exibido** por `ApresentarErro(MENSAGEM)` (:357), capturado em `CapturarDialogoExibido` (`Application.OnIdle`, :353) sobre o `TMessageForm` com `Visible` e `fsModal` (:381): `tests/Unitarios/Testes.FormPrincipal.pas:363` `Assert.AreEqual(1, FExibicoes, ...)`; :364 `Assert.AreEqual('CadCli', FTituloJanela, ...)` (texto da janela exibida, :383); :365 `Assert.AreEqual(MENSAGEM, FMensagemExibida, ...)` (rótulo `Message` do diálogo exibido, :384-386); :367 `Assert.AreEqual(LFormsAntes, Screen.FormCount, ...)`. Os 4 mutantes do apresentador foram mortos (ver Faults) | PASS |
| C21 | exe Release: form principal `CadCli` em 60 s, WM_CLOSE -> 0 | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.IntegracaoFirebird.pas:441` `IsTrue(LFormPrincipal <> 0)`; :444; :446; :448 `AreEqual('CadCli', TextoJanela(LFormPrincipal))`; :452 `AreEqual(Cardinal(0), LCodigoSaida)` | PASS |
| C22 | recusa com `-sem-interacao`: sai 1, sem form principal; Parte 01 C17/C20 verdes | batch em f3a79db exit 0 (3 provas) | carried from 21d51de: `tests/Unitarios/Testes.IntegracaoFirebird.pas:971` `AreEqual(Cardinal(1), LCodigoSaida)`; :972 `IsFalse(LFormPrincipalExistiu)`; Parte 01 :725/:727/:728/:733-738, :892/:893/:911/:913/:915/:918 | PASS |
| C23 | navegador como no exe: lança nos dois destinos sem criar form | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.NavegadorAplicacao.pas:218`, :223 `Assert.WillRaiseAny`; :228; :240-241 | PASS |
| C24 | entrega = fechamento de BPLs importadas, 1 exe | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.EntregaRunner.pas:196` `AreEqual(1, Length(LExecutaveis))`; :200; :209/:211; :214; :217; :219 | PASS |
| C25 | exe abre sem Embarcadero/DevExpress no PATH | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.IntegracaoFirebird.pas:981-982` `IsFalse(ContainsText(LPath, ...))`; :983 -> :441-452 | PASS |
| C26 | `.dfm` só em src\Visao; asserções da Parte 01 C15 | batch em f3a79db exit 0 | carried from 21d51de: `tests/Unitarios/Testes.InicializadorAplicacao.pas:80` `AreEqual(0, Length(GetFiles(<pasta>, '*.dfm')))`; :86; :90-93; :100 | PASS |

## Coverage

Verified at f3a79db: as linhas `falhas de abertura` e `textos`, cuja autoridade passa pelo apresentador real e que tinham lacuna no round 2. As demais são carried from fd2eb1c (ou da origem registrada), e o fix não tocou a autoridade de nenhuma delas.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| menus horizontais (3) - carried from 21d51de | fonte vinculante, Item 1 | `Sistema`/`Cadastros`/`Relatórios` -> C12 | - |
| submenus (3) - carried from 21d51de | fonte vinculante, Item 1 | `Sair`/`Cliente`/`Relatório` -> C13 | - |
| ações do controlador (3) - carried from 21d51de | `TAcaoPrincipal` (`Aplicacao.ControladorPrincipal.pas:10`) | C1/C2/C3 + C14 | - |
| métodos de `INavegadorAplicacao` (3) - carried from 21d51de | `Aplicacao.NavegadorAplicacao.pas:8-10` | Encerrar C1/C11 · AbrirClientes C2/C8/C10 · AbrirRelatorio C3/C9 | - |
| falhas de abertura, até o diálogo exibido (2) - verified at f3a79db | controlador `Aplicacao.ControladorPrincipal.pas:49-51,61-73` -> `TFormPrincipal.ExibirErro` (`Visao.FormPrincipal.pas:81`) -> `TApresentadorErroDialogo.ApresentarErro` (`Visao.ApresentadorErro.pas:34-44`), composto em `CadCli.dpr:41` (sem alteração desde fd2eb1c) | texto no controlador C4/C5; chega ao apresentador C20 (fake); o apresentador exibe o texto recebido, com título `CadCli`, C27 (`Testes.FormPrincipal.pas:364-365`). O apresentador é agnóstico ao texto, e C27 prova que o texto passa sem alteração, então as duas mensagens fixas chegam ao diálogo pela composição C4/C5 + C20 + C27 | - |
| destinos sem tela (2) - carried from 21d51de | `Visao.NavegadorAplicacao.pas:58-59`; `Visao.ComposicaoAplicacao.pas:18` | C23 | - |
| estados aplicáveis do `Observable` (4) - carried from 21d51de | plano `Observable` | empty C18 · loading Parte 01 + C22 · error C4/C5/C20/C27 · density C12/C19 | - |
| textos da tela `Principal` (14) - verified at f3a79db | DFM + `Visao.FormPrincipal.pas` + `Visao.ApresentadorErro.pas:21,30-31` | título C18/C21 · cabeçalho/boas-vindas/status C18 · 3 menus C12 · 3 submenus C13 · erro clientes C4/C20/C27 · erro relatório C5/C27 · sem texto da exceção C6 · título `CadCli` do diálogo C27 | - |
| arranjo (4) - carried from 21d51de | Assumption `layout criativo` + DFM | C12/C19 | - |
| fronteiras da door 1 (4) - carried from 21d51de | Landing door 1 | C14/C15/C16 | - |
| fronteiras da door 2 (2) - carried from 21d51de | Landing door 2 + AGENTS | C7 | - |
| abertura modal de instância única (6) - carried from 21d51de | Assumption `modo de abertura` | C8/C9/C10 | - |
| encerramento (2) - carried from 21d51de | AC 2 | C11/C21 | - |
| assemblies de inicialização (2) - carried from fd2eb1c | `CadCli.dpr:40-41`; `tests/CadCli.Testes.dpr` (nenhum dos dois tocado em fd2eb1c..f3a79db) | exe C21/C22/C25 · harness Parte 01 C3 verde na suíte completa (54/54 em f3a79db) | - |
| one-way doors (4) - carried from 21d51de | Landing | C14-C16 · C7-C11 · C12/C13 · C24/C25 | - |
| entrega com runtime packages (3) - carried from 21d51de | AD-011 | C24/C25 | - |
| provas da Parte 01 reescritas (2) - carried from 21d51de | AD-012 | C24 · C26 | - |

Nota (não bloqueante): C27 usa uma única mensagem, a de clientes. A de relatório chega ao diálogo pela composição descrita acima, e não por uma asserção própria no diálogo exibido. Como `ApresentarErro` não ramifica pelo texto, isso não é um membro sem prova.

## Test policy rows

Verified at f3a79db: a linha do apresentador, que não foi atendida no round 2. As outras são carried from fd2eb1c, e o fix não tocou os arquivos que elas classificam.

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decide sem cruzar fronteira - carried from 21d51de | `src/Aplicacao/Aplicacao.ControladorPrincipal.pas` | unitária com fakes: C1-C6 | yes |
| Adaptador VCL que decide ciclo de vida - carried from 21d51de | `src/Visao/Visao.NavegadorAplicacao.pas` | forms reais de teste: C8-C11 | yes |
| View passiva que não decide - carried from 21d51de | `src/Visao/Visao.FormPrincipal.pas` + `.dfm` | limite da form real: C12-C14, C17-C20 | yes |
| Adaptador VCL de apresentação de erro - verified at f3a79db | `src/Visao/Visao.ApresentadorErro.pas` | prova no próprio nível exibindo o diálogo real: C27 (`Testes.FormPrincipal.pas:311`) | yes - asserido sobre o diálogo exibido: título `CadCli` (:364), mensagem exata (:365), exibido 1x modal (:363, filtro `fsModal` em :381), liberação (:367); os 4 mutantes do apresentador foram mortos |
| Entrada que apenas compõe - carried from fd2eb1c | `CadCli.dpr`, `CadCli.dproj`, `tools/CopiarBplsEntrega.ps1` | artefato entregue: C21, C22, C24, C25 | yes - as quatro provas verdes em f3a79db contra o Release reconstruído |

Arquivos que nenhuma linha classifica: `Visao.ComposicaoAplicacao.pas` (C23) e `Visao.VersaoExecutavel.pas` (C18). Carried from 21d51de.

## Swept existing

Carried from fd2eb1c. Nenhuma linha `Swept` cita uma restrição de código existente que o fix tenha tocado.

## Faults injected

Verified at f3a79db, nas superfícies de `src/Visao/Visao.ApresentadorErro.pas` que C27 reivindica: título, mensagem exibida, liberação e exibição modal. A mensagem exibida é a superfície do sobrevivente do round 2. As 5 mutações do round 1 são carried from 21d51de (todas mortas; o fix não tocou `src/`).

- **Isolamento:** `git worktree add C:\Users\ENVOLT~1.JEA\AppData\Local\Temp\cadcli-wt3 HEAD` (f3a79db). Uma primeira tentativa criou o worktree num caminho errado (`...\LocalCache\Local\Tempcadcli-wt3`). Ele foi removido com `git worktree remove --force` + `prune` antes de qualquer mutação.
- **Execução:** para cada mutação, apliquei a mudança sobre o texto original do arquivo no worktree e recompilei só o runner Debug/Win64 no worktree (`msbuild tests\CadCli.Testes.dproj`). Depois rodei `--run:TTestesApresentadorErro.DialogoDeErroTemTituloCadCliEMostraAMensagem` com o runner do worktree. Controle: com o arquivo restaurado, o runner do worktree recompilado passou (exit 0, 1/1). Assim, as mortes vêm das mutações e não do ambiente do worktree.
- **Árvore real:** o `git status --porcelain` antes era `?? .specs/LESSONS.md`, `?? .specs/features/parte-02-form-principal/verification.md` e `?? .specs/lessons.json`, e depois estava idêntico.
- **Limpeza:** worktree removido com `git worktree remove --force` + `prune`; `git worktree list` mostra só a árvore real.

| Mutation | Location | Killed |
| --- | --- | --- |
| mensagem (sobrevivente do round 2): `ApresentarErro` exibe `CriarDialogo('Erro.')` em vez de `CriarDialogo(AMensagem)` | `src/Visao/Visao.ApresentadorErro.pas:38` | yes - C27 exit 1 ("Expected [Não foi possível abrir o cadastro de clientes.] but got [Erro.] O diálogo real deve exibir exatamente a mensagem recebida.", :365) |
| título só no diálogo exibido: `LDialogo.Caption := 'Error'` depois de `CriarDialogo`, com a fábrica intacta, de modo que :324 continua verde | `src/Visao/Visao.ApresentadorErro.pas:38` | yes - C27 exit 1 ("Expected [CadCli] but got [Error] O diálogo real deve ser exibido com o título CadCli.", :364) |
| liberação: remove `LDialogo.Free` | `src/Visao/Visao.ApresentadorErro.pas:42` | yes - C27 exit 1 ("Expected [0] but got [1] O diálogo deve ser liberado ao fechar.", :367) |
| modalidade: `LDialogo.ShowModal` -> `LDialogo.Show` | `src/Visao/Visao.ApresentadorErro.pas:40` | yes - C27 exit 1 ("Expected [1] but got [0] O diálogo real deve ser exibido exatamente uma vez.", :363) |

## Gate

- Build f3a79db: `build.bat` (Release app + Debug runner) - exit 0
- Proofs: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:<29 names>` - 29 passed, 0 failed (exit 0)
- Full suite: `.\tests\bin\Win64\Debug\CadCli.Testes.exe` - 54 passed, 0 failed (exit 0)
- `py .claude/skills/tlc-spec-lean/scripts/validate_verification.py parte-02-form-principal` - exit 0 (0 errors, 0 warnings)

## Notes (non-blocking)

- A thread vigia de C27 lê `FExibicoes` sem sincronização. É uma leitura benigna de inteiro, usada só para encerrar o polling. Se `OnIdle` nunca disparar, a vigia fecha o diálogo depois de 10 s e a prova falha em :363. Isso é um vermelho, nunca um verde falso.
- A prova substitui `Application.OnIdle` e o restaura para `nil`, não para o valor anterior. Hoje não há outro handler no runner.
- Carried from round 1: C17 não fixa a contagem exata de controles; o logger silencioso do runner esconde as linhas por teste; o Handoff do `.specs/STATE.md` está desatualizado (diz "nenhum código escrito" e branch `feat/parte-01-firebird-servico`); o botão `OK` e o ícone de erro não têm check, e nenhuma fonte vinculante os decide.
- Lessons: este round é um PASS limpo (sem mutante sobrevivente, sem lacuna de precisão, sem membro sem prova), então nenhuma lição nova foi registrada. L-001 e L-002 (round 2) continuam como estão.

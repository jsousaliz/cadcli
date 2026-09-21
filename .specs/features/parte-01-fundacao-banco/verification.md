# Parte 01 - Fundação e banco versionado verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 5d49414..a99e73a
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

O `HEAD` verificado é `a99e73aaed620a38222e23dcf6de93279308ee09` na branch `feat/parte-01-firebird-servico`; a base da feature é `5d49414be49ce1e0762cd697a8e976b238de07cb` (implementação Embedded anterior mais a spec revisada). Este relatório substitui o relatório da era Embedded. Foram verificados todos os checks C1-C24 de `checks.md`, não apenas os alterados. O Verifier é um sub-agente independente, sem contexto herdado do autor; trabalhou somente leitura sobre o código, testes, plano e checks. Ambiente: serviço Firebird 3.0.13 x64 em `localhost:3050`, `fbclient.dll` em `System32`.

Build no `HEAD`: `rsvars.bat` + `MSBuild.exe CadCli.dproj /t:Build /p:Config=Release /p:Platform=Win64` e `MSBuild.exe tests\CadCli.Testes.dproj /t:Build /p:Config=Debug /p:Platform=Win64`, código de saída 0 (somente hints H2443). O diretório `bin\Win64\Release` contém apenas `CadCli.exe` e `dcu\`.

## Binding sources

*Verificado em `a99e73a`.*

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| `.specs/Teste Programador Delphi 2026.md`, item 4 (Firebird 3.0, `CLIENTE`, `ESTADO`, `CIDADE`) | yes - arquivo inteiro aberto no real tree | none - C4 prova motor 3.x e ODS 12; C11 reproduz os 10 campos de `CLIENTE`, 3 de `ESTADO` e 3 de `CIDADE` com os tipos e larguras exatos da tabela | - |
| `.specs/Teste Programador Delphi 2026.md`, item 4, dados de referência | yes | none - os quatro estados exigidos e "algumas cidades" por estado; C12 prova 4 estados e 12 cidades, 3 por estado | - |
| `.specs/Teste Programador Delphi 2026.md`, IDE, FireDAC, entregas | yes | none - Delphi 12 permitido (C1); FireDAC obrigatório (C23 prova `DriverID=FB`); "arquivos necessários (.exe, .dll, e outros)" não exige distribuir DLLs do Firebird, então C22 não contradiz a fonte | - |
| `AGENTS.md` (Plataforma e entrega, Persistência, Migrações, Testes) | yes | none - serviço local em `localhost:3050` (C23), nenhuma DLL do Firebird ao lado de `CadCli.exe` (C22), base em `ExtractFilePath(ParamStr(0))` (`CadCli.dpr:42`, C17), credenciais fora de mensagens e logs (C16, C20, C24), sequências sem `MAX(ID)+1` (C14) | - |
| `.specs/STATE.md` AD-007 | yes | none - serviço local `SYSDBA`/`masterkey`, sem DLL ao lado do executável: C22, C23, C24 | - |
| `.specs/STATE.md` AD-008 | yes | none - trata do instalador Inno Setup, fora do escopo da Parte 01 (pertence à parte 05); nenhum check da Parte 01 o contradiz | - |

**Alteração externa da fonte vinculante durante a verificação.** A comparação acima foi feita contra `.specs/Teste Programador Delphi 2026.md` como está no `HEAD` `a99e73a` (linha da tabela `CLIENTE`: `FK - CIDADE`). Durante a execução, às 11:46:35, o arquivo no working tree foi alterado por outra origem, não pelo Verifier: a linha passou a `FK - CIDADEID`. A alteração não está commitada nem pertence ao diff `5d49414..HEAD`, e o Verifier não a reverteu. Se ela for adotada, passa a contradizer o door 4 do plano, a migração V001 e C11 (`Testes.IntegracaoFirebird.pas:762`, `CLIENTE.CIDADE:INTEGER:0`), e esta verificação precisa ser refeita.

Enumeração por tela: **no screen rows**. `plan.md` declara `Surface: None`; a Parte 01 não contém `.dfm` e C15 assere zero forms próprias em `tests/Unitarios/Testes.InicializadorAplicacao.pas:74`. Não há controles, rótulos, ordem, contagem ou arranjo visual a enumerar; os itens 1-3 da especificação (tela principal, cadastro, relatório) pertencem às partes 02-04. O walkthrough com o usuário (passo 5) não se aplica a esta parte de infraestrutura. As URLs de documentação em `Sources` do plano não são marcadas como vinculantes.

## Checks

*Provas executadas pelo Verifier em `a99e73a`.* Execução em lote: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --exitbehavior:Continue --run:<29 seletores separados por vírgula>` - Tests Found 29, Passed 29, Failed 0, Errored 0, exit 0. Como o logger de console do runner é silencioso por teste (`TDUnitXConsoleLogger.Create(True)` em `tests/CadCli.Testes.dpr`), cada um dos 29 seletores citados em `checks.md` também foi executado isoladamente: todos retornaram `Tests Found : 1`, `Tests Passed : 1`, exit 0, o que prova que cada nome existe e rodou (nenhum filtro vazio).

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | Release gera `CadCli.exe` AMD64, sem variante Win32 | `--run:TTestesEntregaRelease.ProduzCadCliExeSomenteParaWin64` 1/1 exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:61` - `Assert.AreEqual(Word($8664), MaquinaPE(CaminhoExecutavelRelease))`; `:64` - `Assert.IsFalse(LProjeto.Contains('Win32'))` | PASS |
| C2 | sem runtime packages, zero `.bpl`, só um `.exe` | `--run:TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar` 1/1 exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:72` - `Assert.AreEqual(1, Length(TDirectory.GetFiles(LDiretorio, '*.exe')))`; `:74` - `Assert.AreEqual(0, ... '*.bpl')`; `:76` - `Assert.Contains(..., '<DCC_UsePackage>false</DCC_UsePackage>')` | PASS |
| C3 | runner Win64, exit 0, `Screen.FormCount = 0` | `--run:TTestesRunnerDUnitX.ExecutaEmWin64SemCriarForm` 1/1 exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:102` - `Assert.AreEqual(Word($8664), MaquinaPE(ParamStr(0)))`; `:104` - `Assert.AreEqual(0, Screen.FormCount)` | PASS |
| C22 | nenhum arquivo do runtime Firebird ao lado do exe | `--run:TTestesEntregaRelease.NaoDistribuiRuntimeFirebirdAoLadoDoExecutavel` 1/1 exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:93` - `Assert.AreEqual(0, Length(TDirectory.GetFiles(LDiretorio, LPadrao)))` sobre os 6 padrões de `:82-83`; `:96` - `Assert.IsFalse(TDirectory.Exists(... LPadrao))` para `plugins` e `intl` | PASS |
| C4 | serviço cria exatamente `<dir>\cadcli.fdb`, Dialect 3, UTF8, ODS 12, versão final | `--run:TTestesInicializadorBanco.CriaBaseAoLadoDoExecutavelComConfiguracaoEsperada` e `--run:TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado` 1/1 cada, exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:278` - `SameText(FCaminhoBanco, ... 'SELECT MON$DATABASE_NAME FROM MON$DATABASE')`; `:282` - `Assert.AreEqual(3, ... MON$SQL_DIALECT)`; `:284` - `Assert.AreEqual(12, ... MON$ODS_MAJOR)`; `:286` - `Assert.AreEqual('UTF8', ... RDB$CHARACTER_SET_NAME)`; `:289` - `Assert.AreEqual(2, ... MAX(VERSAO))`; diretório do exe: `:708` - `Assert.IsTrue(TFile.Exists(LBanco))` | PASS |
| C23 | conexão TCP loopback como `SYSDBA`; params `FB`/`localhost`/`3050`/`OpenOrCreate`, sem `VendorLib` | `--run:TTestesInicializadorBanco.ConectaPeloServicoLocalEmLocalhost3050` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:337` - `... MON$REMOTE_PROTOCOL ... .StartsWith('TCP')`; `:344` - `LEndereco.StartsWith('127.0.0.1') or LEndereco.StartsWith('::1')`; `:346` - `Assert.AreEqual('SYSDBA', ... MON$USER)`; `:348-351` - `DriverID='FB'`, `Server='localhost'`, `Port='3050'`, `OpenMode='OpenOrCreate'`; `:352` - `Assert.AreEqual('', ...Params.Values['VendorLib'])` | PASS |
| C5 | uma linha em `SCHEMA_VERSION` com `VERSAO`, `DESCRICAO`, `APLICADA_EM` | `--run:TTestesExecutorMigracoes.RegistraUmaLinhaComMetadadosDaMigracao`, `...ReverteAlteracaoERegistroNaMesmaTransacao`, `--run:TTestesMigracaoNoFirebird.RegistraInstanteRealDaAplicacaoEmAplicadaEm` 1/1 cada, exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:143` - `Assert.AreEqual('REGISTRAR:1:migração um:2026-09-19 10:30:00', Operacoes[2])`; `:174` - `Assert.AreEqual(0, MaiorVersaoInstalada)` com falha no commit; `tests/Unitarios/Testes.IntegracaoFirebird.pas:626` e `:628` - `LRegistrado >= IncSecond(LAntes, -2)` e `LRegistrado <= IncSecond(LDepois, 2)` | PASS |
| C6 | rejeita duplicadas e ordena versões | `--run:TTestesCatalogoMigracoes.RejeitaDuplicadasEOrdenaVersoes` 1/1 exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:100` - `Assert.AreEqual(1, LMigracao.Versao)`; `:102` - `Assert.AreEqual(2, LMigracao.Versao)`; `:110` - `Assert.IsTrue(LDuplicadaRejeitada)` | PASS |
| C7 | só pendentes, uma vez, em ordem crescente | `--run:TTestesExecutorMigracoes.ExecutaSomentePendentesUmaVezEmOrdemCrescente` e `--run:TTestesMigracaoNoFirebird.AplicaSomenteAPendenteSobreBaseAnterior` 1/1 cada, exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:221` - `Assert.AreEqual` da sequência `EXECUTAR:2` seguida de `EXECUTAR:4` contra `SomenteExecucoes(...)`; `:223` - `Assert.AreEqual(0, TMigracaoTeste001.Execucoes)`; `tests/Unitarios/Testes.IntegracaoFirebird.pas:552` - `Assert.AreEqual` das linhas `1:cria alfa` seguida de `2:cria beta` em `SCHEMA_VERSION` | PASS |
| C8 | persistência pronta só depois das migrações; antes disso não autoriza a interface | `--run:TTestesInicializadorAplicacao.LiberaAplicacaoSomenteDepoisDasMigracoes` 1/1 exit 0 | `tests/Unitarios/Testes.InicializadorAplicacao.pas:52` - `Assert.IsFalse(LAutorizadorObjeto.Autorizado)`; `:56` - `Assert.IsTrue(LAutorizadorObjeto.Autorizado)` | PASS |
| C9 | falha reverte alterações e registro, erro cita a versão | `--run:TTestesExecutorMigracoes.ReverteAlteracaoERegistroEInformaVersaoNaFalha` e `--run:TTestesMigracaoNoFirebird.ReverteMigracaoInvalidaNoFirebirdEInformaVersao` 1/1 cada, exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:260` - `Assert.Contains(LErro, 'migração 3')`; `tests/Unitarios/Testes.IntegracaoFirebird.pas:578` - `Assert.Contains(LMensagem, 'migração 3')`; `:589` - `Assert.AreEqual(0, ... RDB$RELATION_NAME = 'GAMA')`; `:593` - `Assert.AreEqual(0, ... SCHEMA_VERSION WHERE VERSAO = 3)` | PASS |
| C10 | versão futura: conexão não entregue, orienta atualizar `CadCli.exe` | `--run:TTestesInicializadorBanco.RecusaVersaoFuturaEOrientaAtualizacao` e `--run:TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro` 1/1 cada, exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:302` - `Assert.IsFalse(FInicializador.Conexao.Connected)`; `:304` - `Assert.Contains(LMensagem, 'Atualize o CadCli.exe')`; `:899` - `Assert.Contains(LConteudo, 'CadCli.exe')` | PASS |
| C11 | nomes, larguras, PKs, FKs e unicidades exatos | `--run:TTestesMigracaoInicial.CriaEsquemaComMetadadosExatos` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:789` - `Assert.AreEqual(COLUNAS_ESPERADAS, LinhasSQL(..., SQL_COLUNAS))` (literal em `:757-766`); `:791` - `Assert.AreEqual(RESTRICOES_ESPERADAS, ...)` (`:774-779`); `:793` - `Assert.AreEqual(REFERENCIAS_ESPERADAS, ...)` (`:786-787`) | PASS |
| C12 | 4 estados e 12 cidades, 3 por estado | `--run:TTestesMigracaoInicial.InsereEstadosECidadesDeReferencia` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:804` - `Assert.AreEqual` do literal com os 12 pares, de `Minas Gerais/MG:Belo Horizonte` a `Bahia/BA:Vitória da Conquista`, contra `LReferencias`; `:810` - `Assert.AreEqual(4, ... HAVING COUNT(*)=3)` | PASS |
| C13 | segunda inicialização: zero DDL, referência intacta | `--run:TTestesInicializadorBanco.SegundaExecucaoNaoAlteraEsquemaNemReferencia` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:325` - `Assert.AreEqual(0, LQuantidadeDDL)`; `:327-329` - `Assert.AreEqual(4, ... ESTADO)`, `(12, ... CIDADE)`, `(2, ... SCHEMA_VERSION)` | PASS |
| C14 | uma sequência por entidade, sem `MAX(ID)+1` | `--run:TTestesMigracaoInicial.CriaUmaSequenciaPorEntidadeSemMaxId` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:819` - `Assert.AreEqual(3, ... RDB$GENERATORS ... IN ('SEQ_CLIENTE','SEQ_ESTADO','SEQ_CIDADE'))`; `:826` - `Assert.IsFalse(TRegEx.IsMatch(LConteudo, 'MAX\s*\(\s*ID\s*\)\s*\+\s*1'))` | PASS |
| C15 | zero forms; inicialização com fakes sem VCL/FireDAC/DevExpress/ReportBuilder | `--run:TTestesArquiteturaFundacao.InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos` 1/1 exit 0 | `tests/Unitarios/Testes.InicializadorAplicacao.pas:74` - `Assert.AreEqual(0, Length(LArquivosForm))`; `:77-80` - `Assert.IsFalse(LCodigoInicializador.Contains('VCL.'/'FIREDAC.'/'DEVEXPRESS'/'REPORTBUILDER'))`; `:87` - `Assert.IsTrue(LInicializador.Inicializar(LMensagem))` | PASS |
| C16 | serviço recusando conexão: nada entregue, interface bloqueada, mensagem `Firebird 3` + endpoint, sem credenciais | `--run:TTestesInicializadorBanco.InformaServicoFirebirdIndisponivelSemLiberarAplicacao` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:373` - `Assert.IsFalse(LInicializadorAplicacao.Inicializar(LMensagem))`; `:374` - `Assert.IsFalse(LAutorizadorObjeto.Autorizado)`; `:376` - `Assert.IsFalse(Assigned(Conexao) and Conexao.Connected)`; `:381` - `Assert.Contains(LMensagem, 'Firebird 3')`; `:382` - `Assert.Contains(LMensagem, 'localhost:' + IntToStr(LPorta))`; `:383` - `AssegurarSemCredenciais` (`:171-173` - `SYSDBA`, `masterkey`, `password=`) | PASS |
| C17 | exe Release sem runtime local cria base completa, exit 0 | `--run:TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:697` e `:700` - cópia sem os 6 arquivos e 2 subdiretórios do runtime; `:705` - `Assert.IsTrue(LTerminou)`; `:707` - `Assert.AreEqual(Cardinal(0), LCodigoSaida)`; `:713` - `(2, ... SCHEMA_VERSION)`; `:715-717` - `(4, ESTADO)`, `(12, CIDADE)`, `(0, CLIENTE)`; `:718` - `Assert.AreEqual('Uberlândia', ...)` | PASS |
| C18 | `Migracao.VNNN.Descricao.pas` com `TMigracaoNNNDescricao` derivada de `TMigracaoBanco`, pelo menos 2 versões | `--run:TTestesConvencaoMigracoes.CadaVersaoTemUnitEClasseNoFormatoDefinido` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:665` - `Assert.IsTrue(LConteudo.Contains(LClasseEsperada + ' = class(TMigracaoBanco)'))`; `:668` - `Assert.IsTrue(LQuantidade >= 2)`; compilação no executável corroborada por `:713` (C17: o exe registra 2 versões) | PASS |
| C19 | sequências continuam após a referência; `SEQ_CLIENTE` positiva | `--run:TTestesMigracaoInicial.SequenciasContinuamDepoisDosDadosDeReferencia` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:839` - `LProximoEstado > MAX(ID) FROM ESTADO`; `:844` - `LProximaCidade > MAX(ID) FROM CIDADE`; `:847` - `NEXT VALUE FOR SEQ_CLIENTE > 0` | PASS |
| C20 | recusa no exe: exit 1, sem diálogo, `cadcli-erro.log` com instante e causa, sem credenciais | `--run:TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro` 1/1 exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:891` - `Assert.IsTrue(LTerminou)`; `:893` - `Assert.AreEqual(Cardinal(1), LCodigoSaida)`; `:895` - `Assert.IsTrue(TFile.Exists(LRegistro))`; `:898` - `Assert.Contains(LConteudo, '999')`; `:901` - `AssegurarSemCredenciais(LConteudo, ...)`; `:905` e `:908` - instante entre `LInicio` e `LFim` | PASS |
| C21 | bootstrap cria só `SCHEMA_VERSION` em transação própria, sem registrar, reverte na falha | `--run:TTestesBootstrapTabelaVersoes.CriaTabelaEmTransacaoPropriaSemRegistrarVersao` e `...ReverteBootstrapQuandoCriacaoFalha` 1/1 cada, exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:60-62` - `'INICIAR'`, `StartsWith('CREATE TABLE SCHEMA_VERSION')`, `'CONFIRMAR'`; `:63` - `Assert.AreEqual(0, MaiorVersaoInstalada)`; `:84-86` - `(1, Operacoes.Count)`, `('REVERTER', Operacoes[0])`, `(0, MaiorVersaoInstalada)` | PASS |
| C24 | produção sem `fbclient.dll`, `VendorLib`, `Embedded`; `masterkey` só na unit de conexão | `--run:TTestesArquiteturaFundacao.ProducaoNaoReferenciaRuntimeEmbeddedNemEspalhaCredenciais` 1/1 exit 0 | `tests/Unitarios/Testes.InicializadorAplicacao.pas:110` - `Assert.IsFalse(LConteudo.Contains('FBCLIENT.DLL'))`; `:112` - `...('VENDORLIB')`; `:114` - `...('EMBEDDED')`; `:119` - `Assert.AreEqual(UNIT_CONEXAO, TPath.GetFileName(LArquivo))`; `:123` - `Assert.AreEqual(1, LUnitsComSenha)` | PASS |

Provas ligadas ao diff: os testes novos ou reescritos em `5d49414..HEAD` são C4, C16, C17, C20, C22, C23 e C24 (`Testes.IntegracaoFirebird.pas`, `Testes.EntregaRunner.pas`, `Testes.InicializadorAplicacao.pas`); as demais provas não mudaram, mas todas passaram a construir `TInicializadorBanco` sem `VendorLib` e, portanto, exercitam o serviço no `HEAD`. Varredura de ausência: `grep -rn "masterkey\|SYSDBA" src CadCli.dpr` encontra somente `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:100-101`.

Observações sem efeito sobre o veredito:

- C18 afirma "compiladas no executável"; o teste citado conta units em `src/Migracoes` e não inspeciona o binário. A parte "compilada" fica provada em conjunto com C17 (`Testes.IntegracaoFirebird.pas:713`, o executável registra as duas versões). Não é lacuna, mas a prova de C18 sozinha não bastaria.
- `Password=masterkey` do door 2 não tem asserção própria; fica provado indiretamente pela autenticação bem-sucedida como `SYSDBA` em `Testes.IntegracaoFirebird.pas:346` (uma senha errada impede a conexão e derruba `PrepararBanco` em `:265`).
- AC 11 ("encerrar com código 1") no caso específico de serviço indisponível não é exercido no executável, conforme decisão registrada em `checks.md` (Handoff, "Settled mid-build"). O ramo de falha do executável não depende do tipo de erro: `CadCli.dpr:47-50` define `ExitCode := 1` e chama `RegistrarErroInicializacao` para qualquer `Inicializar = False`, e esse ramo é provado por C20; a mensagem de indisponibilidade é provada por C16. Aceito como coberto.

## Coverage

*Recomputado em `a99e73a` a partir da autoridade de cada conjunto.*

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| campos de `CLIENTE` (10) | `.specs/Teste Programador Delphi 2026.md`, item 4 | os 10 campos com tipo e largura em `COLUNAS_ESPERADAS` - C11 `Testes.IntegracaoFirebird.pas:789` | - |
| campos de `ESTADO` (3) e `CIDADE` (3) | especificação, item 4 | `ID`/`NOME`/`UF` e `ID`/`NOME`/`ESTADOID` - C11 `Testes.IntegracaoFirebird.pas:789` | - |
| estados de referência (4) | especificação, item 4 | MG, SP, RJ, BA - C12 `Testes.IntegracaoFirebird.pas:804` | - |
| cidades de referência (12) | plano AC 9 | as 12 cidades nomeadas, 3 por estado - C12 `:804`, `:810` | - |
| restrições relacionais (5) | plano `Relations` e door 4 | `UQ_ESTADO_UF`, `UQ_CIDADE_ESTADO_NOME`, `FK_CIDADE_ESTADO`, `FK_CLIENTE_CIDADE` - C11 `:791`/`:793`; versão única `PK_SCHEMA_VERSION` - C11 `:791` | - |
| parâmetros de conexão do door 2 (10) | plano `Landing` door 2 e código `Infraestrutura.InicializadorBancoFireDAC.pas:96-104` | `DriverID` C23 `:348` · `Server` C23 `:349` · `Port` C23 `:350` · `User_Name` C23 `:346` · `Password` indireto C23 `:346` · `OpenMode` C23 `:351` · Dialect 3 C4 `:282` · UTF8 C4 `:286` · caminho absoluto C4 `:278` e `CadCli.dpr:42` via C17 `:708` · sem `VendorLib` C23 `:352`/C24 `:112` | - |
| runtime Firebird ausente da entrega (8) | AD-007 e `AGENTS.md` | 6 padrões de arquivo e `plugins`/`intl` - C22 `Testes.EntregaRunner.pas:93`/`:96`; repetidos na cópia de C17 `Testes.IntegracaoFirebird.pas:697`/`:700` | - |
| prova de acesso pelo serviço (3) | AD-007 | protocolo TCP C23 `:337` · loopback C23 `:344` · exe sem runtime local cria base C17 `:708` | - |
| estados da inicialização (6) | plano AC 3, 5, 6, 7, 10, 11 e código `Infraestrutura.InicializadorBancoFireDAC.pas:129-155`, `Aplicacao.ExecutorMigracoes.pas:73-95` | ausente C4 `:272`/`:289` · anterior C7 `:552` · atual C13 `:325` · falha C9 `:589` · futura C10 `:302` · indisponível C16 `:373` | - |
| critérios de aceitação (11) | plano `Criteria` | AC1 C1/C2 · AC2 C3 · AC3 C4/C17 · AC4 C5 · AC5 C6/C7/C8 · AC6 C9/C20 · AC7 C10/C20 · AC8 C11 · AC9 C12 · AC10 C13 · AC11 C16 (mensagem) + C20 (ramo de saída 1 compartilhado, `CadCli.dpr:49`) | - |
| one-way doors de `Landing` (6) | plano `Landing` | door 1 C1/C2 · door 2 C4/C22/C23 · door 3 C5/C18 · door 4 C11 · door 5 C15 · door 6 C21 | - |
| sequências de ID (3) e continuidade (3) | plano `Assumptions` | `SEQ_CLIENTE`/`SEQ_ESTADO`/`SEQ_CIDADE` C14 `:819`; continuidade C19 `:839`/`:844`/`:847` (código `Migracao.V002.DadosReferencia.pas:63-64`) | - |
| credenciais nunca expostas (3) | `AGENTS.md` Persistência e plano `Observable` | mensagem de indisponibilidade C16 `:383` · `cadcli-erro.log` C20 `:901` · `masterkey` restrito C24 `Testes.InicializadorAplicacao.pas:119`/`:123` | - |
| falha observável no executável (4) | plano `Flow` out e `Observable` | exit 1 C20 `:893` · sem diálogo travado C20 `:891` · log com instante e causa C20 `:895`/`:898`/`:905` · log sem credenciais C20 `:901` | - |
| assemblies de inicialização (2) | `CadCli.dpr` e `tests/CadCli.Testes.dpr` lidos diretamente | `CadCli.dpr:41-43` monta `TInicializadorBanco` só com caminho e catálogo (porta padrão 3050), exercido por C17/C20; runner sem forms C3 `Testes.EntregaRunner.pas:104` | - |
| metadados de `SCHEMA_VERSION` (3) | plano door 3 | `VERSAO`/`DESCRICAO`/`APLICADA_EM` - C5 `Testes.CatalogoExecutor.pas:143`, `APLICADA_EM` real C5 `Testes.IntegracaoFirebird.pas:626`/`:628`; tipos C11 `:765-766` | - |

Varredura de conjuntos sem linha: `Surface` é `None`, então não há rotas ou status. As enumerações nomeadas em `Landing`, `Relations`, `Impact` e nas claims estão todas acima. Nenhum membro sem prova.

## Test policy rows

*Julgado em `a99e73a`.*

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decide e é alcançado pela inicialização | `Infraestrutura.InicializadorBancoFireDAC.pas`, `Aplicacao.ExecutorMigracoes.pas` | limite do serviço: C4, C7, C9, C10, C13, C16 · próprio nível (fakes): C5, C7, C9, C21 · uma asserção por estado conforme a linha "estados da inicialização" em Coverage | yes |
| Decide sem cruzar o Firebird | `Aplicacao.CatalogoMigracoes.pas`, `Aplicacao.ExecutorMigracoes.pas` (ordem e pendência), `Aplicacao.InicializadorAplicacao.pas` | unitária: catálogo C6 (duplicada e ordem), pendência e ordem C7, liberação C8 (ramos falso e verdadeiro em `Testes.InicializadorAplicacao.pas:52`/`:56`) | yes |
| Entrada que apenas delega (`CadCli.exe`) | `CadCli.dpr` | artefato entregue: sucesso sem runtime local C17, recusa com código 1 e log C20; indisponibilidade provada no inicializador com FireDAC real C16 | yes |
| Instrumentação sem condição | `Infraestrutura.RegistroErroInicializacao.pas`, observador SQL de `Infraestrutura.ContextoMigracaoFireDAC.pas` | coberta pelos consumidores C20 e C13 | yes |
| Metadados persistidos | `Migracao.V001.EsquemaInicial.pas`, `Migracao.V002.DadosReferencia.pas` | consultas reais a `RDB$RELATION_FIELDS`, `RDB$RELATION_CONSTRAINTS`, `RDB$GENERATORS`: C11, C14, C19 | yes |

## Swept existing

Nenhuma linha de `Swept` em `checks.md` resolve para `existing`: todas citam checks (validados acima) ou são `n/a` aprovados pelo usuário (authorization, concurrency). Nada a reler no código.

## Faults injected

Isolamento: `git worktree add --detach <scratchpad>\wt HEAD`; baseline de `git status --porcelain` do real tree vazio. Cada fault foi aplicado no worktree, seguido de rebuild completo (Release + testes, exit 0) e da prova mais estreita; depois `git checkout -- .` no worktree. Ao final, `git worktree remove --force` e `git status --porcelain` do real tree vazio, igual ao baseline.

| Mutation | Location | Killed |
| --- | --- | --- |
| reintroduz `Params.Values['VendorLib'] := <dir do exe>\fbclient.dll` | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:104` (linha inserida) | yes - C24 vermelho ("não pode referenciar fbclient.dll") e C23 vermelho (`Expected [] but got [...\fbclient.dll]`) |
| remove `Server` e `Port` da conexão | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:97-98` | yes - C23 vermelho em `MON$REMOTE_PROTOCOL` ("deve chegar pelo serviço via TCP") |
| vaza o usuário do serviço na mensagem de falha (`E.Message + ' (conectado como ' + User_Name + ')'`) | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:152` | yes - C16 vermelho ("não pode expor o usuário do serviço") e C20 vermelho no `cadcli-erro.log` |
| coloca `fbclient.dll` ao lado do `CadCli.exe` Release | `bin\Win64\Release\fbclient.dll` (worktree) | yes - C22 vermelho (`Expected [0] but got [1]`) e C17 vermelho na cópia da entrega |
| troca `CharacterSet` `UTF8` -> `WIN1252` | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:104` | yes - C4 vermelho (`Expected [UTF8] but got [WIN1252]`) |

Cinco faults (limite do procedimento), todos no surface alterado pelo diff; cada um derrubou uma prova diferente (C24, C23, C16, C20, C22, C17, C4).

## Gate

`.\tests\bin\Win64\Debug\CadCli.Testes.exe --exitbehavior:Continue` no `HEAD` `a99e73a` - 29 passed, 0 failed, 0 errored, 0 ignored, 0 leaked, exit 0.

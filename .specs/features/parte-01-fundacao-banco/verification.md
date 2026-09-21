# Parte 01 - Fundação e banco versionado verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 251ac8d..fab9a2f
**Fix diff**: 2ff46ee..fab9a2f
**Round**: 4 - scoped
**Verifier**: independent sub-agent (author != verifier)

O `HEAD` verificado foi `fab9a2f50f3604209335c682d0554b336df6c23d`. A reverificação foi delimitada pelo fix diff e pelos FAILs anteriores C4, C13, C14, C15, C16, C20, door 6/C21, três linhas de `Test policy`, fault injection e isolamento. Todas as provas foram reexecutadas em lote no novo `HEAD`; as conclusões não afetadas foram carregadas de `2ff46ee11bf405e2d0bb46adc6d4fa6569df5bfb` com suas provas novamente verdes.

## Binding sources

*Verificado em `fab9a2f`; a troca do PDF pelo Markdown é parte do baseline do usuário e foi preservada.*

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| `.specs/Teste Programador Delphi 2026.md`, itens 1-4 e entregas | yes - arquivo inteiro aberto no real tree | none - permite Delphi 12, exige FireDAC, Firebird 3.0, DevExpress nas telas futuras e fixa os campos/tipos de `CLIENTE`, `ESTADO` e `CIDADE`; C1-C2, C4, C11 e C15 são compatíveis | - |
| `.specs/Teste Programador Delphi 2026.md`, item 4, dados de referência | yes - tabela e lista abertas | none - exige os quatro estados e algumas cidades; C12 prova os quatro estados e as doze cidades escolhidas no plano | - |

Enumeração por tela: **no screen rows**. `plan.md` declara `Surface: None`; a Parte 01 não contém `.dfm` e C15 assere zero forms próprias em `tests/Unitarios/Testes.InicializadorAplicacao.pas:71`. Não há cópia, controles, ordem, contagem ou arranjo visual para enumerar. O walkthrough com o usuário é não aplicável a esta parte de infraestrutura.

As URLs de documentação do plano não estão marcadas como fontes vinculantes e não integram esta comparação estreita.

## Checks

*Provas reexecutadas em `fab9a2f`. A suíte integral encontrou e executou os 27 testes registrados: 27 passaram, 0 falharam, 0 tiveram erro, 0 foram ignorados e 0 vazaram. Os 25 seletores citados pelos 21 checks existem; seletores compartilhados por checks foram executados uma vez no lote.*

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | Release produz somente `CadCli.exe` Win64/AMD64 e não declara Win32 | `TTestesEntregaRelease.ProduzCadCliExeSomenteParaWin64`, suite exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:57` - arquivo existe; `:59` - `Assert.AreEqual(Word($8664), ...)`; `:62` - `Assert.IsFalse(LProjeto.Contains('Win32'))` | PASS |
| C2 | runtime packages desabilitados, zero BPL e zero executáveis auxiliares | `TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar`, suite exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:70` - um `.exe`; `:72` - zero `.bpl`; `:74` - projeto contém `DCC_UsePackage=false` | PASS |
| C3 | runner Win64, código 0 e zero forms | `TTestesRunnerDUnitX.ExecutaEmWin64SemCriarForm`, suite exit 0 | `tests/Unitarios/Testes.EntregaRunner.pas:80` - PE AMD64; `:82` - `Assert.AreEqual(0, Screen.FormCount)`; execução integral exit 0 | PASS |
| C4 | base ausente é criada ao lado do executável com Firebird 3, Dialect 3, UTF8 e versão atual | `TTestesInicializadorBanco.CriaBaseAoLadoDoExecutavelComConfiguracaoEsperada` e `TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:219` - arquivo no caminho informado; `:221-225` - motor 3, Dialect 3, UTF8 e versão 2; `:598-608` - o processo copia a entrega e cria `cadcli.fdb` ao lado de `CadCli.exe` | PASS |
| C5 | uma linha por migração, com versão, descrição e instante real, na mesma transação | três seletores de C5, suite exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:142-144` - versão/descrição/instante; `:174-176` - rollback do registro; `tests/Unitarios/Testes.IntegracaoFirebird.pas:532-535` - instante persistido dentro da janela real | PASS |
| C6 | catálogo rejeita duplicidade e ordena versões | `TTestesCatalogoMigracoes.RejeitaDuplicadasEOrdenaVersoes`, suite exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:100-102` - ordem 1/2; `:110` - duplicada rejeitada | PASS |
| C7 | executa apenas pendentes, uma vez e em ordem crescente | dois seletores de C7, suite exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:221-227` - pendentes 2/4 uma vez e versão 1 ausente; `tests/Unitarios/Testes.IntegracaoFirebird.pas:458-462` - versões 1/2 no Firebird real | PASS |
| C8 | aplicação só é autorizada depois da persistência | `TTestesInicializadorAplicacao.LiberaAplicacaoSomenteDepoisDasMigracoes`, suite exit 0 | `tests/Unitarios/Testes.InicializadorAplicacao.pas:49-55` - falha não autoriza e sucesso autoriza | PASS |
| C9 | falha reverte alteração e registro e identifica a versão | dois seletores de C9, suite exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:258-260` - versão ausente, rollback e mensagem; `tests/Unitarios/Testes.IntegracaoFirebird.pas:482-502` - nenhuma tabela/versão da migração falha no Firebird | PASS |
| C10 | versão futura fecha a conexão e orienta atualização | dois seletores de C10, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:236-239` - falso, conexão fechada e orientação; `:808-817` - processo encerra 1 e log identifica 999/`CadCli.exe` | PASS |
| C11 | esquema exato com tabelas, campos, larguras, PKs, FKs e unicidades | `TTestesMigracaoInicial.CriaEsquemaComMetadadosExatos`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:697-702` - compara impressões digitais completas de colunas, restrições e referências | PASS |
| C12 | quatro estados, doze cidades e três por estado | `TTestesMigracaoInicial.InsereEstadosECidadesDeReferencia`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:712-719` - compara os 12 pares exatos e quatro grupos com contagem 3 | PASS |
| C13 | segunda inicialização executa zero DDL e não duplica dados/versões | `TTestesInicializadorBanco.SegundaExecucaoNaoAlteraEsquemaNemReferencia`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:253-261` - observador conta `CREATE/ALTER/DROP/RECREATE` e exige zero; `:262-264` - 4 estados, 12 cidades, 2 versões | PASS |
| C14 | três sequências e nenhuma estratégia `MAX(ID) + 1` | `TTestesMigracaoInicial.CriaUmaSequenciaPorEntidadeSemMaxId`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:727-729` - três sequências; `:730-736` - regex case-insensitive tolerante a espaços proíbe `MAX\\s*\\(\\s*ID\\s*\\)\\s*\\+\\s*1` em todo `src` | PASS |
| C15 | zero forms e inicializador de aplicação sem VCL/FireDAC/DevExpress/ReportBuilder, exercitado com fakes | `TTestesArquiteturaFundacao.InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos`, suite exit 0 | `tests/Unitarios/Testes.InicializadorAplicacao.pas:71-78` - zero `.dfm` e ausência das quatro dependências no código do inicializador; `:79-86` - inicializa apenas com interfaces falsas | PASS |
| C16 | ausência de `fbclient.dll` não entrega conexão nem autoriza UI e identifica Firebird no executável/log | dois seletores de C16, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:283-289` - inicializador de aplicação retorna falso, não autoriza, não cria conexão e nomeia a dependência; `:841-853` - `CadCli.exe` sem DLL encerra 1, não cria base e grava os dois identificadores no log | PASS |
| C17 | executável entregue cria base completa ao lado, encerra 0 e preserva UTF8 | `TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:602-608` - término, exit 0 e arquivo; `:621-628` - 2 versões, 4 estados, 12 cidades, 0 clientes e `Uberlândia` | PASS |
| C18 | units/classes seguem a convenção e ao menos duas versões estão compiladas | `TTestesConvencaoMigracoes.CadaVersaoTemUnitEClasseNoFormatoDefinido`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:560-574` - valida versão, descrição, classe derivada e quantidade mínima | PASS |
| C19 | sequências continuam depois dos dados de referência | `TTestesMigracaoInicial.SequenciasContinuamDepoisDosDadosDeReferencia`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:747-756` - próximos ESTADO/CIDADE excedem máximos e CLIENTE é positiva | PASS |
| C20 | recusa do executável encerra 1 e grava causa e instante real no log | `TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro`, suite exit 0 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:808-817` - encerra, exit 1, log, causa; `:818-826` - instante do log fica entre início e fim da execução recusada | PASS |
| C21 | bootstrap cria somente `SCHEMA_VERSION` em transação própria, não registra versão e reverte na falha | dois seletores de C21, suite exit 0 | `tests/Unitarios/Testes.CatalogoExecutor.pas:60-64` - `INICIAR`, único `CREATE TABLE SCHEMA_VERSION`, `CONFIRMAR`, versão zero; `:83-86` - falha observada, rollback e versão zero | PASS |

Resultado: **21/21 checks provados com evidência localizada**. Os FAILs anteriores C4, C13, C14, C15, C16 e C20 estão fechados; C21 fecha o door 6.

## Coverage

*Recomputada em `fab9a2f` para as autoridades tocadas pelo fix; linhas não afetadas foram carregadas de `2ff46ee` após a suíte integral verde.*

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| artefato da aplicação (5) | door 1 + `CadCli.dproj` | Win64/AMD64/`CadCli.exe` C1; packages/BPL/auxiliar C2 | - |
| configuração da base (7) | door 2 + `CadCli.dpr:41-44` + parâmetros FireDAC | `DriverID=FB`, Firebird 3, `OpenOrCreate`, Dialect 3, UTF8, `cadcli.fdb`, diretório do executável -> C4/C17 | - |
| estados de inicialização (5) | `Flow` + S2 | ausente C4/C17; anterior C7; atual C13; falha C9; futura C10/C20 | - |
| metadados de `SCHEMA_VERSION` (3) | doors 3/6 | `VERSAO`, `DESCRICAO`, `APLICADA_EM` -> C5/C7/C11 | - |
| entidades de `Relations` (5) | `Relations` | ESTADO/CIDADE/CLIENTE/SCHEMA_VERSION C11; linha MIGRACAO_APLICADA C5 | - |
| campos de `CLIENTE` (10) | Markdown vinculante, item 4 | dez campos, tipos e larguras -> C11 | - |
| campos de `ESTADO` (3) | Markdown vinculante, item 4 | ID/NOME/UF -> C11 | - |
| campos de `CIDADE` (3) | Markdown vinculante, item 4 | ID/NOME/ESTADOID -> C11 | - |
| restrições relacionais (5) | `Relations` + door 4 | unicidades, duas FKs e versão única -> C11/C5 | - |
| sequências (3) | assumption de IDs | SEQ_CLIENTE/SEQ_ESTADO/SEQ_CIDADE -> C14/C19 | - |
| estados de referência (4) | Markdown vinculante, item 4 | MG/SP/RJ/BA -> C12 | - |
| cidades de referência (12) | AC 9 | doze cidades exatas -> C12 | - |
| assemblies de inicialização (2) | `CadCli.dpr` e `tests/CadCli.Testes.dpr` | entrada real C16/C17/C20; runner C3 | - |
| resultados de falha (3) | `Flow out` | versão na falha C9; atualização C10/C20; dependência e não autorização C16 | - |
| falha observável do executável (3) | C20 | exit 1, encerramento e log com causa/instante -> C20 | - |
| one-way doors (6) | `Landing` | doors 1-5 -> C1/C2, C4/C17, C5/C18, C11, C15; door 6 -> C21 | - |

Não há conjunto de rota/status porque `Surface` é `None`.

## Test policy rows

*Rejulgadas em `fab9a2f`; as três linhas anteriormente não atendidas agora estão atendidas.*

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decide e é alcançado pela inicialização | executor e inicializador FireDAC | limite Firebird + próprio nível; ausente C4/C17, anterior C7, atual C13, falha C9, futura C10/C20 | yes |
| Decide sem cruzar o Firebird | catálogo, executor e inicializador de aplicação | unitária por ramo; C6-C9 cobrem unicidade, ordem, pendência, rollback e liberação | yes |
| Entrada que apenas delega | `CadCli.dpr` | sucesso C17, futura C20 e dependência C16 no próprio processo entregue | yes |
| Instrumentação sem condição | registro de erro | consumidor C20 prova arquivo, causa e instante; C16 prova o conteúdo de dependência | yes |
| Metadados persistidos | migrações + contexto FireDAC | C5, C11, C12, C14 e C19 consultam cada membro enumerado no Firebird real | yes |

## Swept existing

*Re-lido em `fab9a2f`; resultados não afetados carregados de `2ff46ee`.*

| Dimension | Re-read | Result |
| --- | --- | --- |
| validation | catálogo, versão futura, esquema, convenção e regex de IDs | presente; C14 cobre grafias equivalentes com espaços/case |
| failure modes | rollback, futura, dependência e saída | presente; C16 chega ao autorizador e ao executável |
| idempotency | pendências e segunda inicialização | presente; C13 observa e exige zero DDL |
| authorization | `n/a` aprovado | aplicação local sem autenticação |
| concurrency | `n/a` aprovado | plano não promete inicialização simultânea |
| data lifecycle | criação, reabertura, referência e sequências | presente |
| dependency failure | Firebird ausente | presente no inicializador de aplicação e no executável entregue |
| state transitions | ausente/anterior/atual/falha/futura | todos os membros exercitados nos níveis exigidos |
| observability | mensagens, exit code e log | causa e instante do log provados |

## Faults injected

*Cinco mutações em worktree destacada de `fab9a2f`; cada arquivo foi restaurado entre experimentos e a worktree foi removida ao final.*

| Mutation | Location | Killed |
| --- | --- | --- |
| remove `IniciarTransacao` do bootstrap | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:51` | yes - `TTestesBootstrapTabelaVersoes.CriaTabelaEmTransacaoPropriaSemRegistrarVersao` falhou: esperava `INICIAR` |
| executa `ALTER TABLE SCHEMA_VERSION ...` depois das migrações, inclusive na segunda inicialização | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:127` | yes - `TTestesInicializadorBanco.SegundaExecucaoNaoAlteraEsquemaNemReferencia` obteve DDL 1 em vez de 0 |
| remove os identificadores `Firebird Embedded 3 x64` da mensagem de dependência | `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas:139` | yes - `TTestesAplicacaoRelease.ExecutavelReleaseSemFirebirdEncerraERegistraOErro` não encontrou o identificador no log |
| substitui `Now` por `2000-01-01` no instante de `cadcli-erro.log` | `src/Infraestrutura/Infraestrutura.RegistroErroInicializacao.pas:36` | yes - `TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro` rejeitou instante anterior à execução |
| persiste `APLICADA_EM=2000-01-01` em vez do instante recebido | `src/Infraestrutura/Infraestrutura.ContextoMigracaoFireDAC.pas:133` | yes - `TTestesMigracaoNoFirebird.RegistraInstanteRealDaAplicacaoEmAplicadaEm` rejeitou instante anterior à janela |

## Baseline isolation

Baseline do real tree antes da worktree: PDF removido; Markdown novo; `plan.md` das Partes 01-05 e `AGENTS.md` modificados; `verification.md` não rastreado. Após as cinco mutações e a remoção de `C:\Projetos\Jean\CadCli\.verifier-parte01`, `git status --porcelain=v1` retornou exatamente o mesmo conjunto. Nenhum arquivo do real tree foi restaurado ou alterado pelo Verifier além deste relatório.

## Gate

- `MSBuild.exe CadCli.dproj /t:Build /p:Config=Release /p:Platform=Win64` - exit 0, Delphi 12 Win64.
- `MSBuild.exe tests/CadCli.Testes.dproj /t:Build /p:Config=Debug /p:Platform=Win64` - exit 0.
- `.\\tests\\bin\\Win64\\Debug\\CadCli.Testes.exe` - exit 0, 27 found, 27 passed, 0 failed, 0 errored, 0 ignored, 0 leaked. A primeira tentativa dentro do sandbox foi inválida por `CreateFile: Acesso negado`; a execução oficial foi repetida fora do sandbox e passou.
- `validate_verification.py parte-01-fundacao-banco` - exit 0, 0 errors, 0 warnings.

## Ranked gaps

None - todos os checks, membros de coverage, linhas de policy e mutantes estão fechados nesta rodada.

# Parte 01 - Fundação e banco versionado checks

Profile: ui
Plan: `.specs/features/parte-01-fundacao-banco/plan.md`

24 checks em 2 slices · 6 one-way doors · 0 questões abertas, 0 bloqueantes para escrever código

Revisão 2026-09-21 (AD-007, AD-008): substitui o Firebird Embedded pelo serviço local do Firebird 3. C1-C15 e C17-C21 mantêm a numeração; C4, C16, C17 e C20 foram reescritos; C22-C24 são novos.

## Checks

### S1 - Projeto compilável e testável · retrabalho: 1 arquivo × 2,6 KB · ~1k tokens

**C1** - O build `Release` produz `CadCli.exe` com cabeçalho PE `AMD64` e não produz uma variante Win32 (S1, AC 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesEntregaRelease.ProduzCadCliExeSomenteParaWin64`

**C2** - A configuração `Win64 Release` mantém runtime packages desabilitados e o diretório distribuível contém zero arquivos `.bpl` e zero executáveis além de `CadCli.exe` (S1, AC 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar`

**C3** - O runner `CadCli.Testes.exe` é Win64, termina com código `0` no teste de sanidade e mantém `Screen.FormCount = 0` (S1, AC 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRunnerDUnitX.ExecutaEmWin64SemCriarForm`

**C22** - O diretório distribuível de `CadCli.exe` contém zero arquivos do runtime Firebird: nenhum `fbclient.dll`, `ib_util.dll`, `icu*.dll`, `firebird.msg`, `firebird.conf`, `plugins.conf` e nenhum subdiretório `plugins` ou `intl` (door 2; AD-007)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesEntregaRelease.NaoDistribuiRuntimeFirebirdAoLadoDoExecutavel`

### S2 - Base criada e migrada na inicialização · retrabalho: 5 arquivos × 40,5 KB · ~10k tokens

**C4** - Sem `cadcli.fdb`, a inicialização pede ao serviço em `localhost:3050` a criação de exatamente `<diretório do executável>\cadcli.fdb`, e a base resultante tem `MON$SQL_DIALECT = 3`, charset padrão `UTF8`, ODS 12 (Firebird 3) e termina na versão mais recente do catálogo (S2, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesInicializadorBanco.CriaBaseAoLadoDoExecutavelComConfiguracaoEsperada`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado`

**C23** - A conexão aberta pelo `TInicializadorBanco` de produção aparece em `MON$ATTACHMENTS` com `MON$REMOTE_PROTOCOL` TCP (`TCPv4` ou `TCPv6`), endereço remoto de loopback e usuário `SYSDBA`, e seus parâmetros FireDAC são `DriverID=FB`, `Server=localhost`, `Port=3050`, `OpenMode=OpenOrCreate`, sem `VendorLib` apontando para o diretório do executável (door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesInicializadorBanco.ConectaPeloServicoLocalEmLocalhost3050`

**C5** - Após uma migração bem-sucedida, `SCHEMA_VERSION` contém exatamente uma linha para ela, com `VERSAO`, `DESCRICAO` e `APLICADA_EM` não nulos e iguais aos valores fornecidos pela migração (S2, AC 4)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesExecutorMigracoes.RegistraUmaLinhaComMetadadosDaMigracao`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesExecutorMigracoes.ReverteAlteracaoERegistroNaMesmaTransacao`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoNoFirebird.RegistraInstanteRealDaAplicacaoEmAplicadaEm`

**C6** - `TCatalogoMigracoes` rejeita versões duplicadas e entrega todas as versões registradas em ordem numérica crescente (S2, AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesCatalogoMigracoes.RejeitaDuplicadasEOrdenaVersoes`

**C7** - Para uma base anterior, `TExecutorMigracoes` executa cada versão pendente exatamente uma vez, em ordem crescente, e não executa versões já registradas (S2, AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesExecutorMigracoes.ExecutaSomentePendentesUmaVezEmOrdemCrescente`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoNoFirebird.AplicaSomenteAPendenteSobreBaseAnterior`

**C8** - `TInicializadorAplicacao` só informa persistência pronta depois que a última migração pendente termina e, antes disso, não autoriza a abertura da interface principal (S2, AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesInicializadorAplicacao.LiberaAplicacaoSomenteDepoisDasMigracoes`

**C9** - Se uma instrução de uma migração falhar, todas as alterações dessa migração e seu registro em `SCHEMA_VERSION` permanecem ausentes, e o erro informa a versão exata que falhou (S2, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesExecutorMigracoes.ReverteAlteracaoERegistroEInformaVersaoNaFalha`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoNoFirebird.ReverteMigracaoInvalidaNoFirebirdEInformaVersao`

**C10** - Se `SCHEMA_VERSION` contiver uma versão maior que a maior versão do catálogo, a conexão não é entregue aos repositórios e o resultado informa que `CadCli.exe` precisa ser atualizado (S2, AC 7)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesInicializadorBanco.RecusaVersaoFuturaEOrientaAtualizacao`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro`

**C11** - A migração inicial cria `CLIENTE`, `ESTADO`, `CIDADE` e `SCHEMA_VERSION` com todos os nomes, larguras, chaves primárias, chaves estrangeiras e unicidades definidos no plano (S2, AC 8)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoInicial.CriaEsquemaComMetadadosExatos`

**C12** - A migração inicial insere os quatro estados e as doze cidades especificadas, com exatamente três cidades associadas a cada estado (S2, AC 9)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoInicial.InsereEstadosECidadesDeReferencia`

**C13** - Em uma segunda inicialização já na versão suportada, são executadas zero instruções DDL e continuam existindo quatro estados, doze cidades e uma linha por versão em `SCHEMA_VERSION` (S2, AC 10)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesInicializadorBanco.SegundaExecucaoNaoAlteraEsquemaNemReferencia`

**C14** - `CLIENTE`, `ESTADO` e `CIDADE` possuem uma sequência Firebird própria para geração de `ID`, e nenhuma migração ou repositório usa `MAX(ID) + 1` (Assumption: criação de IDs)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoInicial.CriaUmaSequenciaPorEntidadeSemMaxId`

**C15** - A Parte 01 contém zero forms próprias e sua inicialização pode ser exercitada com dependências falsas sem carregar VCL, DevExpress, ReportBuilder ou uma conexão FireDAC concreta (door 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaFundacao.InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos`

**C16** - Com o endpoint do serviço recusando a conexão (porta local sem listener, injetada no `TInicializadorBanco` de produção com FireDAC real), a inicialização não entrega conexão, não autoriza a interface principal e retorna uma mensagem que contém `Firebird 3` e `localhost:3050`/porta usada e não contém `SYSDBA`, `masterkey` nem `Password=` (S2, AC 11)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesInicializadorBanco.InformaServicoFirebirdIndisponivelSemLiberarAplicacao`

**C17** - O próprio `CadCli.exe` Release, executado em uma cópia da entrega sem `cadcli.fdb` e sem nenhum arquivo do runtime Firebird no diretório, encerra com código `0` sem diálogo travado e deixa ao seu lado uma base com as duas migrações registradas, 4 estados, 12 cidades, 0 clientes e acentuação preservada (S2, AC 3; Flow hop 1; door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado`

**C18** - Cada unit em `src/Migracoes` segue `Migracao.VNNN.Descricao.pas` e declara a classe `TMigracaoNNNDescricao` derivada de `TMigracaoBanco`, com pelo menos as duas versões da Parte 01 compiladas no executável (door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesConvencaoMigracoes.CadaVersaoTemUnitEClasseNoFormatoDefinido`

**C19** - Depois da carga de referência, a próxima chave de `SEQ_ESTADO` e de `SEQ_CIDADE` é maior que o maior `ID` já gravado na respectiva tabela, e `SEQ_CLIENTE` gera chaves positivas (Assumption: criação de IDs)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesMigracaoInicial.SequenciasContinuamDepoisDosDadosDeReferencia`

**C20** - Uma inicialização recusada pelo `CadCli.exe` entregue encerra o processo com código `1` em vez de ficar presa em um diálogo, e deixa em `cadcli-erro.log`, ao lado do executável, uma linha com o instante e a causa, sem `SYSDBA`, `masterkey` nem `Password=` (Flow out; AC 6, AC 7, AC 11)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro`

**C21** - Quando `SCHEMA_VERSION` não existe, o bootstrap cria somente essa tabela em uma transação própria, não registra versão e reverte integralmente se a criação falhar (door 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesBootstrapTabelaVersoes.CriaTabelaEmTransacaoPropriaSemRegistrarVersao`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesBootstrapTabelaVersoes.ReverteBootstrapQuandoCriacaoFalha`

**C24** - O código de produção não contém referência a `fbclient.dll`, `VendorLib` nem ao texto `Embedded`, e o texto `masterkey` aparece somente na unit que monta a conexão (AD-007; Observable: credenciais)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaFundacao.ProducaoNaoReferenciaRuntimeEmbeddedNemEspalhaCredenciais`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| artefato da aplicação (5) | `Win64 Release` C1 · `CadCli.exe` C1 · PE `AMD64` C1 · runtime packages desabilitados C2 · zero executáveis auxiliares/BPLs C2 | - |
| runtime Firebird ausente da entrega (8) | `fbclient.dll` C22 · `ib_util.dll` C22 · `icu*.dll` C22 · `firebird.msg` C22 · `firebird.conf` C22 · `plugins.conf` C22 · `plugins\` C22 · `intl\` C22 | - |
| parâmetros de conexão do door 2 (9) | `DriverID=FB` C23 · `Server=localhost` C23 · `Port=3050` C23 · `User_Name=SYSDBA` C23 · `OpenMode=OpenOrCreate` C23/C4 · Dialect 3 C4 · UTF8 C4 · caminho `<dir do exe>\cadcli.fdb` C4 · sem `VendorLib` local C23/C24 | - |
| prova de acesso pelo serviço (3) | protocolo remoto TCP C23 · endereço loopback C23 · executável sem runtime local cria a base C17 | - |
| estados da inicialização/migração (6) | base ausente C4 · base anterior C7 · base atual C13 · migração falha C9 · versão futura C10 · serviço indisponível C16 | - |
| metadados de `SCHEMA_VERSION` (3) | `VERSAO` C5/C7 · `DESCRICAO` C5/C7 · `APLICADA_EM` C5 no limite real | - |
| entidades de `Relations` (5) | `ESTADO` C11 · `CIDADE` C11 · `CLIENTE` C11 · `SCHEMA_VERSION` C5 · `MIGRACAO_APLICADA` como linha de `SCHEMA_VERSION` C5 | - |
| campos de `CLIENTE` (10) | `ID` C11 · `NOME` C11 · `CEP` C11 · `CPF_CNPJ` C11 · `ENDERECO` C11 · `NUMERO` C11 · `COMPLEMENTO` C11 · `BAIRRO` C11 · `CIDADE` C11 · `DATANASCIMENTO` C11 | - |
| campos de `ESTADO` (3) | `ID` INTEGER C11 · `NOME` VARCHAR(50) C11 · `UF` CHAR(2) C11 | - |
| campos de `CIDADE` (3) | `ID` INTEGER C11 · `NOME` VARCHAR(50) C11 · `ESTADOID` INTEGER C11 | - |
| restrições relacionais (5) | `ESTADO.UF` única C11 · `CIDADE(ESTADOID,NOME)` única C11 · FK `CIDADE.ESTADOID` C11 · FK `CLIENTE.CIDADE` C11 · versão de migração única C5 | - |
| sequências de ID (3) | `CLIENTE` C14 · `ESTADO` C14 · `CIDADE` C14 | - |
| continuidade das sequências após a referência (3) | `SEQ_ESTADO` livre C19 · `SEQ_CIDADE` livre C19 · `SEQ_CLIENTE` positiva C19 | - |
| estados de referência (4) | Minas Gerais/MG C12 · São Paulo/SP C12 · Rio de Janeiro/RJ C12 · Bahia/BA C12 | - |
| cidades de referência (12) | Belo Horizonte/MG C12 · Uberlândia/MG C12 · Contagem/MG C12 · São Paulo/SP C12 · Campinas/SP C12 · Santos/SP C12 · Rio de Janeiro/RJ C12 · Niterói/RJ C12 · Petrópolis/RJ C12 · Salvador/BA C12 · Feira de Santana/BA C12 · Vitória da Conquista/BA C12 | - |
| assemblies de inicialização (2) | entrada de `CadCli.exe` C17/C20 · harness de testes sem forms C3 | - |
| composição do `CadCli.exe` entregue (3) | cria a base ao lado do executável C17 · aplica o catálogo completo C17 · encerra sem diálogo de erro C17 | - |
| resultados de falha (3) | versão da migração C9 · aplicação precisa ser atualizada C10 · serviço Firebird indisponível C16 | - |
| falha observável no executável (4) | código de saída 1 C20 · processo encerra sem diálogo travado C20 · `cadcli-erro.log` com instante e causa C20 · log sem credenciais C20 | - |
| credenciais nunca expostas (3) | mensagem de serviço indisponível C16 · `cadcli-erro.log` C20 · `masterkey` restrito à unit de conexão C24 | - |
| one-way doors de `Landing` (6) | plataforma/artefato C1 · persistência por serviço local C4/C22/C23 · migrações no código C5/C18 · esquema inicial C11 · controladores testáveis com zero forms nesta parte C15 · bootstrap de `SCHEMA_VERSION` C21 | - |

- Nenhuma rota ou status de interface precisa de join: `Surface` é `None` nesta parte.
- C4, C5, C9, C10, C11, C12, C13, C16, C17 e C23 cruzam a fronteira real do serviço Firebird 3 local, cada uma com uma base em diretório temporário isolado.
- C23 distingue serviço de Embedded pelo próprio servidor: uma conexão Embedded aparece com `MON$REMOTE_PROTOCOL` nulo, então um retorno ao runtime local não passa.
- C16 prova a indisponibilidade com FireDAC real contra uma porta local sem listener, injetada no inicializador; a porta de produção `3050` é provada por C23. O `CadCli.exe` não recebe porta configurável: reproduzir a indisponibilidade no executável exigiria parar o serviço do Windows, o que as provas não fazem. O caminho de recusa do executável é o mesmo para qualquer erro de inicialização e é provado por C20.
- C17 roda o executável num diretório sem nenhum arquivo do runtime Firebird; a base só pode ter sido criada pelo serviço.
- C5 prova `APLICADA_EM` contra o Firebird por uma janela medida ao redor da execução, de modo que uma constante gravada no lugar do relógio não passa.
- C11 compara a impressão digital exata de cada coluna (nome, tipo, largura) e de cada chave e unicidade pelas colunas que cobrem, não por nome ou contagem.
- C7 e C9 têm prova no próprio nível, com fake, e prova no limite real do Firebird, satisfazendo a primeira linha de `Test policy`.
- C6, C7, C8 e C15 também possuem prova no próprio nível de decisão, sem depender apenas da passagem por uma integração.

## Test policy

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decide e é alcançado pela inicialização | uma prova no limite do serviço Firebird e uma no próprio nível | uma asserção por estado: ausente, anterior, atual, falha, futura e serviço indisponível |
| Decide sem cruzar o Firebird | uma prova unitária no próprio nível | uma asserção por ramo do catálogo, ordenação, pendência e liberação da aplicação |
| Entrada que apenas delega (`CadCli.exe`) | uma prova no limite, executando o artefato entregue | sucesso sem runtime local e recusa com código 1 e log; a indisponibilidade do serviço é provada no inicializador com FireDAC real (C16), não no executável |
| Instrumentação sem condição | nenhuma prova exclusiva | coberta pela prova do consumidor |
| Metadados persistidos | uma prova consultando metadados reais do Firebird | cada tabela, campo, largura, chave, unicidade e sequência enumerados em `Coverage` |

Evidence:

- `src/Infraestrutura/Infraestrutura.InicializadorBancoFireDAC.pas`: decide entre conexão recusada, base ausente, anterior, atual e futura; seis estados observáveis.
- `src/Aplicacao/Aplicacao.ExecutorMigracoes.pas`: decide pendência, ordem, sucesso, rollback e versão futura; quatro estados observáveis e pelo menos três pontos de decisão.
- `src/Aplicacao/Aplicacao.CatalogoMigracoes.pas`: decide unicidade e ordenação de versões; dois estados observáveis.
- Closest analogue: `tests/Unitarios/Testes.IntegracaoFirebird.pas`, já provando no limite real as decisões de migração da versão Embedded.

Cost: 24 checks nomeados; 4 provas novas (C16, C22, C23, C24) e 4 reescritas (C4, C17, C20 e a infraestrutura de conexão das integrações).

## Swept

- validation: C6, C10, C11, C14, C18, C19
- failure modes: C9, C10, C16, C20
- idempotency: C7, C13
- authorization: n/a - aplicação desktop local sem autenticação de usuário; as credenciais do serviço são fixas pelo door 2 e seu sigilo está em C16, C20 e C24
- concurrency: n/a - o plano não promete inicialização simultânea por duas instâncias; as provas executam um processo por base temporária
- data lifecycle: C4, C13, C17, C19
- dependency failure: C16, C17, C22, C23
- state transitions: C4, C7, C8, C9, C10, C13, C16, C17
- observability: C9, C10, C16, C20

## Handoff

- Retrabalho sobre código existente: S1 = `Testes.EntregaRunner.pas` 2,6 KB / 4 = ~1k; S2 = `Infraestrutura.InicializadorBancoFireDAC.pas` 4,7 KB + `Infraestrutura.RegistroErroInicializacao.pas` 1,1 KB + `Testes.IntegracaoFirebird.pas` 31,7 KB + `Suporte.CaminhosTeste.pas` 0,7 KB + `CadCli.dpr` 2,3 KB = 40,5 KB / 4 = ~10k; total ~11k, abaixo do budget de 150k - one builder.
- Mechanism: one builder - o escopo cabe no orçamento e não requer handoff entre builders.
- Pré-requisito para provas de integração: Firebird 3 x64 instalado como serviço, escutando em `localhost:3050`, com `SYSDBA`/`masterkey` e `fbclient.dll` acessível pelo sistema; a conta do serviço precisa gravar nos diretórios temporários dos testes. Sem o serviço, as provas de integração falham - não são puladas.
- Remover das saídas locais os arquivos do Firebird Embedded copiados antes; C22 e C17 falham enquanto eles existirem ao lado do executável.
- DUnitX do Delphi 12 e ReportBuilder Win32/Win64 foram localizados; DevExpress não foi localizado, mas não bloqueia a Parte 01 porque esta parte contém zero forms.

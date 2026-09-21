# Parte 02 - Form principal e navegação checks

Profile: ui
Plan: `.specs/features/parte-02-form-principal/plan.md`

27 checks em 4 slices · 4 one-way doors · 0 questões abertas (Q1 e Q2 decididas em 2026-09-21: AD-009, AD-010; S4 acrescentada em 2026-09-21 por AD-011 e AD-012; C27 acrescentada em 2026-09-21 pelo round 1 do Verifier, aprovada pelo usuário)

## Checks

### S1 - Decisão de navegação no controlador e no navegador

**C1** - Ao receber a ação `Sair`, `TControladorPrincipal` chama `INavegadorAplicacao.EncerrarAplicacao` exatamente 1 vez e chama `AbrirClientes` e `AbrirRelatorio` 0 vezes (S1, AC 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPrincipal.SairSolicitaEncerramentoUmaVez`

**C2** - Ao receber a ação `Cliente`, `TControladorPrincipal` chama `INavegadorAplicacao.AbrirClientes` exatamente 1 vez e chama `AbrirRelatorio` e `EncerrarAplicacao` 0 vezes (S1, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPrincipal.ClienteSolicitaAberturaDeClientesUmaVez`

**C3** - Ao receber a ação `Relatório`, `TControladorPrincipal` chama `INavegadorAplicacao.AbrirRelatorio` exatamente 1 vez e chama `AbrirClientes` e `EncerrarAplicacao` 0 vezes (S1, AC 4)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPrincipal.RelatorioSolicitaAberturaDoRelatorioUmaVez`

**C4** - Quando `AbrirClientes` lança exceção, `TControladorPrincipal` não propaga a exceção, chama `IVisaoPrincipal.ExibirErro` exatamente 1 vez com o texto `Não foi possível abrir o cadastro de clientes.`, e uma ação `Relatório` seguinte chama `AbrirRelatorio` exatamente 1 vez (S1, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPrincipal.FalhaAoAbrirClientesExibeErroEMantemNavegacao`

**C5** - Quando `AbrirRelatorio` lança exceção, `TControladorPrincipal` não propaga a exceção, chama `IVisaoPrincipal.ExibirErro` exatamente 1 vez com o texto `Não foi possível abrir o relatório de clientes.`, e uma ação `Cliente` seguinte chama `AbrirClientes` exatamente 1 vez (S1, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPrincipal.FalhaAoAbrirRelatorioExibeErroEMantemNavegacao`

**C6** - Com o navegador falso lançando uma exceção cuja mensagem é `SYSDBA masterkey Password=x`, o texto entregue a `ExibirErro` é exatamente a mensagem fixa da ação e não contém `SYSDBA`, `masterkey` nem `Password=` (S1, AC 6; AGENTS: credenciais)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPrincipal.MensagemDeFalhaNaoRepassaTextoDaExcecao`

**C7** - As units que declaram `TControladorPrincipal`, `IVisaoPrincipal` e `INavegadorAplicacao` não referenciam em `uses` nenhuma unit `Vcl.*`, `dx*`, `cx*`, `FireDAC.*`, `ppReport*` nem unit de form do projeto, e `TControladorPrincipal` pode ser criado e acionado nas 3 ações com visão e navegador falsos sem criar nenhuma form (`Screen.FormCount` inalterado) (door 2; AGENTS: controladores)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaFormPrincipal.ControladorENavegacaoNaoDependemDeVclNemDevExpress`

**C8** - O navegador concreto, em `AbrirClientes`, cria exatamente 1 instância da tela de destino de clientes, exibe-a modalmente - durante a exibição a janela da form principal está desabilitada (`IsWindowEnabled = False`) - e, ao fechá-la, destrói a instância, deixando `Screen.FormCount` igual ao valor anterior à chamada (S1, AC 3; Assumption: modo de abertura)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.AbrirClientesExibeUmaInstanciaModalELibera`

**C9** - O navegador concreto, em `AbrirRelatorio`, cria exatamente 1 instância da tela de filtros do relatório, exibe-a modalmente com a janela da form principal desabilitada durante a exibição e, ao fechá-la, destrói a instância, deixando `Screen.FormCount` igual ao valor anterior (S1, AC 4; Assumption: modo de abertura)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.AbrirRelatorioExibeUmaInstanciaModalELibera`

**C10** - Duas chamadas consecutivas de `AbrirClientes` criam 2 instâncias distintas em sequência e o número máximo de instâncias da tela de destino vivas ao mesmo tempo é 1 (S1, AC 3 "única instância")
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.AcionamentosConsecutivosNuncaMantemDuasInstancias`

**C11** - `EncerrarAplicacao` do navegador concreto fecha a form principal que lhe foi entregue e deixa `ExitCode = 0` (S1, AC 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.EncerrarAplicacaoFechaFormPrincipalComCodigoZero`

### S2 - Tela principal DevExpress

**C12** - `TFormPrincipal` possui exatamente 1 `TdxBar` com `IsMainMenu = True`, ancorada no topo, cujos links são exatamente 3 `TdxBarSubItem` com legendas (sem `&`) `Sistema`, `Cadastros` e `Relatórios`, nessa ordem da esquerda para a direita (S1, AC 1; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.MenuPrincipalTemTresItensHorizontaisNaOrdem`

**C13** - O submenu `Sistema` possui exatamente 1 link, `Sair`; `Cadastros` possui exatamente 1 link, `Cliente`; `Relatórios` possui exatamente 1 link, `Relatório` (legendas sem `&`) (door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.CadaMenuTemExatamenteOSubmenuExigido`

**C14** - Em um `TFormPrincipal` real com `TControladorPrincipal` real e navegador falso, acionar `Sair`, `Cliente` e `Relatório` (via `Click` do item de barra) produz, respectivamente, exatamente 1 chamada a `EncerrarAplicacao`, `AbrirClientes` e `AbrirRelatorio` e 0 chamadas aos outros dois métodos, e nenhuma form além da form principal é criada (S1, AC 2, AC 3, AC 4, AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.CadaSubmenuDelegaSomenteAoControlador`

**C15** - A unit de `TFormPrincipal` não referencia em `uses` nenhuma unit `FireDAC.*`, `Infraestrutura.*`, `Migracao.*`, `Repositorio*` nem outra unit de form do projeto, e a classe declara exatamente 1 campo do tipo `TControladorPrincipal` (S1, AC 5; door 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaFormPrincipal.FormPrincipalSoConheceSeuControlador`

**C16** - `TFormPrincipal` implementa `IVisaoPrincipal` (`Supports` retorna `True`) e é a única classe do projeto que a implementa (door 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaFormPrincipal.FormPrincipalImplementaVisaoPrincipal`

**C17** - Todo controle visual e todo componente de barra de `TFormPrincipal` pertence a uma classe declarada em unit cujo nome começa por `dx` ou `cx`; zero controles `Vcl.StdCtrls`, `Vcl.ExtCtrls`, `Vcl.ComCtrls` ou `Vcl.Menus` (S1, AC 1 "tela DevExpress")
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.TodosOsControlesSaoDevExpress`

**C18** - Os textos da form principal são: título da janela `CadCli`; cabeçalho `CadCli - Cadastro de Clientes`; área central `Bem-vindo! Use o menu para acessar o cadastro e o relatório de clientes.`; barra de status `Versão ` seguido do `FileVersion` lido do recurso de versão do executável em execução (Assumption: layout criativo; Observable: empty state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.TextosDoFormPrincipalSaoOsDefinidos`

**C19** - O arranjo da form principal é: barra de menu no topo; cabeçalho com `Align = alTop`; área de boas-vindas com `Align = alClient`; barra de status com `Align = alBottom`; e, com a form exibida, `cabeçalho.Top < boas-vindas.Top < status.Top` (Assumption: layout criativo; Observable: density and ordering)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.ArranjoCabecalhoCentroEStatus`

**C20** - Em um `TFormPrincipal` real com navegador falso que falha em `AbrirClientes`, acionar `Cliente` apresenta exatamente 1 vez a mensagem `Não foi possível abrir o cadastro de clientes.` como erro, e em seguida a form principal continua `Visible = True`, com janela habilitada, e acionar `Relatório` chega ao navegador exatamente 1 vez (S1, AC 6; Observable: error state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPrincipal.FalhaDeAberturaMostraErroEMantemFormPrincipalUtilizavel`

**C27** - O apresentador de erro usado pelo `CadCli.exe` exibe o diálogo modal com título exatamente `CadCli` e com o texto recebido exatamente como mensagem, e ao fechá-lo libera o diálogo, deixando `Screen.FormCount` igual ao valor anterior (S1, AC 6; Observable: error state; AGENTS: títulos em português)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesApresentadorErro.DialogoDeErroTemTituloCadCliEMostraAMensagem`

### S3 - Composição do `CadCli.exe`

**C21** - O `CadCli.exe` Release, executado numa cópia da entrega sem `cadcli.fdb`, exibe em até 60 s uma janela de topo visível da classe `TFormPrincipal`, pertencente ao seu processo, com título `CadCli`; após `WM_CLOSE` nessa janela, o processo encerra em até 30 s com código `0` (S1, AC 1, AC 2; Flow hops 1 e 4; door 1)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseExibeFormPrincipalEEncerraComCodigoZero`

**C22** - Com a inicialização recusada (base em versão futura), o `CadCli.exe` Release com `-sem-interacao` encerra em até 120 s com código `1` e nenhuma janela da classe `TFormPrincipal` pertencente ao processo chega a existir; e as provas de executável da Parte 01 (C17, C20) continuam verdes com todas as suas asserções (Flow hop 1; Parte 01 C8, C17, C20)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseRecusadoNaoExibeFormPrincipal`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro`

**C23** - O navegador concreto composto como no `CadCli.exe` desta parte, sem tela registrada para clientes nem para relatório, lança exceção em `AbrirClientes` e em `AbrirRelatorio` sem criar nenhuma form (`Screen.FormCount` inalterado), de modo que a form principal exibe a mensagem de AC 6 da ação (AD-010; S1, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.DestinoSemTelaRegistradaFalhaSemCriarForm`

### S4 - Entrega com runtime packages DevExpress (AD-011, AD-012)

**C24** - O diretório `bin\Win64\Release` contém exatamente 1 arquivo `.exe`, `CadCli.exe`, nenhum arquivo `CadCli*.bpl`, e o conjunto de arquivos `.bpl` nele é exatamente o fechamento transitivo das BPLs importadas pela tabela de import PE de `CadCli.exe`, resolvidas no próprio diretório: toda BPL importada está presente e nenhuma BPL presente fica fora do fechamento; o fechamento contém `dxBarRS29.bpl` e `rtl290.bpl` (door 4; AD-011; AD-012 reescreve a prova da Parte 01 C2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar`

**C25** - O `CadCli.exe` Release, executado numa cópia da entrega sem `cadcli.fdb` com o `PATH` do processo filho sem nenhuma entrada que contenha `Embarcadero` ou `DevExpress`, exibe em até 60 s uma janela de topo visível da classe `TFormPrincipal` pertencente ao seu processo e, após `WM_CLOSE` nessa janela, encerra em até 30 s com código `0` (door 4; AD-011)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseAbreSemDelphiNemDevExpressNoPath`

**C26** - Nenhum arquivo `.dfm` existe sob `src\Aplicacao`, `src\Dominio`, `src\Infraestrutura` e `src\Migracoes`; todo `.dfm` sob `src` está em `src\Visao`; e as demais asserções da prova da Parte 01 C15 permanecem sem alteração (unit do inicializador sem `VCL.`, `FIREDAC.`, `DEVEXPRESS`, `REPORTBUILDER`; inicialização com fakes retorna `True`) (AD-012 reescreve a prova da Parte 01 C15)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaFundacao.InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| menus horizontais do door 3, em ordem (3) | `Sistema` C12 · `Cadastros` C12 · `Relatórios` C12 | - |
| submenus do door 3 (3) | `Sistema > Sair` C13 · `Cadastros > Cliente` C13 · `Relatórios > Relatório` C13 | - |
| ações do controlador (3) | `Sair` C1/C14 · `Cliente` C2/C14 · `Relatório` C3/C14 | - |
| métodos de `INavegadorAplicacao` - door 2 (3) | `EncerrarAplicacao` C1/C11 · `AbrirClientes` C2/C8/C10 · `AbrirRelatorio` C3/C9 | - |
| falhas de abertura (2) | clientes C4/C20/C23/C27 · relatório C5/C23/C27 | - |
| destinos sem tela registrada nesta parte - AD-010 (2) | clientes C23 · relatório C23 | - |
| screen `Principal` - estados aplicáveis do `Observable` (4) | empty C18 · loading Parte 01 C8 + C22 · error C4/C5/C20 · density and ordering C12/C19 | - |
| screen `Principal` - textos (14) | título `CadCli` C18/C21 · cabeçalho C18 · boas-vindas C18 · status `Versão <FileVersion>` C18 · `Sistema` C12 · `Cadastros` C12 · `Relatórios` C12 · `Sair` C13 · `Cliente` C13 · `Relatório` C13 · erro de clientes C4/C20 · erro de relatório C5 · mensagem sem texto da exceção C6 · título `CadCli` do diálogo de erro C27 | - |
| screen `Principal` - arranjo (4) | menu no topo C12/C19 · cabeçalho `alTop` C19 · boas-vindas `alClient` C19 · status `alBottom` C19 | - |
| fronteiras do door 1 (4) | form implementa `IVisaoPrincipal` C16 · exatamente 1 `TControladorPrincipal` C15 · form sem acesso a dados C15 · form não cria outras forms C14/C15 | - |
| fronteiras do door 2 (2) | controlador sem VCL/DevExpress/FireDAC C7 · controlador sem units de form C7 | - |
| abertura modal de instância única (6) | clientes: 1 instância C8/C10 · clientes: modal C8 · clientes: liberada C8 · relatório: 1 instância C9 · relatório: modal C9 · relatório: liberada C9 | - |
| encerramento (2) | form principal fechada C11/C21 · código de saída `0` C11/C21 | - |
| assemblies de inicialização (2) | entrada de `CadCli.exe` C21/C22 · harness de testes sem forms remanescentes Parte 01 C3 + C7/C8/C9/C14 | - |
| one-way doors de `Landing` (4) | par form/controlador C14/C15/C16 · navegação desacoplada C7/C8/C9/C11 · menu público C12/C13 · entrega com runtime packages C24/C25 | - |
| entrega com runtime packages - AD-011 (3) | BPLs presentes = fechamento importado C24 · nenhuma BPL própria `CadCli*` C24 · exe abre sem Delphi/DevExpress no `PATH` C25 | - |
| provas da Parte 01 reescritas - AD-012 (2) | Parte 01 C2 (`NaoDistribuiBplNemExecutavelAuxiliar`) C24 · Parte 01 C15 (`InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos`) C26 | - |

- `Surface` e `Relations` são `None`: nenhuma rota nem entidade exige join. Os estados `unauthorised` e `destructive action confirms` do `Observable` são `n/a` no plano (sem autenticação; sair não descarta edição) e ficam fora do join.
- C1-C6 provam a tabela de decisão do controlador no próprio nível; C14 e C20 provam a mesma tabela pela form real, e C21 pelo executável entregue. Nenhum deles substitui o outro: C14 não falha se só o ramo de erro do controlador estiver errado, e por isso C4-C6 existem.
- C8-C10 usam telas de destino de teste injetadas no navegador concreto, que se fecham sozinhas ao serem exibidas; as telas reais de clientes e relatório são registradas no navegador pelas Partes 03 e 04 (AD-010); até lá C23 prova que os dois menus falham pelo caminho de AC 6.
- C18 exige que o `FileVersion` do runner de testes seja diferente do de `CadCli.exe` (`1.0.0.0`), para que um texto `Versão 1.0.0.0` literal na form não passe.
- C21 prova AC 1 e o código `0` pela janela da própria entrega; ele usa `WM_CLOSE` porque os itens de `TdxBar` não são itens de menu Win32 acessíveis a outro processo. O caminho `Sair -> EncerrarAplicacao` é provado por C1, C11 e C14.
- C25 existe porque a máquina de desenvolvimento tem `Embarcadero\Studio\23.0\bin64`, `Public\Documents\Embarcadero\Studio\23.0\Bpl\Win64` e `DevExpress\VCL\Library\RS29\Win64` no `PATH`: sem retirá-los, C21 passaria mesmo com BPLs faltando na entrega. Entradas do `PATH` que não contêm `Embarcadero` nem `DevExpress` (por exemplo, a biblioteca cliente do Firebird) são mantidas.
- C24 e C26 substituem as asserções `0 BPL` e `0 .dfm no repositório` das provas da Parte 01 C2 e C15, que a Parte 02 torna falsas por construção. Os artefatos `.specs` da Parte 01 não são alterados (AD-012); a obrigação passa a ser desta parte.
- A verificação visual dos três caminhos (Independent test do plano) é feita pelo Verifier no passo `ui`, abrindo o executável; ela não substitui nenhuma prova acima.

## Test policy

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decide sem cruzar fronteira (`TControladorPrincipal`) | uma prova unitária no próprio nível, com visão e navegador falsos | uma asserção por ação (3) e por falha de abertura (2), mais a mensagem sem texto de exceção |
| Adaptador VCL que decide ciclo de vida (navegador concreto) | uma prova no próprio nível com forms reais de teste | instância única, modalidade, liberação e encerramento com código `0` |
| View passiva que não decide (`TFormPrincipal`) | uma prova no limite da form real | cada item de menu delega, textos, arranjo, controles DevExpress e erro mantendo a form principal |
| Adaptador VCL de apresentação de erro (`TApresentadorErroDialogo`) | uma prova no próprio nível exibindo o diálogo real | título `CadCli`, mensagem exata e liberação (C27) |
| Entrada que apenas compõe (`CadCli.exe`) | uma prova executando o artefato entregue | sucesso exibe a form principal e encerra com `0`; recusa encerra com `1` sem form principal |

Evidence:

- `TControladorPrincipal` (novo): despacha 3 ações e trata 2 falhas de abertura -> decide.
- navegador concreto (novo): decide criação, modalidade e liberação da tela de destino -> decide no nível VCL.
- entrega (`CadCli.dproj` + BPLs): decide quais pacotes vão ao lado do exe -> prova no artefato entregue (C24, C25), pela linha `Entrada que apenas compõe`.
- `CadCli.dpr`: hoje o `TAutorizadorInterfaceAplicacao` não faz nada; passa a ser o ponto em que a form principal é criada depois da Parte 01 C8 autorizar.
- Closest analogue: `tests/Unitarios/Testes.InicializadorAplicacao.pas` (decisão com fakes) e `TTestesAplicacaoRelease` em `tests/Unitarios/Testes.IntegracaoFirebird.pas` (artefato entregue).

Cost: 27 checks, ~25 provas novas em 4 fixtures novas e 1 existente, 2 provas da Parte 01 reescritas (C24, C26); 1 prova existente da Parte 01 (`ExecutavelReleaseCriaBaseCompletaAoLado`) passa a fechar a form principal (AD-009).

## Swept

- validation: n/a - a form principal não recebe entrada de dados; a única entrada é a escolha do item de menu, enumerada em C12-C14
- failure modes: C4, C5, C6, C20, C22
- idempotency: C10 - acionamentos repetidos criam uma instância nova de cada vez, nunca duas vivas
- authorization: n/a - aplicação local sem autenticação (Observable: unauthorised)
- concurrency: C8, C9 - a exibição modal desabilita a form principal, impedindo um segundo acionamento enquanto a tela de destino está aberta
- data lifecycle: n/a - a form principal não lê nem grava registros (Impact: stored data)
- dependency failure: C4, C5, C20 - falha do navegador ou da tela de destino; C24, C25 - BPL ausente na entrega
- state transitions: C20, C21, C22 - inicialização -> form principal -> encerramento, e recusa sem form principal
- observability: C4, C5, C20, C27 - mensagem ao usuário identificando a ação, em diálogo com título `CadCli`; nenhum requisito de log nesta parte

## Decisões

- **Q1 -> AD-009:** a prova da Parte 01 `ExecutavelReleaseCriaBaseCompletaAoLado` passa a localizar a janela `TFormPrincipal` do processo e enviar `WM_CLOSE`, mantendo todas as asserções existentes; nenhuma é removida ou enfraquecida. `-sem-interacao` continua apenas suprimindo o diálogo de erro e não pula a form principal.
- **Q2 -> AD-010:** o navegador concreto recebe um criador de tela por destino. C8-C10 provam o ciclo de vida com telas de teste; no `CadCli.exe` desta parte os dois destinos não têm tela registrada e falham pelo caminho de AC 6 (C23). As Partes 03 e 04 registram suas telas reais nesse navegador, sem forms provisórias.

## Handoff

- Arquivos existentes tocados: `CadCli.dpr` 2,3 KB + `CadCli.dproj` 6,3 KB + `tests/CadCli.Testes.dpr` 3,8 KB + `tests/CadCli.Testes.dproj` 3,9 KB + `tests/Unitarios/Testes.IntegracaoFirebird.pas` 31,7 KB + `tests/Unitarios/Testes.EntregaRunner.pas` 3,6 KB + `tests/Unitarios/Testes.InicializadorAplicacao.pas` 4,6 KB = 56,2 KB; novos estimados: visão/navegador/controlador ~8 KB + form `.pas`/`.dfm` ~10 KB + 4 fixtures de teste e fakes ~22 KB + leitor de imports PE e cópia de BPLs ~6 KB = ~46 KB; total ~102 KB / 4 = ~26k tokens, abaixo do budget de 150k - one builder.
- Mechanism: one builder - o escopo cabe no orçamento. O build roda em sessão nova, sem o contexto da sessão de planejamento: este `checks.md`, `plan.md`, `AGENTS.md` e `.specs/STATE.md` são a fonte completa.
- Branch: criar `feat/parte-02-form-principal` a partir de `feat/parte-01-firebird-servico` antes do primeiro commit de código.
- Pré-requisitos: C21, C22 e C25 exigem o serviço Firebird 3 em `localhost:3050`, como na Parte 01. Build: `rsvars.bat` + `MSBuild.exe CadCli.dproj /t:Build /p:Config=Release /p:Platform=Win64` e `MSBuild.exe tests\CadCli.Testes.dproj /t:Build /p:Config=Debug /p:Platform=Win64` (Delphi 12 em `C:\Program Files (x86)\Embarcadero\Studio\23.0`).
- DevExpress (AD-011), apurado em 2026-09-21:
  - A instalação é trial e só contém `.bpl`/`.dcp`/`.hpp` em `C:\Program Files (x86)\DevExpress\VCL\Library\RS29\Win64` (variável `DXVCL`); não há `.dcu` nem `.pas`. Com runtime packages desligado, `uses dxBar` falha com `F2613 Unit 'dxBar' not found`, inclusive via MSBuild com o library path da IDE. Com `-LU` dos pacotes compila.
  - Um exe mínimo com `uses Vcl.Forms, dxBar, cxLabel, dxStatusBar` importou: `rtl290`, `vcl290`, `vclwinx290`, `dbrtl290`, `dxCoreRS29`, `dxComnRS29`, `dxGDIPlusRS29`, `cxLibraryRS29`, `dxBarRS29`. `dxBarRS29.bpl` importa ainda `vclx290`, `vcldb290`, `vclimg290`. O conjunto real sai do exe final; C24 exige o fechamento exato, calculado pela tabela de import.
  - Origem das BPLs para a cópia: DevExpress em `$(DXVCL)\Library\RS29\Win64`; Embarcadero em `C:\Program Files (x86)\Embarcadero\Studio\23.0\bin64` (há também `Redist\win64`). A cópia faz parte do build Release (por exemplo, um passo pós-build no `CadCli.dproj` chamando um script em `tools\`); a forma é decisão do builder.
  - O runner de testes também linka os pacotes, porque C12-C20 instanciam `TFormPrincipal`. `tests\bin` fica fora da entrega; o runner roda com o `PATH` da máquina.
- Riscos para verificar primeiro, num spike antes das provas (um erro aqui é stop-and-ask, não contorno):
  - O usuário relatou que o exe mostra um aviso de versão trial. Descobrir se ele é uma janela modal, quando aparece e se aparece também no runner de testes. Se aparecer, as provas de executável (C21, C22, C25 e as da Parte 01 que abrem a form principal por AD-009) podem fechar essa janela para chegar à form principal, sem mudar nenhuma asserção; no runner, uma janela modal travaria a execução e exige decisão do usuário.
  - `TTestesRunnerDUnitX.ExecutaEmWin64SemCriarForm` (Parte 01 C3) assere `Screen.FormCount = 0`. Se o DevExpress trial criar uma form própria ao carregar, essa prova fica vermelha: parar e perguntar, não reescrever.
  - O `PATH` reduzido de C25 não pode remover o diretório da biblioteca cliente do Firebird; se o `fbclient.dll` só for encontrado por uma entrada com `Embarcadero` ou `DevExpress`, parar e perguntar.
- Achados anteriores ao build, ainda válidos:
  - `CadCli.dpr` não tem `{$R *.res}` e `CadCli.dproj` só declara `VerInfo_IncludeVerInfo`/`VerInfo_Keys` no bloco `Base_Win32`; o `CadCli.exe` Win64 atual sai sem `FileVersion`. C18 exige o recurso de versão no alvo Win64 (`FileVersion=1.0.0.0`).
  - `tests/CadCli.Testes.dproj` não tem recurso de versão; C18 exige que o runner tenha um `FileVersion` diferente de `1.0.0.0`.
  - Existe um `bin\Win64\Release\CADCLI.FDB` local, fora do git; `ExecutavelReleaseCriaBaseCompletaAoLado` copia esse diretório e falha enquanto ele existir. Mover o arquivo antes de rodar as provas de executável.
  - `ExecutavelReleaseRecusaVersaoFuturaERegistraOErro` também executa o exe com sucesso na primeira chamada: por AD-009 ela precisa fechar a form principal com `WM_CLOSE`, como `ExecutavelReleaseCriaBaseCompletaAoLado`.
  - O runner precisa mapear as novas fixtures em `QualificarTeste` para que os filtros curtos dos `Proof:` resolvam.
  - Fontes Delphi novos em UTF-8 com BOM (AGENTS.md).

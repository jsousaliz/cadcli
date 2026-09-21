# Parte 03 - CRUD e pesquisa de clientes checks

Profile: ui
Plan: `.specs/features/parte-03-clientes-crud/plan.md`

52 checks em 5 slices · 5 one-way doors · 0 questões abertas (Q1 decidida em 2026-09-21: AD-014; checks aprovados pelo usuário em 2026-09-21)

Textos, rótulos e mensagens abaixo que o plano não fixou literalmente são defaults derivados, listados em `## Decisões`; todos ficam fixos com a aprovação deste arquivo.

## Checks

### S1 - Pesquisa em memória (`TFiltroCliente` e `TControladorPesquisaCliente`)

**C1** - Ao abrir a pesquisa com um repositório falso que devolve os clientes de ID 8, 1 e 5 nessa ordem, `TControladorPesquisaCliente` chama `IRepositorioCliente.ListarTodos` exatamente 1 vez e entrega à visão exatamente 3 clientes na ordem de ID 1, 5, 8, cada um com ID, nome, CPF/CNPJ, CEP, cidade, UF, estado e data de nascimento iguais aos do repositório (S1, AC 1; door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.AberturaCarregaUmaVezEExibePorIdCrescente`

**C2** - `TFiltroCliente.Atende`, table-driven sobre os 7 filtros por campo com os clientes fixos da fixture, aceita e rejeita exatamente: ID `1` aceita o ID 1 e rejeita 10 e 15; nome `SIL` aceita `Ana Silva` e rejeita `Bruno Costa`; CPF/CNPJ `529.982.247-25` aceita `52998224725` e rejeita `529982247` como parcial; CEP `01001-000` aceita `01001000` e `0100100` rejeita `01001000`; cidade `campi` aceita `Campinas`; estado `sp` aceita UF `SP`, estado `paulo` aceita `São Paulo` e estado `MG` rejeita `SP`; data `15/03/1990` aceita somente o nascimento `15/03/1990` (S1, AC 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFiltroCliente.FiltrosPorCampoAceitamERejeitamOsCasosDaTabela`

**C3** - Com nome `silva` e estado `MG` preenchidos juntos, `TFiltroCliente.Atende` aceita somente `Ana Silva` de Belo Horizonte/MG e rejeita `Carlos Silva` de Campinas/SP e `Bruno Costa` de Contagem/MG; com todos os filtros e a busca geral vazios, aceita os 5 clientes da fixture (S1, AC 2, AC 4)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFiltroCliente.FiltrosPreenchidosCombinamPorAndEVaziosAceitamTodos`

**C4** - A busca geral, table-driven sobre os 8 campos, encontra um cliente por uma palavra contida em cada campo: ID (`15` encontra os IDs 15 e 150), nome (`SILVA`), CPF/CNPJ (`247-25` encontra `52998224725`), CEP (`01001` encontra `01001000`), cidade (`campinas`), UF (`sp`), estado (`paulo`) e data de nascimento (`03/1990` encontra `15/03/1990`) (S1, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFiltroCliente.BuscaGeralAlcancaCadaCampo`

**C5** - Na busca geral: `silva campinas` aceita somente `Carlos Silva` de Campinas e rejeita `Ana Silva` de Belo Horizonte e `Denise Rocha` de Campinas; uma palavra sem dígitos (`abc`) não é aceita por CPF/CNPJ nem por CEP; espaços repetidos (`  silva   `) equivalem a `silva`; busca geral `silva` com filtro de estado `SP` aceita somente `Carlos Silva` (S1, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFiltroCliente.BuscaGeralExigeCadaPalavraEDigitosSoComparamDigitos`

**C6** - Depois da abertura, 3 pesquisas seguidas com filtros diferentes chamam `ListarTodos` 0 vezes além da chamada da abertura, e cada pesquisa entrega à visão exatamente os clientes em memória aceitos por `TFiltroCliente.Atende` (S1, AC 2; door 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.FiltrarNaoConsultaORepositorio`

**C7** - Com repositório vazio, e também com 5 clientes e um filtro que não aceita nenhum, o controlador informa à visão 0 clientes, a mensagem `Nenhum cliente encontrado` e as ações `Editar` e `Excluir` desabilitadas; com ao menos 1 cliente exibido, `Editar` e `Excluir` ficam habilitadas (S1, AC 4)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.SemResultadoExibeMensagemEDesabilitaAcoes`

**C8** - Quando `ListarTodos` lança exceção, o controlador não propaga a exceção, chama `ExibirErro` exatamente 1 vez com o texto `Não foi possível carregar os clientes.`, sem o texto da exceção, e entrega 0 clientes à visão; depois de uma carga bem-sucedida de 5 clientes seguida de uma recarga que falha, uma pesquisa com filtros vazios entrega 0 clientes (S1, AC 5)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.FalhaNaCargaExibeErroEEsvaziaAListaEmMemoria`

**C9** - Ao acionar `Novo`, o controlador chama o navegador de clientes exatamente 1 vez em modo inclusão; se o navegador devolver `salvo`, `ListarTodos` é chamado mais 1 vez e o filtro vigente (nome `silva`) é reaplicado à nova lista, exibindo o novo `Eva Silva` e omitindo `Bruno Costa`; se devolver `não salvo`, `ListarTodos` não é chamado de novo (S1, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.NovoAbreInclusaoERecarregaComFiltroSoQuandoSalvo`

**C10** - Ao acionar `Editar` com o cliente de ID 7 selecionado, o controlador chama o navegador de clientes exatamente 1 vez em modo edição com o ID `7`; a recarga com reaplicação do filtro ocorre somente quando o navegador devolve `salvo` (S1, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.EditarAbreEdicaoDoSelecionadoERecarregaSoQuandoSalvo`

### S2 - Tela de pesquisa DevExpress

**C11** - A lista de resultados de `TFormPesquisaCliente` é um `TcxMCListBox` (door 5), sem dataset, com exatamente 8 `HeaderSections`, `Sorted = False` e nenhuma seção com `AllowClick`; a form não contém `TcxGrid`, linha de filtro nem painel de busca de grade, e a ordem das linhas é a entregue pelo controlador: com o repositório falso devolvendo os IDs 8, 1 e 5, as linhas exibidas são 1, 5, 8 (door 2; door 5; S1, AC 2) — reescrito em 2026-09-21 com aprovação do usuário (AD-015)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.GradeNaoVinculadaComFiltrosPropriosDesligados`

**C12** - Em um `TFormPesquisaCliente` real com controlador real e repositório falso de 5 clientes, table-driven sobre as 8 entradas do painel (ID, nome, CPF/CNPJ, CEP, cidade, estado, data de nascimento e `Buscar em todos os campos`), preencher uma entrada e clicar `Pesquisar` deixa na grade exatamente os IDs esperados para aquele valor, e o repositório registra 1 única chamada a `ListarTodos` (S1, AC 2, AC 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.CadaEntradaDoPainelFiltraAGradePeloControlador`

**C13** - Em um `TFormPesquisaCliente` real cujo repositório falha na recarga, os 8 editores do painel mantêm o texto digitado, a grade fica com 0 linhas e exibe `Nenhum cliente encontrado`, e a mensagem `Não foi possível carregar os clientes.` é apresentada exatamente 1 vez (S1, AC 4, AC 5; Observable: error state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.FalhaNaCargaMantemFiltrosEEsvaziaGrade`

**C14** - Os textos de `TFormPesquisaCliente` são exatamente: título `Pesquisa de Clientes`; rótulos do painel `ID`, `Nome`, `CPF/CNPJ`, `CEP`, `Cidade`, `Estado`, `Data de nascimento`, `Buscar em todos os campos`; botões `Pesquisar`, `Novo`, `Editar`, `Excluir`; colunas da grade, nessa ordem, `ID`, `Nome`, `CPF/CNPJ`, `CEP`, `Cidade`, `UF`, `Estado`, `Data de nascimento`; texto de grade vazia `Nenhum cliente encontrado` (Observable: empty state, density and ordering; enunciado item 2)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.TextosDaPesquisaSaoOsDefinidos`

**C15** - O arranjo de `TFormPesquisaCliente` é: painel de filtros com `Align = alTop`, grade com `Align = alClient` e barra de ações com `Align = alBottom`; com a form exibida, `painel.Top < grade.Top < barra.Top`; os botões da barra aparecem da esquerda para a direita como `Novo`, `Editar`, `Excluir`; `Pesquisar` fica no painel de filtros (Observable: density and ordering)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormPesquisaCliente.ArranjoFiltrosGradeEAcoes`

**C16** - Todo controle visual de `TFormPesquisaCliente` e de `TFormCadastroCliente` pertence a uma classe declarada em unit cujo nome começa por `dx` ou `cx`; zero controles `Vcl.StdCtrls`, `Vcl.ExtCtrls`, `Vcl.ComCtrls`, `Vcl.Mask` ou `Vcl.Grids` (enunciado: componentes DevExpress; AGENTS)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaClientes.FormsDeClientesSoUsamControlesDevExpress`

### S3 - Inclusão e alteração validadas (`TControladorCadastroCliente` e `TFormCadastroCliente`)

**C17** - Salvar um cliente novo válido chama, em ordem, `Iniciar` da transação, a resolução de cidade por UF e nome, `IRepositorioCliente.Incluir` exatamente 1 vez e `Confirmar` exatamente 1 vez, com `Reverter` 0 vezes; o ID `42` devolvido pelo repositório é o ID informado à visão e o resultado do cadastro é `salvo` (S2, AC 7)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.InclusaoValidaPersisteEmTransacaoERetornaId`

**C18** - Salvar o cliente de ID 7 aberto em edição chama `Alterar` exatamente 1 vez com o ID `7`, `Incluir` 0 vezes, dentro de `Iniciar` ... `Confirmar`, e o ID informado à visão continua `7` (S2, AC 8)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.AlteracaoValidaAlteraOMesmoIdEmTransacao`

**C19** - Table-driven sobre os 9 campos obrigatórios em ordem de tabulação (`Nome`, `CPF/CNPJ`, `Data de nascimento`, `CEP`, `Endereço`, `Número`, `Bairro`, `Cidade`, `UF`): com somente aquele campo vazio ou só com espaços, salvar chama `Iniciar` 0 vezes, exibe `O campo <rótulo> é obrigatório.` e pede foco nesse campo; com `Nome` e `Bairro` vazios juntos, a mensagem e o foco são de `Nome`; `Complemento` vazio não impede salvar (S2, AC 9; Assumption: obrigatoriedade)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CampoObrigatorioVazioImpedeSalvarEFocaOPrimeiro`

**C20** - Com CPF/CNPJ `529.982.247-25` ou `11.222.333/0001-81` o salvamento prossegue e grava somente os dígitos; com `529.982.247-24`, `11.222.333/0001-80`, `111.111.111-11`, `00.000.000/0000-00`, 10 dígitos, 12 dígitos e 15 dígitos, salvar chama `Iniciar` 0 vezes e exibe `CPF/CNPJ inválido` (S2, AC 10)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesValidacaoCliente.CpfCnpjValidaTamanhoEDigitosVerificadores`

**C21** - Com o relógio falso em `21/09/2026`, nascimento `22/09/2026` impede salvar com `Data de nascimento não pode estar no futuro` e `Iniciar` 0 vezes; nascimento `21/09/2026` é aceito (S2, AC 11)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.NascimentoFuturoImpedeSalvarPeloRelogioInjetado`

**C22** - Ao salvar com CEP preenchido que não tenha exatamente 8 dígitos (`0100100`), o salvamento chama `Iniciar` 0 vezes e exibe `CEP inválido`; CEP `01001-000` é gravado como `01001000` (S2, AC 9; enunciado item 4 `CEP CHAR(8)`)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepComTamanhoErradoImpedeSalvar`

**C23** - Quando `Incluir` ou `Alterar` lança uma exceção cujo texto contém `SYSDBA`, `masterkey` e `localhost:3050`, o controlador chama `Reverter` exatamente 1 vez e `Confirmar` 0 vezes, não propaga a exceção, exibe exatamente `Não foi possível salvar o cliente.` e não altera nenhum valor da visão; o resultado do cadastro continua aberto (S2, AC 14)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.FalhaAoSalvarReverteEMantemValores`

**C24** - Com algum valor alterado desde a abertura, `Cancelar` e o fechamento da janela pedem exatamente 1 confirmação com o texto `Descartar as alterações não salvas?`; resposta `Não` mantém a form aberta com os valores; resposta `Sim` fecha com resultado `não salvo` e 0 chamadas ao repositório; sem alterações, fecha sem pedir confirmação. Provado no controlador e na `TFormCadastroCliente` real via `Close` (S2, AC 13; Observable: destructive action confirms)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.DescarteDeAlteracoesPedeConfirmacao`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormCadastroCliente.FecharComAlteracoesPassaPelaConfirmacaoDoControlador`

**C25** - Em um `TFormCadastroCliente` real exibido, Enter em cada um dos 10 editores move o foco na ordem `Nome`, `CPF/CNPJ`, `Data de nascimento`, `CEP`, `Endereço`, `Número`, `Complemento`, `Bairro`, `Cidade`, `UF`, e Enter em `UF` move o foco para `Salvar`; Enter não fecha a form nem salva (S2, AC 12; Observable: density and ordering)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormCadastroCliente.EnterAvancaNaOrdemDeTabulacaoAteSalvar`

**C26** - Os textos de `TFormCadastroCliente` são exatamente: título `Novo Cliente` em inclusão e `Editar Cliente` em edição; rótulos `Nome`, `CPF/CNPJ`, `Data de nascimento`, `CEP`, `Endereço`, `Número`, `Complemento`, `Bairro`, `Cidade`, `UF`, `Estado`; botões `Salvar` e `Cancelar`; indicador de carregamento `Consultando CEP...` (Observable: empty state, loading state)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormCadastroCliente.TextosDoCadastroSaoOsDefinidos`

**C27** - O arranjo de `TFormCadastroCliente` é: editores dispostos de cima para baixo na ordem de tabulação de C25 (o `Top` de cada linha é maior ou igual ao da anterior), `Estado` somente leitura ao lado de `UF`, barra de botões com `Align = alBottom` contendo `Salvar` à esquerda de `Cancelar`; em inclusão todos os editores começam vazios e o indicador `Consultando CEP...` começa invisível (Observable: empty state, density and ordering)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormCadastroCliente.ArranjoCamposEBotoes`

**C28** - Os editores limitam o texto ao tamanho da coluna: `Nome` 80, `CPF/CNPJ` 18 caracteres com máscara e 14 dígitos gravados, `CEP` 9 caracteres com máscara e 8 dígitos gravados, `Endereço` 100, `Número` 20, `Complemento` 60, `Bairro` 100, `Cidade` 50; `UF` é uma lista fechada com exatamente as 27 UFs (enunciado item 4; Swept: validation)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesFormCadastroCliente.EditoresRespeitamOTamanhoDasColunas`

### S4 - CEP pelo ViaCEP, estado e cidade

**C29** - Com o CEP da visão alterado de vazio para `01001-000` entre a entrada e a saída do campo, o controlador chama `IServicoViaCep.Consultar` exatamente 1 vez com `01001000`, e a visão recebe, em ordem, carregamento ligado, a resposta e carregamento desligado (S3, AC 15)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepAlteradoConsultaUmaVezSinalizandoCarregamento`

**C30** - Saídas do campo CEP sem mudança de dígitos chamam `Consultar` 0 vezes e alteram 0 campos de endereço: ao abrir o cliente de ID 7 em edição com CEP `01001000` e sair do campo; e ao trocar `01001-000` por `01001000` (S3, AC 15)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepSemAlteracaoNaoConsulta`

**C31** - Quando `Consultar` devolve encontrado com `TEnderecoViaCep` (`Praça da Sé`, `Sé`, `São Paulo`, `SP`, `São Paulo`), a visão recebe endereço `Praça da Sé`, bairro `Sé`, cidade `São Paulo`, UF `SP` e estado `São Paulo`, e número `100` e complemento `sala 2` digitados antes permanecem (S3, AC 16, AC 23)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepEncontradoPreencheEnderecoEPreservaNumeroEComplemento`

**C32** - Com o CEP alterado para `0100100` ou para `010010001`, sair do campo chama `Consultar` 0 vezes e exibe `CEP inválido` exatamente 1 vez (S3, AC 17)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepAlteradoComTamanhoErradoNaoConsulta`

**C33** - Quando `Consultar` devolve não encontrado, a visão exibe `CEP não encontrado`, os campos endereço, bairro, cidade e UF continuam editáveis e com os valores anteriores, e o carregamento termina desligado (S3, AC 18)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepNaoEncontradoMantemCamposEditaveis`

**C34** - Quando `Consultar` devolve indisponível, a visão exibe `Serviço de CEP indisponível. Preencha o endereço manualmente.`, o carregamento termina desligado e os 10 valores digitados continuam iguais (S3, AC 19)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepIndisponivelPreservaValores`

**C35** - Quando `Consultar` devolve resposta inválida, a visão exibe `Resposta inválida do serviço de CEP`, 0 campos são preenchidos e os valores digitados continuam iguais (S3, AC 24)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.CepComRespostaInvalidaNaoPreencheCampos`

**C36** - `TServicoViaCep` sobre um transporte HTTP falso pede exatamente a URL `https://viacep.com.br/ws/01001000/json/` e, com o corpo JSON real fixo do ViaCEP para `01001-000`, devolve encontrado com `TEnderecoViaCep` de `CEP = 01001-000`, `Logradouro = Praça da Sé`, `Complemento = lado ímpar`, `Bairro = Sé`, `Localidade = São Paulo`, `UF = SP` e `Estado = São Paulo` (S3, AC 15, AC 23; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesServicoViaCep.MontaUrlEConverteCorpoRealEmEndereco`

**C37** - `TServicoViaCep` traduz, table-driven: HTTP 400 -> não encontrado; HTTP 200 `{"erro": "true"}` e `{"erro": true}` -> não encontrado; HTTP 500 -> indisponível; exceção do transporte -> indisponível; tempo esgotado do transporte -> indisponível; corpo `<html>` -> resposta inválida; corpo `[]` -> resposta inválida; corpo sem `logradouro`, sem `bairro`, sem `localidade` e sem `uf`, cada um -> resposta inválida; nenhum caso propaga exceção (S3, AC 18, AC 19, AC 24; door 3)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesServicoViaCep.TraduzCadaRespostaParaUmResultadoTipado`

**C38** - O transporte HTTP concreto, apontado para um socket local em `127.0.0.1` que aceita a conexão e nunca responde, devolve tempo esgotado depois de pelo menos 9,5 s e em no máximo 13 s, sem acessar a rede externa (S3, AC 19; AGENTS: timeout)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesTransporteHttp.ServidorLocalSemRespostaEsgotaEmDezSegundos`

**C39** - O repositório FireDAC, numa base temporária migrada, resolve cidade por UF e nome nos 3 casos: `Campinas`/`SP` (existentes) insere 0 estados e 0 cidades e usa a cidade existente; `Sorocaba`/`SP` insere 0 estados e 1 cidade ligada a SP; `Florianópolis`/`SC`/`Santa Catarina` insere 1 estado `SC - Santa Catarina` e 1 cidade ligada a ele, com IDs tirados de `SEQ_ESTADO` e `SEQ_CIDADE`; repetir o terceiro caso insere 0 registros (S3, AC 20; Relations)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.ResolveEstadoECidadeNosTresCasos`

**C40** - O nome do estado inserido vem de `Estado` do endereço quando preenchido; com `Estado` vazio ou ausente vem da tabela fixa, que tem exatamente 27 UFs e, table-driven, mapeia cada uma ao seu nome (por exemplo `DF` -> `Distrito Federal`, `SP` -> `São Paulo`) (S3, AC 21)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesTabelaUfs.VinteESeteUfsComNomes`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorCadastroCliente.NomeDoEstadoVemDoViaCepOuDaTabela`

**C41** - Numa base temporária migrada, um salvamento que insere estado `SC` e cidade `Florianópolis` e depois falha ao gravar o cliente (nome com 81 caracteres) termina com as contagens de `ESTADO`, `CIDADE` e `CLIENTE` iguais às anteriores (S3, AC 22)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.FalhaDepoisDeCriarEstadoECidadeNaoDeixaOrfaos`

**C42** - A unit de `TControladorCadastroCliente` não referencia `System.JSON`, `REST.*`, `System.Net.*` nem `Infraestrutura.*`, e o único tipo de endereço externo que ela recebe é `TEnderecoViaCep` (door 3; S3, AC 23)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaClientes.ControladorDeCadastroSoConheceTEnderecoViaCep`

### S5 - Exclusão, persistência e composição

**C43** - Ao acionar `Excluir` com o cliente `7 - Ana Silva` selecionado, o controlador pede exatamente 1 confirmação com o texto `Excluir o cliente 7 - Ana Silva?` antes de qualquer chamada à transação; resposta `Não` resulta em 0 chamadas a `Iniciar` e a `Excluir` (S4, AC 25)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.ExclusaoPedeConfirmacaoComIdENome`

**C44** - Com a confirmação aceita, o controlador chama `Iniciar`, `Excluir` exatamente 1 vez com o ID `7`, `Confirmar`, e depois `ListarTodos` mais 1 vez; a visão deixa de exibir o ID 7 e continua exibindo os demais aceitos pelo filtro vigente (S4, AC 26)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.ExclusaoConfirmadaExcluiEmTransacaoERecarrega`

**C45** - Table-driven sobre os IDs protegidos 1, 5, 8, 10 e 15: `Excluir` resulta em 0 confirmações, 0 chamadas a `Iniciar` e a `Excluir`, e a mensagem `Cliente protegido não pode ser excluído`; os IDs 2, 9 e 16 seguem para a confirmação (S4, AC 27; door 4)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.IdsProtegidosNaoAbremTransacao`

**C46** - Quando `Excluir` lança exceção, o controlador chama `Reverter` exatamente 1 vez e `Confirmar` 0 vezes, exibe exatamente `Não foi possível excluir o cliente.` e a visão continua exibindo o ID 7 (S4, AC 28)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesControladorPesquisaCliente.FalhaNaExclusaoReverteEMantemRegistro`

**C47** - Numa base temporária migrada, com `SEQ_CLIENTE` reiniciada em 100: `Incluir` grava 1 linha com ID `101` e devolve `101`; os campos lidos de volta são iguais aos gravados, incluindo o nome `D'Ávila; DROP TABLE CLIENTE` e CPF/CNPJ e CEP só com dígitos; `Alterar` do ID 101 muda o nome e mantém o ID e a contagem; `Excluir` do ID 101 remove exatamente 1 linha e a tabela `CLIENTE` continua existindo (S2, AC 7, AC 8; S4, AC 26; AGENTS: SQL parametrizado e sequências)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.IncluiAlteraEExcluiPorParametrosESequencia`

**C48** - Numa base temporária migrada com 3 clientes gravados fora de ordem (IDs 30, 10, 20), `ListarTodos` devolve exatamente 3 clientes na ordem 10, 20, 30, cada um com nome da cidade, UF e nome do estado da cidade ligada (S1, AC 1; Relations)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesRepositorioClienteFirebird.ListarTodosTrazCidadeEEstadoPorIdCrescente`

**C49** - `TFormPesquisaCliente` implementa `IVisaoPesquisaCliente` e declara exatamente 1 campo `TControladorPesquisaCliente`; `TFormCadastroCliente` implementa `IVisaoCadastroCliente` e declara exatamente 1 campo `TControladorCadastroCliente`; as units das duas forms não referenciam `FireDAC.*`, `Infraestrutura.*`, `Repositorio*`, `System.Net.*` nem `System.JSON`; as units dos dois controladores não referenciam `Vcl.*`, `FireDAC.*`, `cx*`, `dx*`, `System.Net.*` nem `System.JSON`; `TControladorCadastroCliente` não tem método público cujo nome contenha `Excluir` (door 1; door 4; AGENTS)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesArquiteturaClientes.CadaFormTemSeuControladorESemInfraestrutura`

**C50** - O navegador de clientes concreto, em modo inclusão e em modo edição do ID 7, exibe modalmente exatamente 1 `TFormCadastroCliente` com título `Novo Cliente` ou `Editar Cliente`, devolve `salvo` somente quando o cadastro foi salvo e, ao fechar, `Screen.FormCount` volta ao valor anterior (S1, AC 6)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorClientes.AbreCadastroModalNoModoEDevolveSeSalvou`

**C51** - O navegador composto como no `CadCli.exe`, sobre uma base temporária preparada pelo inicializador, em `AbrirClientes` exibe modalmente exatamente 1 `TFormPesquisaCliente` que lista os 0 clientes da base, e ao fechá-la `Screen.FormCount` volta ao valor anterior; `AbrirRelatorio` continua lançando `ENavegacaoSemTela` sem criar form (AD-010; AD-014 reescreve a prova da Parte 02 C23)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.DestinoSemTelaRegistradaFalhaSemCriarForm`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesNavegadorAplicacao.ClientesAbrePesquisaRealSobreABase`

**C52** - As provas de executável da Parte 02 (C21, C25) e da Parte 01 que abrem a form principal continuam verdes com todas as suas asserções depois da composição das telas de clientes (Flow; Parte 02 C21, C25)
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseExibeFormPrincipalEEncerraComCodigoZero`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseAbreSemDelphiNemDevExpressNoPath`
Proof: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| filtros por campo do AC 2 (7) | ID C2/C12 · nome C2/C12 · CPF/CNPJ C2/C12 · CEP C2/C12 · cidade C2/C12 · estado C2/C12 · data de nascimento C2/C12 | - |
| campos alcançados pela busca geral do AC 3 (8) | ID C4 · nome C4 · CPF/CNPJ C4 · CEP C4 · cidade C4 · UF C4 · estado C4 · data de nascimento C4 | - |
| regras da busca geral (4) | cada palavra em algum campo C5 · dígitos só comparam dígitos C5 · espaços repetidos C5 · AND com filtros por campo C5 | - |
| entradas do painel de pesquisa (8) | ID C12 · nome C12 · CPF/CNPJ C12 · CEP C12 · cidade C12 · estado C12 · data de nascimento C12 · busca geral C12 | - |
| campos obrigatórios do AC 9 (9) | Nome C19 · CPF/CNPJ C19 · Data de nascimento C19 · CEP C19 · Endereço C19 · Número C19 · Bairro C19 · Cidade C19 · UF C19 | - |
| casos de CPF/CNPJ do AC 10 (9) | CPF válido C20 · CNPJ válido C20 · CPF com dígito errado C20 · CNPJ com dígito errado C20 · CPF com dígitos iguais C20 · CNPJ com dígitos iguais C20 · 10 dígitos C20 · 12 dígitos C20 · 15 dígitos C20 | - |
| editores na ordem de tabulação do AC 12 (10) | Nome C25 · CPF/CNPJ C25 · Data de nascimento C25 · CEP C25 · Endereço C25 · Número C25 · Complemento C25 · Bairro C25 · Cidade C25 · UF C25 | - |
| saídas do campo CEP (4) | alterado com 8 dígitos C29 · sem alteração C30 · só máscara mudou C30 · alterado com tamanho errado C32 | - |
| resultados de `IServicoViaCep` - door 3 (4) | encontrado C31/C36 · não encontrado C33/C37 · indisponível C34/C37/C38 · resposta inválida C35/C37 | - |
| respostas HTTP traduzidas pelo serviço (11) | 400 C37 · 200 `erro` texto C37 · 200 `erro` booleano C37 · 500 C37 · exceção de transporte C37 · tempo esgotado C37/C38 · corpo não JSON C37 · corpo array C37 · sem `logradouro` C37 · sem `bairro` C37 · sem `localidade` C37 | - |
| chave obrigatória `uf` ausente (1) | sem `uf` C37 | - |
| propriedades de `TEnderecoViaCep` (7) | `CEP` C36 · `Logradouro` C36/C31 · `Complemento` C36 · `Bairro` C36/C31 · `Localidade` C36/C31 · `UF` C36/C31 · `Estado` C36/C31 | - |
| casos de estado/cidade do AC 20 (3) | ambos existentes C39 · só estado existente C39 · nenhum existente C39 | - |
| origem do nome do estado do AC 21 (3) | `estado` do JSON C40 · `estado` vazio C40 · `estado` ausente C40 | - |
| tabela fixa de UFs (27) | table-driven C40 (27 UFs, tamanho assertado) | - |
| IDs protegidos - door 4 (5) | 1 C45 · 5 C45 · 8 C45 · 10 C45 · 15 C45 | - |
| desfechos da exclusão (4) | cancelada C43 · confirmada C44 · protegida C45 · falha C46 | - |
| operações de `IRepositorioCliente` - door 2 (6) | incluir C47 · alterar C47 · excluir C47 · obter por ID C50 · listar todos C48 · resolver cidade C39/C41 | - |
| escritas em transação (3) | inclusão C17/C23 · alteração C18/C23 · exclusão C44/C46 | - |
| resultados do navegador de clientes (4) | inclusão salvo C9/C50 · inclusão não salvo C9/C50 · edição salvo C10/C50 · edição não salvo C10/C50 | - |
| screen `PesquisaCliente` - estados aplicáveis do `Observable` (5) | empty C7/C13/C14 · loading C1 · error C8/C13 · density and ordering C14/C15 · destructive action confirms C43/C45 | - |
| screen `CadastroCliente` - estados aplicáveis do `Observable` (5) | empty C26/C27 · loading C29/C26 · error C23/C33/C34/C35 · density and ordering C25/C27 · destructive action confirms C24 | - |
| screen `PesquisaCliente` - textos (26) | título C14 · rótulo ID C14 · rótulo Nome C14 · rótulo CPF/CNPJ C14 · rótulo CEP C14 · rótulo Cidade C14 · rótulo Estado C14 · rótulo Data de nascimento C14 · rótulo busca geral C14 · botão Pesquisar C14 · botão Novo C14 · botão Editar C14 · botão Excluir C14 · coluna ID C14 · coluna Nome C14 · coluna CPF/CNPJ C14 · coluna CEP C14 · coluna Cidade C14 · coluna UF C14 · coluna Estado C14 · coluna Data de nascimento C14 · grade vazia C7/C14 · erro de carga C8/C13 · confirmação de exclusão C43 · cliente protegido C45 · erro de exclusão C46 | - |
| screen `CadastroCliente` - textos (25) | título inclusão C26 · título edição C26 · rótulo Nome C26 · rótulo CPF/CNPJ C26 · rótulo Data de nascimento C26 · rótulo CEP C26 · rótulo Endereço C26 · rótulo Número C26 · rótulo Complemento C26 · rótulo Bairro C26 · rótulo Cidade C26 · rótulo UF C26 · rótulo Estado C26 · botão Salvar C26 · botão Cancelar C26 · carregamento C26 · obrigatório C19 · CPF/CNPJ inválido C20 · nascimento futuro C21 · CEP inválido C22/C32 · erro ao salvar C23 · descarte C24 · CEP não encontrado C33 · CEP indisponível C34 · resposta inválida C35 | - |
| screen `PesquisaCliente` - arranjo (4) | filtros `alTop` C15 · grade `alClient` C15 · ações `alBottom` C15 · ordem dos botões C15 | - |
| screen `CadastroCliente` - arranjo (4) | editores na ordem de tabulação C27 · Estado ao lado de UF C27 · botões `alBottom` C27 · Salvar à esquerda de Cancelar C27 | - |
| one-way doors de `Landing` (5) | par form/controlador C49 · persistência e filtragem em memória C6/C11/C12 · fronteira de CEP C36/C37/C42 · regra de exclusão C45/C49 · lista `TcxMCListBox` C11/C14/C16 | - |
| entidades de `Relations` (3) | ESTADO C39/C41 · CIDADE C39/C41/C48 · CLIENTE C47/C48 | - |
| assemblies que compõem a navegação de clientes (2) | `CadCli.exe` C51/C52 · runner de testes C50/C51 | - |

- `Surface` é `None`: nenhuma rota exige join. Os estados `unauthorised` do `Observable` são `n/a` no plano (sem autenticação) e ficam fora do join; `rate limits` do ViaCEP é `n/a` no plano e fica coberto indiretamente por C30 (sem consulta quando o CEP não muda).
- C1-C10 e C17-C24, C29-C35, C43-C46 provam as tabelas de decisão dos controladores no próprio nível, com fakes. C12, C13 e C24 (segunda prova) provam a ligação da form real ao controlador; não substituem as provas de controlador, porque exercitam um caminho por tabela.
- C2 e C4 são table-driven: a enumeração dos membros vive no teste, e cada linha da tabela tem sua asserção.
- C36 usa um corpo real do ViaCEP gravado como constante no teste; nenhum teste acessa a rede externa. C38 usa somente loopback.
- C39, C41, C47 e C48 exigem o serviço Firebird 3 em `localhost:3050` e usam base temporária isolada, como a Parte 01.
- C52 não cria obrigação nova: registra que as provas de executável existentes continuam verdes com a nova composição.

## Test policy

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Regra de domínio pura (`TFiltroCliente`, validação de CPF/CNPJ, tabela de UFs) | uma prova no próprio nível, table-driven | uma linha asserida por filtro, por campo da busca geral, por caso de documento e por UF |
| Controlador que decide sem cruzar fronteira (`TControladorPesquisaCliente`, `TControladorCadastroCliente`) | uma prova unitária por desfecho, com visão, repositório, transação, relógio, confirmação, navegador e ViaCEP falsos | sucesso, cada validação, cancelamento, cada falha e reversão |
| Adaptador que decide tradução de fronteira (`TServicoViaCep`, transporte HTTP) | uma prova no próprio nível com transporte falso, e uma no transporte concreto por loopback | cada resposta HTTP e erro de transporte, e o tempo limite |
| Adaptador de persistência (repositório FireDAC) | uma prova de integração em base temporária no Firebird local | cada operação, os 3 casos de estado/cidade e a reversão sem órfãos |
| View passiva (`TFormPesquisaCliente`, `TFormCadastroCliente`) | uma prova com a form real, controlador real e fakes atrás dele | ligação de cada entrada, textos, arranjo, Enter como Tab, fechamento e controles DevExpress |
| Composição (navegadores concretos) | uma prova no próprio nível abrindo as forms reais modais | form criada, modo, resultado devolvido e liberação |

Evidence:

- `TFiltroCliente` (novo): decide 7 filtros e 8 campos de busca geral -> decide.
- `TControladorCadastroCliente` (novo): decide validações, consulta de CEP e transação -> decide.
- `TServicoViaCep` (novo): decide a tradução de 11 respostas para 4 resultados -> decide na fronteira.
- `Visao.NavegadorAplicacao.pas` (existe): passa a ter a tela de clientes registrada na composição (AD-010).
- Closest analogue: `tests/Unitarios/Testes.ControladorPrincipal.pas` (controlador com fakes), `tests/Unitarios/Testes.FormPrincipal.pas` (form real) e `tests/Unitarios/Testes.IntegracaoFirebird.pas` (base temporária no Firebird).

Cost: 52 checks, ~56 provas novas em 10 fixtures novas e 2 existentes (`TTestesNavegadorAplicacao`, `TTestesAplicacaoRelease`).

## Swept

- validation: C19, C20, C21, C22, C28, C32
- failure modes: C8, C13, C23, C34, C35, C46
- idempotency: C39 - repetir a resolução de estado/cidade não insere de novo; C30 - sair do CEP sem mudar não consulta de novo
- authorization: n/a - aplicação local sem autenticação (Observable: unauthorised)
- concurrency: n/a - aplicação monousuário com formulários modais; a exibição modal de C50 e C51 impede ações simultâneas na mesma instância
- data lifecycle: C41, C44, C47 - reversão sem órfãos, exclusão física de 1 linha, ID pela sequência
- dependency failure: C8, C23, C34, C37, C38, C46 - Firebird e ViaCEP indisponíveis
- state transitions: C9, C10, C24, C29 - pesquisa -> cadastro -> recarga, descarte e carregamento do CEP
- observability: C8, C23, C46 - mensagens fixas ao usuário sem texto de exceção nem credenciais; nenhum requisito de log nesta parte

## Decisões

Defaults derivados pelos checks, fixados com a aprovação deste arquivo:

- Textos não literais no plano: títulos `Pesquisa de Clientes`, `Novo Cliente` e `Editar Cliente`; mensagens `Não foi possível carregar os clientes.`, `Não foi possível salvar o cliente.`, `Não foi possível excluir o cliente.`, `O campo <rótulo> é obrigatório.`, `Descartar as alterações não salvas?`, `Excluir o cliente <ID> - <Nome>?`, `Serviço de CEP indisponível. Preencha o endereço manualmente.` e `Consultando CEP...`.
- Filtro `Estado` da pesquisa é um único campo: aceita pela UF exata ou pelo nome contendo o texto.
- Cidade e UF do cadastro são editáveis também manualmente (AC 18 e AC 19 exigem a correção manual); o salvamento resolve estado e cidade da mesma forma venham do ViaCEP ou digitados, e `UF` é uma lista fechada das 27 UFs. `Estado` é somente leitura, derivado de `UF`.
- CPF/CNPJ com todos os dígitos iguais é recusado como `CPF/CNPJ inválido` (C20), acrescentado ao AC 10 com aprovação do usuário.
- `UF` entra como obrigatório junto com `Cidade` (Assumption: todos os campos exceto `COMPLEMENTO`).
- C22: o salvamento recusa CEP com tamanho diferente de 8 dígitos, porque a coluna é `CHAR(8)` e o AC 9 só cobre vazio.
- C28: os editores limitam o tamanho às colunas do enunciado.
- Confirmações usam uma interface de confirmação injetada no controlador, falsa nos testes, e o diálogo real com título `CadCli`.

## Questões

- **Q1 -> AD-014:** a prova da Parte 02 C23 passa a asserir somente `AbrirRelatorio` sem tela registrada; a abertura real de clientes é provada por `ClientesAbrePesquisaRealSobreABase` (C51). Os artefatos `.specs` da Parte 02 não são alterados e as duas provas passam a ser obrigações desta parte.

## Handoff

- Arquivos existentes tocados: `src/Visao/Visao.ComposicaoAplicacao.pas` 0,4 KB + `src/Visao/Visao.NavegadorAplicacao.pas` 2,1 KB + `CadCli.dpr` 2,3 KB + `CadCli.dproj` 6,3 KB + `tests/CadCli.Testes.dpr` 5,5 KB + `tests/CadCli.Testes.dproj` 5,7 KB + `tests/Unitarios/Testes.NavegadorAplicacao.pas` 7,8 KB + `tests/Unitarios/Testes.IntegracaoFirebird.pas` 38,1 KB (helpers de base temporária) = 68,2 KB; novos estimados: domínio (cliente, filtro, validação, UFs) ~15 KB + 2 controladores ~20 KB + repositório e conexão FireDAC ~12 KB + ViaCEP e transporte ~10 KB + 2 forms `.pas`/`.dfm` ~40 KB + navegador de clientes ~3 KB + 10 fixtures e fakes ~75 KB = ~175 KB; total ~243 KB / 4 = ~61k tokens, abaixo do budget de 150k - one builder.
- Mechanism: one builder - o escopo cabe no orçamento; build pedido pelo usuário em 2026-09-21.
- Decidido durante o build: a grade `TcxGridTableView` não compila no ambiente (Delphi 12.1 + DevExpress 2026.1.4 trial, E2225 em `cxInplaceContainer`); o usuário escolheu `TcxMCListBox` (AD-015, door 5) e aprovou a reescrita de C11.
- Branch: `feat/parte-03-clientes-crud` (atual).
- Pré-requisitos: serviço Firebird 3 em `localhost:3050`; build como na Parte 02 (`rsvars.bat` + `MSBuild.exe` Release do `CadCli.dproj` e Debug do `tests\CadCli.Testes.dproj`); o aviso trial do DevExpress é tratado por AD-013.
- O runner precisa mapear as 10 novas fixtures em `QualificarTeste` para que os filtros curtos dos `Proof:` resolvam.
- Fontes Delphi novos em UTF-8 com BOM (AGENTS.md).
- Estado do build (2026-09-21): C1-C52 fechados; as 57 provas passam isoladas (exit 0, 1 teste cada) e a suíte completa passa com 107/107.
- Verificação round 1 (bb5f82d): FAIL. Um mutante sobreviveu: exigir `estado` no JSON do ViaCEP não quebrava nenhuma prova. Além disso, a ligação CEP/UF da `TFormCadastroCliente` real não tinha prova. Correção só em testes, sem mudar checks: casos sem `estado` em C36/C37/C40 e o teste extra `TTestesFormCadastroCliente.CepEUfDaTelaAcionamOControlador`. Suíte 108/108.

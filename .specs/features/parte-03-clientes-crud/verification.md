# Parte 03 - CRUD e pesquisa de clientes verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: c436143..0220fa2 (`feat/parte-03-clientes-crud`, HEAD = 0220fa2); fix under review bb5f82d..0220fa2
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

A correção (`bb5f82d..0220fa2`) mexe só em testes: `tests/Suporte/Suporte.FakesClientes.pas`, `tests/Unitarios/Testes.ServicoViaCep.pas`, `tests/Unitarios/Testes.ControladorCadastroCliente.pas`, `tests/Unitarios/Testes.FormsClientes.pas`, além de uma nota de Handoff em `checks.md`. Nenhum arquivo de `src/` mudou e nenhum check mudou. Os dois achados do round 1 estão fechados.

1. **Mutante `estado` obrigatório: agora morto.** Reapliquei a mesma mutação do round 1 (`CHAVES_OBRIGATORIAS` passa a incluir `'estado'`, `src/Infraestrutura/Infraestrutura.ServicoViaCep.pas:32`). As três provas que cobrem o membro falharam: C36, C37 e C40.
2. **Test policy "View passiva": agora atendida.** O teste novo `TTestesFormCadastroCliente.CepEUfDaTelaAcionamOControlador` (`tests/Unitarios/Testes.FormsClientes.pas:577`) usa a form real. Ele sai do CEP pelo foco, verifica a consulta, o indicador durante a consulta, o preenchimento dos editores e a troca de UF. Três mutações na ligação da form (`OnExit`, `UfAlterada` e indicador) foram mortas por esse teste.

Seções marcadas `verified at 0220fa2` foram refeitas neste round. Seções marcadas `carried from bb5f82d` foram herdadas do round 1, com as citações de linha atualizadas nos arquivos que a correção tocou.

## Binding sources

`carried from bb5f82d`. O passo 1 não é refeito porque a correção não tocou nenhuma interface nem tela: não há mudança em `src/` nem em `.dfm`. Só atualizei as linhas citadas de `Testes.ServicoViaCep.pas`, porque o arquivo mudou.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| `.specs/Teste Programador Delphi 2026.md` (Item 2, Item 4) | sim, no round 1 (lido na íntegra) | nenhuma: pesquisa por ID, NOME, CPF/CNPJ, CEP, CIDADE, ESTADO, DATANASCIMENTO = C2/C12; IDs 1, 5, 8, 10, 15 = C45; FireDAC = C47/C48; CEP ao mudar de campo, alerta de inválido e preenchimento de endereço/bairro/cidade/estado = C29-C35 (e agora também na form real, `Testes.FormsClientes.pas:606-615`); Enter como Tab = C25; DevExpress = C11/C16; tamanhos do Item 4 = C28; transação = C17/C18/C44/C41 | - |
| ViaCEP (https://viacep.com.br/) | sim, no round 1 (WebFetch em 2026-09-21) | nenhuma: URL `viacep.com.br/ws/{CEP}/json/` com 8 dígitos = C36 (`Testes.ServicoViaCep.pas:93`); formato inválido -> HTTP 400 = C37 (:145); CEP inexistente -> `"erro": "true"` = C37 (:146), booleano (:147); campos `cep, logradouro, complemento, bairro, localidade, uf, estado` = C36 (:95-101); 200 sem `estado` = C36 (:103-110) e C37 (:158); alerta contra uso massivo = C30 | - |
| Transações FireDAC (docwiki Embarcadero) | não - HTTP 403 no WebFetch do round 1; a página não foi lida | não avaliada contra a página; o padrão `StartTransaction`/`Commit`/`Rollback` (`Infraestrutura.RepositorioClienteFireDAC.pas:236-250`) é provado em base real por C41 | - |

A enumeração das telas foi herdada do round 1 sem mudança. Pesquisa: 7 filtros + busca geral (C12, C14), 3 regiões alTop/alClient/alBottom (C15), `TcxMCListBox` com 8 seções (C11, C14). Cadastro: 10 editores + Estado somente leitura, com Salvar/Cancelar em `alBottom` (C26, C27, C28), e Enter como Tab (C25). Nenhum elemento ficou sem check.

## Checks

`verified at 0220fa2`. Os resultados são deste round. As citações dos arquivos tocados foram atualizadas: `Testes.ServicoViaCep.pas`, `Testes.ControladorCadastroCliente.pas` (+16 linhas) e `Testes.FormsClientes.pas` (+3 antes de :577 e +64 depois). As dos demais arquivos são as do round 1, e as linhas conferem porque esses arquivos não mudaram.

- **Build em 0220fa2:** `build.bat` (Release/Win64 de `CadCli.dproj` com cópia de 13 BPLs + Debug/Win64 de `tests\CadCli.Testes.dproj`), exit 0.
- **Batch das provas:** as 57 provas distintas de `checks.md` (`grep -o 'run:[A-Za-z0-9_.]*' | sort -u` = 57) mais o teste novo `TTestesFormCadastroCliente.CepEUfDaTelaAcionamOControlador` rodaram numa única invocação: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:<58 nomes> --exitbehavior:Continue`. O filtro é exato, o que o round 1 já tinha mostrado.
  - Primeira invocação: `Found 58 / Passed 57 / Failed 1`. Falhou `TTestesFormCadastroCliente.EnterAvancaNaOrdemDeTabulacaoAteSalvar` (C25) com "Enter em EditorUf deve focar BotaoSalvar."
  - Repeti o batch duas vezes: `Found 58 / Passed 58`, exit 0 nas duas.
  - A prova de C25 isolada passou 3/3, e as 6 provas da fixture `TTestesFormCadastroCliente` passaram juntas 3/3. Portanto não há dependência de ordem com o teste novo. A falha foi intermitente e depende do foco de janela (ver Notes).
- **Suíte completa:** exit 0, 108/108, igual aos 108 atributos `[Test]` em `tests/Unitarios`.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | abertura: `ListarTodos` 1x, 3 clientes em ID 1,5,8 com 8 campos | batch 58/58 (def `Testes.ControladorPesquisaCliente.pas:95`) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:109` `Assert.AreEqual(1, FRepositorioObjeto.ChamadasListarTodos)`; :110 `AreEqual(3, Length(Exibidos))`; :111 `AreEqual('1,5,8', IdsExibidos)`; :114-122 os 8 campos | PASS (carried citation) |
| C2 | 7 filtros por campo, aceita/rejeita a tabela | batch 58/58 (def `Testes.FiltroCliente.pas:94`) | `tests/Unitarios/Testes.FiltroCliente.pas:116` `Assert.AreEqual(LCaso.Aceita, FiltroCom(...).Atende(...))` sobre os 15 casos de :100-114; :118 `AreEqual('1', IdsAceitos(data))` | PASS (carried citation) |
| C3 | nome+estado por AND; vazios aceitam 5 | batch 58/58 (def :122) | `tests/Unitarios/Testes.FiltroCliente.pas:129-131`; :132 `AreEqual('1', ...)`; :133 `AreEqual('1,10,15,150,23', IdsAceitos(Default(TFiltroCliente)))` | PASS (carried citation) |
| C4 | busca geral alcança os 8 campos | batch 58/58 (def :137) | `tests/Unitarios/Testes.FiltroCliente.pas:145`-:189, um positivo por campo com negativo sobre `ClienteNeutro` | PASS (carried citation) |
| C5 | cada palavra, dígitos, espaços, AND com estado | batch 58/58 (def :192) | `tests/Unitarios/Testes.FiltroCliente.pas:198-201` `AreEqual('15', IdsAceitos('silva campinas'))`; :204; :207-208; :212 | PASS (carried citation) |
| C6 | 3 pesquisas sem nova consulta | batch 58/58 (def `Testes.ControladorPesquisaCliente.pas:128`) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:137`/:141/:145; :147 `AreEqual(1, ChamadasListarTodos)`; :149 `AreEqual(1, TotalChamadas)` | PASS (carried citation) |
| C7 | vazio: mensagem e ações desabilitadas | batch 58/58 (def :152) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:157` `AreEqual('Nenhum cliente encontrado', ...)`; :158 `IsFalse(AcoesHabilitadas)`; :167/:176 `IsTrue` | PASS (carried citation) |
| C8 | falha na carga: 1 erro fixo, 0 clientes | batch 58/58 (def :179) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:184-187`; :204 `AreEqual(0, Length(Exibidos))` | PASS (carried citation) |
| C9 | Novo: 1x inclusão; salvo recarrega e reaplica `silva` | batch 58/58 (def :208) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:218` `AreEqual(1, ChamadasInclusao)`; :231; :232 `AreEqual('1,15,200', IdsExibidos)` | PASS (carried citation) |
| C10 | Editar ID 7: recarga só se salvo | batch 58/58 (def :237) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:247-250`; :256; :257 `'1,7,15'` | PASS (carried citation) |
| C11 | `TcxMCListBox`, 8 seções, sem grade, ordem 1,5,8 | batch 58/58 (def `Testes.FormsClientes.pas:211`) | `tests/Unitarios/Testes.FormsClientes.pas:220` `AreEqual('TcxMCListBox', ListaClientes.ClassName)`; :221 `AreEqual(8, HeaderSections.Count)`; :222 `Sorted`; :224 `AllowClick`; :228-232 sem classes de grade; :234 `AreEqual('1,5,8', IdsDaLista(FForm))` | PASS |
| C12 | form real: 8 entradas do painel filtram, 1 `ListarTodos` | batch 58/58 (def :237) | `tests/Unitarios/Testes.FormsClientes.pas:278` `AreEqual(LCaso.Esperados, IdsDaLista(FForm))` sobre as 8 entradas de :246-253, após `BotaoPesquisar.Click` (:277); :280 `AreEqual(1, ChamadasListarTodos)` | PASS |
| C13 | form real, recarga falha: filtros mantidos, 0 linhas, aviso | batch 58/58 (def :284) | `tests/Unitarios/Testes.FormsClientes.pas:299` `AreEqual(1, Mensagens.Count)`; :301 0 itens; :302-303 `RotuloSemResultado`; :304-311 os 8 editores | PASS |
| C14 | textos da pesquisa | batch 58/58 (def :314) | `tests/Unitarios/Testes.FormsClientes.pas:322` `'Pesquisa de Clientes'`; :323-334; :337 `AreEqual(COLUNAS[I], HeaderSections[I].Text)`; :339-343 nenhum extra | PASS |
| C15 | arranjo alTop/alClient/alBottom e ordem dos botões | batch 58/58 (def :346) | `tests/Unitarios/Testes.FormsClientes.pas:349-351` `Align`; :352-353 `Top`; :357-358 `Left`; :359 `BotaoPesquisar.Parent = PainelFiltros` | PASS |
| C16 | só controles `dx`/`cx` | batch 58/58 (def :840) | `tests/Unitarios/Testes.FormsClientes.pas:831` `IsTrue(UnitDevExpress(Components[I].ClassType))`; :809; :836 `AreEqual(0, LProibidos)`; :837 `IsTrue(LVerificados >= AMinimo)` | PASS |
| C17 | inclusão: Iniciar/Resolver/Incluir/Confirmar, ID 42 | batch 58/58 (def `Testes.ControladorCadastroCliente.pas:142`) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:149` `AreEqual` da sequência `Iniciar`, `ResolverCidade`, `Incluir`, `Confirmar` (unida por barra vertical); :150-152; :153 `AreEqual(42, IdExibido)`; :154 `IsTrue(Salvo)` | PASS |
| C18 | alteração do ID 7 | batch 58/58 (def :164) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:170` `AreEqual` da sequência `Iniciar`, `ResolverCidade`, `Alterar:7`, `Confirmar` (unida por barra vertical); :171-173; :175 `AreEqual(7, IdExibido)` | PASS |
| C19 | 9 obrigatórios, primeiro focado, complemento opcional | batch 58/58 (def :179) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:211` `AreEqual(0, Iniciadas)`; :212 `AreEqual('O campo ' + ROTULOS[LCampo] + ' é obrigatório.', ...)`; :213 `CampoFocado = LCampo`; :224-226; :233-234 | PASS |
| C20 | CPF/CNPJ válidos/inválidos e dígitos gravados | batch 58/58 (def `Testes.ValidacaoCliente.pas:70`) | `tests/Unitarios/Testes.ValidacaoCliente.pas:83-85` `AreEqual(GRAVADOS[I], CpfGravado)`; :90-91 `AreEqual('CPF/CNPJ inválido', ...)`; :93-95 | PASS (carried citation) |
| C21 | relógio 21/09/2026: 22/09 recusa, 21/09 aceita | batch 58/58 (def `Testes.ControladorCadastroCliente.pas:237`) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:243` `AreEqual('Data de nascimento não pode estar no futuro', ...)`; :244; :249-250 | PASS |
| C22 | CEP `0100100` recusa; `01001-000` grava `01001000` | batch 58/58 (def :253) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:259-260` `AreEqual('CEP inválido', ...)`; :266 `AreEqual('01001000', UltimoIncluido.Cep)` | PASS |
| C23 | falha em Incluir/Alterar: reverte 1x, mensagem fixa, visão intacta | batch 58/58 (def :269) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:280-282` `AreEqual(1, Revertidas)`, `AreEqual('Não foi possível salvar o cliente.', ...)`; :283-286; :297-301 em `Alterar` | PASS |
| C24 | descarte: 1 confirmação, Não mantém, Sim fecha; controlador + form real | batch 58/58 (defs `Testes.ControladorCadastroCliente.pas:304`, `Testes.FormsClientes.pas:395`) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:307-322`, :329-330; `tests/Unitarios/Testes.FormsClientes.pas:404` `AreEqual(1, Mensagens.Count)`; :405 texto; :406 `IsTrue(FForm.Visible)`; :412-414; :422-423 | PASS |
| C25 | Enter percorre os 10 editores até Salvar sem salvar | batch 58/58 nas invocações 2 e 3; isolado 3/3 (def `Testes.FormsClientes.pas:438`) | `tests/Unitarios/Testes.FormsClientes.pas:456` `IsTrue(LOrdem[I].Focused)` sobre a ordem de :447-449; :457; :459-461 0 chamadas, não salvo. Uma falha intermitente na 1ª invocação (ver Notes) | PASS |
| C26 | textos do cadastro | batch 58/58 (def :464) | `tests/Unitarios/Testes.FormsClientes.pas:468` `'Novo Cliente'`; :473 `'Editar Cliente'`; :474-487 inclusive `Consultando CEP...` (:487); :488-492 nenhum extra | PASS |
| C27 | arranjo do cadastro, vazio inicial, indicador invisível | batch 58/58 (def :495) | `tests/Unitarios/Testes.FormsClientes.pas:510`; :513-516 Estado na linha de UF, `ReadOnly`; :517 `alBottom`; :520; :523-533 vazios; :534 `IsFalse(RotuloConsultandoCep.Visible)` | PASS |
| C28 | `MaxLength` por coluna, UF com 27, dígitos gravados | batch 58/58 (def :537) | `tests/Unitarios/Testes.FormsClientes.pas:543-550` `AreEqual(80/.../50, Properties.MaxLength)`; :551 `lsFixedList`; :552 `AreEqual(27, Items.Count)`; :556; :572-573 14 e 8 dígitos | PASS |
| C29 | CEP alterado: 1 consulta `01001000`, carregamento em ordem | batch 58/58 (def `Testes.ControladorCadastroCliente.pas:333`) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:339` `AreEqual(1, Chamadas)`; :340 `AreEqual('01001000', UltimoCep)`; :341 `AreEqual` da sequência `Carregamento:True`, `PreencherEndereco`, `Carregamento:False` (unida por barra vertical). Na form real (fora do `Proof:`): `Testes.FormsClientes.pas:606-610` | PASS |
| C30 | sem mudança de dígitos: 0 consultas | batch 58/58 (def :346) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:354` `AreEqual(0, Chamadas)`; :355-356; :365-367 só máscara | PASS |
| C31 | encontrado preenche 5 campos e preserva número/complemento | batch 58/58 (def :370) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:378-382` `'Praça da Sé'`, `'Sé'`, `'São Paulo'`, `'SP'`, `'São Paulo'`; :383-384 `'100'`, `'sala 2'`. Na form real: `Testes.FormsClientes.pas:611-617` | PASS |
| C32 | 7 e 9 dígitos: 0 consultas, `CEP inválido` 1x | batch 58/58 (def :388) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:398` `AreEqual(0, Chamadas)`; :399; :400 `AreEqual('CEP inválido', Mensagens[0])` | PASS |
| C33 | não encontrado: mensagem, valores mantidos | batch 58/58 (def :404) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:417` `AreEqual('CEP não encontrado', ...)`; :418 `Dados = LAntes`; :420 ordem de carregamento | PASS |
| C34 | indisponível: mensagem, valores iguais | batch 58/58 (def :424) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:435` `AreEqual('Serviço de CEP indisponível. Preencha o endereço manualmente.', ...)`; :437; :439 `Dados = LAntes` | PASS |
| C35 | resposta inválida: mensagem, 0 preenchimentos | batch 58/58 (def :442) | `tests/Unitarios/Testes.ControladorCadastroCliente.pas:454` `AreEqual('Resposta inválida do serviço de CEP', ...)`; :455 `AreEqual(0, Preenchimentos)`; :456 | PASS |
| C36 | URL exata e corpo real -> `TEnderecoViaCep` | batch 58/58 (def `Testes.ServicoViaCep.pas:80`) | `tests/Unitarios/Testes.ServicoViaCep.pas:93` `AreEqual('https://viacep.com.br/ws/01001000/json/', Urls[0])`; :94 `scEncontrado`; :95-101 os 7 campos; corpo sem `estado`: :105 `IsFalse(Corpo.Contains('"estado"'))`, :107 `IsTrue(Situacao = scEncontrado)`, :108 `AreEqual('', Endereco.Estado)` | PASS |
| C37 | respostas traduzidas, nenhuma propaga | batch 58/58 (def :113) | `tests/Unitarios/Testes.ServicoViaCep.pas:173` `AreEqual(Ord(LCaso.Esperado), Ord(LResultado.Situacao))` sobre :145-158 (inclui :158 `'sem estado'` -> `scEncontrado`); :170 `Assert.Fail` se propagar; :175 `AreEqual(14, Length(LCasos))`; :180 `scFormatoInvalido` para `0100100`, :182 0 URLs | PASS |
| C38 | socket loopback mudo -> tempo esgotado entre 9,5 e 13 s | batch 58/58 (def :185) | `tests/Unitarios/Testes.ServicoViaCep.pas:222` `AreEqual(Ord(srTempoEsgotado), ...)`; :223 `>= 9500`; :224 `<= 13000` | PASS |
| C39 | 3 casos de estado/cidade e repetição | batch 58/58 (def `Testes.RepositorioClienteFirebird.pas:107`) | `tests/Unitarios/Testes.RepositorioClienteFirebird.pas:120-149` | PASS (carried citation) |
| C40 | nome do estado: do ViaCEP quando preenchido; da tabela quando vazio **ou ausente**; 27 UFs | batch 58/58 (defs `Testes.ValidacaoCliente.pas:101`, `Testes.ControladorCadastroCliente.pas:459`) | `tests/Unitarios/Testes.ValidacaoCliente.pas:114` `AreEqual(27, Length(UNIDADES_FEDERATIVAS))`; :118; `tests/Unitarios/Testes.ControladorCadastroCliente.pas:474` do ViaCEP; :489/:491 vazio -> `Santa Catarina`; :502/:505 DF; **ausente**, com `TServicoViaCep` real e JSON sem `estado`: :518 `AreEqual(0, Mensagens.Count)`, :521 `AreEqual('Santa Catarina', Dados.Estado)`, :523 `AreEqual('Santa Catarina', UltimoEstado)`. Mutante 1 morto | PASS |
| C41 | falha após criar SC/Florianópolis não deixa órfãos | batch 58/58 (def `Testes.RepositorioClienteFirebird.pas:152`) | `tests/Unitarios/Testes.RepositorioClienteFirebird.pas:186`; :191-194; :195 `IsFalse(InTransaction)`; :196-198 contagens iguais | PASS (carried citation) |
| C42 | controlador de cadastro sem JSON/REST/Net/Infraestrutura | batch 58/58 (def `Testes.FormsClientes.pas:872`) | `tests/Unitarios/Testes.FormsClientes.pas:880-881` `AssegurarSemReferencias(... ['System.JSON','REST.','System.Net.','Infraestrutura.'])`; :882; :888 `FieldType.Handle = TypeInfo(TEnderecoViaCep)`; :897 os 7 campos | PASS |
| C43 | confirmação `Excluir o cliente 7 - Ana Silva?` antes da transação | batch 58/58 (def `Testes.ControladorPesquisaCliente.pas:260`) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:269-273` | PASS (carried citation) |
| C44 | confirmada: Iniciar/Excluir 7/Confirmar/ListarTodos | batch 58/58 (def :277) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:288` `AreEqual` da sequência `Confirmacao`, `Iniciar`, `Excluir:7`, `Confirmar`, `ListarTodos` (unida por barra vertical); :293 `'1,15'` | PASS (carried citation) |
| C45 | IDs 1,5,8,10,15 protegidos | batch 58/58 (def :297) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:320-322`; :324 `AreEqual('Cliente protegido não pode ser excluído', Avisos[0])`; :331 | PASS (carried citation) |
| C46 | falha na exclusão: reverte, mensagem, 7 continua | batch 58/58 (def :335) | `tests/Unitarios/Testes.ControladorPesquisaCliente.pas:345-349` | PASS (carried citation) |
| C47 | Incluir 101, nome hostil, Alterar, Excluir | batch 58/58 (def `Testes.RepositorioClienteFirebird.pas:201`) | `tests/Unitarios/Testes.RepositorioClienteFirebird.pas:218` `AreEqual(101, LId)`; :222 `AreEqual(NOME_HOSTIL, LLido.Nome)`; :236-242 | PASS (carried citation) |
| C48 | ListarTodos 10,20,30 com cidade/UF/estado | batch 58/58 (def :246) | `tests/Unitarios/Testes.RepositorioClienteFirebird.pas:270-282` | PASS (carried citation) |
| C49 | form/visão/controlador 1:1, sem infraestrutura, cadastro sem `Excluir` | batch 58/58 (def `Testes.FormsClientes.pas:900`) | `tests/Unitarios/Testes.FormsClientes.pas:912-913` `Supports(...)`; :919/:924 `AreEqual(1, LQuantidade)`; :926-929 `AssegurarSemReferencias`; :933 `IsFalse(ContainsText(LMetodo.Name, 'Excluir'))`; :935 | PASS |
| C50 | navegador de clientes: 1 cadastro modal por modo, `salvo` correto | batch 58/58 (def :674) | `tests/Unitarios/Testes.FormsClientes.pas:724` `AreEqual(1, FExibicoes)`; :725 `IsTrue(FModal)`; :726 título; :727 `AreEqual(LCaso.Salvo, LResultado)` nos 4 casos de :683-687; :734 `AreEqual(LFormsAntes, Screen.FormCount)` | PASS |
| C51 | composição do exe: pesquisa modal real; relatório lança `ENavegacaoSemTela` | batch 58/58 (defs `Testes.NavegadorAplicacao.pas:222`, :280) | `tests/Unitarios/Testes.NavegadorAplicacao.pas:232-237`; :305-310; `CadCli.dpr:57` `ComporNavegador(LFormPrincipal, FBanco.Conexao)` | PASS (carried citation) |
| C52 | provas de executável da Parte 01/02 continuam verdes | batch 58/58 (defs `Testes.IntegracaoFirebird.pas:942`, :984, :712), com Release reconstruído em 0220fa2 | `tests/Unitarios/Testes.IntegracaoFirebird.pas:450`; :457 `AreEqual('CadCli', TextoJanela(...))`; :461 `AreEqual(Cardinal(0), LCodigoSaida)`; :990-991; :736; :742-745 | PASS (carried citation) |

**Checks provados: 52/52.** "carried citation" quer dizer que a linha citada vem do round 1 porque o arquivo não mudou. O resultado em si foi obtido em 0220fa2.

## Coverage

`verified at 0220fa2` para as linhas cujos membros estavam sem prova ou cuja autoridade a correção tocou: respostas HTTP do ViaCEP, situações de `IServicoViaCep`, origem do nome do estado, ligações de eventos da form de cadastro e estados do `Observable` do cadastro. As demais linhas são `carried from bb5f82d`, com as linhas de teste atualizadas.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| respostas HTTP do ViaCEP (contrato) - verified at 0220fa2 | viacep.com.br: 400, 200 com `erro`, 200 com endereço, 200 sem `estado`; mais falhas de transporte | 400 C37 (:145) · `erro` texto/bool C37 (:146-147) · 200 completo C36 (:93-101) · **200 sem `estado`** C36 (:105-108) e C37 (:158) · 500/exceção/falha/timeout C37 (:148-151)/C38 (:222) · corpo não-objeto/sem chave obrigatória C37 (:152-157) | - |
| situações de `IServicoViaCep` (5) - verified at 0220fa2 | `Aplicacao.ServicoViaCep.pas:16-17` + `Infraestrutura.ServicoViaCep.pas:102-103` | encontrado C31/C36 · não encontrado C33/C37 · indisponível C34/C37/C38 · resposta inválida C35/C37 · `scFormatoInvalido` no serviço C37 (`Testes.ServicoViaCep.pas:180-182`, mutante 5 morto) | - |
| origem do nome do estado (3) - verified at 0220fa2 | AC 21 | JSON com `estado` C40 (`Testes.ControladorCadastroCliente.pas:474`) · `estado` vazio C40 (:489, :491) · **`estado` ausente no JSON** C40 (:518-523, com `TServicoViaCep` real) + C36 (`Testes.ServicoViaCep.pas:108`) | - |
| ligações de eventos da form de cadastro (6) - verified at 0220fa2 | `Visao.FormCadastroCliente.dfm:84-85,177` + `Visao.FormCadastroCliente.pas:165-200` | Salvar C28 (`Testes.FormsClientes.pas:570`) · Cancelar/Close C24 (:403, :410) · Enter C25 (:456) · **CEP OnExit** `CepEUfDaTelaAcionamOControlador` (:603-606, mutante 2 morto) · **CEP OnEnter**: sem ele o controlador não consulta ao sair (C30, `Testes.ControladorCadastroCliente.pas:359`), então :606 cai · **UF OnChange -> `UfAlterada`** (:633-635, mutante 3 morto) | - |
| estados do `Observable` - CadastroCliente (5 aplicáveis) - verified at 0220fa2 | plano `Observable` | empty C27 (:523-534) · loading C29 (controlador) + form real (`Testes.FormsClientes.pas:608-610`, mutante 4 morto) · error C23/C33-C35 + form real `CEP inválido` (:631) · density C25/C27 · destructive C24 | - |
| filtros por campo (7) - carried from bb5f82d | enunciado Item 2 + `Dominio.FiltroCliente.pas:76-91` | C2 (`Testes.FiltroCliente.pas:116`), C12 (`Testes.FormsClientes.pas:278`) | - |
| campos da busca geral (8) - carried | AC 3 + `Dominio.FiltroCliente.pas:49-60` | C4 (`Testes.FiltroCliente.pas:145-189`) | - |
| regras da busca geral (4) - carried | AC 3 + `Dominio.FiltroCliente.pas:67-70,92` | C5 (`Testes.FiltroCliente.pas:198-212`) | - |
| entradas do painel de pesquisa (8) - carried | `Visao.FormPesquisaCliente.pas:109-122` | C12 (`Testes.FormsClientes.pas:246-253`, :278) | - |
| campos obrigatórios (9) - carried | AC 9 + `Aplicacao.ControladorCadastroCliente.pas:271-273` | C19 (`Testes.ControladorCadastroCliente.pas:211-213`) | - |
| casos de CPF/CNPJ (9) - carried | AC 10 + `Dominio.ValidacaoCliente.pas` | C20 (`Testes.ValidacaoCliente.pas:72-91`) | - |
| ordem de Enter (10 + Salvar) - carried | AC 12 + DFM `TabOrder` 0-10 | C25 (`Testes.FormsClientes.pas:447-456`) | - |
| saídas do CEP (4) - carried | AC 15/17 + `Aplicacao.ControladorCadastroCliente.pas:201-215` | alterado C29 (`Testes.ControladorCadastroCliente.pas:339`) · sem mudança C30 (:354) · só máscara C30 (:365) · tamanho errado C32 (:398) | - |
| tabela de UFs (27) - carried | `Dominio.UnidadesFederativas.pas:12-39` | C40 (`Testes.ValidacaoCliente.pas:114,118`) | - |
| IDs protegidos (5) - carried | door 4 + `Aplicacao.ControladorPesquisaCliente.pas:51` | C45 (`Testes.ControladorPesquisaCliente.pas:320-324`) | - |
| desfechos da exclusão (4) - carried | `Aplicacao.ControladorPesquisaCliente.pas:185-212` | C43 · C44 · C45 · C46 | - |
| operações de `IRepositorioCliente` (6) - carried | `Aplicacao.RepositorioCliente.pas:10-16` | C47 (`Testes.RepositorioClienteFirebird.pas:218-242`) · C48 · C39/C41 | - |
| escritas em transação (3) - carried | `Aplicacao.ControladorCadastroCliente.pas:314-331`, `Aplicacao.ControladorPesquisaCliente.pas:198-209` | inclusão C17/C23 · alteração C18/C23 · exclusão C44/C46; reversão real C41 | - |
| casos estado/cidade (3) - carried | AC 20 + `Infraestrutura.RepositorioClienteFireDAC.pas:202-226` | C39 (`Testes.RepositorioClienteFirebird.pas:120-145`) | - |
| resultados do navegador de clientes (4) - carried | `Visao.NavegadorClientes.pas:51-66` | C50 (`Testes.FormsClientes.pas:683-687`, :727) | - |
| estados do `Observable` - PesquisaCliente (5) - carried | plano `Observable` | empty C7/C13 · loading C1 · error C8/C13 · density C14/C15 · destructive C43/C45 | - |
| textos PesquisaCliente (26) / CadastroCliente (25) - carried | DFMs + constantes | C14/C26 (`Testes.FormsClientes.pas:339-343`, :488-492) | - |
| arranjo das duas telas (4 + 4) - carried | `Decisões` + DFMs | C15, C27 | - |
| one-way doors (5) - carried | `Landing` | door 1 C49 · door 2 C6/C12 · door 3 C36/C37/C42 · door 4 C45/C49 · door 5 C11/C14/C16 | - |
| assemblies que compõem clientes (2) - carried | `CadCli.dpr:57`, `Visao.ComposicaoAplicacao.pas:53-66` | exe C52 + `CadCli.dpr:57` · runner C50/C51 | - |
| entidades de `Relations` (3) - carried | plano | ESTADO C39/C41 · CIDADE C39/C41/C48 · CLIENTE C47/C48 | - |

## Test policy rows

Rejulguei `verified at 0220fa2` as duas linhas que falharam no round 1 e as que classificam arquivos tocados pela correção. As outras são `carried from bb5f82d`.

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Regra de domínio pura (carried) | `Dominio.FiltroCliente.pas`, `Dominio.ValidacaoCliente.pas`, `Dominio.UnidadesFederativas.pas` | própria camada, table-driven: C2, C4, C5, C20, C40 | yes - uma linha por filtro, por campo, por documento e por UF |
| Controlador que decide sem cruzar fronteira (verified at 0220fa2) | `Aplicacao.ControladorPesquisaCliente.pas`, `Aplicacao.ControladorCadastroCliente.pas` | unitária com fakes por desfecho: C1-C10, C17-C24, C29-C35, C40, C43-C46 | yes - sucesso, cada validação, cancelamento, cada falha e reversão; o teste tocado (C40) segue com fakes e ganhou o caso de JSON sem `estado` |
| Adaptador que decide tradução de fronteira (verified at 0220fa2) | `Infraestrutura.ServicoViaCep.pas`, `Infraestrutura.TransporteHttp.pas` | transporte falso C36/C37 + loopback C38 | yes - cada resposta HTTP do contrato, inclusive 200 sem `estado` (`Testes.ServicoViaCep.pas:158`), cada erro de transporte, formato inválido (:180) e o tempo limite (:222-224); mutantes 1 e 5 mortos |
| Adaptador de persistência (carried) | `Infraestrutura.RepositorioClienteFireDAC.pas` | integração em base temporária: C39, C41, C47, C48 | yes - cada operação, os 3 casos e a reversão sem órfãos |
| View passiva (verified at 0220fa2) | `Visao.FormPesquisaCliente.pas/.dfm`, `Visao.FormCadastroCliente.pas/.dfm` | form real + controlador real + fakes: C11-C16, C24-C28 + `CepEUfDaTelaAcionamOControlador` | yes - pesquisa: cada entrada ligada (C12). Cadastro: CEP OnEnter/OnExit com consulta (`Testes.FormsClientes.pas:606-607`), indicador visível durante a consulta e oculto depois (:608-610), preenchimento dos editores preservando número/complemento (:611-617), CEP sem alteração (:623), CEP incompleto (:630-631), UF OnChange -> Estado (:635), Salvar (:570), fechamento (:404-423), Enter (:456), textos, arranjo e DevExpress; mutantes 2, 3 e 4 mortos |
| Composição (carried) | `Visao.NavegadorClientes.pas`, `Visao.ComposicaoAplicacao.pas`, `CadCli.dpr` | forms reais modais: C50, C51 | yes |

## Swept existing

`carried from bb5f82d`. Nenhuma linha de `Swept` cita restrição de código existente. `idempotency` confere com C39 e C30. `authorization` e `concurrency` são `n/a`.

## Faults injected

`verified at 0220fa2`. Refiz a injeção só nas superfícies que a correção tocou ou criou: o membro `estado` ausente, o ramo de formato inválido agora asserido e a ligação da form que o teste novo reivindica.

- **Isolamento:** `git worktree add <scratchpad>\wt2 HEAD` (0220fa2). Recompilei só o runner Debug/Win64 no worktree com um `.bat` próprio que faz `cd /d` para ele. Controle antes das mutações: as 4 provas-alvo passaram (4/4).
- **Execução:** cada mutação foi aplicada por substituição exata de uma ocorrência. Em seguida, recompilei, rodei a prova mais estreita e revertei com `git checkout -- <arquivo>`, e o `git status --porcelain` do worktree voltou vazio.
- **Árvore real:** o `git status --porcelain` antes (`?? .specs/features/parte-03-clientes-crud/verification.md`) é igual ao de depois (`diff` vazio). Removi o worktree com `git worktree remove --force` + `prune`, e `git worktree list` mostra só a árvore real.

| Mutation | Location | Killed |
| --- | --- | --- |
| mutante do round 1: `CHAVES_OBRIGATORIAS` ganha `'estado'`, então 200 sem `estado` vira resposta inválida | `src/Infraestrutura/Infraestrutura.ServicoViaCep.pas:32` | yes - 3/3 falharam: C36 "Sem a chave estado o endereço continua encontrado." (`Testes.ServicoViaCep.pas:107`); C37 "Expected [0] but got [3] sem estado" (:173); C40 "Expected [0] but got [1] JSON sem estado não é resposta inválida." (`Testes.ControladorCadastroCliente.pas:518`) |
| `EditorCepExit` deixa de chamar `FControlador.CepPerdeuFoco` | `src/Visao/Visao.FormCadastroCliente.pas:185` | yes - `CepEUfDaTelaAcionamOControlador` "Expected [1] but got [0] Sair do CEP alterado na tela deve consultar o ViaCEP 1 vez." (`Testes.FormsClientes.pas:606`) |
| `EditorUfPropertiesChange` deixa de chamar `FControlador.UfAlterada` | `src/Visao/Visao.FormCadastroCliente.pas:191` | yes - "Expected [Distrito Federal] but got [São Paulo] Trocar a UF na tela atualiza o Estado." (`Testes.FormsClientes.pas:635`) |
| `SinalizarCarregamento` mantém `RotuloConsultandoCep.Visible := False` | `src/Visao/Visao.FormCadastroCliente.pas:279` | yes - "Consultando CEP... deve aparecer durante a consulta." (`Testes.FormsClientes.pas:608`) |
| guarda de formato do serviço `<> TAMANHO_CEP` -> `> TAMANHO_CEP` (CEP de 7 dígitos chega ao transporte) | `src/Infraestrutura/Infraestrutura.ServicoViaCep.pas:102` | yes - C37 "Expected [4] but got [2] CEP com 7 dígitos é formato inválido." (`Testes.ServicoViaCep.pas:180`) |

As quatro mutações mortas do round 1 (AND->OR na busca geral, ID protegido 15->16, CEP sem mudança volta a consultar, `Reverter` com `Commit`) são `carried from bb5f82d`. Elas atingem código de `src/` que a correção não tocou, e as provas que as mataram continuam verdes em 0220fa2.

## Gate

- Build 0220fa2: `build.bat` (Release app + Debug runner) - exit 0
- Proofs: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --run:<57 names + CepEUfDaTelaAcionamOControlador> --exitbehavior:Continue`
  - 1ª invocação: 57 passed, 1 failed (C25, intermitente)
  - 2ª e 3ª invocações: 58 passed, 0 failed (exit 0)
- Full suite: `.\tests\bin\Win64\Debug\CadCli.Testes.exe --exitbehavior:Continue` - 108 passed, 0 failed (exit 0)
- `python .claude/skills/tlc-spec-lean/scripts/validate_verification.py parte-03-clientes-crud` - ver resultado abaixo do relatório (rodado após a escrita)

## Notes (non-blocking)

- **Intermitência de C25.** Na primeira invocação do batch, `EnterAvancaNaOrdemDeTabulacaoAteSalvar` falhou em `LOrdem[I].Focused` (`Testes.FormsClientes.pas:456`). Depois disso passou 2/2 no batch, 3/3 isolada, 3/3 com as 6 provas da fixture juntas e 1/1 na suíte completa, sempre sem nenhuma mudança de código. A asserção depende de a form de teste ter o foco do Windows, e outra janela em primeiro plano (a IDE ou o uso da máquina) derruba a prova. A correção não mexeu nessa prova nem em `src/`. O teste novo usa `SetFocus` e tem o mesmo risco. Registro isso como fragilidade do ambiente de prova, não como defeito do código.
- **Rastreabilidade do teste novo.** O teste novo `CepEUfDaTelaAcionamOControlador` não é `Proof:` de nenhum check, porque `checks.md` não foi alterado. Ele atende a linha "View passiva" de `Test policy` e rodou no batch, mas se for apagado nenhum `Proof:` deixa de resolver. Para trancar a ligação no artefato, convém citá-lo em C29/C31 (ou em um check de form).
- **Achado resolvido do round 1.** A nota sobre `scFormatoInvalido` está resolvida: `Testes.ServicoViaCep.pas:180-182` agora asserta o ramo do serviço, e o mutante 5 foi morto.
- **Notes herdadas do round 1** (`carried from bb5f82d`):
  - a página FireDAC retornou 403;
  - lacuna de precisão em C28 ("com máscara" sem `EditMask`);
  - o prefixo `Repositorio*` em C49;
  - `uses` VCL residuais nas forms;
  - ícone de erro no aviso de cliente protegido;
  - consulta ViaCEP síncrona na thread de UI;
  - smoke test manual pendente com o usuário.
- **Lessons (passo 7).** Não registrei nenhuma, porque o escopo proíbe alterar arquivos além deste relatório. Candidata: "uma prova de form que depende de `Focused`/`SetFocus` fica intermitente quando outra janela toma o primeiro plano".

unit Testes.RepositorioClienteFirebird;

interface

uses
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  Dominio.FiltroCliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.CatalogoMigracoes,
  Aplicacao.RepositorioCliente,
  Infraestrutura.InicializadorBancoFireDAC;

type
  [TestFixture]
  TTestesRepositorioClienteFirebird = class
  private
    FDiretorio: string;
    FCatalogo: TCatalogoMigracoes;
    FInicializador: TInicializadorBanco;
    FRepositorio: IRepositorioCliente;
    function Conexao: TFDConnection;
    function Contar(const ATabela: string): Integer;
    procedure InserirCliente(AId: Integer; const ANome, ACpfCnpj, ACep: string; ACidadeId: Integer;
      ADataNascimento: TDate);
    function CidadeId(const ANome: string): Integer;
    function EstadoId(const AUf: string): Integer;
    procedure SemearBaseF5;
    function PesquisarNomes(const AFiltro: TFiltroCliente): string;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure ResolveEstadoECidadeNosTresCasos;
    [Test]
    procedure FalhaDepoisDeCriarEstadoECidadeNaoDeixaOrfaos;
    [Test]
    procedure IncluiAlteraEExcluiPorParametrosESequencia;
    [Test]
    procedure PesquisaSemFiltroDevolveOsPrimeiros50PelaOrdenacao;
    [Test]
    procedure CadaCampoMarcadoAceitaERejeitaOsCasosDaTabela;
    [Test]
    procedure CamposMarcadosCombinamPorOr;
    [Test]
    procedure NenhumCampoMarcadoPesquisaNosSeisCampos;
    [Test]
    procedure DataCombinaPorAndComOTexto;
    [Test]
    procedure TextoComApostrofoEPesquisadoPorParametro;
    [Test]
    procedure TextoLongoNaoGeraErro;
    [Test]
    procedure OrdenaPorCadaColunaNasDuasDirecoesComAusentesPorUltimo;
    [Test]
    procedure PesquisaTrazCidadeUfEEstadoDoCliente;
    [Test]
    procedure RelatorioPorIntervaloIncluiOsDoisLimites;
    [Test]
    procedure RelatorioPorCidadeEstadoFiltraACombinacaoOuOEstado;
    [Test]
    procedure RelatorioTodosSemLimiteEmIdCrescente;
    [Test]
    procedure ListaEstadosECidadesDoEstadoPorNome;
  end;

implementation

uses
  Data.DB,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Dominio.Cliente,
  Aplicacao.ControladorCadastroCliente,
  Aplicacao.Transacao,
  Infraestrutura.CatalogoPadraoMigracoes,
  Infraestrutura.RepositorioClienteFireDAC,
  Suporte.CaminhosTeste,
  Suporte.FakesClientes;

function Inteiro(AConexao: TFDConnection; const ASql: string;
  const AParametros: array of Variant): Integer;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := AConexao;
    LConsulta.Open(ASql, AParametros);
    Result := LConsulta.Fields[0].AsInteger;
  finally
    LConsulta.Free;
  end;
end;

function Texto(AConexao: TFDConnection; const ASql: string;
  const AParametros: array of Variant): string;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := AConexao;
    LConsulta.Open(ASql, AParametros);
    Result := Trim(LConsulta.Fields[0].AsString);
  finally
    LConsulta.Free;
  end;
end;

procedure TTestesRepositorioClienteFirebird.Preparar;
var
  LMensagem: string;
begin
  FDiretorio := CriarDiretorioTemporario;
  FCatalogo := CriarCatalogoPadrao;
  FInicializador := TInicializadorBanco.Create(TPath.Combine(FDiretorio, 'cadcli.fdb'), FCatalogo);
  Assert.IsTrue(FInicializador.Preparar(LMensagem), LMensagem);
end;

procedure TTestesRepositorioClienteFirebird.Limpar;
begin
  FRepositorio := nil;
  FreeAndNil(FInicializador);
  FreeAndNil(FCatalogo);
  if TDirectory.Exists(FDiretorio) then
    TDirectory.Delete(FDiretorio, True);
end;

function TTestesRepositorioClienteFirebird.Conexao: TFDConnection;
begin
  Result := FInicializador.Conexao;
end;

function TTestesRepositorioClienteFirebird.Contar(const ATabela: string): Integer;
begin
  Result := Inteiro(Conexao, 'SELECT COUNT(*) FROM ' + ATabela, []);
end;

procedure TTestesRepositorioClienteFirebird.ResolveEstadoECidadeNosTresCasos;
var
  LRepositorio: IRepositorioCliente;
  LEstados: Integer;
  LCidades: Integer;
  LCidadeId: Integer;
  LEstadoSc: Integer;
begin
  LRepositorio := TRepositorioClienteFireDAC.Create(Conexao);

  LEstados := Contar('ESTADO');
  LCidades := Contar('CIDADE');
  LCidadeId := LRepositorio.ResolverCidade('Campinas', 'SP', 'São Paulo');
  Assert.AreEqual(LEstados, Contar('ESTADO'), 'Campinas/SP não insere estado.');
  Assert.AreEqual(LCidades, Contar('CIDADE'), 'Campinas/SP não insere cidade.');
  Assert.AreEqual(Inteiro(Conexao, 'SELECT C.ID FROM CIDADE C JOIN ESTADO E ON E.ID = C.ESTADOID ' +
    'WHERE C.NOME = :NOME AND E.UF = :UF', ['Campinas', 'SP']), LCidadeId,
    'Deve usar a cidade existente.');

  LCidadeId := LRepositorio.ResolverCidade('Sorocaba', 'SP', 'São Paulo');
  Assert.AreEqual(LEstados, Contar('ESTADO'), 'Sorocaba/SP não insere estado.');
  Assert.AreEqual(LCidades + 1, Contar('CIDADE'), 'Sorocaba/SP insere 1 cidade.');
  Assert.AreEqual('SP', Texto(Conexao, 'SELECT E.UF FROM CIDADE C JOIN ESTADO E ON E.ID = C.ESTADOID ' +
    'WHERE C.ID = :ID', [LCidadeId]), 'Sorocaba deve ficar ligada a SP.');
  Assert.AreEqual(Inteiro(Conexao, 'SELECT GEN_ID(SEQ_CIDADE, 0) FROM RDB$DATABASE', []), LCidadeId,
    'O ID da cidade deve vir de SEQ_CIDADE.');

  LCidadeId := LRepositorio.ResolverCidade('Florianópolis', 'SC', 'Santa Catarina');
  Assert.AreEqual(LEstados + 1, Contar('ESTADO'), 'Florianópolis/SC insere 1 estado.');
  Assert.AreEqual(LCidades + 2, Contar('CIDADE'), 'Florianópolis/SC insere 1 cidade.');
  LEstadoSc := Inteiro(Conexao, 'SELECT ID FROM ESTADO WHERE UF = :UF', ['SC']);
  Assert.AreEqual('SC - Santa Catarina', Texto(Conexao,
    'SELECT TRIM(UF) || '' - '' || NOME FROM ESTADO WHERE ID = :ID', [LEstadoSc]));
  Assert.AreEqual(Inteiro(Conexao, 'SELECT GEN_ID(SEQ_ESTADO, 0) FROM RDB$DATABASE', []), LEstadoSc,
    'O ID do estado deve vir de SEQ_ESTADO.');
  Assert.AreEqual(LEstadoSc, Inteiro(Conexao, 'SELECT ESTADOID FROM CIDADE WHERE ID = :ID', [LCidadeId]),
    'Florianópolis deve ficar ligada ao novo estado.');
  Assert.AreEqual('Florianópolis', Texto(Conexao, 'SELECT NOME FROM CIDADE WHERE ID = :ID', [LCidadeId]));
  Assert.AreEqual(Inteiro(Conexao, 'SELECT GEN_ID(SEQ_CIDADE, 0) FROM RDB$DATABASE', []), LCidadeId);

  Assert.AreEqual(LCidadeId, LRepositorio.ResolverCidade('Florianópolis', 'SC', 'Santa Catarina'));
  Assert.AreEqual(LEstados + 1, Contar('ESTADO'), 'Repetir não insere estado.');
  Assert.AreEqual(LCidades + 2, Contar('CIDADE'), 'Repetir não insere cidade.');
end;

procedure TTestesRepositorioClienteFirebird.FalhaDepoisDeCriarEstadoECidadeNaoDeixaOrfaos;
var
  LVisaoObjeto: TVisaoCadastroClienteFake;
  LVisao: IVisaoCadastroCliente;
  LRepositorio: IRepositorioCliente;
  LTransacao: ITransacao;
  LControlador: TControladorCadastroCliente;
  LEstados: Integer;
  LCidades: Integer;
  LClientes: Integer;
  LSequenciaEstado: Integer;
  LSequenciaCidade: Integer;
begin
  LSequenciaEstado := Inteiro(Conexao, 'SELECT GEN_ID(SEQ_ESTADO, 0) FROM RDB$DATABASE', []);
  LSequenciaCidade := Inteiro(Conexao, 'SELECT GEN_ID(SEQ_CIDADE, 0) FROM RDB$DATABASE', []);
  LEstados := Contar('ESTADO');
  LCidades := Contar('CIDADE');
  LClientes := Contar('CLIENTE');
  Assert.AreEqual(0, Inteiro(Conexao, 'SELECT COUNT(*) FROM ESTADO WHERE UF = :UF', ['SC']));

  LVisaoObjeto := TVisaoCadastroClienteFake.Create;
  LVisao := LVisaoObjeto;
  LRepositorio := TRepositorioClienteFireDAC.Create(Conexao);
  LTransacao := TTransacaoFireDAC.Create(Conexao);
  LControlador := TControladorCadastroCliente.Create(LVisao, LRepositorio, LTransacao,
    TServicoViaCepFake.Create, TRelogioFake.Create(EncodeDate(2026, 9, 21)), TConfirmacaoFake.Create);
  try
    LControlador.Abrir(mcInclusao);
    LVisaoObjeto.Dados := DadosValidos;
    LVisaoObjeto.Dados.Nome := StringOfChar('N', 81);
    LVisaoObjeto.Dados.Cidade := 'Florianópolis';
    LVisaoObjeto.Dados.Uf := 'SC';
    LVisaoObjeto.Dados.Estado := 'Santa Catarina';
    LControlador.Salvar;
    Assert.AreEqual('Não foi possível salvar o cliente.', LVisaoObjeto.Mensagens.Text.Trim);
    Assert.IsFalse(LControlador.Salvo);
  finally
    LControlador.Free;
  end;
  Assert.AreEqual(LSequenciaEstado + 1, Inteiro(Conexao, 'SELECT GEN_ID(SEQ_ESTADO, 0) FROM RDB$DATABASE', []),
    'O estado SC deve ter sido criado antes da falha.');
  Assert.AreEqual(LSequenciaCidade + 1, Inteiro(Conexao, 'SELECT GEN_ID(SEQ_CIDADE, 0) FROM RDB$DATABASE', []),
    'A cidade Florianópolis deve ter sido criada antes da falha.');
  Assert.IsFalse(Conexao.InTransaction, 'A transação deve ter sido encerrada.');
  Assert.AreEqual(LEstados, Contar('ESTADO'), 'Nenhum estado órfão pode ficar no banco.');
  Assert.AreEqual(LCidades, Contar('CIDADE'), 'Nenhuma cidade órfã pode ficar no banco.');
  Assert.AreEqual(LClientes, Contar('CLIENTE'));
end;

procedure TTestesRepositorioClienteFirebird.IncluiAlteraEExcluiPorParametrosESequencia;
const
  NOME_HOSTIL = 'D''Ávila; DROP TABLE CLIENTE';
var
  LRepositorio: IRepositorioCliente;
  LCliente: TCliente;
  LLido: TCliente;
  LId: Integer;
begin
  LRepositorio := TRepositorioClienteFireDAC.Create(Conexao);
  Conexao.ExecSQL('ALTER SEQUENCE SEQ_CLIENTE RESTART WITH 100');
  LCliente := NovoCliente(0, NOME_HOSTIL, '52998224725', '01001000', 'São Paulo', 'SP',
    'São Paulo', EncodeDate(1990, 3, 15));
  LCliente.Complemento := 'lado ímpar';
  LCliente.CidadeId := LRepositorio.ResolverCidade('São Paulo', 'SP', 'São Paulo');

  LId := LRepositorio.Incluir(LCliente);
  Assert.AreEqual(101, LId, 'O ID deve vir de SEQ_CLIENTE.');
  Assert.AreEqual(1, Contar('CLIENTE'));
  Assert.AreEqual(101, Inteiro(Conexao, 'SELECT ID FROM CLIENTE', []));
  LLido := LRepositorio.ObterPorId(101);
  Assert.AreEqual(NOME_HOSTIL, LLido.Nome);
  Assert.AreEqual('52998224725', LLido.CpfCnpj);
  Assert.AreEqual('01001000', LLido.Cep);
  Assert.AreEqual(LCliente.Endereco, LLido.Endereco);
  Assert.AreEqual(LCliente.Numero, LLido.Numero);
  Assert.AreEqual('lado ímpar', LLido.Complemento);
  Assert.AreEqual(LCliente.Bairro, LLido.Bairro);
  Assert.AreEqual(LCliente.CidadeId, LLido.CidadeId);
  Assert.AreEqual('São Paulo', LLido.Cidade);
  Assert.AreEqual('SP', LLido.Uf);
  Assert.AreEqual(Double(EncodeDate(1990, 3, 15)), Double(LLido.DataNascimento));

  LLido.Nome := 'Nome alterado';
  LRepositorio.Alterar(LLido);
  Assert.AreEqual(1, Contar('CLIENTE'), 'Alterar mantém a contagem.');
  Assert.AreEqual('Nome alterado', Texto(Conexao, 'SELECT NOME FROM CLIENTE WHERE ID = :ID', [101]));
  Assert.AreEqual(101, Inteiro(Conexao, 'SELECT ID FROM CLIENTE', []), 'Alterar mantém o ID.');

  LRepositorio.Excluir(101);
  Assert.AreEqual(0, Contar('CLIENTE'), 'Excluir remove exatamente 1 linha.');
  Assert.AreEqual(1, Inteiro(Conexao, 'SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = :N',
    ['CLIENTE']), 'A tabela CLIENTE deve continuar existindo.');
end;

function PrimeirosNomes(const AClientes: TClientes): string;
var
  LCliente: TCliente;
begin
  Result := '';
  for LCliente in AClientes do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LCliente.Nome.Split([' '])[0];
  end;
end;

function Filtro(const ATexto: string; ACampos: TCamposPesquisa;
  const ADataNascimento: string = ''): TFiltroCliente;
begin
  Result := Default(TFiltroCliente);
  Result.Texto := ATexto;
  Result.Campos := ACampos;
  Result.DataNascimento := ADataNascimento;
end;

function Ordenacao(ACampo: TCampoOrdenacao; ADescendente: Boolean = False): TOrdenacaoCliente;
begin
  Result.Campo := ACampo;
  Result.Descendente := ADescendente;
end;

procedure TTestesRepositorioClienteFirebird.InserirCliente(AId: Integer; const ANome, ACpfCnpj,
  ACep: string; ACidadeId: Integer; ADataNascimento: TDate);
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := Conexao;
    LConsulta.SQL.Text := 'INSERT INTO CLIENTE (ID, NOME, CEP, CPF_CNPJ, ENDERECO, NUMERO, BAIRRO, ' +
      'CIDADEID, DATANASCIMENTO) VALUES (:ID, :NOME, :CEP, :DOC, :END, :NUM, :BAIRRO, :CID, :NASC)';
    LConsulta.ParamByName('ID').AsInteger := AId;
    LConsulta.ParamByName('NOME').AsString := ANome;
    LConsulta.ParamByName('CEP').AsString := ACep;
    LConsulta.ParamByName('DOC').AsString := ACpfCnpj;
    LConsulta.ParamByName('END').AsString := 'Rua A';
    LConsulta.ParamByName('NUM').AsString := '1';
    LConsulta.ParamByName('BAIRRO').AsString := 'Centro';
    LConsulta.ParamByName('CID').DataType := ftInteger;
    if ACidadeId > 0 then
      LConsulta.ParamByName('CID').AsInteger := ACidadeId
    else
      LConsulta.ParamByName('CID').Clear;
    LConsulta.ParamByName('NASC').DataType := ftDate;
    if ADataNascimento > 0 then
      LConsulta.ParamByName('NASC').AsDate := ADataNascimento
    else
      LConsulta.ParamByName('NASC').Clear;
    LConsulta.ExecSQL;
  finally
    LConsulta.Free;
  end;
end;

function TTestesRepositorioClienteFirebird.CidadeId(const ANome: string): Integer;
begin
  Result := Inteiro(Conexao, 'SELECT ID FROM CIDADE WHERE NOME = :N', [ANome]);
end;

procedure TTestesRepositorioClienteFirebird.SemearBaseF5;
var
  LMariana: Integer;
begin
  LMariana := Inteiro(Conexao, 'SELECT NEXT VALUE FOR SEQ_CIDADE FROM RDB$DATABASE', []);
  Conexao.ExecSQL('INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (:ID, :NOME, ' +
    '(SELECT ID FROM ESTADO WHERE UF = :UF))', [LMariana, 'Mariana', 'MG']);
  InserirCliente(1, 'Ana Silva', '52998224725', '30130010', CidadeId('Belo Horizonte'),
    EncodeDate(1990, 3, 15));
  InserirCliente(2, 'Bruno Costa', '11144477735', '35420000', LMariana, EncodeDate(1985, 7, 20));
  InserirCliente(3, 'Carlos Silva', '11222333000181', '13010000', CidadeId('Campinas'),
    EncodeDate(1990, 3, 15));
  InserirCliente(4, 'Denise D''Avila', '39053344705', '13015000', CidadeId('Campinas'),
    EncodeDate(2000, 1, 1));
  InserirCliente(5, 'bianca souza', '71428793860', '01001000', 0, 0);
  FRepositorio := TRepositorioClienteFireDAC.Create(Conexao);
end;

function TTestesRepositorioClienteFirebird.PesquisarNomes(const AFiltro: TFiltroCliente): string;
begin
  Result := PrimeirosNomes(FRepositorio.Pesquisar(AFiltro, Ordenacao(coId), 50));
end;

procedure TTestesRepositorioClienteFirebird.PesquisaSemFiltroDevolveOsPrimeiros50PelaOrdenacao;
var
  I: Integer;
  LClientes: TClientes;
begin
  for I := 60 downto 1 do
    InserirCliente(I, Format('Cliente %.2d', [61 - I]), '52998224725', '13010000',
      CidadeId('Campinas'), EncodeDate(1980, 1, 1));
  FRepositorio := TRepositorioClienteFireDAC.Create(Conexao);

  LClientes := FRepositorio.Pesquisar(Default(TFiltroCliente), Ordenacao(coNome), 50);
  Assert.AreEqual(50, Integer(Length(LClientes)), 'Mais de 50 corta em 50.');
  Assert.AreEqual('Cliente 01', LClientes[0].Nome);
  Assert.AreEqual('Cliente 50', LClientes[49].Nome);

  LClientes := FRepositorio.Pesquisar(Default(TFiltroCliente), Ordenacao(coNome, True), 50);
  Assert.AreEqual(50, Integer(Length(LClientes)));
  Assert.AreEqual('Cliente 60', LClientes[0].Nome);
  Assert.AreEqual('Cliente 11', LClientes[49].Nome);

  Conexao.ExecSQL('DELETE FROM CLIENTE');
  SemearBaseF5;
  LClientes := FRepositorio.Pesquisar(Default(TFiltroCliente), Ordenacao(coNome), 50);
  Assert.AreEqual(5, Integer(Length(LClientes)), 'Menos de 50 devolve todos.');
end;

procedure TTestesRepositorioClienteFirebird.CadaCampoMarcadoAceitaERejeitaOsCasosDaTabela;
type
  TCaso = record
    Campo: TCampoPesquisa;
    Valor: string;
    Esperados: string;
  end;
const
  CASOS: array[0..10] of TCaso = (
    (Campo: cpId; Valor: '1'; Esperados: 'Ana'),
    (Campo: cpId; Valor: 'abc'; Esperados: ''),
    (Campo: cpNome; Valor: 'SIL'; Esperados: 'Ana,Carlos'),
    (Campo: cpNome; Valor: '  SIL  '; Esperados: 'Ana,Carlos'),
    (Campo: cpCpfCnpj; Valor: '529.982.247-25'; Esperados: 'Ana'),
    (Campo: cpCpfCnpj; Valor: '529982247'; Esperados: ''),
    (Campo: cpCep; Valor: '30130-010'; Esperados: 'Ana'),
    (Campo: cpCep; Valor: '3013001'; Esperados: ''),
    (Campo: cpCidade; Valor: 'campi'; Esperados: 'Carlos,Denise'),
    (Campo: cpEstado; Valor: 'mg'; Esperados: 'Ana,Bruno'),
    (Campo: cpEstado; Valor: 'paulo'; Esperados: 'Carlos,Denise'));
var
  LCaso: TCaso;
  LVerificados: Integer;
begin
  SemearBaseF5;
  Assert.AreEqual(1, Inteiro(Conexao, 'SELECT ID FROM CLIENTE WHERE NOME = :N', ['Ana Silva']),
    'O caso de ID usa o ID de Ana.');
  LVerificados := 0;
  for LCaso in CASOS do
  begin
    Assert.AreEqual(LCaso.Esperados, PesquisarNomes(Filtro(LCaso.Valor, [LCaso.Campo])),
      'Campo ' + IntToStr(Ord(LCaso.Campo)) + ' com "' + LCaso.Valor + '"');
    Inc(LVerificados);
  end;
  Assert.AreEqual(11, LVerificados);
end;

procedure TTestesRepositorioClienteFirebird.CamposMarcadosCombinamPorOr;
begin
  SemearBaseF5;
  Assert.AreEqual('Ana', PesquisarNomes(Filtro('ana', [cpNome])));
  Assert.AreEqual('Bruno', PesquisarNomes(Filtro('ana', [cpCidade])));
  Assert.AreEqual('Ana,Bruno', PesquisarNomes(Filtro('ana', [cpNome, cpCidade])));
end;

procedure TTestesRepositorioClienteFirebird.NenhumCampoMarcadoPesquisaNosSeisCampos;
type
  TCaso = record
    Campo: TCampoPesquisa;
    Valor: string;
  end;
const
  CASOS: array[0..5] of TCaso = (
    (Campo: cpId; Valor: '1'),
    (Campo: cpNome; Valor: 'SIL'),
    (Campo: cpCpfCnpj; Valor: '529.982.247-25'),
    (Campo: cpCep; Valor: '30130-010'),
    (Campo: cpCidade; Valor: 'campi'),
    (Campo: cpEstado; Valor: 'mg'));
var
  LCaso: TCaso;
  LSozinho: string;
  LTodos: TArray<string>;
  LNome: string;
  LVerificados: Integer;
begin
  SemearBaseF5;
  Assert.AreEqual('Ana,Bruno', PesquisarNomes(Filtro('ana', [])));
  LVerificados := 0;
  for LCaso in CASOS do
  begin
    LSozinho := PesquisarNomes(Filtro(LCaso.Valor, [LCaso.Campo]));
    Assert.AreNotEqual('', LSozinho, 'O valor deve encontrar alguém: ' + LCaso.Valor);
    LTodos := PesquisarNomes(Filtro(LCaso.Valor, [])).Split([',']);
    for LNome in LSozinho.Split([',']) do
      Assert.IsTrue(MatchStr(LNome, LTodos),
        LNome + ' deve aparecer sem campos marcados para "' + LCaso.Valor + '"');
    Inc(LVerificados);
  end;
  Assert.AreEqual(6, LVerificados);
end;

procedure TTestesRepositorioClienteFirebird.DataCombinaPorAndComOTexto;
begin
  SemearBaseF5;
  Assert.AreEqual('Ana,Carlos', PesquisarNomes(Filtro('', [], '15/03/1990')));
  Assert.AreEqual('Ana,Carlos', PesquisarNomes(Filtro('silva', [cpNome], '15/03/1990')));
  Assert.AreEqual('', PesquisarNomes(Filtro('costa', [cpNome], '15/03/1990')));
  Assert.AreEqual('Bruno', PesquisarNomes(Filtro('ana', [cpNome, cpCidade], '20/07/1985')));
end;

procedure TTestesRepositorioClienteFirebird.TextoComApostrofoEPesquisadoPorParametro;
begin
  SemearBaseF5;
  Assert.AreEqual('Denise', PesquisarNomes(Filtro('d''avila', [cpNome])));
  Assert.AreEqual('', PesquisarNomes(Filtro(''' OR 1=1 --', [])));
  Assert.AreEqual(5, Contar('CLIENTE'));
end;

procedure TTestesRepositorioClienteFirebird.TextoLongoNaoGeraErro;
begin
  SemearBaseF5;
  Assert.AreEqual('', PesquisarNomes(Filtro(StringOfChar('a', 300), [])),
    'Texto maior que as colunas não pode gerar erro.');
  Assert.AreEqual('', PesquisarNomes(Filtro(StringOfChar('1', 30), [])),
    'Dígitos além do CPF/CNPJ não podem gerar erro.');
end;

procedure TTestesRepositorioClienteFirebird.OrdenaPorCadaColunaNasDuasDirecoesComAusentesPorUltimo;
type
  TCaso = record
    Campo: TCampoOrdenacao;
    Crescente: string;
    Decrescente: string;
  end;
const
  CASOS: array[0..7] of TCaso = (
    (Campo: coId; Crescente: 'Ana,Bruno,Carlos,Denise,bianca';
      Decrescente: 'bianca,Denise,Carlos,Bruno,Ana'),
    (Campo: coNome; Crescente: 'Ana,bianca,Bruno,Carlos,Denise';
      Decrescente: 'Denise,Carlos,Bruno,bianca,Ana'),
    (Campo: coCpfCnpj; Crescente: 'Bruno,Carlos,Denise,Ana,bianca';
      Decrescente: 'bianca,Ana,Denise,Carlos,Bruno'),
    (Campo: coCep; Crescente: 'bianca,Carlos,Denise,Ana,Bruno';
      Decrescente: 'Bruno,Ana,Denise,Carlos,bianca'),
    (Campo: coCidade; Crescente: 'Ana,Carlos,Denise,Bruno,bianca';
      Decrescente: 'Bruno,Carlos,Denise,Ana,bianca'),
    (Campo: coUf; Crescente: 'Ana,Bruno,Carlos,Denise,bianca';
      Decrescente: 'Carlos,Denise,Ana,Bruno,bianca'),
    (Campo: coEstado; Crescente: 'Ana,Bruno,Carlos,Denise,bianca';
      Decrescente: 'Carlos,Denise,Ana,Bruno,bianca'),
    (Campo: coDataNascimento; Crescente: 'Bruno,Ana,Carlos,Denise,bianca';
      Decrescente: 'Denise,Ana,Carlos,Bruno,bianca'));
var
  LCaso: TCaso;
  LVerificados: Integer;
  LEstado: Integer;
  LCidade: Integer;
begin
  SemearBaseF5;
  LVerificados := 0;
  for LCaso in CASOS do
  begin
    Assert.AreEqual(LCaso.Crescente, PrimeirosNomes(FRepositorio.Pesquisar(Default(TFiltroCliente),
      Ordenacao(LCaso.Campo), 50)), 'Coluna ' + IntToStr(Ord(LCaso.Campo)) + ' crescente');
    Inc(LVerificados);
    Assert.AreEqual(LCaso.Decrescente, PrimeirosNomes(FRepositorio.Pesquisar(Default(TFiltroCliente),
      Ordenacao(LCaso.Campo, True), 50)), 'Coluna ' + IntToStr(Ord(LCaso.Campo)) + ' decrescente');
    Inc(LVerificados);
  end;
  Assert.AreEqual(16, LVerificados);

  LEstado := Inteiro(Conexao, 'SELECT NEXT VALUE FOR SEQ_ESTADO FROM RDB$DATABASE', []);
  Conexao.ExecSQL('INSERT INTO ESTADO (ID, NOME, UF) VALUES (:ID, :NOME, :UF)',
    [LEstado, 'amapá', 'AP']);
  LCidade := Inteiro(Conexao, 'SELECT NEXT VALUE FOR SEQ_CIDADE FROM RDB$DATABASE', []);
  Conexao.ExecSQL('INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (:ID, :NOME, :ESTADOID)',
    [LCidade, 'macapá', LEstado]);
  InserirCliente(6, 'Eva Lima', '12345678909', '68900000', LCidade, EncodeDate(1995, 5, 5));
  Assert.AreEqual('Ana,Carlos,Denise,Eva,Bruno,bianca', PrimeirosNomes(FRepositorio.Pesquisar(
    Default(TFiltroCliente), Ordenacao(coCidade), 50)), 'Cidade crescente sem diferença de caixa.');
  Assert.AreEqual('Bruno,Eva,Carlos,Denise,Ana,bianca', PrimeirosNomes(FRepositorio.Pesquisar(
    Default(TFiltroCliente), Ordenacao(coCidade, True), 50)), 'Cidade decrescente sem diferença de caixa.');
  Assert.AreEqual('Eva,Ana,Bruno,Carlos,Denise,bianca', PrimeirosNomes(FRepositorio.Pesquisar(
    Default(TFiltroCliente), Ordenacao(coEstado), 50)), 'Estado crescente sem diferença de caixa.');
  Assert.AreEqual('Carlos,Denise,Ana,Bruno,Eva,bianca', PrimeirosNomes(FRepositorio.Pesquisar(
    Default(TFiltroCliente), Ordenacao(coEstado, True), 50)), 'Estado decrescente sem diferença de caixa.');
end;

procedure TTestesRepositorioClienteFirebird.PesquisaTrazCidadeUfEEstadoDoCliente;
var
  LClientes: TClientes;
begin
  SemearBaseF5;
  LClientes := FRepositorio.Pesquisar(Filtro('carlos', [cpNome]), Ordenacao(coId), 50);
  Assert.AreEqual(1, Integer(Length(LClientes)));
  Assert.AreEqual('Campinas', LClientes[0].Cidade);
  Assert.AreEqual('SP', LClientes[0].Uf);
  Assert.AreEqual('São Paulo', LClientes[0].Estado);
  LClientes := FRepositorio.Pesquisar(Filtro('bianca', [cpNome]), Ordenacao(coId), 50);
  Assert.AreEqual(1, Integer(Length(LClientes)));
  Assert.AreEqual('', LClientes[0].Cidade);
  Assert.AreEqual('', LClientes[0].Uf);
  Assert.AreEqual('', LClientes[0].Estado);
end;

function IdsDoRelatorio(const AClientes: TClientes): string;
var
  LCliente: TCliente;
begin
  Result := '';
  for LCliente in AClientes do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(LCliente.Id);
  end;
end;

function FiltroIntervalo(ADe, AAte: Integer): TFiltroRelatorioCliente;
begin
  Result := Default(TFiltroRelatorioCliente);
  Result.Modo := mrIntervalo;
  Result.IdInicial := ADe;
  Result.IdFinal := AAte;
end;

function FiltroCidadeEstado(AEstadoId, ACidadeId: Integer): TFiltroRelatorioCliente;
begin
  Result := Default(TFiltroRelatorioCliente);
  Result.Modo := mrCidadeEstado;
  Result.EstadoId := AEstadoId;
  Result.CidadeId := ACidadeId;
end;

function FiltroTodos: TFiltroRelatorioCliente;
begin
  Result := Default(TFiltroRelatorioCliente);
  Result.Modo := mrTodos;
end;

function TTestesRepositorioClienteFirebird.EstadoId(const AUf: string): Integer;
begin
  Result := Inteiro(Conexao, 'SELECT ID FROM ESTADO WHERE UF = :UF', [AUf]);
end;

function NomesDosEstados(const AEstados: TEstados): string;
var
  LEstado: TEstado;
begin
  Result := '';
  for LEstado in AEstados do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LEstado.Uf + ' - ' + LEstado.Nome;
  end;
end;

function NomesDasCidades(const ACidades: TCidades): string;
var
  LCidade: TCidade;
begin
  Result := '';
  for LCidade in ACidades do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LCidade.Nome;
  end;
end;

procedure TTestesRepositorioClienteFirebird.RelatorioPorIntervaloIncluiOsDoisLimites;
type
  TCasoIntervalo = record
    De: Integer;
    Ate: Integer;
    Esperados: string;
  end;
const
  CASOS: array[0..3] of TCasoIntervalo = (
    (De: 2; Ate: 4; Esperados: '2,3,4'),
    (De: 1; Ate: 1; Esperados: '1'),
    (De: 4; Ate: 9; Esperados: '4,5'),
    (De: 6; Ate: 9; Esperados: ''));
var
  LCaso: TCasoIntervalo;
  LVerificados: Integer;
begin
  SemearBaseF5;
  LVerificados := 0;
  for LCaso in CASOS do
  begin
    Assert.AreEqual(LCaso.Esperados,
      IdsDoRelatorio(FRepositorio.ListarParaRelatorio(FiltroIntervalo(LCaso.De, LCaso.Ate))),
      Format('Intervalo %d..%d', [LCaso.De, LCaso.Ate]));
    Inc(LVerificados);
  end;
  Assert.AreEqual(4, LVerificados, 'Os quatro intervalos devem ser asseridos.');
end;

procedure TTestesRepositorioClienteFirebird.RelatorioPorCidadeEstadoFiltraACombinacaoOuOEstado;
type
  TCasoLocalidade = record
    Uf: string;
    Cidade: string;
    Esperados: string;
  end;
const
  CASOS: array[0..5] of TCasoLocalidade = (
    (Uf: 'SP'; Cidade: 'Campinas'; Esperados: '3,4'),
    (Uf: 'MG'; Cidade: 'Mariana'; Esperados: '2'),
    (Uf: 'SP'; Cidade: 'Santos'; Esperados: ''),
    (Uf: 'MG'; Cidade: ''; Esperados: '1,2'),
    (Uf: 'SP'; Cidade: ''; Esperados: '3,4'),
    (Uf: 'RJ'; Cidade: ''; Esperados: ''));
var
  LCaso: TCasoLocalidade;
  LCidadeId: Integer;
  LVerificados: Integer;
begin
  SemearBaseF5;
  LVerificados := 0;
  for LCaso in CASOS do
  begin
    if LCaso.Cidade = '' then
      LCidadeId := 0
    else
      LCidadeId := CidadeId(LCaso.Cidade);
    Assert.AreEqual(LCaso.Esperados, IdsDoRelatorio(FRepositorio.ListarParaRelatorio(
      FiltroCidadeEstado(EstadoId(LCaso.Uf), LCidadeId))),
      Format('Estado %s, cidade "%s"', [LCaso.Uf, LCaso.Cidade]));
    Inc(LVerificados);
  end;
  Assert.AreEqual(6, LVerificados, 'As seis combinações devem ser asseridas.');
end;

procedure TTestesRepositorioClienteFirebird.RelatorioTodosSemLimiteEmIdCrescente;
var
  I: Integer;
  LClientes: TClientes;
  LEsperados: string;
begin
  for I := 60 downto 1 do
    InserirCliente(I, Format('Cliente %.2d', [61 - I]), '52998224725', '13010000',
      CidadeId('Campinas'), EncodeDate(1980, 1, 1));
  FRepositorio := TRepositorioClienteFireDAC.Create(Conexao);

  LClientes := FRepositorio.ListarParaRelatorio(FiltroTodos);
  Assert.AreEqual(60, Integer(Length(LClientes)), 'O relatório não corta os clientes.');
  LEsperados := '';
  for I := 1 to 60 do
  begin
    if LEsperados <> '' then
      LEsperados := LEsperados + ',';
    LEsperados := LEsperados + IntToStr(I);
  end;
  Assert.AreEqual(LEsperados, IdsDoRelatorio(LClientes), 'Os IDs vêm em ordem crescente.');

  Conexao.ExecSQL('DELETE FROM CLIENTE');
  SemearBaseF5;
  LClientes := FRepositorio.ListarParaRelatorio(FiltroTodos);
  Assert.AreEqual('1,2,3,4,5', IdsDoRelatorio(LClientes));
  Assert.AreEqual('Centro', LClientes[2].Bairro, 'O cliente 3 traz o bairro.');
  Assert.AreEqual('Campinas', LClientes[2].Cidade, 'O cliente 3 traz a cidade.');
  Assert.AreEqual('SP', LClientes[2].Uf, 'O cliente 3 traz a UF.');
  Assert.AreEqual('São Paulo', LClientes[2].Estado, 'O cliente 3 traz o estado.');
  Assert.AreEqual('', LClientes[4].Cidade, 'O cliente 5 não tem cidade.');
  Assert.AreEqual('', LClientes[4].Uf, 'O cliente 5 não tem UF.');
  Assert.AreEqual('', LClientes[4].Estado, 'O cliente 5 não tem estado.');
end;

procedure TTestesRepositorioClienteFirebird.ListaEstadosECidadesDoEstadoPorNome;
begin
  SemearBaseF5;

  Assert.AreEqual('BA - Bahia,MG - Minas Gerais,RJ - Rio de Janeiro,SP - São Paulo',
    NomesDosEstados(FRepositorio.ListarEstados), 'Os estados vêm por nome.');
  Assert.AreEqual('Belo Horizonte,Contagem,Mariana,Uberlândia',
    NomesDasCidades(FRepositorio.ListarCidades(EstadoId('MG'))), 'As cidades de MG vêm por nome.');
  Assert.AreEqual('Campinas,Santos,São Paulo',
    NomesDasCidades(FRepositorio.ListarCidades(EstadoId('SP'))), 'As cidades de SP vêm por nome.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesRepositorioClienteFirebird);

end.

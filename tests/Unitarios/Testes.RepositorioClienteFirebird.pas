unit Testes.RepositorioClienteFirebird;

interface

uses
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  Aplicacao.CatalogoMigracoes,
  Infraestrutura.InicializadorBancoFireDAC;

type
  [TestFixture]
  TTestesRepositorioClienteFirebird = class
  private
    FDiretorio: string;
    FCatalogo: TCatalogoMigracoes;
    FInicializador: TInicializadorBanco;
    function Conexao: TFDConnection;
    function Contar(const ATabela: string): Integer;
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
    procedure ListarTodosTrazCidadeEEstadoPorIdCrescente;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Dominio.Cliente,
  Aplicacao.ControladorCadastroCliente,
  Aplicacao.RepositorioCliente,
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

procedure TTestesRepositorioClienteFirebird.ListarTodosTrazCidadeEEstadoPorIdCrescente;
var
  LRepositorio: IRepositorioCliente;
  LClientes: TClientes;
  LId: Integer;
  LCidadeCampinas: Integer;
  LCidadeSalvador: Integer;
  LCidade: Integer;
begin
  LCidadeCampinas := Inteiro(Conexao, 'SELECT ID FROM CIDADE WHERE NOME = :N', ['Campinas']);
  LCidadeSalvador := Inteiro(Conexao, 'SELECT ID FROM CIDADE WHERE NOME = :N', ['Salvador']);
  for LId in TArray<Integer>.Create(30, 10, 20) do
  begin
    if LId = 20 then
      LCidade := LCidadeSalvador
    else
      LCidade := LCidadeCampinas;
    Conexao.ExecSQL('INSERT INTO CLIENTE (ID, NOME, CEP, CPF_CNPJ, ENDERECO, NUMERO, BAIRRO, ' +
      'CIDADEID, DATANASCIMENTO) VALUES (:ID, :NOME, :CEP, :DOC, :END, :NUM, :BAIRRO, :CID, :NASC)',
      [LId, 'Cliente ' + IntToStr(LId), '13010000', '52998224725', 'Rua A', '1', 'Centro',
       LCidade, EncodeDate(1980, 1, 1)]);
  end;
  LRepositorio := TRepositorioClienteFireDAC.Create(Conexao);
  LClientes := LRepositorio.ListarTodos;
  Assert.AreEqual(3, Integer(Length(LClientes)));
  Assert.AreEqual(10, LClientes[0].Id);
  Assert.AreEqual(20, LClientes[1].Id);
  Assert.AreEqual(30, LClientes[2].Id);
  Assert.AreEqual('Campinas', LClientes[0].Cidade);
  Assert.AreEqual('SP', LClientes[0].Uf);
  Assert.AreEqual('São Paulo', LClientes[0].Estado);
  Assert.AreEqual('Salvador', LClientes[1].Cidade);
  Assert.AreEqual('BA', LClientes[1].Uf);
  Assert.AreEqual('Bahia', LClientes[1].Estado);
  Assert.AreEqual('Campinas', LClientes[2].Cidade);
  Assert.AreEqual('SP', LClientes[2].Uf);
  Assert.AreEqual('São Paulo', LClientes[2].Estado);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesRepositorioClienteFirebird);

end.

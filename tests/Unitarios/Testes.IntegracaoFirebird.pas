unit Testes.IntegracaoFirebird;

interface

uses
  Aplicacao.CatalogoMigracoes,
  DUnitX.TestFramework,
  Infraestrutura.InicializadorBancoFireDAC;

type
  [TestFixture]
  TTestesInicializadorBanco = class
  private
    FDiretorio: string;
    FCaminhoBanco: string;
    FCatalogo: TCatalogoMigracoes;
    FInicializador: TInicializadorBanco;
    procedure PrepararBanco;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure CriaBaseAoLadoDoExecutavelComConfiguracaoEsperada;
    [Test]
    procedure RecusaVersaoFuturaEOrientaAtualizacao;
    [Test]
    procedure SegundaExecucaoNaoAlteraEsquemaNemReferencia;
    [Test]
    procedure ConectaPeloServicoLocalEmLocalhost3050;
    [Test]
    procedure InformaServicoFirebirdIndisponivelSemLiberarAplicacao;
  end;

  [TestFixture]
  TTestesMigracaoNoFirebird = class
  private
    FDiretorio: string;
    FCaminhoBanco: string;
    function PrepararCom(ACatalogo: TCatalogoMigracoes; out AMensagem: string): Boolean;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure AplicaSomenteAPendenteSobreBaseAnterior;
    [Test]
    procedure ReverteMigracaoInvalidaNoFirebirdEInformaVersao;
    [Test]
    procedure RegistraInstanteRealDaAplicacaoEmAplicadaEm;
  end;

  [TestFixture]
  TTestesConvencaoMigracoes = class
  public
    [Test]
    procedure CadaVersaoTemUnitEClasseNoFormatoDefinido;
  end;

  [TestFixture]
  TTestesAplicacaoRelease = class
  private
    FDiretorio: string;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure ExecutavelReleaseCriaBaseCompletaAoLado;
    [Test]
    procedure ExecutavelReleaseRecusaVersaoFuturaERegistraOErro;
  end;

  [TestFixture]
  TTestesMigracaoInicial = class
  private
    FDiretorio: string;
    FCaminhoBanco: string;
    FCatalogo: TCatalogoMigracoes;
    FInicializador: TInicializadorBanco;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure CriaEsquemaComMetadadosExatos;
    [Test]
    procedure InsereEstadosECidadesDeReferencia;
    [Test]
    procedure CriaUmaSequenciaPorEntidadeSemMaxId;
    [Test]
    procedure SequenciasContinuamDepoisDosDadosDeReferencia;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.Winsock2,
  System.Classes,
  System.DateUtils,
  System.IOUtils,
  System.RegularExpressions,
  System.SysUtils,
  FireDAC.Comp.Client,
  Aplicacao.InicializadorAplicacao,
  Dominio.Migracao,
  Infraestrutura.CatalogoPadraoMigracoes,
  Suporte.CaminhosTeste,
  Suporte.FakesMigracao;

const
  ARQUIVOS_RUNTIME_FIREBIRD: array[0..5] of string = ('fbclient.dll', 'ib_util.dll',
    'icu*.dll', 'firebird.msg', 'firebird.conf', 'plugins.conf');
  DIRETORIOS_RUNTIME_FIREBIRD: array[0..1] of string = ('plugins', 'intl');

function ConectarPeloServico(const ABanco: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.LoginPrompt := False;
    Result.Params.Values['DriverID'] := 'FB';
    Result.Params.Values['Server'] := 'localhost';
    Result.Params.Values['Port'] := '3050';
    Result.Params.Values['Database'] := ABanco;
    Result.Params.Values['User_Name'] := 'SYSDBA';
    Result.Params.Values['Password'] := 'masterkey';
    Result.Params.Values['OpenMode'] := 'Open';
    Result.Params.Values['CharacterSet'] := 'UTF8';
    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

function PortaLocalSemServico: Integer;
var
  LDados: TWSAData;
  LSocket: TSocket;
  LEndereco: TSockAddrIn;
  LTamanho: Integer;
begin
  Assert.AreEqual(0, WSAStartup($0202, LDados), 'Winsock indisponível.');
  try
    LSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    Assert.IsTrue(LSocket <> INVALID_SOCKET, 'Não foi possível criar o socket de sondagem.');
    try
      FillChar(LEndereco, SizeOf(LEndereco), 0);
      LEndereco.sin_family := AF_INET;
      LEndereco.sin_addr.S_addr := htonl(INADDR_LOOPBACK);
      LEndereco.sin_port := 0;
      Assert.AreEqual(0, bind(LSocket, PSockAddr(@LEndereco)^, SizeOf(LEndereco)));
      LTamanho := SizeOf(LEndereco);
      Assert.AreEqual(0, getsockname(LSocket, PSockAddr(@LEndereco)^, LTamanho));
      Result := ntohs(LEndereco.sin_port);
    finally
      closesocket(LSocket);
    end;
  finally
    WSACleanup;
  end;
end;

procedure AssegurarSemCredenciais(const ATexto, AContexto: string);
begin
  Assert.IsFalse(ATexto.Contains('SYSDBA'), AContexto + ' não pode expor o usuário do serviço.');
  Assert.IsFalse(ATexto.ToLower.Contains('masterkey'), AContexto + ' não pode expor a senha do serviço.');
  Assert.IsFalse(ATexto.ToLower.Contains('password='), AContexto + ' não pode expor a string de conexão.');
end;

function InteiroSQL(AConexao: TFDConnection; const ASql: string): Integer;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := AConexao;
    LConsulta.SQL.Text := ASql;
    LConsulta.Open;
    Result := LConsulta.Fields[0].AsInteger;
  finally
    LConsulta.Free;
  end;
end;

function TextoSQL(AConexao: TFDConnection; const ASql: string): string;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := AConexao;
    LConsulta.SQL.Text := ASql;
    LConsulta.Open;
    Result := Trim(LConsulta.Fields[0].AsString);
  finally
    LConsulta.Free;
  end;
end;

function DataHoraSQL(AConexao: TFDConnection; const ASql: string): TDateTime;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := AConexao;
    LConsulta.SQL.Text := ASql;
    LConsulta.Open;
    Assert.IsFalse(LConsulta.Fields[0].IsNull, 'O instante persistido nao pode ser nulo.');
    Result := LConsulta.Fields[0].AsDateTime;
  finally
    LConsulta.Free;
  end;
end;

function LinhasSQL(AConexao: TFDConnection; const ASql: string): string;
var
  LConsulta: TFDQuery;
  LLinhas: TStringList;
begin
  LConsulta := TFDQuery.Create(nil);
  LLinhas := TStringList.Create;
  try
    LConsulta.Connection := AConexao;
    LConsulta.SQL.Text := ASql;
    LConsulta.Open;
    while not LConsulta.Eof do
    begin
      LLinhas.Add(Trim(LConsulta.Fields[0].AsString));
      LConsulta.Next;
    end;
    Result := string.Join('|', LLinhas.ToStringArray);
  finally
    LLinhas.Free;
    LConsulta.Free;
  end;
end;

procedure TTestesInicializadorBanco.Preparar;
begin
  FDiretorio := CriarDiretorioTemporario;
  FCaminhoBanco := TPath.Combine(FDiretorio, 'cadcli.fdb');
  FCatalogo := CriarCatalogoPadrao;
end;

procedure TTestesInicializadorBanco.Limpar;
begin
  FreeAndNil(FInicializador);
  FreeAndNil(FCatalogo);
  if TDirectory.Exists(FDiretorio) then
    TDirectory.Delete(FDiretorio, True);
end;

procedure TTestesInicializadorBanco.PrepararBanco;
var
  LMensagem: string;
begin
  FInicializador := TInicializadorBanco.Create(FCaminhoBanco, FCatalogo);
  Assert.IsTrue(FInicializador.Preparar(LMensagem), LMensagem);
end;

procedure TTestesInicializadorBanco.CriaBaseAoLadoDoExecutavelComConfiguracaoEsperada;
var
  LVersaoMotor: string;
begin
  Assert.IsFalse(TFile.Exists(FCaminhoBanco), 'A prova deve partir sem cadcli.fdb.');
  PrepararBanco;
  LVersaoMotor := TextoSQL(FInicializador.Conexao,
    'SELECT RDB$GET_CONTEXT(''SYSTEM'', ''ENGINE_VERSION'') FROM RDB$DATABASE');
  Assert.IsTrue(TFile.Exists(FCaminhoBanco),
    'cadcli.fdb deve ser criado exatamente no diretório informado pela inicialização.');
  Assert.IsTrue(SameText(FCaminhoBanco, TextoSQL(FInicializador.Conexao,
    'SELECT MON$DATABASE_NAME FROM MON$DATABASE')),
    'O serviço deve ter aberto exatamente o caminho absoluto de cadcli.fdb.');
  Assert.IsTrue(LVersaoMotor.StartsWith('3.'), 'O motor deve ser Firebird 3.');
  Assert.AreEqual(3, InteiroSQL(FInicializador.Conexao,
    'SELECT MON$SQL_DIALECT FROM MON$DATABASE'), 'A base deve estar em Dialect 3.');
  Assert.AreEqual(12, InteiroSQL(FInicializador.Conexao,
    'SELECT MON$ODS_MAJOR FROM MON$DATABASE'), 'A base deve usar a ODS 12 do Firebird 3.');
  Assert.AreEqual('UTF8', TextoSQL(FInicializador.Conexao,
    'SELECT RDB$CHARACTER_SET_NAME FROM RDB$DATABASE'),
    'O charset padrão da base deve ser UTF8.');
  Assert.AreEqual(2, InteiroSQL(FInicializador.Conexao,
    'SELECT MAX(VERSAO) FROM SCHEMA_VERSION'));
end;

procedure TTestesInicializadorBanco.RecusaVersaoFuturaEOrientaAtualizacao;
var
  LMensagem: string;
begin
  PrepararBanco;
  FInicializador.Conexao.ExecSQL(
    'INSERT INTO SCHEMA_VERSION (VERSAO, DESCRICAO, APLICADA_EM) VALUES (999, ''futura'', CURRENT_TIMESTAMP)');
  FInicializador.Conexao.Connected := False;
  Assert.IsFalse(FInicializador.Preparar(LMensagem));
  Assert.IsFalse(FInicializador.Conexao.Connected,
    'A conexão futura não pode ser entregue aos repositórios.');
  Assert.Contains(LMensagem, 'Atualize o CadCli.exe');
end;

procedure TTestesInicializadorBanco.SegundaExecucaoNaoAlteraEsquemaNemReferencia;
var
  LQuantidadeDDL: Integer;
  LMensagem: string;
begin
  PrepararBanco;
  Assert.AreEqual(4, InteiroSQL(FInicializador.Conexao, 'SELECT COUNT(*) FROM ESTADO'));
  Assert.AreEqual(12, InteiroSQL(FInicializador.Conexao, 'SELECT COUNT(*) FROM CIDADE'));
  FInicializador.Conexao.Connected := False;
  FreeAndNil(FInicializador);
  LQuantidadeDDL := 0;
  FInicializador := TInicializadorBanco.Create(FCaminhoBanco, FCatalogo,
    procedure(const ASql: string)
    begin
      if TRegEx.IsMatch(ASql, '^\s*(CREATE|ALTER|DROP|RECREATE)\b', [roIgnoreCase]) then
        Inc(LQuantidadeDDL);
    end);
  Assert.IsTrue(FInicializador.Preparar(LMensagem), LMensagem);
  Assert.AreEqual(0, LQuantidadeDDL,
    'Uma base na versão suportada não pode executar instruções DDL.');
  Assert.AreEqual(4, InteiroSQL(FInicializador.Conexao, 'SELECT COUNT(*) FROM ESTADO'));
  Assert.AreEqual(12, InteiroSQL(FInicializador.Conexao, 'SELECT COUNT(*) FROM CIDADE'));
  Assert.AreEqual(2, InteiroSQL(FInicializador.Conexao, 'SELECT COUNT(*) FROM SCHEMA_VERSION'));
end;

procedure TTestesInicializadorBanco.ConectaPeloServicoLocalEmLocalhost3050;
var
  LEndereco: string;
begin
  PrepararBanco;
  Assert.IsTrue(TextoSQL(FInicializador.Conexao,
    'SELECT MON$REMOTE_PROTOCOL FROM MON$ATTACHMENTS ' +
    'WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION').StartsWith('TCP'),
    'A conexão deve chegar pelo serviço via TCP, não pelo runtime local.');
  LEndereco := TextoSQL(FInicializador.Conexao,
    'SELECT MON$REMOTE_ADDRESS FROM MON$ATTACHMENTS ' +
    'WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION');
  Assert.IsTrue(LEndereco.StartsWith('127.0.0.1') or LEndereco.StartsWith('::1'),
    'A conexão deve partir do loopback: ' + LEndereco);
  Assert.AreEqual('SYSDBA', TextoSQL(FInicializador.Conexao,
    'SELECT MON$USER FROM MON$ATTACHMENTS WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION'));
  Assert.AreEqual('FB', FInicializador.Conexao.Params.Values['DriverID']);
  Assert.AreEqual('localhost', FInicializador.Conexao.Params.Values['Server']);
  Assert.AreEqual('3050', FInicializador.Conexao.Params.Values['Port']);
  Assert.AreEqual('OpenOrCreate', FInicializador.Conexao.Params.Values['OpenMode']);
  Assert.AreEqual('', FInicializador.Conexao.Params.Values['VendorLib'],
    'A biblioteca cliente deve vir da instalação do Firebird, não do diretório do executável.');
end;

procedure TTestesInicializadorBanco.InformaServicoFirebirdIndisponivelSemLiberarAplicacao;
var
  LPorta: Integer;
  LInicializadorObjeto: TInicializadorBanco;
  LPersistencia: IInicializadorPersistencia;
  LAutorizadorObjeto: TAutorizadorInterfaceFake;
  LAutorizador: IAutorizadorInterface;
  LInicializadorAplicacao: TInicializadorAplicacao;
  LMensagem: string;
begin
  LPorta := PortaLocalSemServico;
  LInicializadorObjeto := TInicializadorBanco.Create(FCaminhoBanco, FCatalogo, nil, LPorta);
  LPersistencia := LInicializadorObjeto;
  LAutorizadorObjeto := TAutorizadorInterfaceFake.Create;
  LAutorizador := LAutorizadorObjeto;
  LInicializadorAplicacao := TInicializadorAplicacao.Create(LPersistencia, LAutorizador);
  try
    Assert.IsFalse(LInicializadorAplicacao.Inicializar(LMensagem));
    Assert.IsFalse(LAutorizadorObjeto.Autorizado,
      'A interface não pode ser autorizada com o serviço Firebird indisponível.');
    Assert.IsFalse(Assigned(LInicializadorObjeto.Conexao) and
      LInicializadorObjeto.Conexao.Connected,
      'Nenhuma conexão pode ser entregue com o serviço indisponível.');
    Assert.IsFalse(TFile.Exists(FCaminhoBanco),
      'Nenhuma base pode ser criada sem o serviço.');
    Assert.Contains(LMensagem, 'Firebird 3');
    Assert.Contains(LMensagem, 'localhost:' + IntToStr(LPorta));
    AssegurarSemCredenciais(LMensagem, 'A mensagem de serviço indisponível');
  finally
    LInicializadorAplicacao.Free;
    LPersistencia := nil;
    LAutorizador := nil;
  end;
end;

procedure CopiarArvore(const AOrigem, ADestino, ASubdiretorioIgnorado: string);
var
  LArquivo: string;
  LSubdiretorio: string;
  LNome: string;
begin
  TDirectory.CreateDirectory(ADestino);
  for LArquivo in TDirectory.GetFiles(AOrigem) do
    TFile.Copy(LArquivo, TPath.Combine(ADestino, TPath.GetFileName(LArquivo)), True);
  for LSubdiretorio in TDirectory.GetDirectories(AOrigem) do
  begin
    LNome := TPath.GetFileName(LSubdiretorio);
    if SameText(LNome, ASubdiretorioIgnorado) then
      Continue;
    CopiarArvore(LSubdiretorio, TPath.Combine(ADestino, LNome), ASubdiretorioIgnorado);
  end;
end;

function ExecutarEAguardar(const ACaminho, ADiretorio: string; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal; const AArgumentos: string = ''): Boolean;
var
  LInfo: TStartupInfo;
  LProcesso: TProcessInformation;
  LComando: string;
begin
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.cb := SizeOf(LInfo);
  FillChar(LProcesso, SizeOf(LProcesso), 0);
  LComando := Trim('"' + ACaminho + '" ' + AArgumentos);
  if not CreateProcess(nil, PChar(LComando), nil, nil, False, 0, nil,
    PChar(ADiretorio), LInfo, LProcesso) then
    RaiseLastOSError;
  try
    Result := WaitForSingleObject(LProcesso.hProcess, ALimiteMs) = WAIT_OBJECT_0;
    if Result then
      GetExitCodeProcess(LProcesso.hProcess, ACodigoSaida)
    else
    begin
      ACodigoSaida := High(Cardinal);
      TerminateProcess(LProcesso.hProcess, 1);
    end;
  finally
    CloseHandle(LProcesso.hThread);
    CloseHandle(LProcesso.hProcess);
  end;
end;

type
  TMigracaoRealAlfa = class(TMigracaoBanco)
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

  TMigracaoRealBeta = class(TMigracaoBanco)
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

  TMigracaoRealInvalida = class(TMigracaoBanco)
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

function TMigracaoRealAlfa.Versao: Integer;
begin
  Result := 1;
end;

function TMigracaoRealAlfa.Descricao: string;
begin
  Result := 'cria alfa';
end;

procedure TMigracaoRealAlfa.Executar(const AContexto: IContextoMigracao);
begin
  AContexto.Executar('CREATE TABLE ALFA (ID INTEGER NOT NULL PRIMARY KEY)');
end;

function TMigracaoRealBeta.Versao: Integer;
begin
  Result := 2;
end;

function TMigracaoRealBeta.Descricao: string;
begin
  Result := 'cria beta';
end;

procedure TMigracaoRealBeta.Executar(const AContexto: IContextoMigracao);
begin
  AContexto.Executar('CREATE TABLE BETA (ID INTEGER NOT NULL PRIMARY KEY)');
end;

function TMigracaoRealInvalida.Versao: Integer;
begin
  Result := 3;
end;

function TMigracaoRealInvalida.Descricao: string;
begin
  Result := 'cria gama e falha';
end;

procedure TMigracaoRealInvalida.Executar(const AContexto: IContextoMigracao);
begin
  AContexto.Executar('CREATE TABLE GAMA (ID INTEGER NOT NULL PRIMARY KEY)');
  AContexto.Executar('ESTA INSTRUCAO NAO E SQL VALIDO');
end;

procedure TTestesMigracaoNoFirebird.Preparar;
begin
  FDiretorio := CriarDiretorioTemporario;
  FCaminhoBanco := TPath.Combine(FDiretorio, 'cadcli.fdb');
end;

procedure TTestesMigracaoNoFirebird.Limpar;
begin
  if TDirectory.Exists(FDiretorio) then
    TDirectory.Delete(FDiretorio, True);
end;

function TTestesMigracaoNoFirebird.PrepararCom(ACatalogo: TCatalogoMigracoes;
  out AMensagem: string): Boolean;
var
  LInicializador: TInicializadorBanco;
begin
  LInicializador := TInicializadorBanco.Create(FCaminhoBanco, ACatalogo);
  try
    Result := LInicializador.Preparar(AMensagem);
  finally
    LInicializador.Free;
  end;
end;

procedure TTestesMigracaoNoFirebird.AplicaSomenteAPendenteSobreBaseAnterior;
var
  LCatalogo: TCatalogoMigracoes;
  LMensagem: string;
  LInicializador: TInicializadorBanco;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  try
    LCatalogo.Registrar(TMigracaoRealAlfa);
    Assert.IsTrue(PrepararCom(LCatalogo, LMensagem), LMensagem);
  finally
    LCatalogo.Free;
  end;

  LCatalogo := TCatalogoMigracoes.Create;
  try
    LCatalogo.Registrar(TMigracaoRealBeta);
    LCatalogo.Registrar(TMigracaoRealAlfa);
    LInicializador := TInicializadorBanco.Create(FCaminhoBanco, LCatalogo);
    try
      Assert.IsTrue(LInicializador.Preparar(LMensagem), LMensagem);
      Assert.AreEqual('1:cria alfa|2:cria beta', LinhasSQL(LInicializador.Conexao,
        'SELECT VERSAO || '':'' || TRIM(DESCRICAO) FROM SCHEMA_VERSION ORDER BY VERSAO'),
        'A base anterior deve receber apenas a pendente, sem reaplicar a versao 1.');
      Assert.AreEqual(2, InteiroSQL(LInicializador.Conexao,
        'SELECT COUNT(*) FROM RDB$RELATIONS WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 ' +
        'AND RDB$RELATION_NAME IN (''ALFA'',''BETA'')'));
    finally
      LInicializador.Free;
    end;
  finally
    LCatalogo.Free;
  end;
end;

procedure TTestesMigracaoNoFirebird.ReverteMigracaoInvalidaNoFirebirdEInformaVersao;
var
  LCatalogo: TCatalogoMigracoes;
  LMensagem: string;
  LInicializador: TInicializadorBanco;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  try
    LCatalogo.Registrar(TMigracaoRealAlfa);
    LCatalogo.Registrar(TMigracaoRealInvalida);
    Assert.IsFalse(PrepararCom(LCatalogo, LMensagem),
      'Uma migracao invalida deve impedir a preparacao da persistencia.');
    Assert.Contains(LMensagem, 'migração 3', 'O erro deve identificar a versao que falhou.');
  finally
    LCatalogo.Free;
  end;

  LCatalogo := TCatalogoMigracoes.Create;
  try
    LCatalogo.Registrar(TMigracaoRealAlfa);
    LInicializador := TInicializadorBanco.Create(FCaminhoBanco, LCatalogo);
    try
      Assert.IsTrue(LInicializador.Preparar(LMensagem), LMensagem);
      Assert.AreEqual(0, InteiroSQL(LInicializador.Conexao,
        'SELECT COUNT(*) FROM RDB$RELATIONS WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 ' +
        'AND RDB$RELATION_NAME = ''GAMA'''),
        'A tabela criada pela migracao que falhou nao pode sobreviver ao rollback.');
      Assert.AreEqual(0, InteiroSQL(LInicializador.Conexao,
        'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSAO = 3'),
        'A versao que falhou nao pode ser registrada.');
      Assert.AreEqual(1, InteiroSQL(LInicializador.Conexao,
        'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSAO = 1'),
        'A migracao anterior bem-sucedida deve permanecer registrada.');
    finally
      LInicializador.Free;
    end;
  finally
    LCatalogo.Free;
  end;
end;

procedure TTestesMigracaoNoFirebird.RegistraInstanteRealDaAplicacaoEmAplicadaEm;
var
  LCatalogo: TCatalogoMigracoes;
  LMensagem: string;
  LInicializador: TInicializadorBanco;
  LAntes: TDateTime;
  LDepois: TDateTime;
  LRegistrado: TDateTime;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  try
    LCatalogo.Registrar(TMigracaoRealAlfa);
    LAntes := Now;
    LInicializador := TInicializadorBanco.Create(FCaminhoBanco, LCatalogo);
    try
      Assert.IsTrue(LInicializador.Preparar(LMensagem), LMensagem);
      LDepois := Now;
      LRegistrado := DataHoraSQL(LInicializador.Conexao,
        'SELECT APLICADA_EM FROM SCHEMA_VERSION WHERE VERSAO = 1');
      Assert.IsTrue(LRegistrado >= IncSecond(LAntes, -2),
        'APLICADA_EM nao pode ser anterior ao inicio da aplicacao da migracao.');
      Assert.IsTrue(LRegistrado <= IncSecond(LDepois, 2),
        'APLICADA_EM nao pode ser posterior ao fim da aplicacao da migracao.');
    finally
      LInicializador.Free;
    end;
  finally
    LCatalogo.Free;
  end;
end;

procedure TTestesConvencaoMigracoes.CadaVersaoTemUnitEClasseNoFormatoDefinido;
var
  LArquivo: string;
  LNome: string;
  LNumero: string;
  LDescricao: string;
  LClasseEsperada: string;
  LConteudo: string;
  LQuantidade: Integer;
begin
  LQuantidade := 0;
  for LArquivo in TDirectory.GetFiles(
    TPath.Combine(RaizRepositorio, 'src' + TPath.DirectorySeparatorChar + 'Migracoes'), '*.pas') do
  begin
    Inc(LQuantidade);
    LNome := TPath.GetFileNameWithoutExtension(LArquivo);
    Assert.IsTrue(LNome.StartsWith('Migracao.V'),
      'Uma unit de migracao deve seguir Migracao.VNNN.Descricao: ' + LNome);
    LNumero := LNome.Substring(Length('Migracao.V'), 3);
    Assert.IsTrue(StrToIntDef(LNumero, -1) > 0,
      'A unit deve trazer a versao com tres digitos: ' + LNome);
    LDescricao := LNome.Substring(Length('Migracao.VNNN.'));
    Assert.IsFalse(LDescricao.IsEmpty, 'A unit deve trazer uma descricao: ' + LNome);
    Assert.IsFalse(LDescricao.Contains('.'),
      'A unit deve ter exatamente quatro partes separadas por ponto: ' + LNome);
    LClasseEsperada := 'TMigracao' + LNumero + LDescricao;
    LConteudo := TFile.ReadAllText(LArquivo);
    Assert.IsTrue(LConteudo.Contains(LClasseEsperada + ' = class(TMigracaoBanco)'),
      'A unit deve declarar ' + LClasseEsperada + ' derivada de TMigracaoBanco: ' + LNome);
  end;
  Assert.IsTrue(LQuantidade >= 2,
    'O historico de migracoes compiladas deve conter as versoes da Parte 01.');
end;

procedure TTestesAplicacaoRelease.Preparar;
begin
  FDiretorio := CriarDiretorioTemporario;
end;

procedure TTestesAplicacaoRelease.Limpar;
begin
  if TDirectory.Exists(FDiretorio) then
    TDirectory.Delete(FDiretorio, True);
end;

procedure TTestesAplicacaoRelease.ExecutavelReleaseCriaBaseCompletaAoLado;
var
  LCodigoSaida: Cardinal;
  LTerminou: Boolean;
  LConexao: TFDConnection;
  LBanco: string;
  LPadrao: string;
begin
  Assert.IsTrue(TFile.Exists(CaminhoExecutavelRelease),
    'Compile a configuracao Release antes de executar esta prova.');
  CopiarArvore(TPath.GetDirectoryName(CaminhoExecutavelRelease), FDiretorio, 'dcu');
  LBanco := TPath.Combine(FDiretorio, 'cadcli.fdb');
  Assert.IsFalse(TFile.Exists(LBanco), 'A copia da entrega nao pode conter cadcli.fdb.');
  for LPadrao in ARQUIVOS_RUNTIME_FIREBIRD do
    Assert.AreEqual(0, Integer(Length(TDirectory.GetFiles(FDiretorio, LPadrao))),
      'A copia da entrega nao pode conter ' + LPadrao + '.');
  for LPadrao in DIRETORIOS_RUNTIME_FIREBIRD do
    Assert.IsFalse(TDirectory.Exists(TPath.Combine(FDiretorio, LPadrao)),
      'A copia da entrega nao pode conter o subdiretorio ' + LPadrao + '.');

  LTerminou := ExecutarEAguardar(TPath.Combine(FDiretorio, 'CadCli.exe'), FDiretorio,
    120000, LCodigoSaida);
  Assert.IsTrue(LTerminou,
    'CadCli.exe nao encerrou: a inicializacao travou, provavelmente em um dialogo de erro.');
  Assert.AreEqual(Cardinal(0), LCodigoSaida, 'CadCli.exe deve encerrar com codigo 0.');
  Assert.IsTrue(TFile.Exists(LBanco),
    'CadCli.exe deve criar cadcli.fdb ao lado do executavel.');

  LConexao := ConectarPeloServico(LBanco);
  try
    Assert.AreEqual(2, InteiroSQL(LConexao, 'SELECT COUNT(*) FROM SCHEMA_VERSION'),
      'A base criada pelo executavel deve registrar as duas migracoes.');
    Assert.AreEqual(4, InteiroSQL(LConexao, 'SELECT COUNT(*) FROM ESTADO'));
    Assert.AreEqual(12, InteiroSQL(LConexao, 'SELECT COUNT(*) FROM CIDADE'));
    Assert.AreEqual(0, InteiroSQL(LConexao, 'SELECT COUNT(*) FROM CLIENTE'));
    Assert.AreEqual('Uberlândia', TextoSQL(LConexao,
      'SELECT NOME FROM CIDADE WHERE ID = 2'),
      'Os dados de referencia devem preservar acentuacao em UTF8.');
  finally
    LConexao.Free;
  end;
end;

procedure TTestesMigracaoInicial.Preparar;
var
  LMensagem: string;
begin
  FDiretorio := CriarDiretorioTemporario;
  FCaminhoBanco := TPath.Combine(FDiretorio, 'cadcli.fdb');
  FCatalogo := CriarCatalogoPadrao;
  FInicializador := TInicializadorBanco.Create(FCaminhoBanco, FCatalogo);
  Assert.IsTrue(FInicializador.Preparar(LMensagem), LMensagem);
end;

procedure TTestesMigracaoInicial.Limpar;
begin
  FreeAndNil(FInicializador);
  FreeAndNil(FCatalogo);
  if TDirectory.Exists(FDiretorio) then
    TDirectory.Delete(FDiretorio, True);
end;

procedure TTestesMigracaoInicial.CriaEsquemaComMetadadosExatos;
const
  SQL_COLUNAS =
    'SELECT TRIM(RF.RDB$RELATION_NAME) || ''.'' || TRIM(RF.RDB$FIELD_NAME) || '':'' || ' +
    'CASE F.RDB$FIELD_TYPE WHEN 8 THEN ''INTEGER'' WHEN 12 THEN ''DATE'' ' +
    'WHEN 14 THEN ''CHAR'' WHEN 35 THEN ''TIMESTAMP'' WHEN 37 THEN ''VARCHAR'' ' +
    'ELSE ''TIPO'' || CAST(F.RDB$FIELD_TYPE AS VARCHAR(10)) END || '':'' || ' +
    'CAST(COALESCE(F.RDB$CHARACTER_LENGTH, 0) AS VARCHAR(10)) ' +
    'FROM RDB$RELATION_FIELDS RF ' +
    'JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = RF.RDB$FIELD_SOURCE ' +
    'WHERE RF.RDB$RELATION_NAME IN (''CLIENTE'',''ESTADO'',''CIDADE'',''SCHEMA_VERSION'') ' +
    'ORDER BY RF.RDB$RELATION_NAME, RF.RDB$FIELD_POSITION';
  COLUNAS_ESPERADAS =
    'CIDADE.ID:INTEGER:0|CIDADE.NOME:VARCHAR:50|CIDADE.ESTADOID:INTEGER:0|' +
    'CLIENTE.ID:INTEGER:0|CLIENTE.NOME:VARCHAR:80|CLIENTE.CEP:CHAR:8|' +
    'CLIENTE.CPF_CNPJ:VARCHAR:14|CLIENTE.ENDERECO:VARCHAR:100|' +
    'CLIENTE.NUMERO:VARCHAR:20|CLIENTE.COMPLEMENTO:VARCHAR:60|' +
    'CLIENTE.BAIRRO:VARCHAR:100|CLIENTE.CIDADE:INTEGER:0|' +
    'CLIENTE.DATANASCIMENTO:DATE:0|' +
    'ESTADO.ID:INTEGER:0|ESTADO.NOME:VARCHAR:50|ESTADO.UF:CHAR:2|' +
    'SCHEMA_VERSION.VERSAO:INTEGER:0|SCHEMA_VERSION.DESCRICAO:VARCHAR:200|' +
    'SCHEMA_VERSION.APLICADA_EM:TIMESTAMP:0';
  SQL_RESTRICOES =
    'SELECT TRIM(RC.RDB$CONSTRAINT_NAME) || '':'' || TRIM(RC.RDB$CONSTRAINT_TYPE) || ' +
    ''':'' || TRIM(SEG.RDB$FIELD_NAME) ' +
    'FROM RDB$RELATION_CONSTRAINTS RC ' +
    'JOIN RDB$INDEX_SEGMENTS SEG ON SEG.RDB$INDEX_NAME = RC.RDB$INDEX_NAME ' +
    'WHERE RC.RDB$RELATION_NAME IN (''CLIENTE'',''ESTADO'',''CIDADE'',''SCHEMA_VERSION'') ' +
    'ORDER BY RC.RDB$CONSTRAINT_NAME, SEG.RDB$FIELD_POSITION';
  RESTRICOES_ESPERADAS =
    'FK_CIDADE_ESTADO:FOREIGN KEY:ESTADOID|FK_CLIENTE_CIDADE:FOREIGN KEY:CIDADE|' +
    'PK_CIDADE:PRIMARY KEY:ID|PK_CLIENTE:PRIMARY KEY:ID|PK_ESTADO:PRIMARY KEY:ID|' +
    'PK_SCHEMA_VERSION:PRIMARY KEY:VERSAO|' +
    'UQ_CIDADE_ESTADO_NOME:UNIQUE:ESTADOID|UQ_CIDADE_ESTADO_NOME:UNIQUE:NOME|' +
    'UQ_ESTADO_UF:UNIQUE:UF';
  SQL_REFERENCIAS =
    'SELECT TRIM(RC.RDB$CONSTRAINT_NAME) || ''->'' || TRIM(ALVO.RDB$RELATION_NAME) ' +
    'FROM RDB$RELATION_CONSTRAINTS RC ' +
    'JOIN RDB$REF_CONSTRAINTS REFC ON REFC.RDB$CONSTRAINT_NAME = RC.RDB$CONSTRAINT_NAME ' +
    'JOIN RDB$RELATION_CONSTRAINTS ALVO ON ALVO.RDB$CONSTRAINT_NAME = REFC.RDB$CONST_NAME_UQ ' +
    'WHERE RC.RDB$CONSTRAINT_TYPE = ''FOREIGN KEY'' ORDER BY RC.RDB$CONSTRAINT_NAME';
  REFERENCIAS_ESPERADAS =
    'FK_CIDADE_ESTADO->ESTADO|FK_CLIENTE_CIDADE->CIDADE';
begin
  Assert.AreEqual(COLUNAS_ESPERADAS, LinhasSQL(FInicializador.Conexao, SQL_COLUNAS),
    'As colunas, tipos e larguras devem corresponder exatamente ao door 4 do plano.');
  Assert.AreEqual(RESTRICOES_ESPERADAS, LinhasSQL(FInicializador.Conexao, SQL_RESTRICOES),
    'Cada chave e unicidade deve cobrir exatamente as colunas definidas no plano.');
  Assert.AreEqual(REFERENCIAS_ESPERADAS, LinhasSQL(FInicializador.Conexao, SQL_REFERENCIAS),
    'Cada chave estrangeira deve apontar para a tabela definida no plano.');
end;

procedure TTestesMigracaoInicial.InsereEstadosECidadesDeReferencia;
var
  LReferencias: string;
begin
  LReferencias := LinhasSQL(FInicializador.Conexao,
    'SELECT E.NOME || ''/'' || E.UF || '':'' || C.NOME FROM ESTADO E ' +
    'JOIN CIDADE C ON C.ESTADOID=E.ID ORDER BY E.ID, C.ID');
  Assert.AreEqual(
    'Minas Gerais/MG:Belo Horizonte|Minas Gerais/MG:Uberlândia|Minas Gerais/MG:Contagem|' +
    'São Paulo/SP:São Paulo|São Paulo/SP:Campinas|São Paulo/SP:Santos|' +
    'Rio de Janeiro/RJ:Rio de Janeiro|Rio de Janeiro/RJ:Niterói|Rio de Janeiro/RJ:Petrópolis|' +
    'Bahia/BA:Salvador|Bahia/BA:Feira de Santana|Bahia/BA:Vitória da Conquista',
    LReferencias);
  Assert.AreEqual(4, InteiroSQL(FInicializador.Conexao,
    'SELECT COUNT(*) FROM (SELECT ESTADOID FROM CIDADE GROUP BY ESTADOID HAVING COUNT(*)=3)'));
end;

procedure TTestesMigracaoInicial.CriaUmaSequenciaPorEntidadeSemMaxId;
var
  LArquivo: string;
  LConteudo: string;
begin
  Assert.AreEqual(3, InteiroSQL(FInicializador.Conexao,
    'SELECT COUNT(*) FROM RDB$GENERATORS WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 ' +
    'AND RDB$GENERATOR_NAME IN (''SEQ_CLIENTE'',''SEQ_ESTADO'',''SEQ_CIDADE'')'));
  for LArquivo in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.pas',
    TSearchOption.soAllDirectories) do
  begin
    LConteudo := TFile.ReadAllText(LArquivo);
    Assert.IsFalse(TRegEx.IsMatch(LConteudo,
      'MAX\s*\(\s*ID\s*\)\s*\+\s*1', [roIgnoreCase]),
      'Nenhuma migração ou repositório pode usar MAX(ID) + 1: ' + LArquivo);
  end;
end;

procedure TTestesMigracaoInicial.SequenciasContinuamDepoisDosDadosDeReferencia;
var
  LProximoEstado: Integer;
  LProximaCidade: Integer;
begin
  LProximoEstado := InteiroSQL(FInicializador.Conexao,
    'SELECT NEXT VALUE FOR SEQ_ESTADO FROM RDB$DATABASE');
  Assert.IsTrue(LProximoEstado > InteiroSQL(FInicializador.Conexao,
    'SELECT MAX(ID) FROM ESTADO'),
    'A proxima chave de SEQ_ESTADO deve estar livre apos os estados de referencia.');
  LProximaCidade := InteiroSQL(FInicializador.Conexao,
    'SELECT NEXT VALUE FOR SEQ_CIDADE FROM RDB$DATABASE');
  Assert.IsTrue(LProximaCidade > InteiroSQL(FInicializador.Conexao,
    'SELECT MAX(ID) FROM CIDADE'),
    'A proxima chave de SEQ_CIDADE deve estar livre apos as cidades de referencia.');
  Assert.IsTrue(InteiroSQL(FInicializador.Conexao,
    'SELECT NEXT VALUE FOR SEQ_CLIENTE FROM RDB$DATABASE') > 0,
    'SEQ_CLIENTE deve gerar chaves positivas.');
end;

procedure TTestesAplicacaoRelease.ExecutavelReleaseRecusaVersaoFuturaERegistraOErro;
var
  LCodigoSaida: Cardinal;
  LTerminou: Boolean;
  LConexao: TFDConnection;
  LBanco: string;
  LExecutavel: string;
  LRegistro: string;
  LConteudo: string;
  LInstanteRegistro: string;
  LInicio: TDateTime;
  LFim: TDateTime;
begin
  Assert.IsTrue(TFile.Exists(CaminhoExecutavelRelease),
    'Compile a configuracao Release antes de executar esta prova.');
  CopiarArvore(TPath.GetDirectoryName(CaminhoExecutavelRelease), FDiretorio, 'dcu');
  LExecutavel := TPath.Combine(FDiretorio, 'CadCli.exe');
  LBanco := TPath.Combine(FDiretorio, 'cadcli.fdb');

  LTerminou := ExecutarEAguardar(LExecutavel, FDiretorio, 120000, LCodigoSaida);
  Assert.IsTrue(LTerminou, 'CadCli.exe nao encerrou na primeira execucao.');
  Assert.AreEqual(Cardinal(0), LCodigoSaida);

  LConexao := ConectarPeloServico(LBanco);
  try
    LConexao.ExecSQL('INSERT INTO SCHEMA_VERSION (VERSAO, DESCRICAO, APLICADA_EM) ' +
      'VALUES (999, ''versao de um CadCli mais novo'', CURRENT_TIMESTAMP)');
  finally
    LConexao.Free;
  end;

  LRegistro := TPath.Combine(FDiretorio, 'cadcli-erro.log');
  Assert.IsFalse(TFile.Exists(LRegistro), 'Nenhum erro deveria ter sido registrado ainda.');

  LInicio := Now;
  LTerminou := ExecutarEAguardar(LExecutavel, FDiretorio, 120000, LCodigoSaida,
    '-sem-interacao');
  LFim := Now;

  Assert.IsTrue(LTerminou,
    'CadCli.exe nao encerrou diante de uma base mais nova: a falha ficou presa em um dialogo.');
  Assert.AreEqual(Cardinal(1), LCodigoSaida,
    'Uma inicializacao recusada deve encerrar com codigo 1.');
  Assert.IsTrue(TFile.Exists(LRegistro),
    'A falha de inicializacao deve ficar registrada para investigacao.');
  LConteudo := TFile.ReadAllText(LRegistro, TEncoding.UTF8);
  Assert.Contains(LConteudo, '999', 'O registro deve identificar a versao encontrada.');
  Assert.Contains(LConteudo, 'CadCli.exe',
    'O registro deve orientar a atualizacao do CadCli.exe.');
  AssegurarSemCredenciais(LConteudo, 'O cadcli-erro.log');
  if (LConteudo <> '') and (Ord(LConteudo[1]) = $FEFF) then
    Delete(LConteudo, 1, 1);
  LInstanteRegistro := Copy(LConteudo, 1, 19);
  Assert.IsTrue(CompareStr(LInstanteRegistro,
    FormatDateTime('yyyy-mm-dd hh:nn:ss', LInicio)) >= 0,
    'O instante do log não pode ser anterior à execução recusada.');
  Assert.IsTrue(CompareStr(LInstanteRegistro,
    FormatDateTime('yyyy-mm-dd hh:nn:ss', LFim)) <= 0,
    'O instante do log não pode ser posterior ao encerramento do processo.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesInicializadorBanco);
  TDUnitX.RegisterTestFixture(TTestesMigracaoInicial);
  TDUnitX.RegisterTestFixture(TTestesAplicacaoRelease);
  TDUnitX.RegisterTestFixture(TTestesMigracaoNoFirebird);
  TDUnitX.RegisterTestFixture(TTestesConvencaoMigracoes);

end.

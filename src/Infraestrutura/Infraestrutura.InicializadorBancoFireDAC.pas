unit Infraestrutura.InicializadorBancoFireDAC;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Aplicacao.CatalogoMigracoes,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.InicializadorAplicacao,
  Dominio.Migracao,
  Infraestrutura.ContextoMigracaoFireDAC;

type
  TBootstrapTabelaVersoes = class
  public
    class procedure Executar(const AContexto: IContextoMigracao); static;
  end;

  TInicializadorBanco = class(TInterfacedObject, IInicializadorPersistencia)
  private
    FCaminhoBanco: string;
    FBibliotecaCliente: string;
    FCatalogo: TCatalogoMigracoes;
    FConexao: TFDConnection;
    FObservadorSql: TObservadorSql;
    procedure ConfigurarConexao;
    procedure GarantirTabelaVersoes;
  public
    constructor Create(const ACaminhoBanco: string; ACatalogo: TCatalogoMigracoes;
      const ABibliotecaCliente: string = ''; AObservadorSql: TObservadorSql = nil);
    destructor Destroy; override;
    function Preparar(out AMensagemErro: string): Boolean;
    property Conexao: TFDConnection read FConexao;
  end;

implementation

uses
  FireDAC.Stan.Def,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef;

class procedure TBootstrapTabelaVersoes.Executar(const AContexto: IContextoMigracao);
begin
  if not Assigned(AContexto) then
    raise EArgumentNilException.Create('O contexto de migração deve ser informado.');
  if AContexto.TabelaExiste('SCHEMA_VERSION') then
    Exit;
  AContexto.IniciarTransacao;
  try
    AContexto.Executar(
      'CREATE TABLE SCHEMA_VERSION (' +
      'VERSAO INTEGER NOT NULL, DESCRICAO VARCHAR(200) NOT NULL, ' +
      'APLICADA_EM TIMESTAMP NOT NULL, ' +
      'CONSTRAINT PK_SCHEMA_VERSION PRIMARY KEY (VERSAO))');
    AContexto.ConfirmarTransacao;
  except
    AContexto.ReverterTransacao;
    raise;
  end;
end;

constructor TInicializadorBanco.Create(const ACaminhoBanco: string;
  ACatalogo: TCatalogoMigracoes; const ABibliotecaCliente: string;
  AObservadorSql: TObservadorSql);
begin
  inherited Create;
  if Trim(ACaminhoBanco) = '' then
    raise EArgumentException.Create('O caminho do banco deve ser informado.');
  if not Assigned(ACatalogo) then
    raise EArgumentNilException.Create('O catálogo de migrações deve ser informado.');
  FCaminhoBanco := ExpandFileName(ACaminhoBanco);
  FBibliotecaCliente := ABibliotecaCliente;
  FCatalogo := ACatalogo;
  FObservadorSql := AObservadorSql;
end;

destructor TInicializadorBanco.Destroy;
begin
  FConexao.Free;
  inherited;
end;

procedure TInicializadorBanco.ConfigurarConexao;
begin
  if not Assigned(FConexao) then
    FConexao := TFDConnection.Create(nil);
  FConexao.LoginPrompt := False;
  FConexao.Params.Clear;
  FConexao.Params.Values['DriverID'] := 'FB';
  FConexao.Params.Values['Database'] := FCaminhoBanco;
  FConexao.Params.Values['User_Name'] := 'SYSDBA';
  FConexao.Params.Values['Password'] := 'masterkey';
  FConexao.Params.Values['OpenMode'] := 'OpenOrCreate';
  FConexao.Params.Values['SQLDialect'] := '3';
  FConexao.Params.Values['CharacterSet'] := 'UTF8';
  if FBibliotecaCliente <> '' then
    FConexao.Params.Values['VendorLib'] := FBibliotecaCliente;
end;

procedure TInicializadorBanco.GarantirTabelaVersoes;
var
  LContexto: IContextoMigracao;
begin
  LContexto := TContextoMigracaoFireDAC.Create(FConexao, FObservadorSql);
  TBootstrapTabelaVersoes.Executar(LContexto);
end;

function TInicializadorBanco.Preparar(out AMensagemErro: string): Boolean;
var
  LContexto: IContextoMigracao;
  LExecutor: TExecutorMigracoes;
begin
  Result := False;
  AMensagemErro := '';
  try
    if (FBibliotecaCliente <> '') and not FileExists(FBibliotecaCliente) then
      raise Exception.Create('fbclient.dll x64 não foi encontrada em ' + FBibliotecaCliente);
    ConfigurarConexao;
    FConexao.Connected := True;
    GarantirTabelaVersoes;
    LContexto := TContextoMigracaoFireDAC.Create(FConexao, FObservadorSql);
    LExecutor := TExecutorMigracoes.Create(FCatalogo, TRelogioSistema.Create);
    try
      LExecutor.Executar(LContexto);
    finally
      LExecutor.Free;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      if Assigned(FConexao) and FConexao.Connected then
        FConexao.Connected := False;
      if (Pos('fbclient', LowerCase(E.Message)) > 0) or
         (Pos('vendor lib', LowerCase(E.Message)) > 0) then
        AMensagemErro := 'A dependência Firebird Embedded 3 x64 (fbclient.dll) não foi encontrada ou não pôde ser carregada: ' + E.Message
      else
        AMensagemErro := E.Message;
    end;
  end;
end;

end.

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

const
  SERVIDOR_FIREBIRD = 'localhost';
  PORTA_FIREBIRD = 3050;

type
  TBootstrapTabelaVersoes = class
  public
    class procedure Executar(const AContexto: IContextoMigracao); static;
  end;

  TInicializadorBanco = class(TInterfacedObject, IInicializadorPersistencia)
  private
    FCaminhoBanco: string;
    FPorta: Integer;
    FCatalogo: TCatalogoMigracoes;
    FConexao: TFDConnection;
    FObservadorSql: TObservadorSql;
    procedure ConfigurarConexao;
    procedure GarantirTabelaVersoes;
    procedure Conectar;
  public
    constructor Create(const ACaminhoBanco: string; ACatalogo: TCatalogoMigracoes;
      AObservadorSql: TObservadorSql = nil; APorta: Integer = PORTA_FIREBIRD);
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
  ACatalogo: TCatalogoMigracoes; AObservadorSql: TObservadorSql; APorta: Integer);
begin
  inherited Create;
  if Trim(ACaminhoBanco) = '' then
    raise EArgumentException.Create('O caminho do banco deve ser informado.');
  if not Assigned(ACatalogo) then
    raise EArgumentNilException.Create('O catálogo de migrações deve ser informado.');
  FCaminhoBanco := ExpandFileName(ACaminhoBanco);
  FPorta := APorta;
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
  FConexao.Params.Values['Server'] := SERVIDOR_FIREBIRD;
  FConexao.Params.Values['Port'] := IntToStr(FPorta);
  FConexao.Params.Values['Database'] := FCaminhoBanco;
  FConexao.Params.Values['User_Name'] := 'SYSDBA';
  FConexao.Params.Values['Password'] := 'masterkey';
  FConexao.Params.Values['OpenMode'] := 'OpenOrCreate';
  FConexao.Params.Values['SQLDialect'] := '3';
  FConexao.Params.Values['CharacterSet'] := 'UTF8';
end;

procedure TInicializadorBanco.Conectar;
begin
  ConfigurarConexao;
  try
    FConexao.Connected := True;
  except
    on E: Exception do
      raise Exception.CreateFmt(
        'Não foi possível conectar ao serviço Firebird 3 em %s:%d. ' +
        'Verifique se o serviço está instalado e em execução. Detalhe: %s',
        [SERVIDOR_FIREBIRD, FPorta, E.Message]);
  end;
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
    Conectar;
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
      AMensagemErro := E.Message;
    end;
  end;
end;

end.

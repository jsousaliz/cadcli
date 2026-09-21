unit Infraestrutura.ContextoMigracaoFireDAC;

interface

uses
  FireDAC.DApt,
  FireDAC.Stan.Async,
  System.SysUtils,
  FireDAC.Comp.Client,
  Dominio.Migracao;

type
  TObservadorSql = reference to procedure(const ASql: string);

  TContextoMigracaoFireDAC = class(TInterfacedObject, IContextoMigracao)
  private
    FConexao: TFDConnection;
    FObservadorSql: TObservadorSql;
  public
    constructor Create(AConexao: TFDConnection; AObservadorSql: TObservadorSql = nil);
    procedure IniciarTransacao;
    procedure ConfirmarTransacao;
    procedure ReverterTransacao;
    procedure Executar(const ASql: string);
    procedure ExecutarParametrizado(const ASql: string; const AValores: array of Variant);
    function TabelaExiste(const ANome: string): Boolean;
    function MaiorVersaoInstalada: Integer;
    function VersaoInstalada(AVersao: Integer): Boolean;
    procedure RegistrarMigracao(AVersao: Integer; const ADescricao: string; AAplicadaEm: TDateTime);
  end;

implementation

constructor TContextoMigracaoFireDAC.Create(AConexao: TFDConnection;
  AObservadorSql: TObservadorSql);
begin
  inherited Create;
  if not Assigned(AConexao) then
    raise EArgumentNilException.Create('A conexão FireDAC deve ser informada.');
  FConexao := AConexao;
  FObservadorSql := AObservadorSql;
end;

procedure TContextoMigracaoFireDAC.IniciarTransacao;
begin
  FConexao.StartTransaction;
end;

procedure TContextoMigracaoFireDAC.ConfirmarTransacao;
begin
  FConexao.Commit;
end;

procedure TContextoMigracaoFireDAC.ReverterTransacao;
begin
  if FConexao.InTransaction then
    FConexao.Rollback;
end;

procedure TContextoMigracaoFireDAC.Executar(const ASql: string);
begin
  if Assigned(FObservadorSql) then
    FObservadorSql(ASql);
  FConexao.ExecSQL(ASql);
end;

procedure TContextoMigracaoFireDAC.ExecutarParametrizado(const ASql: string;
  const AValores: array of Variant);
begin
  if Assigned(FObservadorSql) then
    FObservadorSql(ASql);
  FConexao.ExecSQL(ASql, AValores);
end;

function TContextoMigracaoFireDAC.TabelaExiste(const ANome: string): Boolean;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := FConexao;
    LConsulta.SQL.Text :=
      'SELECT COUNT(*) FROM RDB$RELATIONS ' +
      'WHERE RDB$RELATION_NAME = :NOME AND COALESCE(RDB$SYSTEM_FLAG, 0) = 0';
    LConsulta.ParamByName('NOME').AsString := UpperCase(ANome);
    LConsulta.Open;
    Result := LConsulta.Fields[0].AsInteger = 1;
  finally
    LConsulta.Free;
  end;
end;

function TContextoMigracaoFireDAC.MaiorVersaoInstalada: Integer;
var
  LConsulta: TFDQuery;
begin
  if not TabelaExiste('SCHEMA_VERSION') then
    Exit(0);
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := FConexao;
    LConsulta.SQL.Text := 'SELECT COALESCE(MAX(VERSAO), 0) FROM SCHEMA_VERSION';
    LConsulta.Open;
    Result := LConsulta.Fields[0].AsInteger;
  finally
    LConsulta.Free;
  end;
end;

function TContextoMigracaoFireDAC.VersaoInstalada(AVersao: Integer): Boolean;
var
  LConsulta: TFDQuery;
begin
  if not TabelaExiste('SCHEMA_VERSION') then
    Exit(False);
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := FConexao;
    LConsulta.SQL.Text := 'SELECT COUNT(*) FROM SCHEMA_VERSION WHERE VERSAO = :VERSAO';
    LConsulta.ParamByName('VERSAO').AsInteger := AVersao;
    LConsulta.Open;
    Result := LConsulta.Fields[0].AsInteger = 1;
  finally
    LConsulta.Free;
  end;
end;

procedure TContextoMigracaoFireDAC.RegistrarMigracao(AVersao: Integer;
  const ADescricao: string; AAplicadaEm: TDateTime);
begin
  ExecutarParametrizado(
    'INSERT INTO SCHEMA_VERSION (VERSAO, DESCRICAO, APLICADA_EM) VALUES (?, ?, ?)',
    [AVersao, ADescricao, AAplicadaEm]);
end;

end.

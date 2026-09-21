unit Infraestrutura.RepositorioClienteFireDAC;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Dominio.Cliente,
  Aplicacao.RepositorioCliente,
  Aplicacao.Transacao;

type
  TRepositorioClienteFireDAC = class(TInterfacedObject, IRepositorioCliente)
  private
    FConexao: TFDConnection;
    function CriarConsulta(const ASql: string): TFDQuery;
    function ProximoValor(const ASequencia: string): Integer;
    function ObterId(const ASql: string; const AParametros: array of Variant): Integer;
    procedure DefinirParametros(AConsulta: TFDQuery; const ACliente: TCliente);
    function LerClientes(const ASql: string; const AParametros: array of Variant): TClientes;
  public
    constructor Create(AConexao: TFDConnection);
    function Incluir(const ACliente: TCliente): Integer;
    procedure Alterar(const ACliente: TCliente);
    procedure Excluir(AId: Integer);
    function ObterPorId(AId: Integer): TCliente;
    function ListarTodos: TClientes;
    function ResolverCidade(const ANomeCidade, AUf, ANomeEstado: string): Integer;
  end;

  TTransacaoFireDAC = class(TInterfacedObject, ITransacao)
  private
    FConexao: TFDConnection;
  public
    constructor Create(AConexao: TFDConnection);
    procedure Iniciar;
    procedure Confirmar;
    procedure Reverter;
  end;

  EClienteNaoEncontrado = class(Exception);

implementation

uses
  FireDAC.DApt,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param;

const
  SQL_SELECAO_CLIENTES =
    'SELECT C.ID, C.NOME, C.CPF_CNPJ, C.CEP, C.ENDERECO, C.NUMERO, C.COMPLEMENTO, C.BAIRRO, ' +
    'C.CIDADEID, C.DATANASCIMENTO, CI.NOME AS CIDADE, E.UF, E.NOME AS ESTADO ' +
    'FROM CLIENTE C ' +
    'LEFT JOIN CIDADE CI ON CI.ID = C.CIDADEID ' +
    'LEFT JOIN ESTADO E ON E.ID = CI.ESTADOID ';

constructor TRepositorioClienteFireDAC.Create(AConexao: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConexao) then
    raise EArgumentNilException.Create('A conexão FireDAC deve ser informada.');
  FConexao := AConexao;
end;

function TRepositorioClienteFireDAC.CriarConsulta(const ASql: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConexao;
  Result.SQL.Text := ASql;
end;

function TRepositorioClienteFireDAC.ProximoValor(const ASequencia: string): Integer;
begin
  Result := ObterId('SELECT NEXT VALUE FOR ' + ASequencia + ' FROM RDB$DATABASE', []);
end;

function TRepositorioClienteFireDAC.ObterId(const ASql: string;
  const AParametros: array of Variant): Integer;
var
  LConsulta: TFDQuery;
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := FConexao;
    LConsulta.Open(ASql, AParametros);
    if LConsulta.IsEmpty then
      Result := 0
    else
      Result := LConsulta.Fields[0].AsInteger;
  finally
    LConsulta.Free;
  end;
end;

procedure TRepositorioClienteFireDAC.DefinirParametros(AConsulta: TFDQuery; const ACliente: TCliente);
begin
  AConsulta.ParamByName('NOME').AsString := ACliente.Nome;
  AConsulta.ParamByName('CEP').AsString := ACliente.Cep;
  AConsulta.ParamByName('CPF_CNPJ').AsString := ACliente.CpfCnpj;
  AConsulta.ParamByName('ENDERECO').AsString := ACliente.Endereco;
  AConsulta.ParamByName('NUMERO').AsString := ACliente.Numero;
  AConsulta.ParamByName('COMPLEMENTO').AsString := ACliente.Complemento;
  AConsulta.ParamByName('BAIRRO').AsString := ACliente.Bairro;
  AConsulta.ParamByName('CIDADEID').AsInteger := ACliente.CidadeId;
  AConsulta.ParamByName('DATANASCIMENTO').AsDate := ACliente.DataNascimento;
end;

function TRepositorioClienteFireDAC.LerClientes(const ASql: string;
  const AParametros: array of Variant): TClientes;
var
  LConsulta: TFDQuery;
  LCliente: TCliente;
begin
  Result := [];
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := FConexao;
    LConsulta.Open(ASql, AParametros);
    while not LConsulta.Eof do
    begin
      LCliente := Default(TCliente);
      LCliente.Id := LConsulta.FieldByName('ID').AsInteger;
      LCliente.Nome := LConsulta.FieldByName('NOME').AsString;
      LCliente.CpfCnpj := LConsulta.FieldByName('CPF_CNPJ').AsString;
      LCliente.Cep := Trim(LConsulta.FieldByName('CEP').AsString);
      LCliente.Endereco := LConsulta.FieldByName('ENDERECO').AsString;
      LCliente.Numero := LConsulta.FieldByName('NUMERO').AsString;
      LCliente.Complemento := LConsulta.FieldByName('COMPLEMENTO').AsString;
      LCliente.Bairro := LConsulta.FieldByName('BAIRRO').AsString;
      LCliente.CidadeId := LConsulta.FieldByName('CIDADEID').AsInteger;
      LCliente.DataNascimento := LConsulta.FieldByName('DATANASCIMENTO').AsDateTime;
      LCliente.Cidade := LConsulta.FieldByName('CIDADE').AsString;
      LCliente.Uf := Trim(LConsulta.FieldByName('UF').AsString);
      LCliente.Estado := LConsulta.FieldByName('ESTADO').AsString;
      Result := Result + [LCliente];
      LConsulta.Next;
    end;
  finally
    LConsulta.Free;
  end;
end;

function TRepositorioClienteFireDAC.Incluir(const ACliente: TCliente): Integer;
var
  LConsulta: TFDQuery;
begin
  Result := ProximoValor('SEQ_CLIENTE');
  LConsulta := CriarConsulta(
    'INSERT INTO CLIENTE (ID, NOME, CEP, CPF_CNPJ, ENDERECO, NUMERO, COMPLEMENTO, BAIRRO, ' +
    'CIDADEID, DATANASCIMENTO) VALUES (:ID, :NOME, :CEP, :CPF_CNPJ, :ENDERECO, :NUMERO, ' +
    ':COMPLEMENTO, :BAIRRO, :CIDADEID, :DATANASCIMENTO)');
  try
    LConsulta.ParamByName('ID').AsInteger := Result;
    DefinirParametros(LConsulta, ACliente);
    LConsulta.ExecSQL;
  finally
    LConsulta.Free;
  end;
end;

procedure TRepositorioClienteFireDAC.Alterar(const ACliente: TCliente);
var
  LConsulta: TFDQuery;
begin
  LConsulta := CriarConsulta(
    'UPDATE CLIENTE SET NOME = :NOME, CEP = :CEP, CPF_CNPJ = :CPF_CNPJ, ENDERECO = :ENDERECO, ' +
    'NUMERO = :NUMERO, COMPLEMENTO = :COMPLEMENTO, BAIRRO = :BAIRRO, CIDADEID = :CIDADEID, ' +
    'DATANASCIMENTO = :DATANASCIMENTO WHERE ID = :ID');
  try
    LConsulta.ParamByName('ID').AsInteger := ACliente.Id;
    DefinirParametros(LConsulta, ACliente);
    LConsulta.ExecSQL;
    if LConsulta.RowsAffected <> 1 then
      raise EClienteNaoEncontrado.CreateFmt('Cliente %d não encontrado.', [ACliente.Id]);
  finally
    LConsulta.Free;
  end;
end;

procedure TRepositorioClienteFireDAC.Excluir(AId: Integer);
begin
  if FConexao.ExecSQL('DELETE FROM CLIENTE WHERE ID = :ID', [AId]) <> 1 then
    raise EClienteNaoEncontrado.CreateFmt('Cliente %d não encontrado.', [AId]);
end;

function TRepositorioClienteFireDAC.ObterPorId(AId: Integer): TCliente;
var
  LClientes: TClientes;
begin
  LClientes := LerClientes(SQL_SELECAO_CLIENTES + 'WHERE C.ID = :ID', [AId]);
  if Length(LClientes) <> 1 then
    raise EClienteNaoEncontrado.CreateFmt('Cliente %d não encontrado.', [AId]);
  Result := LClientes[0];
end;

function TRepositorioClienteFireDAC.ListarTodos: TClientes;
begin
  Result := LerClientes(SQL_SELECAO_CLIENTES + 'ORDER BY C.ID', []);
end;

function TRepositorioClienteFireDAC.ResolverCidade(const ANomeCidade, AUf,
  ANomeEstado: string): Integer;
var
  LUf: string;
  LNomeCidade: string;
  LEstadoId: Integer;
begin
  LUf := UpperCase(Trim(AUf));
  LNomeCidade := Trim(ANomeCidade);
  LEstadoId := ObterId('SELECT ID FROM ESTADO WHERE UF = :UF', [LUf]);
  if LEstadoId = 0 then
  begin
    LEstadoId := ProximoValor('SEQ_ESTADO');
    FConexao.ExecSQL('INSERT INTO ESTADO (ID, NOME, UF) VALUES (:ID, :NOME, :UF)',
      [LEstadoId, Trim(ANomeEstado), LUf]);
  end;
  Result := ObterId('SELECT ID FROM CIDADE WHERE ESTADOID = :ESTADOID AND UPPER(NOME) = UPPER(:NOME)',
    [LEstadoId, LNomeCidade]);
  if Result = 0 then
  begin
    Result := ProximoValor('SEQ_CIDADE');
    FConexao.ExecSQL('INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (:ID, :NOME, :ESTADOID)',
      [Result, LNomeCidade, LEstadoId]);
  end;
end;

constructor TTransacaoFireDAC.Create(AConexao: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConexao) then
    raise EArgumentNilException.Create('A conexão FireDAC deve ser informada.');
  FConexao := AConexao;
end;

procedure TTransacaoFireDAC.Iniciar;
begin
  FConexao.StartTransaction;
end;

procedure TTransacaoFireDAC.Confirmar;
begin
  FConexao.Commit;
end;

procedure TTransacaoFireDAC.Reverter;
begin
  if FConexao.InTransaction then
    FConexao.Rollback;
end;

end.

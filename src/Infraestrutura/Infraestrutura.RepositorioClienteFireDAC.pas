unit Infraestrutura.RepositorioClienteFireDAC;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Dominio.FiltroRelatorioCliente,
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
    function LerClientesDaConsulta(AConsulta: TFDQuery): TClientes;
  public
    constructor Create(AConexao: TFDConnection);
    function Incluir(const ACliente: TCliente): Integer;
    procedure Alterar(const ACliente: TCliente);
    procedure Excluir(AId: Integer);
    function ObterPorId(AId: Integer): TCliente;
    function Pesquisar(const AFiltro: TFiltroCliente; const AOrdenacao: TOrdenacaoCliente;
      ALimite: Integer): TClientes;
    function ResolverCidade(const ANomeCidade, AUf, ANomeEstado: string): Integer;
    function ListarParaRelatorio(const AFiltro: TFiltroRelatorioCliente): TClientes;
    function ListarEstados: TEstados;
    function ListarCidades(AEstadoId: Integer): TCidades;
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
  System.Classes,
  System.Variants,
  FireDAC.DApt,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param;

const
  SQL_CAMPOS_CLIENTES =
    'C.ID, C.NOME, C.CPF_CNPJ, C.CEP, C.ENDERECO, C.NUMERO, C.COMPLEMENTO, C.BAIRRO, ' +
    'C.CIDADEID, C.DATANASCIMENTO, CI.NOME AS CIDADE, E.UF, E.NOME AS ESTADO ' +
    'FROM CLIENTE C ' +
    'LEFT JOIN CIDADE CI ON CI.ID = C.CIDADEID ' +
    'LEFT JOIN ESTADO E ON E.ID = CI.ESTADOID ';
  SQL_SELECAO_CLIENTES = 'SELECT ' + SQL_CAMPOS_CLIENTES;
  COLUNAS_ORDENACAO: array[TCampoOrdenacao] of string = ('C.ID', 'UPPER(C.NOME)', 'C.CPF_CNPJ',
    'C.CEP', 'UPPER(CI.NOME)', 'E.UF', 'UPPER(E.NOME)', 'C.DATANASCIMENTO');
  TAMANHO_UF = 2;
  TAMANHO_NOME_CLIENTE = 80;
  TAMANHO_NOME_CIDADE = 50;
  TAMANHO_NOME_ESTADO = 50;

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
begin
  LConsulta := TFDQuery.Create(nil);
  try
    LConsulta.Connection := FConexao;
    LConsulta.Open(ASql, AParametros);
    Result := LerClientesDaConsulta(LConsulta);
  finally
    LConsulta.Free;
  end;
end;

function TRepositorioClienteFireDAC.LerClientesDaConsulta(AConsulta: TFDQuery): TClientes;
var
  LCliente: TCliente;
begin
  Result := [];
  while not AConsulta.Eof do
  begin
    LCliente := Default(TCliente);
    LCliente.Id := AConsulta.FieldByName('ID').AsInteger;
    LCliente.Nome := AConsulta.FieldByName('NOME').AsString;
    LCliente.CpfCnpj := AConsulta.FieldByName('CPF_CNPJ').AsString;
    LCliente.Cep := Trim(AConsulta.FieldByName('CEP').AsString);
    LCliente.Endereco := AConsulta.FieldByName('ENDERECO').AsString;
    LCliente.Numero := AConsulta.FieldByName('NUMERO').AsString;
    LCliente.Complemento := AConsulta.FieldByName('COMPLEMENTO').AsString;
    LCliente.Bairro := AConsulta.FieldByName('BAIRRO').AsString;
    LCliente.CidadeId := AConsulta.FieldByName('CIDADEID').AsInteger;
    LCliente.DataNascimento := AConsulta.FieldByName('DATANASCIMENTO').AsDateTime;
    LCliente.Cidade := AConsulta.FieldByName('CIDADE').AsString;
    LCliente.Uf := Trim(AConsulta.FieldByName('UF').AsString);
    LCliente.Estado := AConsulta.FieldByName('ESTADO').AsString;
    Result := Result + [LCliente];
    AConsulta.Next;
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

function PredicadosDoTexto(const ATexto: string; ACampos: TCamposPesquisa;
  APredicados: TStrings): Boolean;
var
  LId: Integer;
  LDigitos: string;
begin
  if ACampos = [] then
    ACampos := [Low(TCampoPesquisa)..High(TCampoPesquisa)];
  LDigitos := SomenteDigitos(ATexto);
  if (cpId in ACampos) and TryStrToInt(ATexto, LId) then
    APredicados.Add('C.ID = :ID');
  if (cpNome in ACampos) and (Length(ATexto) <= TAMANHO_NOME_CLIENTE) then
    APredicados.Add('C.NOME CONTAINING :NOME');
  if (cpCpfCnpj in ACampos) and (LDigitos <> '') and (Length(LDigitos) <= TAMANHO_CNPJ) then
    APredicados.Add('C.CPF_CNPJ = :CPF_CNPJ');
  if (cpCep in ACampos) and (Length(LDigitos) = TAMANHO_CEP) then
    APredicados.Add('C.CEP = :CEP');
  if (cpCidade in ACampos) and (Length(ATexto) <= TAMANHO_NOME_CIDADE) then
    APredicados.Add('CI.NOME CONTAINING :CIDADE');
  if (cpEstado in ACampos) and (Length(ATexto) = TAMANHO_UF) then
    APredicados.Add('E.UF = :UF');
  if (cpEstado in ACampos) and (Length(ATexto) <= TAMANHO_NOME_ESTADO) then
    APredicados.Add('E.NOME CONTAINING :ESTADO');
  Result := APredicados.Count > 0;
end;

procedure DefinirParametroSeExistir(AConsulta: TFDQuery; const ANome: string; const AValor: Variant);
var
  LParametro: TFDParam;
begin
  LParametro := AConsulta.Params.FindParam(ANome);
  if Assigned(LParametro) then
    LParametro.Value := AValor;
end;

function TRepositorioClienteFireDAC.Pesquisar(const AFiltro: TFiltroCliente;
  const AOrdenacao: TOrdenacaoCliente; ALimite: Integer): TClientes;
const
  DIRECOES: array[Boolean] of string = ('ASC', 'DESC');
var
  LTexto: string;
  LData: TDate;
  LCondicoes: TStringList;
  LPredicados: TStringList;
  LSql: string;
  LConsulta: TFDQuery;
begin
  LTexto := Trim(AFiltro.Texto);
  LData := 0;
  LCondicoes := TStringList.Create;
  LPredicados := TStringList.Create;
  try
    if LTexto <> '' then
    begin
      if not PredicadosDoTexto(LTexto, AFiltro.Campos, LPredicados) then
        Exit(nil);
      LCondicoes.Add('(' + string.Join(' OR ', LPredicados.ToStringArray) + ')');
    end;
    if Trim(AFiltro.DataNascimento) <> '' then
    begin
      if not TentarLerData(AFiltro.DataNascimento, LData) then
        Exit(nil);
      LCondicoes.Add('C.DATANASCIMENTO = :DATANASCIMENTO');
    end;
    LSql := 'SELECT FIRST :LIMITE ' + SQL_CAMPOS_CLIENTES;
    if LCondicoes.Count > 0 then
      LSql := LSql + 'WHERE ' + string.Join(' AND ', LCondicoes.ToStringArray) + ' ';
    LSql := LSql + 'ORDER BY ' + COLUNAS_ORDENACAO[AOrdenacao.Campo] + ' ' +
      DIRECOES[AOrdenacao.Descendente] + ' NULLS LAST, C.ID ASC';
  finally
    LPredicados.Free;
    LCondicoes.Free;
  end;
  LConsulta := CriarConsulta(LSql);
  try
    LConsulta.ParamByName('LIMITE').AsInteger := ALimite;
    DefinirParametroSeExistir(LConsulta, 'ID', StrToIntDef(LTexto, 0));
    DefinirParametroSeExistir(LConsulta, 'NOME', LTexto);
    DefinirParametroSeExistir(LConsulta, 'CPF_CNPJ', SomenteDigitos(LTexto));
    DefinirParametroSeExistir(LConsulta, 'CEP', SomenteDigitos(LTexto));
    DefinirParametroSeExistir(LConsulta, 'CIDADE', LTexto);
    DefinirParametroSeExistir(LConsulta, 'UF', UpperCase(LTexto));
    DefinirParametroSeExistir(LConsulta, 'ESTADO', LTexto);
    if Assigned(LConsulta.Params.FindParam('DATANASCIMENTO')) then
      LConsulta.ParamByName('DATANASCIMENTO').AsDate := LData;
    LConsulta.Open;
    Result := LerClientesDaConsulta(LConsulta);
  finally
    LConsulta.Free;
  end;
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

function TRepositorioClienteFireDAC.ListarParaRelatorio(
  const AFiltro: TFiltroRelatorioCliente): TClientes;
var
  LSql: string;
  LConsulta: TFDQuery;
begin
  LSql := SQL_SELECAO_CLIENTES;
  case AFiltro.Modo of
    mrIntervalo:
      LSql := LSql + 'WHERE C.ID BETWEEN :IDINICIAL AND :IDFINAL ';
    mrCidadeEstado:
      if AFiltro.CidadeId > 0 then
        LSql := LSql + 'WHERE C.CIDADEID = :CIDADEID '
      else
        LSql := LSql + 'WHERE CI.ESTADOID = :ESTADOID ';
  end;
  LSql := LSql + 'ORDER BY UPPER(C.NOME), C.ID';
  LConsulta := CriarConsulta(LSql);
  try
    case AFiltro.Modo of
      mrIntervalo:
        begin
          LConsulta.ParamByName('IDINICIAL').AsInteger := AFiltro.IdInicial;
          LConsulta.ParamByName('IDFINAL').AsInteger := AFiltro.IdFinal;
        end;
      mrCidadeEstado:
        if AFiltro.CidadeId > 0 then
          LConsulta.ParamByName('CIDADEID').AsInteger := AFiltro.CidadeId
        else
          LConsulta.ParamByName('ESTADOID').AsInteger := AFiltro.EstadoId;
    end;
    LConsulta.Open;
    Result := LerClientesDaConsulta(LConsulta);
  finally
    LConsulta.Free;
  end;
end;

function TRepositorioClienteFireDAC.ListarEstados: TEstados;
var
  LConsulta: TFDQuery;
  LEstado: TEstado;
begin
  Result := [];
  LConsulta := CriarConsulta('SELECT ID, NOME, UF FROM ESTADO ORDER BY UPPER(NOME)');
  try
    LConsulta.Open;
    while not LConsulta.Eof do
    begin
      LEstado := Default(TEstado);
      LEstado.Id := LConsulta.FieldByName('ID').AsInteger;
      LEstado.Nome := LConsulta.FieldByName('NOME').AsString;
      LEstado.Uf := Trim(LConsulta.FieldByName('UF').AsString);
      Result := Result + [LEstado];
      LConsulta.Next;
    end;
  finally
    LConsulta.Free;
  end;
end;

function TRepositorioClienteFireDAC.ListarCidades(AEstadoId: Integer): TCidades;
var
  LConsulta: TFDQuery;
  LCidade: TCidade;
begin
  Result := [];
  LConsulta := CriarConsulta(
    'SELECT ID, NOME FROM CIDADE WHERE ESTADOID = :ESTADOID ORDER BY UPPER(NOME)');
  try
    LConsulta.ParamByName('ESTADOID').AsInteger := AEstadoId;
    LConsulta.Open;
    while not LConsulta.Eof do
    begin
      LCidade := Default(TCidade);
      LCidade.Id := LConsulta.FieldByName('ID').AsInteger;
      LCidade.Nome := LConsulta.FieldByName('NOME').AsString;
      Result := Result + [LCidade];
      LConsulta.Next;
    end;
  finally
    LConsulta.Free;
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

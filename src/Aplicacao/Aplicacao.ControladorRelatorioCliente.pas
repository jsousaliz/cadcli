unit Aplicacao.ControladorRelatorioCliente;

interface

uses
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.GeradorRelatorioCliente,
  Aplicacao.RepositorioCliente;

type
  IVisaoRelatorioCliente = interface
    ['{F1A7C5D2-3E84-4B90-8C61-D0A9F2B47E53}']
    procedure ExibirModo(AModo: TModoRelatorio);
    procedure HabilitarIntervalo(AHabilitar: Boolean);
    procedure HabilitarCidadeEstado(AHabilitar: Boolean);
    procedure ExibirEstados(const AEstados: TEstados);
    procedure ExibirCidades(const ACidades: TCidades; AIndiceSelecionado: Integer);
    function ObterEntrada: TEntradaFiltroRelatorio;
    procedure SinalizarCarregamento(AAtivo: Boolean);
    procedure FocarCampo(ACampo: TCampoFiltroRelatorio);
    procedure ExibirAviso(const AMensagem: string);
    procedure ExibirErro(const AMensagem: string);
    procedure Fechar;
  end;

  TControladorRelatorioCliente = class
  private
    FVisao: IVisaoRelatorioCliente;
    FRepositorio: IRepositorioCliente;
    FGerador: IGeradorRelatorioCliente;
    FRelogio: IRelogio;
    FEstados: TEstados;
    FCidades: TCidades;
    function Uf(AEstadoId: Integer): string;
    function NomeDaCidade(ACidadeId: Integer): string;
    function Descrever(const AFiltro: TFiltroRelatorioCliente): string;
    function Consultar(const AFiltro: TFiltroRelatorioCliente; out AClientes: TClientes): Boolean;
    function Gerar(const AFiltro: TFiltroRelatorioCliente; const AClientes: TClientes): Boolean;
  public
    constructor Create(const AVisao: IVisaoRelatorioCliente;
      const ARepositorio: IRepositorioCliente; const AGerador: IGeradorRelatorioCliente;
      const ARelogio: IRelogio);
    procedure Iniciar;
    procedure SelecionarModo(AModo: TModoRelatorio);
    procedure SelecionarEstado(AEstadoId: Integer);
    procedure Visualizar;
  end;

const
  CIDADE_TODAS = 'Todas as cidades';
  MENSAGEM_SEM_RESULTADO = 'Nenhum cliente encontrado para o filtro informado';
  MENSAGEM_FALHA_LOCALIDADES = 'NÃ£o foi possÃ­vel carregar os estados e cidades.';
  MENSAGEM_FALHA_CONSULTA = 'NÃ£o foi possÃ­vel consultar os clientes do relatÃ³rio.';
  MENSAGEM_FALHA_GERACAO = 'NÃ£o foi possÃ­vel gerar o relatÃ³rio de clientes.';
  DESCRICAO_TODOS = 'Filtro: Todos';
  DESCRICAO_INTERVALO = 'Filtro: ID Inicial %d e ID Final %d';
  DESCRICAO_ESTADO = 'Filtro: Estado %s';
  DESCRICAO_CIDADE = 'Filtro: Cidade %s/%s';

implementation

constructor TControladorRelatorioCliente.Create(const AVisao: IVisaoRelatorioCliente;
  const ARepositorio: IRepositorioCliente; const AGerador: IGeradorRelatorioCliente;
  const ARelogio: IRelogio);
begin
  inherited Create;
  if not Assigned(AVisao) then
    raise EArgumentNilException.Create('A visÃ£o do relatÃ³rio deve ser informada.');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('O repositÃ³rio de clientes deve ser informado.');
  if not Assigned(AGerador) then
    raise EArgumentNilException.Create('O gerador do relatÃ³rio deve ser informado.');
  if not Assigned(ARelogio) then
    raise EArgumentNilException.Create('O relÃ³gio deve ser informado.');
  FVisao := AVisao;
  FRepositorio := ARepositorio;
  FGerador := AGerador;
  FRelogio := ARelogio;
end;

procedure TControladorRelatorioCliente.Iniciar;
begin
  FVisao.ExibirModo(mrTodos);
  SelecionarModo(mrTodos);
  FEstados := [];
  try
    FEstados := FRepositorio.ListarEstados;
  except
    on Exception do
      FVisao.ExibirErro(MENSAGEM_FALHA_LOCALIDADES);
  end;
  FVisao.ExibirEstados(FEstados);
  SelecionarEstado(0);
end;

procedure TControladorRelatorioCliente.SelecionarModo(AModo: TModoRelatorio);
begin
  FVisao.HabilitarIntervalo(AModo = mrIntervalo);
  FVisao.HabilitarCidadeEstado(AModo = mrCidadeEstado);
end;

procedure TControladorRelatorioCliente.SelecionarEstado(AEstadoId: Integer);
var
  LTodas: TCidade;
begin
  FCidades := [];
  if AEstadoId > 0 then
    try
      FCidades := FRepositorio.ListarCidades(AEstadoId);
    except
      on Exception do
      begin
        FCidades := [];
        FVisao.ExibirErro(MENSAGEM_FALHA_LOCALIDADES);
      end;
    end;
  LTodas := Default(TCidade);
  LTodas.Nome := CIDADE_TODAS;
  FVisao.ExibirCidades([LTodas] + FCidades, 0);
end;

function TControladorRelatorioCliente.Uf(AEstadoId: Integer): string;
var
  LEstado: TEstado;
begin
  for LEstado in FEstados do
    if LEstado.Id = AEstadoId then
      Exit(LEstado.Uf);
  Result := '';
end;

function TControladorRelatorioCliente.NomeDaCidade(ACidadeId: Integer): string;
var
  LCidade: TCidade;
begin
  for LCidade in FCidades do
    if LCidade.Id = ACidadeId then
      Exit(LCidade.Nome);
  Result := '';
end;

function TControladorRelatorioCliente.Descrever(const AFiltro: TFiltroRelatorioCliente): string;
begin
  case AFiltro.Modo of
    mrIntervalo:
      Result := Format(DESCRICAO_INTERVALO, [AFiltro.IdInicial, AFiltro.IdFinal]);
    mrCidadeEstado:
      if AFiltro.CidadeId > 0 then
        Result := Format(DESCRICAO_CIDADE, [NomeDaCidade(AFiltro.CidadeId), Uf(AFiltro.EstadoId)])
      else
        Result := Format(DESCRICAO_ESTADO, [Uf(AFiltro.EstadoId)]);
  else
    Result := DESCRICAO_TODOS;
  end;
end;

function TControladorRelatorioCliente.Consultar(const AFiltro: TFiltroRelatorioCliente;
  out AClientes: TClientes): Boolean;
begin
  AClientes := [];
  try
    AClientes := FRepositorio.ListarParaRelatorio(AFiltro);
    Result := True;
  except
    on Exception do
    begin
      FVisao.ExibirErro(MENSAGEM_FALHA_CONSULTA);
      Result := False;
    end;
  end;
end;

function TControladorRelatorioCliente.Gerar(const AFiltro: TFiltroRelatorioCliente;
  const AClientes: TClientes): Boolean;
var
  LDados: TDadosRelatorioCliente;
begin
  LDados := Default(TDadosRelatorioCliente);
  LDados.Clientes := AClientes;
  LDados.DescricaoFiltro := Descrever(AFiltro);
  LDados.Emissao := FRelogio.Agora;
  try
    FGerador.Visualizar(LDados);
    Result := True;
  except
    on Exception do
    begin
      FVisao.ExibirErro(MENSAGEM_FALHA_GERACAO);
      Result := False;
    end;
  end;
end;

procedure TControladorRelatorioCliente.Visualizar;
var
  LResultado: TResultadoFiltroRelatorio;
  LClientes: TClientes;
begin
  LResultado := TValidacaoFiltroRelatorio.Validar(FVisao.ObterEntrada);
  if not LResultado.Valido then
  begin
    FVisao.FocarCampo(LResultado.Campo);
    FVisao.ExibirAviso(LResultado.Mensagem);
    Exit;
  end;
  FVisao.SinalizarCarregamento(True);
  try
    if not Consultar(LResultado.Filtro, LClientes) then
      Exit;
    if Length(LClientes) = 0 then
    begin
      FVisao.ExibirAviso(MENSAGEM_SEM_RESULTADO);
      Exit;
    end;
    Gerar(LResultado.Filtro, LClientes);
  finally
    FVisao.SinalizarCarregamento(False);
  end;
end;

end.

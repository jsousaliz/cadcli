unit Suporte.FakesRelatorioCliente;

interface

uses
  System.Classes,
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.ControladorRelatorioCliente,
  Aplicacao.GeradorRelatorioCliente;

type
  TVisaoRelatorioClienteFake = class(TInterfacedObject, IVisaoRelatorioCliente)
  private
    FErros: TStringList;
    FAvisos: TStringList;
    FRegistro: TStringList;
  public
    Entrada: TEntradaFiltroRelatorio;
    ModosExibidos: TArray<TModoRelatorio>;
    IntervaloHabilitado: Boolean;
    CidadeEstadoHabilitado: Boolean;
    HabilitacoesIntervalo: Integer;
    HabilitacoesCidadeEstado: Integer;
    EstadosExibidos: TEstados;
    ExibicoesDeEstados: Integer;
    CidadesExibidas: TCidades;
    ExibicoesDeCidades: Integer;
    CidadeSelecionada: Integer;
    CamposFocados: TArray<TCampoFiltroRelatorio>;
    Carregando: Boolean;
    Fechamentos: Integer;
    constructor Create;
    destructor Destroy; override;
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
    function NomesDosEstados: string;
    function NomesDasCidades: string;
    function UltimoCampoFocado: TCampoFiltroRelatorio;
    property Erros: TStringList read FErros;
    property Avisos: TStringList read FAvisos;
    property Registro: TStringList read FRegistro;
  end;

  TGeradorRelatorioClienteFake = class(TInterfacedObject, IGeradorRelatorioCliente)
  private
    FRegistro: TStrings;
  public
    Chamadas: Integer;
    Dados: TDadosRelatorioCliente;
    Falhar: Boolean;
    MensagemFalha: string;
    AoVisualizar: TProc;
    constructor Create(ARegistro: TStrings = nil);
    procedure Visualizar(const ADados: TDadosRelatorioCliente);
    function IdsRecebidos: string;
  end;

function EntradaDoFiltro(AModo: TModoRelatorio; const AIdInicial: string = '';
  const AIdFinal: string = ''; AEstadoId: Integer = 0; ACidadeId: Integer = 0):
  TEntradaFiltroRelatorio;
function EstadosDaFixture: TEstados;
function CidadesDeSaoPaulo: TCidades;
function IdDoEstado(const AEstados: TEstados; const AUf: string): Integer;
function IdsDosClientes(const AClientes: TClientes): string;

implementation

function EntradaDoFiltro(AModo: TModoRelatorio; const AIdInicial: string; const AIdFinal: string;
  AEstadoId: Integer; ACidadeId: Integer): TEntradaFiltroRelatorio;
begin
  Result := Default(TEntradaFiltroRelatorio);
  Result.Modo := AModo;
  Result.IdInicial := AIdInicial;
  Result.IdFinal := AIdFinal;
  Result.EstadoId := AEstadoId;
  Result.CidadeId := ACidadeId;
end;

function NovoEstado(AId: Integer; const ANome, AUf: string): TEstado;
begin
  Result := Default(TEstado);
  Result.Id := AId;
  Result.Nome := ANome;
  Result.Uf := AUf;
end;

function NovaCidade(AId: Integer; const ANome: string): TCidade;
begin
  Result := Default(TCidade);
  Result.Id := AId;
  Result.Nome := ANome;
end;

function EstadosDaFixture: TEstados;
begin
  Result := [
    NovoEstado(1, 'Bahia', 'BA'),
    NovoEstado(2, 'Minas Gerais', 'MG'),
    NovoEstado(3, 'Rio de Janeiro', 'RJ'),
    NovoEstado(4, 'São Paulo', 'SP')];
end;

function CidadesDeSaoPaulo: TCidades;
begin
  Result := [NovaCidade(11, 'Campinas'), NovaCidade(12, 'Santos'), NovaCidade(13, 'São Paulo')];
end;

function IdDoEstado(const AEstados: TEstados; const AUf: string): Integer;
var
  LEstado: TEstado;
begin
  for LEstado in AEstados do
    if LEstado.Uf = AUf then
      Exit(LEstado.Id);
  Result := 0;
end;

function IdsDosClientes(const AClientes: TClientes): string;
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

constructor TVisaoRelatorioClienteFake.Create;
begin
  inherited Create;
  FErros := TStringList.Create;
  FAvisos := TStringList.Create;
  FRegistro := TStringList.Create;
end;

destructor TVisaoRelatorioClienteFake.Destroy;
begin
  FRegistro.Free;
  FAvisos.Free;
  FErros.Free;
  inherited;
end;

procedure TVisaoRelatorioClienteFake.ExibirModo(AModo: TModoRelatorio);
begin
  FRegistro.Add('ExibirModo:' + IntToStr(Ord(AModo)));
  ModosExibidos := ModosExibidos + [AModo];
end;

procedure TVisaoRelatorioClienteFake.HabilitarIntervalo(AHabilitar: Boolean);
begin
  FRegistro.Add('HabilitarIntervalo:' + BoolToStr(AHabilitar, True));
  Inc(HabilitacoesIntervalo);
  IntervaloHabilitado := AHabilitar;
end;

procedure TVisaoRelatorioClienteFake.HabilitarCidadeEstado(AHabilitar: Boolean);
begin
  FRegistro.Add('HabilitarCidadeEstado:' + BoolToStr(AHabilitar, True));
  Inc(HabilitacoesCidadeEstado);
  CidadeEstadoHabilitado := AHabilitar;
end;

procedure TVisaoRelatorioClienteFake.ExibirEstados(const AEstados: TEstados);
begin
  FRegistro.Add('ExibirEstados');
  Inc(ExibicoesDeEstados);
  EstadosExibidos := Copy(AEstados);
end;

procedure TVisaoRelatorioClienteFake.ExibirCidades(const ACidades: TCidades;
  AIndiceSelecionado: Integer);
begin
  FRegistro.Add('ExibirCidades');
  Inc(ExibicoesDeCidades);
  CidadesExibidas := Copy(ACidades);
  CidadeSelecionada := AIndiceSelecionado;
end;

function TVisaoRelatorioClienteFake.ObterEntrada: TEntradaFiltroRelatorio;
begin
  FRegistro.Add('ObterEntrada');
  Result := Entrada;
end;

procedure TVisaoRelatorioClienteFake.SinalizarCarregamento(AAtivo: Boolean);
begin
  FRegistro.Add('Carregamento:' + BoolToStr(AAtivo, True));
  Carregando := AAtivo;
end;

procedure TVisaoRelatorioClienteFake.FocarCampo(ACampo: TCampoFiltroRelatorio);
begin
  FRegistro.Add('FocarCampo:' + IntToStr(Ord(ACampo)));
  CamposFocados := CamposFocados + [ACampo];
end;

procedure TVisaoRelatorioClienteFake.ExibirAviso(const AMensagem: string);
begin
  FRegistro.Add('Aviso');
  FAvisos.Add(AMensagem);
end;

procedure TVisaoRelatorioClienteFake.ExibirErro(const AMensagem: string);
begin
  FRegistro.Add('Erro');
  FErros.Add(AMensagem);
end;

procedure TVisaoRelatorioClienteFake.Fechar;
begin
  FRegistro.Add('Fechar');
  Inc(Fechamentos);
end;

function TVisaoRelatorioClienteFake.NomesDosEstados: string;
var
  LEstado: TEstado;
begin
  Result := '';
  for LEstado in EstadosExibidos do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LEstado.Nome;
  end;
end;

function TVisaoRelatorioClienteFake.NomesDasCidades: string;
var
  LCidade: TCidade;
begin
  Result := '';
  for LCidade in CidadesExibidas do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LCidade.Nome;
  end;
end;

function TVisaoRelatorioClienteFake.UltimoCampoFocado: TCampoFiltroRelatorio;
begin
  Result := CamposFocados[High(CamposFocados)];
end;

constructor TGeradorRelatorioClienteFake.Create(ARegistro: TStrings);
begin
  inherited Create;
  FRegistro := ARegistro;
  MensagemFalha := 'falha simulada do gerador';
end;

procedure TGeradorRelatorioClienteFake.Visualizar(const ADados: TDadosRelatorioCliente);
begin
  Inc(Chamadas);
  if Assigned(FRegistro) then
    FRegistro.Add('Gerar');
  if Assigned(AoVisualizar) then
    AoVisualizar;
  if Falhar then
    raise Exception.Create(MensagemFalha);
  Dados := ADados;
end;

function TGeradorRelatorioClienteFake.IdsRecebidos: string;
begin
  Result := IdsDosClientes(Dados.Clientes);
end;

end.

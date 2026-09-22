unit Visao.FormFiltroRelatorioCliente;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  cxGraphics,
  cxControls,
  cxLookAndFeels,
  cxLookAndFeelPainters,
  cxContainer,
  cxEdit,
  cxGroupBox,
  cxRadioGroup,
  cxLabel,
  cxTextEdit,
  cxMaskEdit,
  cxDropDownEdit,
  cxButtons,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.ControladorRelatorioCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.GeradorRelatorioCliente,
  Aplicacao.RepositorioCliente,
  Visao.ApresentadorErro;

type
  TFormFiltroRelatorioCliente = class(TForm, IVisaoRelatorioCliente)
    GrupoModos: TcxRadioGroup;
    RotuloIdInicial: TcxLabel;
    EditorIdInicial: TcxTextEdit;
    RotuloIdFinal: TcxLabel;
    EditorIdFinal: TcxTextEdit;
    RotuloEstado: TcxLabel;
    ComboEstado: TcxComboBox;
    RotuloCidade: TcxLabel;
    ComboCidade: TcxComboBox;
    BotaoVisualizar: TcxButton;
    BotaoFechar: TcxButton;
    procedure FormShow(Sender: TObject);
    procedure BotaoVisualizarClick(Sender: TObject);
    procedure ModoAlterado(Sender: TObject);
    procedure EstadoAlterado(Sender: TObject);
  private
    FControlador: TControladorRelatorioCliente;
    FApresentadorErro: IApresentadorErro;
    FIdsEstados: TArray<Integer>;
    FIdsCidades: TArray<Integer>;
    FAtualizando: Boolean;
    function IdSelecionado(const AIds: TArray<Integer>; AIndice: Integer): Integer;
  public
    destructor Destroy; override;
    procedure Conectar(const ARepositorio: IRepositorioCliente;
      const AGerador: IGeradorRelatorioCliente; const ARelogio: IRelogio;
      const AApresentadorErro: IApresentadorErro);
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

implementation

uses
  System.SysUtils,
  System.UITypes;

{$R *.dfm}

destructor TFormFiltroRelatorioCliente.Destroy;
begin
  FControlador.Free;
  inherited;
end;

procedure TFormFiltroRelatorioCliente.Conectar(const ARepositorio: IRepositorioCliente;
  const AGerador: IGeradorRelatorioCliente; const ARelogio: IRelogio;
  const AApresentadorErro: IApresentadorErro);
begin
  FApresentadorErro := AApresentadorErro;
  FControlador := TControladorRelatorioCliente.Create(Self, ARepositorio, AGerador, ARelogio);
end;

procedure TFormFiltroRelatorioCliente.FormShow(Sender: TObject);
begin
  FControlador.Iniciar;
end;

procedure TFormFiltroRelatorioCliente.ModoAlterado(Sender: TObject);
begin
  if FAtualizando then
    Exit;
  FControlador.SelecionarModo(TModoRelatorio(GrupoModos.ItemIndex));
end;

procedure TFormFiltroRelatorioCliente.EstadoAlterado(Sender: TObject);
begin
  if FAtualizando then
    Exit;
  FControlador.SelecionarEstado(IdSelecionado(FIdsEstados, ComboEstado.ItemIndex));
end;

procedure TFormFiltroRelatorioCliente.BotaoVisualizarClick(Sender: TObject);
begin
  FControlador.Visualizar;
end;

function TFormFiltroRelatorioCliente.IdSelecionado(const AIds: TArray<Integer>;
  AIndice: Integer): Integer;
begin
  if (AIndice < 0) or (AIndice > High(AIds)) then
    Exit(0);
  Result := AIds[AIndice];
end;

procedure TFormFiltroRelatorioCliente.ExibirModo(AModo: TModoRelatorio);
begin
  FAtualizando := True;
  try
    GrupoModos.ItemIndex := Ord(AModo);
  finally
    FAtualizando := False;
  end;
end;

procedure TFormFiltroRelatorioCliente.HabilitarIntervalo(AHabilitar: Boolean);
begin
  EditorIdInicial.Enabled := AHabilitar;
  EditorIdFinal.Enabled := AHabilitar;
end;

procedure TFormFiltroRelatorioCliente.HabilitarCidadeEstado(AHabilitar: Boolean);
begin
  ComboEstado.Enabled := AHabilitar;
  ComboCidade.Enabled := AHabilitar;
end;

procedure TFormFiltroRelatorioCliente.ExibirEstados(const AEstados: TEstados);
var
  LEstado: TEstado;
begin
  FAtualizando := True;
  try
    FIdsEstados := [];
    ComboEstado.Properties.Items.BeginUpdate;
    try
      ComboEstado.Properties.Items.Clear;
      for LEstado in AEstados do
      begin
        ComboEstado.Properties.Items.Add(LEstado.Nome);
        FIdsEstados := FIdsEstados + [LEstado.Id];
      end;
    finally
      ComboEstado.Properties.Items.EndUpdate;
    end;
    ComboEstado.ItemIndex := -1;
    ComboEstado.Text := '';
  finally
    FAtualizando := False;
  end;
end;

procedure TFormFiltroRelatorioCliente.ExibirCidades(const ACidades: TCidades;
  AIndiceSelecionado: Integer);
var
  LCidade: TCidade;
begin
  FAtualizando := True;
  try
    FIdsCidades := [];
    ComboCidade.Properties.Items.BeginUpdate;
    try
      ComboCidade.Properties.Items.Clear;
      for LCidade in ACidades do
      begin
        ComboCidade.Properties.Items.Add(LCidade.Nome);
        FIdsCidades := FIdsCidades + [LCidade.Id];
      end;
    finally
      ComboCidade.Properties.Items.EndUpdate;
    end;
    ComboCidade.ItemIndex := AIndiceSelecionado;
  finally
    FAtualizando := False;
  end;
end;

function TFormFiltroRelatorioCliente.ObterEntrada: TEntradaFiltroRelatorio;
begin
  Result := Default(TEntradaFiltroRelatorio);
  Result.Modo := TModoRelatorio(GrupoModos.ItemIndex);
  Result.IdInicial := EditorIdInicial.Text;
  Result.IdFinal := EditorIdFinal.Text;
  Result.EstadoId := IdSelecionado(FIdsEstados, ComboEstado.ItemIndex);
  Result.CidadeId := IdSelecionado(FIdsCidades, ComboCidade.ItemIndex);
end;

procedure TFormFiltroRelatorioCliente.SinalizarCarregamento(AAtivo: Boolean);
begin
  BotaoVisualizar.Enabled := not AAtivo;
  if AAtivo then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

procedure TFormFiltroRelatorioCliente.FocarCampo(ACampo: TCampoFiltroRelatorio);
begin
  case ACampo of
    cfIdInicial:
      ActiveControl := EditorIdInicial;
    cfIdFinal:
      ActiveControl := EditorIdFinal;
    cfEstado:
      ActiveControl := ComboEstado;
  end;
end;

procedure TFormFiltroRelatorioCliente.ExibirAviso(const AMensagem: string);
begin
  FApresentadorErro.ApresentarErro(AMensagem);
end;

procedure TFormFiltroRelatorioCliente.ExibirErro(const AMensagem: string);
begin
  FApresentadorErro.ApresentarErro(AMensagem);
end;

procedure TFormFiltroRelatorioCliente.Fechar;
begin
  Close;
end;

end.

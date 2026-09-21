unit Visao.FormPesquisaCliente;

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
  cxCustomListBox,
  cxMCListBox,
  cxGroupBox,
  cxLabel,
  cxTextEdit,
  cxMaskEdit,
  cxDropDownEdit,
  cxCalendar,
  cxButtons,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Aplicacao.Confirmacao,
  Aplicacao.ControladorPesquisaCliente,
  Aplicacao.NavegadorClientes,
  Aplicacao.RepositorioCliente,
  Aplicacao.Transacao,
  Visao.ApresentadorErro, Vcl.ComCtrls, dxCore, cxDateUtils, Vcl.Menus,
  Vcl.StdCtrls;

type
  TFormPesquisaCliente = class(TForm, IVisaoPesquisaCliente)
    PainelFiltros: TcxGroupBox;
    RotuloId: TcxLabel;
    EditorId: TcxTextEdit;
    RotuloNome: TcxLabel;
    EditorNome: TcxTextEdit;
    RotuloCpfCnpj: TcxLabel;
    EditorCpfCnpj: TcxTextEdit;
    RotuloCep: TcxLabel;
    EditorCep: TcxTextEdit;
    RotuloCidade: TcxLabel;
    EditorCidade: TcxTextEdit;
    RotuloEstado: TcxLabel;
    EditorEstado: TcxTextEdit;
    RotuloDataNascimento: TcxLabel;
    EditorDataNascimento: TcxDateEdit;
    RotuloBuscaGeral: TcxLabel;
    EditorBuscaGeral: TcxTextEdit;
    BotaoPesquisar: TcxButton;
    ListaClientes: TcxMCListBox;
    RotuloSemResultado: TcxLabel;
    BarraAcoes: TcxGroupBox;
    BotaoNovo: TcxButton;
    BotaoEditar: TcxButton;
    BotaoExcluir: TcxButton;
    procedure FormShow(Sender: TObject);
    procedure BotaoPesquisarClick(Sender: TObject);
    procedure BotaoNovoClick(Sender: TObject);
    procedure BotaoEditarClick(Sender: TObject);
    procedure BotaoExcluirClick(Sender: TObject);
    procedure ListaClientesDblClick(Sender: TObject);
  private
    FControlador: TControladorPesquisaCliente;
    FApresentadorErro: IApresentadorErro;
    FIdsExibidos: TArray<Integer>;
    function MontarFiltro: TFiltroCliente;
    function Linha(const ACliente: TCliente): string;
  public
    destructor Destroy; override;
    procedure Conectar(const ARepositorio: IRepositorioCliente; const ATransacao: ITransacao;
      const ANavegador: INavegadorClientes; const AConfirmacao: IConfirmacao;
      const AApresentadorErro: IApresentadorErro);
    procedure SinalizarCarregamento(AAtivo: Boolean);
    procedure ExibirClientes(const AClientes: TClientes);
    procedure ExibirSemResultado(const AMensagem: string);
    procedure HabilitarEdicaoEExclusao(AHabilitar: Boolean);
    function IdSelecionado: Integer;
    procedure ExibirErro(const AMensagem: string);
    procedure ExibirAviso(const AMensagem: string);
  end;

implementation

uses
  System.SysUtils,
  System.UITypes;

{$R *.dfm}

destructor TFormPesquisaCliente.Destroy;
begin
  FControlador.Free;
  inherited;
end;

procedure TFormPesquisaCliente.Conectar(const ARepositorio: IRepositorioCliente;
  const ATransacao: ITransacao; const ANavegador: INavegadorClientes;
  const AConfirmacao: IConfirmacao; const AApresentadorErro: IApresentadorErro);
begin
  FApresentadorErro := AApresentadorErro;
  FControlador := TControladorPesquisaCliente.Create(Self, ARepositorio, ATransacao, ANavegador,
    AConfirmacao);
end;

function TFormPesquisaCliente.MontarFiltro: TFiltroCliente;
begin
  Result.Id := EditorId.Text;
  Result.Nome := EditorNome.Text;
  Result.CpfCnpj := EditorCpfCnpj.Text;
  Result.Cep := EditorCep.Text;
  Result.Cidade := EditorCidade.Text;
  Result.Estado := EditorEstado.Text;
  if EditorDataNascimento.Date = NullDate then
    Result.DataNascimento := ''
  else
    Result.DataNascimento := FormatarData(EditorDataNascimento.Date);
  Result.BuscaGeral := EditorBuscaGeral.Text;
end;

procedure TFormPesquisaCliente.FormShow(Sender: TObject);
begin
  FControlador.Abrir;
end;

procedure TFormPesquisaCliente.BotaoPesquisarClick(Sender: TObject);
begin
  FControlador.Pesquisar(MontarFiltro);
end;

procedure TFormPesquisaCliente.BotaoNovoClick(Sender: TObject);
begin
  FControlador.Novo;
end;

procedure TFormPesquisaCliente.BotaoEditarClick(Sender: TObject);
begin
  FControlador.Editar;
end;

procedure TFormPesquisaCliente.BotaoExcluirClick(Sender: TObject);
begin
  FControlador.Excluir;
end;

procedure TFormPesquisaCliente.ListaClientesDblClick(Sender: TObject);
begin
  FControlador.Editar;
end;

procedure TFormPesquisaCliente.SinalizarCarregamento(AAtivo: Boolean);
begin
  ListaClientes.Enabled := not AAtivo;
  if AAtivo then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

function TFormPesquisaCliente.Linha(const ACliente: TCliente): string;
var
  LValores: TArray<string>;
  I: Integer;
begin
  LValores := [IntToStr(ACliente.Id), ACliente.Nome, FormatarCpfCnpj(ACliente.CpfCnpj),
    FormatarCep(ACliente.Cep), ACliente.Cidade, ACliente.Uf, ACliente.Estado,
    FormatarData(ACliente.DataNascimento)];
  for I := 0 to High(LValores) do
    LValores[I] := LValores[I].Replace(ListaClientes.Delimiter, ' ');
  Result := string.Join(ListaClientes.Delimiter, LValores);
end;

procedure TFormPesquisaCliente.ExibirClientes(const AClientes: TClientes);
var
  LCliente: TCliente;
begin
  RotuloSemResultado.Visible := False;
  FIdsExibidos := [];
  ListaClientes.Items.BeginUpdate;
  try
    ListaClientes.Items.Clear;
    for LCliente in AClientes do
    begin
      ListaClientes.Items.Add(Linha(LCliente));
      FIdsExibidos := FIdsExibidos + [LCliente.Id];
    end;
  finally
    ListaClientes.Items.EndUpdate;
  end;
  if Length(AClientes) > 0 then
    ListaClientes.ItemIndex := 0;
end;

procedure TFormPesquisaCliente.ExibirSemResultado(const AMensagem: string);
begin
  RotuloSemResultado.Caption := AMensagem;
  RotuloSemResultado.Visible := True;
  RotuloSemResultado.BringToFront;
end;

procedure TFormPesquisaCliente.HabilitarEdicaoEExclusao(AHabilitar: Boolean);
begin
  BotaoEditar.Enabled := AHabilitar;
  BotaoExcluir.Enabled := AHabilitar;
end;

function TFormPesquisaCliente.IdSelecionado: Integer;
var
  LIndice: Integer;
begin
  LIndice := ListaClientes.ItemIndex;
  if (LIndice < 0) or (LIndice > High(FIdsExibidos)) then
    Exit(0);
  Result := FIdsExibidos[LIndice];
end;

procedure TFormPesquisaCliente.ExibirErro(const AMensagem: string);
begin
  FApresentadorErro.ApresentarErro(AMensagem);
end;

procedure TFormPesquisaCliente.ExibirAviso(const AMensagem: string);
begin
  FApresentadorErro.ApresentarErro(AMensagem);
end;

end.

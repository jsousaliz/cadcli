unit Visao.FormCadastroCliente;

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
  cxLabel,
  cxTextEdit,
  cxMaskEdit,
  cxDropDownEdit,
  cxCalendar,
  cxButtons,
  Aplicacao.Confirmacao,
  Aplicacao.ControladorCadastroCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.RepositorioCliente,
  Aplicacao.ServicoViaCep,
  Aplicacao.Transacao,
  Visao.ApresentadorErro, Vcl.ComCtrls, dxCore, cxDateUtils, Vcl.Menus,
  Vcl.StdCtrls;

type
  TFormCadastroCliente = class(TForm, IVisaoCadastroCliente)
    PainelCampos: TcxGroupBox;
    RotuloNome: TcxLabel;
    EditorNome: TcxTextEdit;
    RotuloCpfCnpj: TcxLabel;
    EditorCpfCnpj: TcxTextEdit;
    RotuloDataNascimento: TcxLabel;
    EditorDataNascimento: TcxDateEdit;
    RotuloCep: TcxLabel;
    EditorCep: TcxTextEdit;
    RotuloConsultandoCep: TcxLabel;
    RotuloEndereco: TcxLabel;
    EditorEndereco: TcxTextEdit;
    RotuloNumero: TcxLabel;
    EditorNumero: TcxTextEdit;
    RotuloComplemento: TcxLabel;
    EditorComplemento: TcxTextEdit;
    RotuloBairro: TcxLabel;
    EditorBairro: TcxTextEdit;
    RotuloCidade: TcxLabel;
    EditorCidade: TcxTextEdit;
    RotuloUf: TcxLabel;
    EditorUf: TcxComboBox;
    RotuloEstado: TcxLabel;
    EditorEstado: TcxTextEdit;
    BarraBotoes: TcxGroupBox;
    BotaoSalvar: TcxButton;
    BotaoCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure EditorCepEnter(Sender: TObject);
    procedure EditorCepExit(Sender: TObject);
    procedure EditorUfPropertiesChange(Sender: TObject);
    procedure BotaoSalvarClick(Sender: TObject);
    procedure BotaoCancelarClick(Sender: TObject);
  private
    FControlador: TControladorCadastroCliente;
    FApresentadorErro: IApresentadorErro;
    FId: Integer;
    FPreenchendo: Boolean;
    function Editor(ACampo: TCampoCliente): TcxCustomEdit;
    procedure SelecionarUf(const AUf: string);
    function GetSalvo: Boolean;
  public
    destructor Destroy; override;
    procedure Conectar(const ARepositorio: IRepositorioCliente; const ATransacao: ITransacao;
      const AServicoViaCep: IServicoViaCep; const ARelogio: IRelogio;
      const AConfirmacao: IConfirmacao; const AApresentadorErro: IApresentadorErro);
    function Abrir(AModo: TModoCadastro; AId: Integer = 0): Boolean;
    procedure DefinirTitulo(const ATitulo: string);
    function ObterDados: TDadosCadastroCliente;
    procedure ExibirDados(const ADados: TDadosCadastroCliente);
    procedure PreencherEndereco(const AEndereco, ABairro, ACidade, AUf, AEstado: string);
    procedure ExibirEstado(const AEstado: string);
    procedure ExibirId(AId: Integer);
    procedure SinalizarCarregamento(AAtivo: Boolean);
    procedure ExibirMensagem(const AMensagem: string);
    procedure FocarCampo(ACampo: TCampoCliente);
    procedure Fechar;
    property Id: Integer read FId;
    property Salvo: Boolean read GetSalvo;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  Dominio.Cliente,
  Dominio.UnidadesFederativas,
  Visao.ModuloIconesAcao;

{$R *.dfm}

const
  TECLA_ENTER = #13;

destructor TFormCadastroCliente.Destroy;
begin
  FControlador.Free;
  inherited;
end;

procedure TFormCadastroCliente.FormCreate(Sender: TObject);
var
  LUnidade: TUnidadeFederativa;
begin
  EditorUf.Properties.Items.Clear;
  for LUnidade in UNIDADES_FEDERATIVAS do
    EditorUf.Properties.Items.Add(LUnidade.Sigla);
end;

procedure TFormCadastroCliente.Conectar(const ARepositorio: IRepositorioCliente;
  const ATransacao: ITransacao; const AServicoViaCep: IServicoViaCep; const ARelogio: IRelogio;
  const AConfirmacao: IConfirmacao; const AApresentadorErro: IApresentadorErro);
begin
  FApresentadorErro := AApresentadorErro;
  FControlador := TControladorCadastroCliente.Create(Self, ARepositorio, ATransacao,
    AServicoViaCep, ARelogio, AConfirmacao);
end;

function TFormCadastroCliente.Abrir(AModo: TModoCadastro; AId: Integer): Boolean;
begin
  Result := FControlador.Abrir(AModo, AId);
end;

function TFormCadastroCliente.GetSalvo: Boolean;
begin
  Result := Assigned(FControlador) and FControlador.Salvo;
end;

function TFormCadastroCliente.Editor(ACampo: TCampoCliente): TcxCustomEdit;
begin
  case ACampo of
    ccNome: Result := EditorNome;
    ccCpfCnpj: Result := EditorCpfCnpj;
    ccDataNascimento: Result := EditorDataNascimento;
    ccCep: Result := EditorCep;
    ccEndereco: Result := EditorEndereco;
    ccNumero: Result := EditorNumero;
    ccComplemento: Result := EditorComplemento;
    ccBairro: Result := EditorBairro;
    ccCidade: Result := EditorCidade;
  else
    Result := EditorUf;
  end;
end;

procedure TFormCadastroCliente.SelecionarUf(const AUf: string);
begin
  EditorUf.ItemIndex := EditorUf.Properties.Items.IndexOf(UpperCase(Trim(AUf)));
end;

procedure TFormCadastroCliente.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key <> TECLA_ENTER then
    Exit;
  Key := #0;
  SelectNext(ActiveControl, True, True);
end;

procedure TFormCadastroCliente.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FControlador) or FControlador.PodeFechar;
end;

procedure TFormCadastroCliente.EditorCepEnter(Sender: TObject);
begin
  FControlador.CepRecebeuFoco;
end;

procedure TFormCadastroCliente.EditorCepExit(Sender: TObject);
begin
  FControlador.CepPerdeuFoco;
end;

procedure TFormCadastroCliente.EditorUfPropertiesChange(Sender: TObject);
begin
  if not FPreenchendo and Assigned(FControlador) then
    FControlador.UfAlterada;
end;

procedure TFormCadastroCliente.BotaoSalvarClick(Sender: TObject);
begin
  FControlador.Salvar;
end;

procedure TFormCadastroCliente.BotaoCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TFormCadastroCliente.DefinirTitulo(const ATitulo: string);
begin
  Caption := ATitulo;
end;

function TFormCadastroCliente.ObterDados: TDadosCadastroCliente;
begin
  Result.Nome := EditorNome.Text;
  Result.CpfCnpj := EditorCpfCnpj.Text;
  if EditorDataNascimento.Date = NullDate then
    Result.DataNascimento := ''
  else
    Result.DataNascimento := FormatarData(EditorDataNascimento.Date);
  Result.Cep := EditorCep.Text;
  Result.Endereco := EditorEndereco.Text;
  Result.Numero := EditorNumero.Text;
  Result.Complemento := EditorComplemento.Text;
  Result.Bairro := EditorBairro.Text;
  Result.Cidade := EditorCidade.Text;
  Result.Uf := EditorUf.Text;
  Result.Estado := EditorEstado.Text;
end;

procedure TFormCadastroCliente.ExibirDados(const ADados: TDadosCadastroCliente);
var
  LNascimento: TDate;
begin
  FPreenchendo := True;
  try
    EditorNome.Text := ADados.Nome;
    EditorCpfCnpj.Text := ADados.CpfCnpj;
    if TentarLerData(ADados.DataNascimento, LNascimento) then
      EditorDataNascimento.Date := LNascimento
    else
      EditorDataNascimento.Clear;
    EditorCep.Text := ADados.Cep;
    EditorEndereco.Text := ADados.Endereco;
    EditorNumero.Text := ADados.Numero;
    EditorComplemento.Text := ADados.Complemento;
    EditorBairro.Text := ADados.Bairro;
    EditorCidade.Text := ADados.Cidade;
    SelecionarUf(ADados.Uf);
    EditorEstado.Text := ADados.Estado;
  finally
    FPreenchendo := False;
  end;
end;

procedure TFormCadastroCliente.PreencherEndereco(const AEndereco, ABairro, ACidade, AUf,
  AEstado: string);
begin
  FPreenchendo := True;
  try
    EditorEndereco.Text := AEndereco;
    EditorBairro.Text := ABairro;
    EditorCidade.Text := ACidade;
    SelecionarUf(AUf);
    EditorEstado.Text := AEstado;
  finally
    FPreenchendo := False;
  end;
end;

procedure TFormCadastroCliente.ExibirEstado(const AEstado: string);
begin
  EditorEstado.Text := AEstado;
end;

procedure TFormCadastroCliente.ExibirId(AId: Integer);
begin
  FId := AId;
end;

procedure TFormCadastroCliente.SinalizarCarregamento(AAtivo: Boolean);
begin
  RotuloConsultandoCep.Visible := AAtivo;
  if AAtivo then
  begin
    Screen.Cursor := crHourGlass;
    Update;
  end
  else
    Screen.Cursor := crDefault;
end;

procedure TFormCadastroCliente.ExibirMensagem(const AMensagem: string);
begin
  FApresentadorErro.ApresentarErro(AMensagem);
end;

procedure TFormCadastroCliente.FocarCampo(ACampo: TCampoCliente);
begin
  if Editor(ACampo).CanFocus then
    Editor(ACampo).SetFocus;
end;

procedure TFormCadastroCliente.Fechar;
begin
  if fsModal in FormState then
    ModalResult := mrOk
  else
    Close;
end;

end.

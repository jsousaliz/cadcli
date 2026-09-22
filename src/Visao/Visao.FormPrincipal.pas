unit Visao.FormPrincipal;

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
  cxLabel,
  cxClasses,
  dxBar,
  dxStatusBar,
  Aplicacao.ControladorPrincipal,
  Aplicacao.NavegadorAplicacao,
  Visao.ApresentadorErro;

type
  TFormPrincipal = class(TForm, IVisaoPrincipal)
    GerenciadorBarras: TdxBarManager;
    BarraMenuPrincipal: TdxBar;
    MenuSistema: TdxBarSubItem;
    MenuCadastros: TdxBarSubItem;
    MenuRelatorios: TdxBarSubItem;
    ItemSair: TdxBarButton;
    ItemCliente: TdxBarButton;
    ItemRelatorio: TdxBarButton;
    RotuloBoasVindas: TcxLabel;
    BarraStatus: TdxStatusBar;
    procedure ItemSairClick(Sender: TObject);
    procedure ItemClienteClick(Sender: TObject);
    procedure ItemRelatorioClick(Sender: TObject);
  private
    FControlador: TControladorPrincipal;
    FApresentadorErro: IApresentadorErro;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Conectar(const ANavegador: INavegadorAplicacao;
      const AApresentadorErro: IApresentadorErro);
    procedure ExibirErro(const AMensagem: string);
  end;

const
  PREFIXO_VERSAO = 'Versão ';

implementation

uses
  Visao.VersaoExecutavel;

{$R *.dfm}

constructor TFormPrincipal.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BarraStatus.Panels[0].Text := PREFIXO_VERSAO + VersaoExecutavelEmExecucao;
end;

destructor TFormPrincipal.Destroy;
begin
  FControlador.Free;
  inherited;
end;

procedure TFormPrincipal.Conectar(const ANavegador: INavegadorAplicacao;
  const AApresentadorErro: IApresentadorErro);
begin
  FApresentadorErro := AApresentadorErro;
  FControlador := TControladorPrincipal.Create(Self, ANavegador);
end;

procedure TFormPrincipal.ExibirErro(const AMensagem: string);
begin
  FApresentadorErro.ApresentarErro(AMensagem);
end;

procedure TFormPrincipal.ItemSairClick(Sender: TObject);
begin
  FControlador.Executar(apSair);
end;

procedure TFormPrincipal.ItemClienteClick(Sender: TObject);
begin
  FControlador.Executar(apCliente);
end;

procedure TFormPrincipal.ItemRelatorioClick(Sender: TObject);
begin
  FControlador.Executar(apRelatorio);
end;

end.

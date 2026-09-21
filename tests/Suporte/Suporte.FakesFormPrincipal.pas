unit Suporte.FakesFormPrincipal;

interface

uses
  System.Classes,
  System.SysUtils,
  Aplicacao.ControladorPrincipal,
  Aplicacao.NavegadorAplicacao,
  Visao.ApresentadorErro;

type
  TNavegadorFake = class(TInterfacedObject, INavegadorAplicacao)
  public
    ChamadasClientes: Integer;
    ChamadasRelatorio: Integer;
    ChamadasEncerrar: Integer;
    FalharClientes: Boolean;
    FalharRelatorio: Boolean;
    MensagemExcecao: string;
    constructor Create;
    procedure AbrirClientes;
    procedure AbrirRelatorio;
    procedure EncerrarAplicacao;
  end;

  TVisaoPrincipalFake = class(TInterfacedObject, IVisaoPrincipal)
  private
    FErros: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExibirErro(const AMensagem: string);
    property Erros: TStringList read FErros;
  end;

  TApresentadorErroFake = class(TInterfacedObject, IApresentadorErro)
  private
    FMensagens: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ApresentarErro(const AMensagem: string);
    property Mensagens: TStringList read FMensagens;
  end;

implementation

constructor TNavegadorFake.Create;
begin
  inherited Create;
  MensagemExcecao := 'falha simulada ao abrir a tela';
end;

procedure TNavegadorFake.AbrirClientes;
begin
  Inc(ChamadasClientes);
  if FalharClientes then
    raise Exception.Create(MensagemExcecao);
end;

procedure TNavegadorFake.AbrirRelatorio;
begin
  Inc(ChamadasRelatorio);
  if FalharRelatorio then
    raise Exception.Create(MensagemExcecao);
end;

procedure TNavegadorFake.EncerrarAplicacao;
begin
  Inc(ChamadasEncerrar);
end;

constructor TVisaoPrincipalFake.Create;
begin
  inherited Create;
  FErros := TStringList.Create;
end;

destructor TVisaoPrincipalFake.Destroy;
begin
  FErros.Free;
  inherited;
end;

procedure TVisaoPrincipalFake.ExibirErro(const AMensagem: string);
begin
  FErros.Add(AMensagem);
end;

constructor TApresentadorErroFake.Create;
begin
  inherited Create;
  FMensagens := TStringList.Create;
end;

destructor TApresentadorErroFake.Destroy;
begin
  FMensagens.Free;
  inherited;
end;

procedure TApresentadorErroFake.ApresentarErro(const AMensagem: string);
begin
  FMensagens.Add(AMensagem);
end;

end.

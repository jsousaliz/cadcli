unit Visao.NavegadorAplicacao;

interface

uses
  System.SysUtils,
  Vcl.Forms,
  Aplicacao.NavegadorAplicacao;

type
  TCriadorTela = reference to function: TForm;

  ENavegacaoSemTela = class(Exception);

  TNavegadorAplicacao = class(TInterfacedObject, INavegadorAplicacao)
  private
    FShell: TForm;
    FCriadorClientes: TCriadorTela;
    FCriadorRelatorio: TCriadorTela;
    procedure AbrirModal(const ACriador: TCriadorTela; const ADestino: string);
  public
    constructor Create(AShell: TForm);
    procedure RegistrarTelaClientes(const ACriador: TCriadorTela);
    procedure RegistrarTelaRelatorio(const ACriador: TCriadorTela);
    procedure AbrirClientes;
    procedure AbrirRelatorio;
    procedure EncerrarAplicacao;
  end;

const
  DESTINO_CLIENTES = 'o cadastro de clientes';
  DESTINO_RELATORIO = 'o relatório de clientes';

implementation

constructor TNavegadorAplicacao.Create(AShell: TForm);
begin
  inherited Create;
  if not Assigned(AShell) then
    raise EArgumentNilException.Create('O shell da aplicação deve ser informado.');
  FShell := AShell;
end;

procedure TNavegadorAplicacao.RegistrarTelaClientes(const ACriador: TCriadorTela);
begin
  FCriadorClientes := ACriador;
end;

procedure TNavegadorAplicacao.RegistrarTelaRelatorio(const ACriador: TCriadorTela);
begin
  FCriadorRelatorio := ACriador;
end;

procedure TNavegadorAplicacao.AbrirModal(const ACriador: TCriadorTela; const ADestino: string);
var
  LTela: TForm;
begin
  if not Assigned(ACriador) then
    raise ENavegacaoSemTela.CreateFmt('Nenhuma tela registrada para %s.', [ADestino]);
  LTela := ACriador();
  try
    LTela.ShowModal;
  finally
    LTela.Free;
  end;
end;

procedure TNavegadorAplicacao.AbrirClientes;
begin
  AbrirModal(FCriadorClientes, DESTINO_CLIENTES);
end;

procedure TNavegadorAplicacao.AbrirRelatorio;
begin
  AbrirModal(FCriadorRelatorio, DESTINO_RELATORIO);
end;

procedure TNavegadorAplicacao.EncerrarAplicacao;
begin
  ExitCode := 0;
  FShell.Close;
end;

end.

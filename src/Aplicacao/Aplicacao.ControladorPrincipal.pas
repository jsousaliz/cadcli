unit Aplicacao.ControladorPrincipal;

interface

uses
  System.SysUtils,
  Aplicacao.NavegadorAplicacao;

type
  TAcaoPrincipal = (apSair, apCliente, apRelatorio);

  IVisaoPrincipal = interface
    ['{0F7B1C3D-8E2A-4B6F-A1D4-5C9E7B3F2A60}']
    procedure ExibirErro(const AMensagem: string);
  end;

  TControladorPrincipal = class
  private
    FVisao: IVisaoPrincipal;
    FNavegador: INavegadorAplicacao;
    procedure Abrir(const AAbertura: TProc; const AMensagemFalha: string);
  public
    constructor Create(const AVisao: IVisaoPrincipal; const ANavegador: INavegadorAplicacao);
    procedure Executar(AAcao: TAcaoPrincipal);
  end;

const
  MENSAGEM_FALHA_CLIENTES = 'Não foi possível abrir o cadastro de clientes.';
  MENSAGEM_FALHA_RELATORIO = 'Não foi possível abrir o relatório de clientes.';

implementation

constructor TControladorPrincipal.Create(const AVisao: IVisaoPrincipal;
  const ANavegador: INavegadorAplicacao);
begin
  inherited Create;
  if not Assigned(AVisao) then
    raise EArgumentNilException.Create('A visão principal deve ser informada.');
  if not Assigned(ANavegador) then
    raise EArgumentNilException.Create('O navegador da aplicação deve ser informado.');
  FVisao := AVisao;
  FNavegador := ANavegador;
end;

procedure TControladorPrincipal.Abrir(const AAbertura: TProc; const AMensagemFalha: string);
begin
  try
    AAbertura;
  except
    on Exception do
      FVisao.ExibirErro(AMensagemFalha);
  end;
end;

procedure TControladorPrincipal.Executar(AAcao: TAcaoPrincipal);
begin
  case AAcao of
    apSair:
      FNavegador.EncerrarAplicacao;
    apCliente:
      Abrir(
        procedure
        begin
          FNavegador.AbrirClientes;
        end,
        MENSAGEM_FALHA_CLIENTES);
    apRelatorio:
      Abrir(
        procedure
        begin
          FNavegador.AbrirRelatorio;
        end,
        MENSAGEM_FALHA_RELATORIO);
  end;
end;

end.

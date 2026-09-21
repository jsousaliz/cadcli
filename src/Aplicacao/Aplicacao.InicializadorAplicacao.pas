unit Aplicacao.InicializadorAplicacao;

interface

uses
  System.SysUtils;

type
  IInicializadorPersistencia = interface
    ['{199C6294-15D7-40ED-A59B-638710337D41}']
    function Preparar(out AMensagemErro: string): Boolean;
  end;

  IAutorizadorInterface = interface
    ['{F5E9C79D-AB64-4382-88FE-AEF5D4943ADB}']
    procedure AutorizarAbertura;
  end;

  TInicializadorAplicacao = class
  private
    FPersistencia: IInicializadorPersistencia;
    FAutorizadorInterface: IAutorizadorInterface;
  public
    constructor Create(const APersistencia: IInicializadorPersistencia;
      const AAutorizadorInterface: IAutorizadorInterface);
    function Inicializar(out AMensagemErro: string): Boolean;
  end;

implementation

constructor TInicializadorAplicacao.Create(const APersistencia: IInicializadorPersistencia;
  const AAutorizadorInterface: IAutorizadorInterface);
begin
  inherited Create;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('O inicializador de persistência deve ser informado.');
  if not Assigned(AAutorizadorInterface) then
    raise EArgumentNilException.Create('O autorizador da interface deve ser informado.');
  FPersistencia := APersistencia;
  FAutorizadorInterface := AAutorizadorInterface;
end;

function TInicializadorAplicacao.Inicializar(out AMensagemErro: string): Boolean;
begin
  Result := FPersistencia.Preparar(AMensagemErro);
  if Result then
    FAutorizadorInterface.AutorizarAbertura;
end;

end.

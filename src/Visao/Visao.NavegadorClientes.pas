unit Visao.NavegadorClientes;

interface

uses
  Aplicacao.Confirmacao,
  Aplicacao.ControladorCadastroCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.NavegadorClientes,
  Aplicacao.RepositorioCliente,
  Aplicacao.ServicoViaCep,
  Aplicacao.Transacao,
  Visao.ApresentadorErro;

type
  TNavegadorClientes = class(TInterfacedObject, INavegadorClientes)
  private
    FRepositorio: IRepositorioCliente;
    FTransacao: ITransacao;
    FServicoViaCep: IServicoViaCep;
    FRelogio: IRelogio;
    FConfirmacao: IConfirmacao;
    FApresentadorErro: IApresentadorErro;
    function Abrir(AModo: TModoCadastro; AId: Integer): Boolean;
  public
    constructor Create(const ARepositorio: IRepositorioCliente; const ATransacao: ITransacao;
      const AServicoViaCep: IServicoViaCep; const ARelogio: IRelogio;
      const AConfirmacao: IConfirmacao; const AApresentadorErro: IApresentadorErro);
    function AbrirInclusao: Boolean;
    function AbrirEdicao(AId: Integer): Boolean;
  end;

implementation

uses
  Visao.FormCadastroCliente;

constructor TNavegadorClientes.Create(const ARepositorio: IRepositorioCliente;
  const ATransacao: ITransacao; const AServicoViaCep: IServicoViaCep; const ARelogio: IRelogio;
  const AConfirmacao: IConfirmacao; const AApresentadorErro: IApresentadorErro);
begin
  inherited Create;
  FRepositorio := ARepositorio;
  FTransacao := ATransacao;
  FServicoViaCep := AServicoViaCep;
  FRelogio := ARelogio;
  FConfirmacao := AConfirmacao;
  FApresentadorErro := AApresentadorErro;
end;

function TNavegadorClientes.Abrir(AModo: TModoCadastro; AId: Integer): Boolean;
var
  LForm: TFormCadastroCliente;
begin
  LForm := TFormCadastroCliente.Create(nil);
  try
    LForm.Conectar(FRepositorio, FTransacao, FServicoViaCep, FRelogio, FConfirmacao,
      FApresentadorErro);
    if not LForm.Abrir(AModo, AId) then
      Exit(False);
    LForm.ShowModal;
    Result := LForm.Salvo;
  finally
    LForm.Free;
  end;
end;

function TNavegadorClientes.AbrirInclusao: Boolean;
begin
  Result := Abrir(mcInclusao, 0);
end;

function TNavegadorClientes.AbrirEdicao(AId: Integer): Boolean;
begin
  Result := Abrir(mcEdicao, AId);
end;

end.

unit Visao.ComposicaoAplicacao;

interface

uses
  Vcl.Forms,
  FireDAC.Comp.Client,
  Aplicacao.NavegadorAplicacao;

function ComporNavegador(AFormPrincipal: TForm; AConexao: TFDConnection): INavegadorAplicacao;

implementation

uses
  Aplicacao.Confirmacao,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.RepositorioCliente,
  Aplicacao.Transacao,
  Infraestrutura.RepositorioClienteFireDAC,
  Infraestrutura.ServicoViaCep,
  Infraestrutura.TransporteHttp,
  Visao.ApresentadorErro,
  Visao.ConfirmacaoDialogo,
  Visao.FormPesquisaCliente,
  Visao.NavegadorAplicacao,
  Visao.NavegadorClientes;

function CriarTelaClientes(AConexao: TFDConnection): TForm;
var
  LRepositorio: IRepositorioCliente;
  LTransacao: ITransacao;
  LConfirmacao: IConfirmacao;
  LApresentadorErro: IApresentadorErro;
  LForm: TFormPesquisaCliente;
begin
  LRepositorio := TRepositorioClienteFireDAC.Create(AConexao);
  LTransacao := TTransacaoFireDAC.Create(AConexao);
  LConfirmacao := TConfirmacaoDialogo.Create;
  LApresentadorErro := TApresentadorErroDialogo.Create;
  LForm := TFormPesquisaCliente.Create(nil);
  try
    LForm.Conectar(LRepositorio, LTransacao,
      TNavegadorClientes.Create(LRepositorio, LTransacao,
        TServicoViaCep.Create(TTransporteHttpNet.Create), TRelogioSistema.Create, LConfirmacao,
        LApresentadorErro),
      LConfirmacao, LApresentadorErro);
  except
    LForm.Free;
    raise;
  end;
  Result := LForm;
end;

function ComporNavegador(AFormPrincipal: TForm; AConexao: TFDConnection): INavegadorAplicacao;

var
  LNavegador: TNavegadorAplicacao;
begin
  LNavegador := TNavegadorAplicacao.Create(AFormPrincipal);
  Result := LNavegador;
  LNavegador.RegistrarTelaClientes(
    function: TForm
    begin
      Result := CriarTelaClientes(AConexao);
    end);
end;

end.

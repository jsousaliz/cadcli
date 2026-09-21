program CadCli;

{$APPTYPE GUI}

{$R *.res}

uses
  System.SysUtils,
  Vcl.Forms,
  FireDAC.VCLUI.Wait,
  Aplicacao.CatalogoMigracoes in 'src\Aplicacao\Aplicacao.CatalogoMigracoes.pas',
  Aplicacao.ControladorPrincipal in 'src\Aplicacao\Aplicacao.ControladorPrincipal.pas',
  Aplicacao.ExecutorMigracoes in 'src\Aplicacao\Aplicacao.ExecutorMigracoes.pas',
  Aplicacao.InicializadorAplicacao in 'src\Aplicacao\Aplicacao.InicializadorAplicacao.pas',
  Aplicacao.NavegadorAplicacao in 'src\Aplicacao\Aplicacao.NavegadorAplicacao.pas',
  Dominio.Migracao in 'src\Dominio\Dominio.Migracao.pas',
  Infraestrutura.CaminhosAplicacao in 'src\Infraestrutura\Infraestrutura.CaminhosAplicacao.pas',
  Infraestrutura.CatalogoPadraoMigracoes in 'src\Infraestrutura\Infraestrutura.CatalogoPadraoMigracoes.pas',
  Infraestrutura.ContextoMigracaoFireDAC in 'src\Infraestrutura\Infraestrutura.ContextoMigracaoFireDAC.pas',
  Infraestrutura.InicializadorBancoFireDAC in 'src\Infraestrutura\Infraestrutura.InicializadorBancoFireDAC.pas',
  Infraestrutura.RegistroErroInicializacao in 'src\Infraestrutura\Infraestrutura.RegistroErroInicializacao.pas',
  Migracao.V001.EsquemaInicial in 'src\Migracoes\Migracao.V001.EsquemaInicial.pas',
  Migracao.V002.DadosReferencia in 'src\Migracoes\Migracao.V002.DadosReferencia.pas',
  Visao.ApresentadorErro in 'src\Visao\Visao.ApresentadorErro.pas',
  Visao.ComposicaoAplicacao in 'src\Visao\Visao.ComposicaoAplicacao.pas',
  Visao.FormPrincipal in 'src\Visao\Visao.FormPrincipal.pas' {FormPrincipal},
  Visao.NavegadorAplicacao in 'src\Visao\Visao.NavegadorAplicacao.pas',
  Visao.VersaoExecutavel in 'src\Visao\Visao.VersaoExecutavel.pas',
  Infraestrutura.TransporteHttp in 'src\Infraestrutura\Infraestrutura.TransporteHttp.pas',
  Infraestrutura.ServicoViaCep in 'src\Infraestrutura\Infraestrutura.ServicoViaCep.pas';

type
  TAutorizadorInterfaceAplicacao = class(TInterfacedObject, IAutorizadorInterface)
  public
    procedure AutorizarAbertura;
  end;

procedure TAutorizadorInterfaceAplicacao.AutorizarAbertura;
var
  LFormPrincipal: TFormPrincipal;
begin
  Application.CreateForm(TFormPrincipal, LFormPrincipal);
  LFormPrincipal.Conectar(ComporNavegador(LFormPrincipal), TApresentadorErroDialogo.Create);
end;

var
  LCatalogo: TCatalogoMigracoes;
  LPersistencia: IInicializadorPersistencia;
  LAutorizador: IAutorizadorInterface;
  LInicializador: TInicializadorAplicacao;
  LMensagemErro: string;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CadCli';
  LCatalogo := CriarCatalogoPadrao;
  try
    LPersistencia := TInicializadorBanco.Create(CaminhoBancoAplicacao, LCatalogo);
    LAutorizador := TAutorizadorInterfaceAplicacao.Create;
    LInicializador := TInicializadorAplicacao.Create(LPersistencia, LAutorizador);
    try
      if LInicializador.Inicializar(LMensagemErro) then
        Application.Run
      else
      begin
        ExitCode := 1;
        RegistrarErroInicializacao(LMensagemErro);
        if ExibeDialogoDeErro then
          (TApresentadorErroDialogo.Create as IApresentadorErro).ApresentarErro(
            'Não foi possível inicializar o CadCli: ' + LMensagemErro);
      end;
    finally
      LInicializador.Free;
    end;
    LPersistencia := nil;
    LAutorizador := nil;
  finally
    LCatalogo.Free;
  end;
end.

program CadCli.Testes;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

{$R *.res}

uses
  Suporte.AvisoTrialDevExpress in 'Suporte\Suporte.AvisoTrialDevExpress.pas',
  Suporte.ProcessoAplicacao in 'Suporte\Suporte.ProcessoAplicacao.pas',
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Vcl.Forms,
  DUnitX.FilterBuilder,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  Testes.CatalogoExecutor in 'Unitarios\Testes.CatalogoExecutor.pas',
  Testes.ControladorPrincipal in 'Unitarios\Testes.ControladorPrincipal.pas',
  Testes.EntregaRunner in 'Unitarios\Testes.EntregaRunner.pas',
  Testes.FormPrincipal in 'Unitarios\Testes.FormPrincipal.pas',
  Testes.InicializadorAplicacao in 'Unitarios\Testes.InicializadorAplicacao.pas',
  Testes.IntegracaoFirebird in 'Unitarios\Testes.IntegracaoFirebird.pas',
  Testes.NavegadorAplicacao in 'Unitarios\Testes.NavegadorAplicacao.pas',
  Testes.ValidacaoCliente in 'Unitarios\Testes.ValidacaoCliente.pas',
  Testes.ControladorPesquisaCliente in 'Unitarios\Testes.ControladorPesquisaCliente.pas',
  Testes.ControladorCadastroCliente in 'Unitarios\Testes.ControladorCadastroCliente.pas',
  Suporte.CaminhosTeste in 'Suporte\Suporte.CaminhosTeste.pas',
  Suporte.FakesMigracao in 'Suporte\Suporte.FakesMigracao.pas',
  Suporte.FakesFormPrincipal in 'Suporte\Suporte.FakesFormPrincipal.pas',
  Suporte.FakesClientes in 'Suporte\Suporte.FakesClientes.pas',
  Suporte.FakesRelatorioCliente in 'Suporte\Suporte.FakesRelatorioCliente.pas',
  Testes.ServicoViaCep in 'Unitarios\Testes.ServicoViaCep.pas',
  Testes.RepositorioClienteFirebird in 'Unitarios\Testes.RepositorioClienteFirebird.pas',
  Testes.FormsClientes in 'Unitarios\Testes.FormsClientes.pas',
  Testes.FiltroRelatorioCliente in 'Unitarios\Testes.FiltroRelatorioCliente.pas',
  Testes.ControladorRelatorioCliente in 'Unitarios\Testes.ControladorRelatorioCliente.pas',
  Testes.FormFiltroRelatorioCliente in 'Unitarios\Testes.FormFiltroRelatorioCliente.pas',
  Testes.GeradorRelatorioCliente in 'Unitarios\Testes.GeradorRelatorioCliente.pas',
  Aplicacao.CatalogoMigracoes in '..\src\Aplicacao\Aplicacao.CatalogoMigracoes.pas',
  Aplicacao.ControladorPrincipal in '..\src\Aplicacao\Aplicacao.ControladorPrincipal.pas',
  Aplicacao.ExecutorMigracoes in '..\src\Aplicacao\Aplicacao.ExecutorMigracoes.pas',
  Aplicacao.InicializadorAplicacao in '..\src\Aplicacao\Aplicacao.InicializadorAplicacao.pas',
  Aplicacao.NavegadorAplicacao in '..\src\Aplicacao\Aplicacao.NavegadorAplicacao.pas',
  Aplicacao.Confirmacao in '..\src\Aplicacao\Aplicacao.Confirmacao.pas',
  Aplicacao.ControladorCadastroCliente in '..\src\Aplicacao\Aplicacao.ControladorCadastroCliente.pas',
  Aplicacao.ControladorPesquisaCliente in '..\src\Aplicacao\Aplicacao.ControladorPesquisaCliente.pas',
  Aplicacao.NavegadorClientes in '..\src\Aplicacao\Aplicacao.NavegadorClientes.pas',
  Aplicacao.RepositorioCliente in '..\src\Aplicacao\Aplicacao.RepositorioCliente.pas',
  Aplicacao.GeradorRelatorioCliente in '..\src\Aplicacao\Aplicacao.GeradorRelatorioCliente.pas',
  Aplicacao.ControladorRelatorioCliente in '..\src\Aplicacao\Aplicacao.ControladorRelatorioCliente.pas',
  Aplicacao.ServicoViaCep in '..\src\Aplicacao\Aplicacao.ServicoViaCep.pas',
  Aplicacao.Transacao in '..\src\Aplicacao\Aplicacao.Transacao.pas',
  Dominio.Migracao in '..\src\Dominio\Dominio.Migracao.pas',
  Dominio.Cliente in '..\src\Dominio\Dominio.Cliente.pas',
  Dominio.FiltroCliente in '..\src\Dominio\Dominio.FiltroCliente.pas',
  Dominio.FiltroRelatorioCliente in '..\src\Dominio\Dominio.FiltroRelatorioCliente.pas',
  Dominio.UnidadesFederativas in '..\src\Dominio\Dominio.UnidadesFederativas.pas',
  Dominio.ValidacaoCliente in '..\src\Dominio\Dominio.ValidacaoCliente.pas',
  Infraestrutura.CaminhosAplicacao in '..\src\Infraestrutura\Infraestrutura.CaminhosAplicacao.pas',
  Infraestrutura.CatalogoPadraoMigracoes in '..\src\Infraestrutura\Infraestrutura.CatalogoPadraoMigracoes.pas',
  Infraestrutura.ContextoMigracaoFireDAC in '..\src\Infraestrutura\Infraestrutura.ContextoMigracaoFireDAC.pas',
  Infraestrutura.InicializadorBancoFireDAC in '..\src\Infraestrutura\Infraestrutura.InicializadorBancoFireDAC.pas',
  Infraestrutura.RegistroErroInicializacao in '..\src\Infraestrutura\Infraestrutura.RegistroErroInicializacao.pas',
  Migracao.V001.EsquemaInicial in '..\src\Migracoes\Migracao.V001.EsquemaInicial.pas',
  Migracao.V002.DadosReferencia in '..\src\Migracoes\Migracao.V002.DadosReferencia.pas',
  Migracao.V003.ClientesProtegidos in '..\src\Migracoes\Migracao.V003.ClientesProtegidos.pas',
  Visao.ApresentadorErro in '..\src\Visao\Visao.ApresentadorErro.pas',
  Visao.ComposicaoAplicacao in '..\src\Visao\Visao.ComposicaoAplicacao.pas',
  Visao.FormPrincipal in '..\src\Visao\Visao.FormPrincipal.pas' {FormPrincipal},
  Visao.NavegadorAplicacao in '..\src\Visao\Visao.NavegadorAplicacao.pas',
  Visao.VersaoExecutavel in '..\src\Visao\Visao.VersaoExecutavel.pas',
  Infraestrutura.TransporteHttp in '..\src\Infraestrutura\Infraestrutura.TransporteHttp.pas',
  Infraestrutura.ServicoViaCep in '..\src\Infraestrutura\Infraestrutura.ServicoViaCep.pas',
  Infraestrutura.RepositorioClienteFireDAC in '..\src\Infraestrutura\Infraestrutura.RepositorioClienteFireDAC.pas',
  Infraestrutura.GeradorRelatorioClienteReportBuilder in '..\src\Infraestrutura\Infraestrutura.GeradorRelatorioClienteReportBuilder.pas',
  Visao.ConfirmacaoDialogo in '..\src\Visao\Visao.ConfirmacaoDialogo.pas',
  Visao.FormPesquisaCliente in '..\src\Visao\Visao.FormPesquisaCliente.pas' {FormPesquisaCliente},
  Visao.FormCadastroCliente in '..\src\Visao\Visao.FormCadastroCliente.pas' {FormCadastroCliente},
  Visao.NavegadorClientes in '..\src\Visao\Visao.NavegadorClientes.pas',
  Visao.FormFiltroRelatorioCliente in '..\src\Visao\Visao.FormFiltroRelatorioCliente.pas' {FormFiltroRelatorioCliente};

function QualificarTeste(const ANome: string): string;
begin
  Result := Trim(ANome);
  if StartsText('TTestesCatalogoMigracoes.', Result) or
     StartsText('TTestesExecutorMigracoes.', Result) or
     StartsText('TTestesBootstrapTabelaVersoes.', Result) then
    Exit('Testes.CatalogoExecutor.' + Result);
  if StartsText('TTestesEntregaRelease.', Result) or
     StartsText('TTestesRunnerDUnitX.', Result) then
    Exit('Testes.EntregaRunner.' + Result);
  if StartsText('TTestesControladorPrincipal.', Result) or
     StartsText('TTestesArquiteturaFormPrincipal.', Result) then
    Exit('Testes.ControladorPrincipal.' + Result);
  if StartsText('TTestesNavegadorAplicacao.', Result) then
    Exit('Testes.NavegadorAplicacao.' + Result);
  if StartsText('TTestesValidacaoCliente.', Result) or
     StartsText('TTestesTabelaUfs.', Result) then
    Exit('Testes.ValidacaoCliente.' + Result);
  if StartsText('TTestesControladorPesquisaCliente.', Result) then
    Exit('Testes.ControladorPesquisaCliente.' + Result);
  if StartsText('TTestesFiltroRelatorioCliente.', Result) then
    Exit('Testes.FiltroRelatorioCliente.' + Result);
  if StartsText('TTestesControladorRelatorioCliente.', Result) then
    Exit('Testes.ControladorRelatorioCliente.' + Result);
  if StartsText('TTestesGeradorRelatorioClienteReportBuilder.', Result) then
    Exit('Testes.GeradorRelatorioCliente.' + Result);
  if StartsText('TTestesFormFiltroRelatorioCliente.', Result) or
     StartsText('TTestesArquiteturaRelatorioCliente.', Result) then
    Exit('Testes.FormFiltroRelatorioCliente.' + Result);
  if StartsText('TTestesServicoViaCep.', Result) or
     StartsText('TTestesTransporteHttp.', Result) then
    Exit('Testes.ServicoViaCep.' + Result);
  if StartsText('TTestesRepositorioClienteFirebird.', Result) then
    Exit('Testes.RepositorioClienteFirebird.' + Result);
  if StartsText('TTestesFormPesquisaCliente.', Result) or
     StartsText('TTestesFormCadastroCliente.', Result) or
     StartsText('TTestesNavegadorClientes.', Result) or
     StartsText('TTestesArquiteturaClientes.', Result) then
    Exit('Testes.FormsClientes.' + Result);
  if StartsText('TTestesControladorCadastroCliente.', Result) then
    Exit('Testes.ControladorCadastroCliente.' + Result);
  if StartsText('TTestesFormPrincipal.', Result) or
     StartsText('TTestesApresentadorErro.', Result) then
    Exit('Testes.FormPrincipal.' + Result);
  if StartsText('TTestesInicializadorAplicacao.', Result) or
     StartsText('TTestesArquiteturaFundacao.', Result) then
    Exit('Testes.InicializadorAplicacao.' + Result);
  if StartsText('TTestesInicializadorBanco.', Result) or
     StartsText('TTestesMigracaoInicial.', Result) or
     StartsText('TTestesAplicacaoRelease.', Result) or
     StartsText('TTestesMigracaoNoFirebird.', Result) or
     StartsText('TTestesConvencaoMigracoes.', Result) then
    Exit('Testes.IntegracaoFirebird.' + Result);
end;

procedure QualificarFiltrosCurtos;
var
  I: Integer;
  J: Integer;
  LItens: TStringList;
begin
  LItens := TStringList.Create;
  try
    LItens.StrictDelimiter := True;
    LItens.Delimiter := ',';
    for I := 0 to TDUnitX.Options.Run.Count - 1 do
    begin
      LItens.DelimitedText := TDUnitX.Options.Run[I];
      for J := 0 to LItens.Count - 1 do
        LItens[J] := QualificarTeste(LItens[J]);
      TDUnitX.Options.Run[I] := LItens.CommaText;
    end;
  finally
    LItens.Free;
  end;
end;

var
  LExecutor: ITestRunner;
  LResultados: IRunResults;
  LLogger: ITestLogger;
begin
  try
    Application.ProcessMessages;
    TDUnitX.CheckCommandLine;
    QualificarFiltrosCurtos;
    TDUnitX.Filter := TDUnitXFilterBuilder.BuildFilter(TDUnitX.Options);
    LExecutor := TDUnitX.CreateRunner;
    LExecutor.UseRTTI := True;
    LExecutor.FailsOnNoAsserts := True;
    LLogger := TDUnitXConsoleLogger.Create(True);
    LExecutor.AddLogger(LLogger);
    LResultados := LExecutor.Execute;
    if not LResultados.AllPassed then
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 2;
    end;
  end;
  FDManager.Close;
end.

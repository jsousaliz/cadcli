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
  Suporte.CaminhosTeste in 'Suporte\Suporte.CaminhosTeste.pas',
  Suporte.FakesMigracao in 'Suporte\Suporte.FakesMigracao.pas',
  Suporte.FakesShell in 'Suporte\Suporte.FakesShell.pas',
  Aplicacao.CatalogoMigracoes in '..\src\Aplicacao\Aplicacao.CatalogoMigracoes.pas',
  Aplicacao.ControladorPrincipal in '..\src\Aplicacao\Aplicacao.ControladorPrincipal.pas',
  Aplicacao.ExecutorMigracoes in '..\src\Aplicacao\Aplicacao.ExecutorMigracoes.pas',
  Aplicacao.InicializadorAplicacao in '..\src\Aplicacao\Aplicacao.InicializadorAplicacao.pas',
  Aplicacao.NavegadorAplicacao in '..\src\Aplicacao\Aplicacao.NavegadorAplicacao.pas',
  Dominio.Migracao in '..\src\Dominio\Dominio.Migracao.pas',
  Infraestrutura.CatalogoPadraoMigracoes in '..\src\Infraestrutura\Infraestrutura.CatalogoPadraoMigracoes.pas',
  Infraestrutura.ContextoMigracaoFireDAC in '..\src\Infraestrutura\Infraestrutura.ContextoMigracaoFireDAC.pas',
  Infraestrutura.InicializadorBancoFireDAC in '..\src\Infraestrutura\Infraestrutura.InicializadorBancoFireDAC.pas',
  Infraestrutura.RegistroErroInicializacao in '..\src\Infraestrutura\Infraestrutura.RegistroErroInicializacao.pas',
  Migracao.V001.EsquemaInicial in '..\src\Migracoes\Migracao.V001.EsquemaInicial.pas',
  Migracao.V002.DadosReferencia in '..\src\Migracoes\Migracao.V002.DadosReferencia.pas',
  Visao.ApresentadorErro in '..\src\Visao\Visao.ApresentadorErro.pas',
  Visao.ComposicaoAplicacao in '..\src\Visao\Visao.ComposicaoAplicacao.pas',
  Visao.FormPrincipal in '..\src\Visao\Visao.FormPrincipal.pas' {FormPrincipal},
  Visao.NavegadorAplicacao in '..\src\Visao\Visao.NavegadorAplicacao.pas',
  Visao.VersaoExecutavel in '..\src\Visao\Visao.VersaoExecutavel.pas';

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
     StartsText('TTestesArquiteturaShell.', Result) then
    Exit('Testes.ControladorPrincipal.' + Result);
  if StartsText('TTestesNavegadorAplicacao.', Result) then
    Exit('Testes.NavegadorAplicacao.' + Result);
  if StartsText('TTestesFormPrincipal.', Result) then
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

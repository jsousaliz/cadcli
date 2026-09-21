program CadCli.Testes;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  DUnitX.FilterBuilder,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  FireDAC.Comp.Client,
  Testes.CatalogoExecutor in 'Unitarios\Testes.CatalogoExecutor.pas',
  Testes.EntregaRunner in 'Unitarios\Testes.EntregaRunner.pas',
  Testes.InicializadorAplicacao in 'Unitarios\Testes.InicializadorAplicacao.pas',
  Testes.IntegracaoFirebird in 'Unitarios\Testes.IntegracaoFirebird.pas',
  Suporte.CaminhosTeste in 'Suporte\Suporte.CaminhosTeste.pas',
  Suporte.FakesMigracao in 'Suporte\Suporte.FakesMigracao.pas',
  Aplicacao.CatalogoMigracoes in '..\src\Aplicacao\Aplicacao.CatalogoMigracoes.pas',
  Aplicacao.ExecutorMigracoes in '..\src\Aplicacao\Aplicacao.ExecutorMigracoes.pas',
  Aplicacao.InicializadorAplicacao in '..\src\Aplicacao\Aplicacao.InicializadorAplicacao.pas',
  Dominio.Migracao in '..\src\Dominio\Dominio.Migracao.pas',
  Infraestrutura.CatalogoPadraoMigracoes in '..\src\Infraestrutura\Infraestrutura.CatalogoPadraoMigracoes.pas',
  Infraestrutura.ContextoMigracaoFireDAC in '..\src\Infraestrutura\Infraestrutura.ContextoMigracaoFireDAC.pas',
  Infraestrutura.InicializadorBancoFireDAC in '..\src\Infraestrutura\Infraestrutura.InicializadorBancoFireDAC.pas',
  Infraestrutura.RegistroErroInicializacao in '..\src\Infraestrutura\Infraestrutura.RegistroErroInicializacao.pas',
  Migracao.V001.EsquemaInicial in '..\src\Migracoes\Migracao.V001.EsquemaInicial.pas',
  Migracao.V002.DadosReferencia in '..\src\Migracoes\Migracao.V002.DadosReferencia.pas';

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

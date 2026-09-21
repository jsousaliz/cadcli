unit Testes.CatalogoExecutor;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesCatalogoMigracoes = class
  public
    [Test]
    procedure RejeitaDuplicadasEOrdenaVersoes;
  end;

  [TestFixture]
  TTestesExecutorMigracoes = class
  public
    [Setup]
    procedure Preparar;
    [Test]
    procedure RegistraUmaLinhaComMetadadosDaMigracao;
    [Test]
    procedure ReverteAlteracaoERegistroNaMesmaTransacao;
    [Test]
    procedure ExecutaSomentePendentesUmaVezEmOrdemCrescente;
    [Test]
    procedure ReverteAlteracaoERegistroEInformaVersaoNaFalha;
  end;

  [TestFixture]
  TTestesBootstrapTabelaVersoes = class
  public
    [Test]
    procedure CriaTabelaEmTransacaoPropriaSemRegistrarVersao;
    [Test]
    procedure ReverteBootstrapQuandoCriacaoFalha;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.SysUtils,
  Aplicacao.CatalogoMigracoes,
  Aplicacao.ExecutorMigracoes,
  Dominio.Migracao,
  Infraestrutura.InicializadorBancoFireDAC,
  Suporte.FakesMigracao;

procedure TTestesBootstrapTabelaVersoes.CriaTabelaEmTransacaoPropriaSemRegistrarVersao;
var
  LContextoObjeto: TContextoMigracaoFake;
  LContexto: IContextoMigracao;
begin
  LContextoObjeto := TContextoMigracaoFake.Create;
  LContexto := LContextoObjeto;
  TBootstrapTabelaVersoes.Executar(LContexto);
  Assert.AreEqual('INICIAR', LContextoObjeto.Operacoes[0]);
  Assert.IsTrue(LContextoObjeto.Operacoes[1].StartsWith('CREATE TABLE SCHEMA_VERSION'));
  Assert.AreEqual('CONFIRMAR', LContextoObjeto.Operacoes[2]);
  Assert.AreEqual(0, LContextoObjeto.MaiorVersaoInstalada,
    'O bootstrap não pode registrar uma versão de migração.');
end;

procedure TTestesBootstrapTabelaVersoes.ReverteBootstrapQuandoCriacaoFalha;
var
  LContextoObjeto: TContextoMigracaoFake;
  LContexto: IContextoMigracao;
  LFalhou: Boolean;
begin
  LContextoObjeto := TContextoMigracaoFake.Create;
  LContextoObjeto.FalharAoExecutar := True;
  LContexto := LContextoObjeto;
  LFalhou := False;
  try
    TBootstrapTabelaVersoes.Executar(LContexto);
  except
    on Exception do
      LFalhou := True;
  end;
  Assert.IsTrue(LFalhou);
  Assert.AreEqual(1, LContextoObjeto.Operacoes.Count);
  Assert.AreEqual('REVERTER', LContextoObjeto.Operacoes[0]);
  Assert.AreEqual(0, LContextoObjeto.MaiorVersaoInstalada);
end;

procedure TTestesCatalogoMigracoes.RejeitaDuplicadasEOrdenaVersoes;
var
  LCatalogo: TCatalogoMigracoes;
  LDuplicadaRejeitada: Boolean;
  LMigracao: IMigracaoBanco;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  try
    LCatalogo.Registrar(TMigracaoTeste002);
    LCatalogo.Registrar(TMigracaoTeste001);
    LMigracao := LCatalogo.ClasseNaPosicao(0).Create;
    Assert.AreEqual(1, LMigracao.Versao, 'A primeira versão deve ser 1.');
    LMigracao := LCatalogo.ClasseNaPosicao(1).Create;
    Assert.AreEqual(2, LMigracao.Versao, 'A segunda versão deve ser 2.');
    LDuplicadaRejeitada := False;
    try
      LCatalogo.Registrar(TMigracaoTeste002Duplicada);
    except
      on EMigracaoDuplicada do
        LDuplicadaRejeitada := True;
    end;
    Assert.IsTrue(LDuplicadaRejeitada, 'Uma versão duplicada deve ser rejeitada.');
  finally
    LCatalogo.Free;
  end;
end;

procedure TTestesExecutorMigracoes.Preparar;
begin
  TMigracaoTeste001.Execucoes := 0;
  TMigracaoTeste002.Execucoes := 0;
  TMigracaoTeste004.Execucoes := 0;
end;

procedure TTestesExecutorMigracoes.RegistraUmaLinhaComMetadadosDaMigracao;
var
  LCatalogo: TCatalogoMigracoes;
  LContextoObjeto: TContextoMigracaoFake;
  LContexto: IContextoMigracao;
  LExecutor: TExecutorMigracoes;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  LContextoObjeto := TContextoMigracaoFake.Create;
  LContexto := LContextoObjeto;
  try
    LCatalogo.Registrar(TMigracaoTeste001);
    LExecutor := TExecutorMigracoes.Create(LCatalogo,
      TRelogioFake.Create(EncodeDateTime(2026, 9, 19, 10, 30, 0, 0)));
    try
      LExecutor.Executar(LContexto);
    finally
      LExecutor.Free;
    end;
    Assert.AreEqual(1, LContextoObjeto.MaiorVersaoInstalada);
    Assert.AreEqual('REGISTRAR:1:migração um:2026-09-19 10:30:00',
      LContextoObjeto.Operacoes[2]);
  finally
    LContexto := nil;
    LCatalogo.Free;
  end;
end;

procedure TTestesExecutorMigracoes.ReverteAlteracaoERegistroNaMesmaTransacao;
var
  LCatalogo: TCatalogoMigracoes;
  LContextoObjeto: TContextoMigracaoFake;
  LContexto: IContextoMigracao;
  LExecutor: TExecutorMigracoes;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  LContextoObjeto := TContextoMigracaoFake.Create;
  LContextoObjeto.FalharAoConfirmar := True;
  LContexto := LContextoObjeto;
  try
    LCatalogo.Registrar(TMigracaoTeste001);
    LExecutor := TExecutorMigracoes.Create(LCatalogo, TRelogioFake.Create(Now));
    try
      try
        LExecutor.Executar(LContexto);
      except
        on EErroMigracao do;
      end;
    finally
      LExecutor.Free;
    end;
    Assert.AreEqual(0, LContextoObjeto.MaiorVersaoInstalada,
      'O registro da versão deve participar da mesma transação.');
    Assert.AreEqual('REVERTER', LContextoObjeto.Operacoes[0]);
  finally
    LContexto := nil;
    LCatalogo.Free;
  end;
end;

function SomenteExecucoes(AContexto: TContextoMigracaoFake): string;
var
  I: Integer;
  LExecucoes: TStringList;
begin
  LExecucoes := TStringList.Create;
  try
    for I := 0 to AContexto.Operacoes.Count - 1 do
      if AContexto.Operacoes[I].StartsWith('EXECUTAR:') then
        LExecucoes.Add(AContexto.Operacoes[I]);
    Result := string.Join('|', LExecucoes.ToStringArray);
  finally
    LExecucoes.Free;
  end;
end;

procedure TTestesExecutorMigracoes.ExecutaSomentePendentesUmaVezEmOrdemCrescente;
var
  LCatalogo: TCatalogoMigracoes;
  LContextoObjeto: TContextoMigracaoFake;
  LContexto: IContextoMigracao;
  LExecutor: TExecutorMigracoes;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  LContextoObjeto := TContextoMigracaoFake.Create;
  LContextoObjeto.AdicionarVersaoInstalada(1);
  LContexto := LContextoObjeto;
  try
    LCatalogo.Registrar(TMigracaoTeste004);
    LCatalogo.Registrar(TMigracaoTeste002);
    LCatalogo.Registrar(TMigracaoTeste001);
    LExecutor := TExecutorMigracoes.Create(LCatalogo, TRelogioFake.Create(Now));
    try
      LExecutor.Executar(LContexto);
      LExecutor.Executar(LContexto);
    finally
      LExecutor.Free;
    end;
    Assert.AreEqual('EXECUTAR:2|EXECUTAR:4', SomenteExecucoes(LContextoObjeto),
      'As pendentes devem ser aplicadas uma vez, em ordem numerica crescente.');
    Assert.AreEqual(0, TMigracaoTeste001.Execucoes,
      'A versao ja instalada nao pode ser reaplicada.');
    Assert.AreEqual(1, TMigracaoTeste002.Execucoes);
    Assert.AreEqual(1, TMigracaoTeste004.Execucoes);
    Assert.AreEqual(4, LContextoObjeto.MaiorVersaoInstalada);
  finally
    LContexto := nil;
    LCatalogo.Free;
  end;
end;

procedure TTestesExecutorMigracoes.ReverteAlteracaoERegistroEInformaVersaoNaFalha;
var
  LCatalogo: TCatalogoMigracoes;
  LContextoObjeto: TContextoMigracaoFake;
  LContexto: IContextoMigracao;
  LExecutor: TExecutorMigracoes;
  LErro: string;
begin
  LCatalogo := TCatalogoMigracoes.Create;
  LContextoObjeto := TContextoMigracaoFake.Create;
  LContexto := LContextoObjeto;
  try
    LCatalogo.Registrar(TMigracaoTeste003Falha);
    LExecutor := TExecutorMigracoes.Create(LCatalogo, TRelogioFake.Create(Now));
    try
      try
        LExecutor.Executar(LContexto);
      except
        on E: EErroMigracao do
          LErro := E.Message;
      end;
    finally
      LExecutor.Free;
    end;
    Assert.AreEqual(0, LContextoObjeto.MaiorVersaoInstalada);
    Assert.AreEqual('REVERTER', LContextoObjeto.Operacoes[0]);
    Assert.Contains(LErro, 'migração 3');
    Assert.IsFalse(LErro.Contains('falha simulada'),
      'O erro de migração não pode repassar o texto da exceção de infraestrutura.');
  finally
    LContexto := nil;
    LCatalogo.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesCatalogoMigracoes);
  TDUnitX.RegisterTestFixture(TTestesExecutorMigracoes);
  TDUnitX.RegisterTestFixture(TTestesBootstrapTabelaVersoes);

end.

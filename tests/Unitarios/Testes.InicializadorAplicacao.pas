unit Testes.InicializadorAplicacao;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesInicializadorAplicacao = class
  public
    [Test]
    procedure LiberaAplicacaoSomenteDepoisDasMigracoes;
  end;

  [TestFixture]
  TTestesArquiteturaFundacao = class
  public
    [Test]
    procedure InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  System.Types,
  Aplicacao.InicializadorAplicacao,
  Suporte.CaminhosTeste,
  Suporte.FakesMigracao;

procedure TTestesInicializadorAplicacao.LiberaAplicacaoSomenteDepoisDasMigracoes;
var
  LPersistenciaObjeto: TPersistenciaFake;
  LPersistencia: IInicializadorPersistencia;
  LAutorizadorObjeto: TAutorizadorInterfaceFake;
  LAutorizador: IAutorizadorInterface;
  LInicializador: TInicializadorAplicacao;
  LMensagem: string;
begin
  LPersistenciaObjeto := TPersistenciaFake.Create;
  LPersistenciaObjeto.Resultado := False;
  LPersistencia := LPersistenciaObjeto;
  LAutorizadorObjeto := TAutorizadorInterfaceFake.Create;
  LAutorizador := LAutorizadorObjeto;
  LInicializador := TInicializadorAplicacao.Create(LPersistencia, LAutorizador);
  try
    Assert.IsFalse(LInicializador.Inicializar(LMensagem));
    Assert.IsFalse(LAutorizadorObjeto.Autorizado,
      'A interface não pode ser autorizada antes da persistência.');
    LPersistenciaObjeto.Resultado := True;
    Assert.IsTrue(LInicializador.Inicializar(LMensagem));
    Assert.IsTrue(LAutorizadorObjeto.Autorizado,
      'A interface deve ser autorizada depois da persistência.');
  finally
    LInicializador.Free;
  end;
end;

procedure TTestesArquiteturaFundacao.InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos;
var
  LArquivosForm: TStringDynArray;
  LPersistenciaObjeto: TPersistenciaFake;
  LPersistencia: IInicializadorPersistencia;
  LAutorizador: IAutorizadorInterface;
  LInicializador: TInicializadorAplicacao;
  LCodigoInicializador: string;
  LMensagem: string;
begin
  LArquivosForm := TDirectory.GetFiles(RaizRepositorio, '*.dfm', TSearchOption.soAllDirectories);
  Assert.AreEqual(0, Integer(Length(LArquivosForm)), 'A Parte 01 deve conter zero forms próprias.');
  LCodigoInicializador := UpperCase(TFile.ReadAllText(TPath.Combine(RaizRepositorio,
    'src\Aplicacao\Aplicacao.InicializadorAplicacao.pas')));
  Assert.IsFalse(LCodigoInicializador.Contains('VCL.'));
  Assert.IsFalse(LCodigoInicializador.Contains('FIREDAC.'));
  Assert.IsFalse(LCodigoInicializador.Contains('DEVEXPRESS'));
  Assert.IsFalse(LCodigoInicializador.Contains('REPORTBUILDER'));
  LPersistenciaObjeto := TPersistenciaFake.Create;
  LPersistenciaObjeto.Resultado := True;
  LPersistencia := LPersistenciaObjeto;
  LAutorizador := TAutorizadorInterfaceFake.Create;
  LInicializador := TInicializadorAplicacao.Create(LPersistencia, LAutorizador);
  try
    Assert.IsTrue(LInicializador.Inicializar(LMensagem),
      'A inicialização de aplicação deve funcionar apenas com interfaces falsas.');
  finally
    LInicializador.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesInicializadorAplicacao);
  TDUnitX.RegisterTestFixture(TTestesArquiteturaFundacao);

end.

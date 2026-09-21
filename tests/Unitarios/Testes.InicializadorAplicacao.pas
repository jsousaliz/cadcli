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
    [Test]
    procedure ProducaoNaoReferenciaRuntimeEmbeddedNemEspalhaCredenciais;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
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
const
  PASTAS_PARTE_01: array[0..3] of string = ('src\Aplicacao', 'src\Dominio',
    'src\Infraestrutura', 'src\Migracoes');
var
  LPasta: string;
  LArquivoForm: string;
  LPastaVisao: string;
  LPersistenciaObjeto: TPersistenciaFake;
  LPersistencia: IInicializadorPersistencia;
  LAutorizador: IAutorizadorInterface;
  LInicializador: TInicializadorAplicacao;
  LCodigoInicializador: string;
  LMensagem: string;
begin
  for LPasta in PASTAS_PARTE_01 do
    Assert.AreEqual(0, Integer(Length(TDirectory.GetFiles(TPath.Combine(RaizRepositorio, LPasta),
      '*.dfm', TSearchOption.soAllDirectories))),
      'A Parte 01 deve conter zero forms próprias em ' + LPasta + '.');
  LPastaVisao := IncludeTrailingPathDelimiter(TPath.Combine(RaizRepositorio, 'src\Visao'));
  for LArquivoForm in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.dfm',
    TSearchOption.soAllDirectories) do
    Assert.IsTrue(StartsText(LPastaVisao, LArquivoForm),
      'Todo .dfm sob src deve estar em src\Visao: ' + LArquivoForm);
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

procedure TTestesArquiteturaFundacao.ProducaoNaoReferenciaRuntimeEmbeddedNemEspalhaCredenciais;
const
  UNIT_CONEXAO = 'Infraestrutura.InicializadorBancoFireDAC.pas';
var
  LArquivos: TStringDynArray;
  LArquivo: string;
  LConteudo: string;
  LUnitsComSenha: Integer;
begin
  LArquivos := TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.pas',
    TSearchOption.soAllDirectories);
  LArquivos := LArquivos + [TPath.Combine(RaizRepositorio, 'CadCli.dpr')];
  LUnitsComSenha := 0;
  for LArquivo in LArquivos do
  begin
    LConteudo := UpperCase(TFile.ReadAllText(LArquivo));
    Assert.IsFalse(LConteudo.Contains('FBCLIENT.DLL'),
      'O código de produção não pode referenciar fbclient.dll: ' + LArquivo);
    Assert.IsFalse(LConteudo.Contains('VENDORLIB'),
      'O código de produção não pode definir VendorLib: ' + LArquivo);
    Assert.IsFalse(LConteudo.Contains('EMBEDDED'),
      'O código de produção não pode citar o Firebird Embedded: ' + LArquivo);
    if LConteudo.Contains('MASTERKEY') then
    begin
      Inc(LUnitsComSenha);
      Assert.AreEqual(UNIT_CONEXAO, TPath.GetFileName(LArquivo),
        'A senha do serviço só pode aparecer na unit que monta a conexão.');
    end;
  end;
  Assert.AreEqual(1, LUnitsComSenha,
    'A senha do serviço deve aparecer exatamente na unit que monta a conexão.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesInicializadorAplicacao);
  TDUnitX.RegisterTestFixture(TTestesArquiteturaFundacao);

end.

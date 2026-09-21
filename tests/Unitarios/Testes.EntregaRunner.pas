unit Testes.EntregaRunner;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesEntregaRelease = class
  public
    [Test]
    procedure ProduzCadCliExeSomenteParaWin64;
    [Test]
    procedure NaoDistribuiBplNemExecutavelAuxiliar;
  end;

  [TestFixture]
  TTestesRunnerDUnitX = class
  public
    [Test]
    procedure ExecutaEmWin64SemCriarForm;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Vcl.Forms,
  Suporte.CaminhosTeste;

function MaquinaPE(const ACaminho: string): Word;
var
  LFluxo: TFileStream;
  LOffsetPE: Cardinal;
  LAssinatura: Cardinal;
begin
  LFluxo := TFileStream.Create(ACaminho, fmOpenRead or fmShareDenyWrite);
  try
    LFluxo.Position := $3C;
    LFluxo.ReadBuffer(LOffsetPE, SizeOf(LOffsetPE));
    LFluxo.Position := LOffsetPE;
    LFluxo.ReadBuffer(LAssinatura, SizeOf(LAssinatura));
    Assert.AreEqual(Cardinal($00004550), LAssinatura, 'Assinatura PE inválida.');
    LFluxo.ReadBuffer(Result, SizeOf(Result));
  finally
    LFluxo.Free;
  end;
end;

procedure TTestesEntregaRelease.ProduzCadCliExeSomenteParaWin64;
var
  LProjeto: string;
begin
  Assert.IsTrue(TFile.Exists(CaminhoExecutavelRelease),
    'O build Release deve produzir CadCli.exe.');
  Assert.AreEqual(Word($8664), MaquinaPE(CaminhoExecutavelRelease),
    'CadCli.exe deve possuir cabeçalho AMD64.');
  LProjeto := TFile.ReadAllText(TPath.Combine(RaizRepositorio, 'CadCli.dproj'));
  Assert.IsFalse(LProjeto.Contains('Win32'), 'O projeto não pode declarar uma variante Win32.');
end;

procedure TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar;
var
  LDiretorio: string;
begin
  LDiretorio := TPath.GetDirectoryName(CaminhoExecutavelRelease);
  Assert.AreEqual(1, Integer(Length(TDirectory.GetFiles(LDiretorio, '*.exe'))),
    'O diretório Release deve conter somente CadCli.exe.');
  Assert.AreEqual(0, Integer(Length(TDirectory.GetFiles(LDiretorio, '*.bpl'))),
    'O diretório Release não deve conter BPLs.');
  Assert.Contains(TFile.ReadAllText(TPath.Combine(RaizRepositorio, 'CadCli.dproj')),
    '<DCC_UsePackage>false</DCC_UsePackage>');
end;

procedure TTestesRunnerDUnitX.ExecutaEmWin64SemCriarForm;
begin
  Assert.AreEqual(Word($8664), MaquinaPE(ParamStr(0)),
    'O runner de testes deve ser Win64.');
  Assert.AreEqual(0, Screen.FormCount,
    'O runner de testes não pode criar forms reais.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesEntregaRelease);
  TDUnitX.RegisterTestFixture(TTestesRunnerDUnitX);

end.

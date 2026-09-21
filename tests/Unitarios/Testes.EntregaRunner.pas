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
    [Test]
    procedure NaoDistribuiRuntimeFirebirdAoLadoDoExecutavel;
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
  System.StrUtils,
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
begin
  Assert.IsTrue(TFile.Exists(CaminhoExecutavelRelease),
    'O build Release deve produzir CadCli.exe.');
  Assert.AreEqual(Word($8664), MaquinaPE(CaminhoExecutavelRelease),
    'CadCli.exe deve possuir cabeçalho AMD64.');
end;

function RvaParaDeslocamento(const ASecoes: TBytes; AQuantidade: Integer; ARva: Cardinal): Int64;
var
  I: Integer;
  LTamanhoVirtual: Cardinal;
  LEnderecoVirtual: Cardinal;
  LTamanhoBruto: Cardinal;
  LPonteiroBruto: Cardinal;
  LExtensao: Cardinal;
begin
  for I := 0 to AQuantidade - 1 do
  begin
    Move(ASecoes[40 * I + 8], LTamanhoVirtual, 4);
    Move(ASecoes[40 * I + 12], LEnderecoVirtual, 4);
    Move(ASecoes[40 * I + 16], LTamanhoBruto, 4);
    Move(ASecoes[40 * I + 20], LPonteiroBruto, 4);
    if LTamanhoVirtual > LTamanhoBruto then
      LExtensao := LTamanhoVirtual
    else
      LExtensao := LTamanhoBruto;
    if (ARva >= LEnderecoVirtual) and (ARva < LEnderecoVirtual + LExtensao) then
      Exit(Int64(ARva) - LEnderecoVirtual + LPonteiroBruto);
  end;
  raise Exception.CreateFmt('RVA %d fora das seções.', [ARva]);
end;

function DllsImportadas(const ACaminho: string): TArray<string>;
var
  LFluxo: TFileStream;
  LOffsetPE: Cardinal;
  LAssinatura: Cardinal;
  LQuantidadeSecoes: Word;
  LTamanhoOpcional: Word;
  LMagico: Word;
  LInicioOpcional: Int64;
  LRvaImportacoes: Cardinal;
  LSecoes: TBytes;
  LDescritor: Int64;
  LRvaNome: Cardinal;
  LNome: AnsiString;
  LCaractere: AnsiChar;
begin
  Result := [];
  LFluxo := TFileStream.Create(ACaminho, fmOpenRead or fmShareDenyWrite);
  try
    LFluxo.Position := $3C;
    LFluxo.ReadBuffer(LOffsetPE, 4);
    LFluxo.Position := LOffsetPE;
    LFluxo.ReadBuffer(LAssinatura, 4);
    Assert.AreEqual(Cardinal($00004550), LAssinatura, 'Assinatura PE inválida: ' + ACaminho);
    LFluxo.Position := LOffsetPE + 4 + 2;
    LFluxo.ReadBuffer(LQuantidadeSecoes, 2);
    LFluxo.Position := LOffsetPE + 4 + 16;
    LFluxo.ReadBuffer(LTamanhoOpcional, 2);
    LInicioOpcional := LOffsetPE + 4 + 20;
    LFluxo.Position := LInicioOpcional;
    LFluxo.ReadBuffer(LMagico, 2);
    Assert.AreEqual(Word($20B), LMagico, 'Somente PE32+ é esperado: ' + ACaminho);
    LFluxo.Position := LInicioOpcional + 112 + 8;
    LFluxo.ReadBuffer(LRvaImportacoes, 4);
    if LRvaImportacoes = 0 then
      Exit;
    SetLength(LSecoes, 40 * LQuantidadeSecoes);
    LFluxo.Position := LInicioOpcional + LTamanhoOpcional;
    LFluxo.ReadBuffer(LSecoes[0], Length(LSecoes));
    LDescritor := RvaParaDeslocamento(LSecoes, LQuantidadeSecoes, LRvaImportacoes);
    while True do
    begin
      LFluxo.Position := LDescritor + 12;
      LFluxo.ReadBuffer(LRvaNome, 4);
      if LRvaNome = 0 then
        Break;
      LFluxo.Position := RvaParaDeslocamento(LSecoes, LQuantidadeSecoes, LRvaNome);
      LNome := '';
      LFluxo.ReadBuffer(LCaractere, 1);
      while LCaractere <> #0 do
      begin
        LNome := LNome + LCaractere;
        LFluxo.ReadBuffer(LCaractere, 1);
      end;
      Result := Result + [string(LNome)];
      Inc(LDescritor, 20);
    end;
  finally
    LFluxo.Free;
  end;
end;

function FechamentoDeBpls(const AExecutavel: string): TStringList;
var
  LDiretorio: string;
  LPendentes: TStringList;
  LAtual: string;
  LImportada: string;
begin
  LDiretorio := TPath.GetDirectoryName(AExecutavel);
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  LPendentes := TStringList.Create;
  try
    for LImportada in DllsImportadas(AExecutavel) do
      if EndsText('.bpl', LImportada) then
        LPendentes.Add(LImportada);
    while LPendentes.Count > 0 do
    begin
      LAtual := LPendentes[0];
      LPendentes.Delete(0);
      if Result.IndexOf(LAtual) >= 0 then
        Continue;
      Assert.IsTrue(TFile.Exists(TPath.Combine(LDiretorio, LAtual)),
        'BPL importada ausente ao lado de CadCli.exe: ' + LAtual);
      Result.Add(LAtual);
      for LImportada in DllsImportadas(TPath.Combine(LDiretorio, LAtual)) do
        if EndsText('.bpl', LImportada) then
          LPendentes.Add(LImportada);
    end;
  finally
    LPendentes.Free;
  end;
end;

procedure TTestesEntregaRelease.NaoDistribuiBplNemExecutavelAuxiliar;
var
  LDiretorio: string;
  LExecutaveis: TArray<string>;
  LFechamento: TStringList;
  LPresentes: TStringList;
  LArquivo: string;
begin
  LDiretorio := TPath.GetDirectoryName(CaminhoExecutavelRelease);
  LExecutaveis := TDirectory.GetFiles(LDiretorio, '*.exe');
  Assert.AreEqual(1, Integer(Length(LExecutaveis)),
    'O diretório Release deve conter somente CadCli.exe.');
  Assert.IsTrue(SameText('CadCli.exe', TPath.GetFileName(LExecutaveis[0])),
    'O único executável do diretório Release deve ser CadCli.exe.');
  Assert.AreEqual(0, Integer(Length(TDirectory.GetFiles(LDiretorio, 'CadCli*.bpl'))),
    'O diretório Release não pode conter BPL própria da aplicação.');
  LFechamento := FechamentoDeBpls(CaminhoExecutavelRelease);
  LPresentes := TStringList.Create;
  try
    LPresentes.CaseSensitive := False;
    LPresentes.Sorted := True;
    for LArquivo in TDirectory.GetFiles(LDiretorio, '*.bpl') do
      LPresentes.Add(TPath.GetFileName(LArquivo));
    Assert.IsTrue(LFechamento.IndexOf('dxBarRS29.bpl') >= 0,
      'O fechamento importado deve conter dxBarRS29.bpl.');
    Assert.IsTrue(LFechamento.IndexOf('rtl290.bpl') >= 0,
      'O fechamento importado deve conter rtl290.bpl.');
    for LArquivo in LPresentes do
      Assert.IsTrue(LFechamento.IndexOf(LArquivo) >= 0,
        'BPL fora do fechamento importado por CadCli.exe: ' + LArquivo);
    for LArquivo in LFechamento do
      Assert.IsTrue(LPresentes.IndexOf(LArquivo) >= 0,
        'BPL do fechamento ausente no diretório Release: ' + LArquivo);
    Assert.AreEqual(LFechamento.Count, LPresentes.Count,
      'As BPLs presentes devem ser exatamente o fechamento importado.');
  finally
    LPresentes.Free;
    LFechamento.Free;
  end;
end;

procedure TTestesEntregaRelease.NaoDistribuiRuntimeFirebirdAoLadoDoExecutavel;
const
  ARQUIVOS_FIREBIRD: array[0..5] of string = ('fbclient.dll', 'ib_util.dll', 'icu*.dll',
    'firebird.msg', 'firebird.conf', 'plugins.conf');
  DIRETORIOS_FIREBIRD: array[0..1] of string = ('plugins', 'intl');
var
  LDiretorio: string;
  LPadrao: string;
begin
  Assert.IsTrue(TFile.Exists(CaminhoExecutavelRelease),
    'O build Release deve produzir CadCli.exe.');
  LDiretorio := TPath.GetDirectoryName(CaminhoExecutavelRelease);
  for LPadrao in ARQUIVOS_FIREBIRD do
    Assert.AreEqual(0, Integer(Length(TDirectory.GetFiles(LDiretorio, LPadrao))),
      'O diretório de CadCli.exe não pode conter ' + LPadrao + ' do runtime Firebird.');
  for LPadrao in DIRETORIOS_FIREBIRD do
    Assert.IsFalse(TDirectory.Exists(TPath.Combine(LDiretorio, LPadrao)),
      'O diretório de CadCli.exe não pode conter o subdiretório ' + LPadrao + ' do Firebird.');
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

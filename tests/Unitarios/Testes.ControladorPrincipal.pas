unit Testes.ControladorPrincipal;

interface

uses
  DUnitX.TestFramework,
  Aplicacao.ControladorPrincipal,
  Suporte.FakesShell;

type
  [TestFixture]
  TTestesControladorPrincipal = class
  private
    FNavegadorObjeto: TNavegadorFake;
    FNavegador: IInterface;
    FVisaoObjeto: TVisaoPrincipalFake;
    FVisao: IInterface;
    FControlador: TControladorPrincipal;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure SairSolicitaEncerramentoUmaVez;
    [Test]
    procedure ClienteSolicitaAberturaDeClientesUmaVez;
    [Test]
    procedure RelatorioSolicitaAberturaDoRelatorioUmaVez;
    [Test]
    procedure FalhaAoAbrirClientesExibeErroEMantemNavegacao;
    [Test]
    procedure FalhaAoAbrirRelatorioExibeErroEMantemNavegacao;
    [Test]
    procedure MensagemDeFalhaNaoRepassaTextoDaExcecao;
  end;

  [TestFixture]
  TTestesArquiteturaShell = class
  public
    [Test]
    procedure ControladorENavegacaoNaoDependemDeVclNemDevExpress;
    [Test]
    procedure FormPrincipalSoConheceSeuControlador;
    [Test]
    procedure FormPrincipalImplementaVisaoPrincipal;
  end;

implementation

uses
  System.IOUtils,
  System.RegularExpressions,
  System.Rtti,
  System.StrUtils,
  System.SysUtils,
  System.TypInfo,
  System.Types,
  Vcl.Forms,
  Aplicacao.NavegadorAplicacao,
  Visao.FormPrincipal,
  Suporte.CaminhosTeste;

procedure TTestesControladorPrincipal.Preparar;
begin
  FNavegadorObjeto := TNavegadorFake.Create;
  FNavegador := FNavegadorObjeto as INavegadorAplicacao;
  FVisaoObjeto := TVisaoPrincipalFake.Create;
  FVisao := FVisaoObjeto as IVisaoPrincipal;
  FControlador := TControladorPrincipal.Create(FVisaoObjeto, FNavegadorObjeto);
end;

procedure TTestesControladorPrincipal.Limpar;
begin
  FreeAndNil(FControlador);
  FNavegador := nil;
  FVisao := nil;
end;

procedure TTestesControladorPrincipal.SairSolicitaEncerramentoUmaVez;
begin
  FControlador.Executar(apSair);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasEncerrar);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasRelatorio);
end;

procedure TTestesControladorPrincipal.ClienteSolicitaAberturaDeClientesUmaVez;
begin
  FControlador.Executar(apCliente);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasRelatorio);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasEncerrar);
end;

procedure TTestesControladorPrincipal.RelatorioSolicitaAberturaDoRelatorioUmaVez;
begin
  FControlador.Executar(apRelatorio);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasRelatorio);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasEncerrar);
end;

procedure TTestesControladorPrincipal.FalhaAoAbrirClientesExibeErroEMantemNavegacao;
begin
  FNavegadorObjeto.FalharClientes := True;
  Assert.WillNotRaiseAny(
    procedure
    begin
      FControlador.Executar(apCliente);
    end);
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível abrir o cadastro de clientes.', FVisaoObjeto.Erros[0]);
  FControlador.Executar(apRelatorio);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasRelatorio);
end;

procedure TTestesControladorPrincipal.FalhaAoAbrirRelatorioExibeErroEMantemNavegacao;
begin
  FNavegadorObjeto.FalharRelatorio := True;
  Assert.WillNotRaiseAny(
    procedure
    begin
      FControlador.Executar(apRelatorio);
    end);
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível abrir o relatório de clientes.', FVisaoObjeto.Erros[0]);
  FControlador.Executar(apCliente);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasClientes);
end;

procedure TTestesControladorPrincipal.MensagemDeFalhaNaoRepassaTextoDaExcecao;
const
  TEXTO_SENSIVEL = 'SYSDBA masterkey Password=x';
  ESPERADAS: array[0..1] of string = ('Não foi possível abrir o cadastro de clientes.',
    'Não foi possível abrir o relatório de clientes.');
var
  I: Integer;
begin
  FNavegadorObjeto.MensagemExcecao := TEXTO_SENSIVEL;
  FNavegadorObjeto.FalharClientes := True;
  FNavegadorObjeto.FalharRelatorio := True;
  FControlador.Executar(apCliente);
  FControlador.Executar(apRelatorio);
  Assert.AreEqual(2, FVisaoObjeto.Erros.Count);
  for I := 0 to 1 do
  begin
    Assert.AreEqual(ESPERADAS[I], FVisaoObjeto.Erros[I]);
    Assert.IsFalse(FVisaoObjeto.Erros[I].Contains('SYSDBA'));
    Assert.IsFalse(FVisaoObjeto.Erros[I].Contains('masterkey'));
    Assert.IsFalse(FVisaoObjeto.Erros[I].Contains('Password='));
  end;
end;

function UnitsReferenciadas(const ACaminho: string): TArray<string>;
var
  LTexto: string;
  LClausula: TMatch;
  LItem: string;
  LNome: TMatch;
begin
  Result := [];
  LTexto := TFile.ReadAllText(ACaminho);
  LTexto := TRegEx.Replace(LTexto, '\{[^}]*\}|\(\*.*?\*\)|//[^\r\n]*', ' ', [roSingleLine]);
  LTexto := TRegEx.Replace(LTexto, '''[^'']*''', '''''');
  for LClausula in TRegEx.Matches(LTexto, '\buses\b(.*?);', [roIgnoreCase, roSingleLine]) do
    for LItem in LClausula.Groups[1].Value.Split([',']) do
    begin
      LNome := TRegEx.Match(LItem, '^\s*([\w.]+)');
      if LNome.Success then
        Result := Result + [LNome.Groups[1].Value];
    end;
end;

function ArquivoDaUnit(const AUnit: string): string;
var
  LArquivos: TStringDynArray;
begin
  LArquivos := TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), AUnit + '.pas',
    TSearchOption.soAllDirectories);
  Assert.AreEqual(1, Integer(Length(LArquivos)), 'Unit não encontrada em src: ' + AUnit);
  Result := LArquivos[0];
end;

function UnitsDeFormDoProjeto: TArray<string>;
var
  LArquivo: string;
begin
  Result := [];
  for LArquivo in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.dfm',
    TSearchOption.soAllDirectories) do
    Result := Result + [TPath.GetFileNameWithoutExtension(LArquivo)];
end;

function UnitsDeProducao: TArray<string>;
var
  LArquivo: string;
begin
  Result := [];
  for LArquivo in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.pas',
    TSearchOption.soAllDirectories) do
    Result := Result + [TPath.GetFileNameWithoutExtension(LArquivo)];
end;

function UnitDaInterface(ATipo: PTypeInfo): string;
var
  LContexto: TRttiContext;
begin
  Result := (LContexto.GetType(ATipo) as TRttiInterfaceType).DeclaringUnitName;
end;

procedure TTestesArquiteturaShell.ControladorENavegacaoNaoDependemDeVclNemDevExpress;
const
  PREFIXOS_PROIBIDOS: array[0..4] of string = ('Vcl.', 'dx', 'cx', 'FireDAC.', 'ppReport');
var
  LUnits: TArray<string>;
  LUnitsForm: TArray<string>;
  LUnit: string;
  LReferencia: string;
  LPrefixo: string;
  LNavegadorObjeto: TNavegadorFake;
  LNavegador: INavegadorAplicacao;
  LVisao: IVisaoPrincipal;
  LControlador: TControladorPrincipal;
  LFormsAntes: Integer;
begin
  LUnits := [TControladorPrincipal.UnitName, UnitDaInterface(TypeInfo(IVisaoPrincipal)),
    UnitDaInterface(TypeInfo(INavegadorAplicacao))];
  LUnitsForm := UnitsDeFormDoProjeto;
  for LUnit in LUnits do
    for LReferencia in UnitsReferenciadas(ArquivoDaUnit(LUnit)) do
    begin
      for LPrefixo in PREFIXOS_PROIBIDOS do
        Assert.IsFalse(StartsText(LPrefixo, LReferencia),
          LUnit + ' não pode referenciar ' + LReferencia);
      Assert.IsFalse(MatchText(LReferencia, LUnitsForm),
        LUnit + ' não pode referenciar a unit de form ' + LReferencia);
    end;

  LFormsAntes := Screen.FormCount;
  LNavegadorObjeto := TNavegadorFake.Create;
  LNavegador := LNavegadorObjeto;
  LVisao := TVisaoPrincipalFake.Create;
  LControlador := TControladorPrincipal.Create(LVisao, LNavegador);
  try
    LControlador.Executar(apSair);
    LControlador.Executar(apCliente);
    LControlador.Executar(apRelatorio);
  finally
    LControlador.Free;
  end;
  Assert.AreEqual(1, LNavegadorObjeto.ChamadasEncerrar);
  Assert.AreEqual(1, LNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(1, LNavegadorObjeto.ChamadasRelatorio);
  Assert.AreEqual(LFormsAntes, Screen.FormCount,
    'O controlador não pode criar forms.');
end;

procedure TTestesArquiteturaShell.FormPrincipalSoConheceSeuControlador;
const
  PREFIXOS_PROIBIDOS: array[0..3] of string = ('FireDAC.', 'Infraestrutura.', 'Migracao.',
    'Repositorio');
var
  LUnitForm: string;
  LUnitsForm: TArray<string>;
  LReferencia: string;
  LPrefixo: string;
  LContexto: TRttiContext;
  LCampo: TRttiField;
  LCamposControlador: Integer;
begin
  LUnitForm := TFormPrincipal.UnitName;
  LUnitsForm := UnitsDeFormDoProjeto;
  for LReferencia in UnitsReferenciadas(ArquivoDaUnit(LUnitForm)) do
  begin
    for LPrefixo in PREFIXOS_PROIBIDOS do
      Assert.IsFalse(StartsText(LPrefixo, LReferencia),
        LUnitForm + ' não pode referenciar ' + LReferencia);
    Assert.IsFalse(MatchText(LReferencia, LUnitsForm) and not SameText(LReferencia, LUnitForm),
      LUnitForm + ' não pode referenciar outra unit de form: ' + LReferencia);
  end;

  LCamposControlador := 0;
  for LCampo in LContexto.GetType(TFormPrincipal).GetDeclaredFields do
    if Assigned(LCampo.FieldType) and (LCampo.FieldType.Handle = TypeInfo(TControladorPrincipal)) then
      Inc(LCamposControlador);
  Assert.AreEqual(1, LCamposControlador,
    'TFormPrincipal deve declarar exatamente um campo TControladorPrincipal.');
end;

procedure TTestesArquiteturaShell.FormPrincipalImplementaVisaoPrincipal;
var
  LContexto: TRttiContext;
  LTipo: TRttiType;
  LUnitsProducao: TArray<string>;
  LImplementacoes: TArray<string>;
begin
  Assert.IsTrue(Supports(TFormPrincipal, IVisaoPrincipal),
    'TFormPrincipal deve implementar IVisaoPrincipal.');
  LUnitsProducao := UnitsDeProducao;
  LImplementacoes := [];
  for LTipo in LContexto.GetTypes do
    if (LTipo is TRttiInstanceType) and
       MatchText(TRttiInstanceType(LTipo).DeclaringUnitName, LUnitsProducao) and
       Assigned(TRttiInstanceType(LTipo).MetaclassType.GetInterfaceEntry(IVisaoPrincipal)) then
      LImplementacoes := LImplementacoes + [LTipo.Name];
  Assert.AreEqual(1, Integer(Length(LImplementacoes)),
    'Somente uma classe do projeto pode implementar IVisaoPrincipal: ' +
    String.Join(', ', LImplementacoes));
  Assert.AreEqual('TFormPrincipal', LImplementacoes[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesControladorPrincipal);
  TDUnitX.RegisterTestFixture(TTestesArquiteturaShell);

end.

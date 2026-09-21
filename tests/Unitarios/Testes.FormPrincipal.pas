unit Testes.FormPrincipal;

interface

uses
  DUnitX.TestFramework,
  Visao.FormPrincipal,
  Suporte.FakesShell;

type
  [TestFixture]
  TTestesFormPrincipal = class
  private
    FForm: TFormPrincipal;
    FNavegadorObjeto: TNavegadorFake;
    FNavegador: IInterface;
    FApresentadorObjeto: TApresentadorErroFake;
    FApresentador: IInterface;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure MenuPrincipalTemTresItensHorizontaisNaOrdem;
    [Test]
    procedure CadaMenuTemExatamenteOSubmenuExigido;
    [Test]
    procedure CadaSubmenuDelegaSomenteAoControlador;
    [Test]
    procedure TodosOsControlesSaoDevExpress;
    [Test]
    procedure TextosDoShellSaoOsDefinidos;
    [Test]
    procedure ArranjoCabecalhoCentroEStatus;
    [Test]
    procedure FalhaDeAberturaMostraErroEMantemShellUtilizavel;
  end;

  [TestFixture]
  TTestesApresentadorErro = class
  private
    FExibicoes: Integer;
    FTituloJanela: string;
    FMensagemExibida: string;
    procedure CapturarDialogoExibido(Sender: TObject; var ADone: Boolean);
  public
    [Test]
    procedure DialogoDeErroTemTituloCadCliEMostraAMensagem;
  end;

implementation

uses
  Winapi.Messages,
  Winapi.Windows,
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Menus,
  Vcl.StdCtrls,
  dxBar,
  Aplicacao.NavegadorAplicacao,
  Visao.ApresentadorErro,
  Suporte.CaminhosTeste,
  Suporte.ProcessoAplicacao;

function Legenda(const ACaption: string): string;
begin
  Result := StripHotkey(ACaption);
end;

function BarrasMenuPrincipal(AForm: TFormPrincipal): TArray<TdxBar>;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to AForm.GerenciadorBarras.Bars.Count - 1 do
    if AForm.GerenciadorBarras.Bars[I].IsMainMenu then
      Result := Result + [AForm.GerenciadorBarras.Bars[I]];
end;

function MenuPrincipal(AForm: TFormPrincipal): TdxBar;
var
  LBarras: TArray<TdxBar>;
begin
  LBarras := BarrasMenuPrincipal(AForm);
  Assert.AreEqual(1, Integer(Length(LBarras)), 'Deve existir exatamente uma barra de menu principal.');
  Result := LBarras[0];
end;

function SubItem(AMenu: TdxBar; AIndice: Integer): TdxBarSubItem;
begin
  Assert.IsTrue(AMenu.ItemLinks[AIndice].Item is TdxBarSubItem,
    'O item de menu deve ser um TdxBarSubItem.');
  Result := TdxBarSubItem(AMenu.ItemLinks[AIndice].Item);
end;

procedure TTestesFormPrincipal.Preparar;
begin
  FNavegadorObjeto := TNavegadorFake.Create;
  FNavegador := FNavegadorObjeto as INavegadorAplicacao;
  FApresentadorObjeto := TApresentadorErroFake.Create;
  FApresentador := FApresentadorObjeto as IApresentadorErro;
  FForm := TFormPrincipal.Create(nil);
  FForm.Conectar(FNavegadorObjeto, FApresentadorObjeto);
end;

procedure TTestesFormPrincipal.Limpar;
begin
  FreeAndNil(FForm);
  FNavegador := nil;
  FApresentador := nil;
end;

procedure TTestesFormPrincipal.MenuPrincipalTemTresItensHorizontaisNaOrdem;
const
  ESPERADAS: array[0..2] of string = ('Sistema', 'Cadastros', 'Relatórios');
var
  LMenu: TdxBar;
  I: Integer;
begin
  LMenu := MenuPrincipal(FForm);
  Assert.IsTrue(LMenu.DockingStyle = dsTop, 'A barra de menu deve estar ancorada no topo.');
  Assert.AreEqual(3, LMenu.ItemLinks.Count, 'O menu principal deve ter exatamente três itens.');
  for I := 0 to 2 do
    Assert.AreEqual(ESPERADAS[I], Legenda(SubItem(LMenu, I).Caption));
  FForm.Show;
  Application.ProcessMessages;
  for I := 1 to 2 do
  begin
    Assert.IsTrue(LMenu.ItemLinks[I].ItemRect.Left > LMenu.ItemLinks[I - 1].ItemRect.Left,
      'Os menus devem aparecer da esquerda para a direita na ordem exigida.');
    Assert.AreEqual(LMenu.ItemLinks[0].ItemRect.Top, LMenu.ItemLinks[I].ItemRect.Top,
      'Os menus devem estar na mesma linha horizontal.');
  end;
end;

procedure TTestesFormPrincipal.CadaMenuTemExatamenteOSubmenuExigido;
const
  ESPERADOS: array[0..2] of string = ('Sair', 'Cliente', 'Relatório');
var
  LMenu: TdxBar;
  LSubItem: TdxBarSubItem;
  I: Integer;
begin
  LMenu := MenuPrincipal(FForm);
  Assert.AreEqual(3, LMenu.ItemLinks.Count);
  for I := 0 to 2 do
  begin
    LSubItem := SubItem(LMenu, I);
    Assert.AreEqual(1, LSubItem.ItemLinks.Count,
      'O menu ' + Legenda(LSubItem.Caption) + ' deve ter exatamente um submenu.');
    Assert.AreEqual(ESPERADOS[I], Legenda(LSubItem.ItemLinks[0].Item.Caption));
  end;
end;

procedure TTestesFormPrincipal.CadaSubmenuDelegaSomenteAoControlador;
var
  LFormsComShell: Integer;
begin
  LFormsComShell := Screen.FormCount;
  FForm.ItemSair.Click;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasEncerrar);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasRelatorio);
  FForm.ItemCliente.Click;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasEncerrar);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasRelatorio);
  FForm.ItemRelatorio.Click;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasEncerrar);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasClientes);
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasRelatorio);
  Assert.AreEqual(LFormsComShell, Screen.FormCount,
    'Acionar os menus não pode criar nenhuma form além do shell.');
end;

function UnitDevExpress(AClasse: TClass): Boolean;
begin
  Result := StartsText('dx', AClasse.UnitName) or StartsText('cx', AClasse.UnitName);
end;

function UnitVclProibida(AClasse: TClass): Boolean;
begin
  Result := MatchText(AClasse.UnitName, ['Vcl.StdCtrls', 'Vcl.ExtCtrls', 'Vcl.ComCtrls', 'Vcl.Menus']);
end;

procedure VerificarControles(AControle: TWinControl; var AVerificados, AProibidos: Integer);
var
  I: Integer;
  LControle: TControl;
begin
  for I := 0 to AControle.ControlCount - 1 do
  begin
    LControle := AControle.Controls[I];
    Inc(AVerificados);
    if UnitVclProibida(LControle.ClassType) then
      Inc(AProibidos);
    Assert.IsTrue(UnitDevExpress(LControle.ClassType),
      LControle.ClassName + ' (' + LControle.ClassType.UnitName + ') não é um controle DevExpress.');
    if LControle is TWinControl then
      VerificarControles(TWinControl(LControle), AVerificados, AProibidos);
  end;
end;

procedure TTestesFormPrincipal.TodosOsControlesSaoDevExpress;
var
  I: Integer;
  LComponente: TComponent;
  LVerificados: Integer;
  LProibidos: Integer;
begin
  FForm.Show;
  Application.ProcessMessages;
  LVerificados := 0;
  LProibidos := 0;
  for I := 0 to FForm.ComponentCount - 1 do
  begin
    LComponente := FForm.Components[I];
    Inc(LVerificados);
    if UnitVclProibida(LComponente.ClassType) then
      Inc(LProibidos);
    Assert.IsTrue(UnitDevExpress(LComponente.ClassType),
      LComponente.ClassName + ' (' + LComponente.ClassType.UnitName + ') não é um componente DevExpress.');
  end;
  VerificarControles(FForm, LVerificados, LProibidos);
  Assert.AreEqual(0, LProibidos, 'A tela principal não pode conter controles VCL padrão.');
  Assert.IsTrue(LVerificados >= 11, 'A verificação deve alcançar os componentes da tela.');
end;

function FileVersionDoRunner: string;
type
  TTraducao = record
    Idioma: Word;
    PaginaCodigo: Word;
  end;
var
  LTamanho: DWORD;
  LDescarte: DWORD;
  LDados: TBytes;
  LTraducao: ^TTraducao;
  LValor: PChar;
  LComprimento: UINT;
begin
  LTamanho := GetFileVersionInfoSize(PChar(ParamStr(0)), LDescarte);
  Assert.IsTrue(LTamanho > 0, 'O runner de testes deve possuir recurso de versão.');
  SetLength(LDados, LTamanho);
  Assert.IsTrue(GetFileVersionInfo(PChar(ParamStr(0)), 0, LTamanho, LDados));
  Assert.IsTrue(VerQueryValue(LDados, '\VarFileInfo\Translation', Pointer(LTraducao), LComprimento));
  Assert.IsTrue(VerQueryValue(LDados, PChar(Format('\StringFileInfo\%.4x%.4x\FileVersion',
    [LTraducao.Idioma, LTraducao.PaginaCodigo])), Pointer(LValor), LComprimento));
  Result := Trim(LValor);
end;

procedure TTestesFormPrincipal.TextosDoShellSaoOsDefinidos;
var
  LVersao: string;
begin
  LVersao := FileVersionDoRunner;
  Assert.AreNotEqual('', LVersao);
  Assert.AreNotEqual('1.0.0.0', LVersao,
    'O runner precisa de um FileVersion diferente do CadCli.exe para esta prova.');
  Assert.AreEqual('CadCli', FForm.Caption);
  Assert.AreEqual('CadCli - Cadastro de Clientes', FForm.RotuloCabecalho.Caption);
  Assert.AreEqual('Bem-vindo! Use o menu para acessar o cadastro e o relatório de clientes.',
    FForm.RotuloBoasVindas.Caption);
  Assert.AreEqual(1, FForm.BarraStatus.Panels.Count);
  Assert.AreEqual('Versão ' + LVersao, FForm.BarraStatus.Panels[0].Text);
end;

procedure TTestesFormPrincipal.ArranjoCabecalhoCentroEStatus;
var
  LMenu: TdxBar;
begin
  LMenu := MenuPrincipal(FForm);
  Assert.IsTrue(LMenu.DockingStyle = dsTop, 'A barra de menu deve ficar no topo.');
  Assert.IsTrue(FForm.RotuloCabecalho.Align = alTop, 'O cabeçalho deve ter Align = alTop.');
  Assert.IsTrue(FForm.RotuloBoasVindas.Align = alClient, 'As boas-vindas devem ter Align = alClient.');
  Assert.IsTrue(FForm.BarraStatus.Align = alBottom, 'A barra de status deve ter Align = alBottom.');
  FForm.Show;
  Application.ProcessMessages;
  Assert.IsTrue(Assigned(LMenu.RealDockControl), 'A barra de menu deve estar ancorada.');
  Assert.IsTrue(LMenu.RealDockControl.Top + LMenu.RealDockControl.Height <= FForm.RotuloCabecalho.Top,
    Format('A barra de menu deve ficar acima do cabeçalho (menu %s %d+%d, cabeçalho %d).',
    [LMenu.RealDockControl.ClassName, LMenu.RealDockControl.Top, LMenu.RealDockControl.Height,
    FForm.RotuloCabecalho.Top]));
  Assert.IsTrue(FForm.RotuloCabecalho.Top < FForm.RotuloBoasVindas.Top,
    'O cabeçalho deve ficar acima das boas-vindas.');
  Assert.IsTrue(FForm.RotuloBoasVindas.Top < FForm.BarraStatus.Top,
    'As boas-vindas devem ficar acima da barra de status.');
end;

procedure TTestesFormPrincipal.FalhaDeAberturaMostraErroEMantemShellUtilizavel;
begin
  FNavegadorObjeto.FalharClientes := True;
  FForm.Show;
  Application.ProcessMessages;
  FForm.ItemCliente.Click;
  Assert.AreEqual(1, FApresentadorObjeto.Mensagens.Count, 'A falha deve ser apresentada uma vez.');
  Assert.AreEqual('Não foi possível abrir o cadastro de clientes.', FApresentadorObjeto.Mensagens[0]);
  Assert.IsTrue(FForm.Visible, 'O shell deve continuar visível.');
  Assert.IsTrue(IsWindowEnabled(FForm.Handle), 'O shell deve continuar habilitado.');
  FForm.ItemRelatorio.Click;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasRelatorio,
    'O shell deve continuar navegando depois da falha.');
end;

procedure TTestesApresentadorErro.DialogoDeErroTemTituloCadCliEMostraAMensagem;
const
  MENSAGEM = 'Não foi possível abrir o cadastro de clientes.';
  LIMITE_TENTATIVAS = 200;
var
  LDialogo: TForm;
  LRotulo: TComponent;
  LVigia: TThread;
  LApresentador: IApresentadorErro;
  LFormsAntes: Integer;
begin
  LDialogo := TApresentadorErroDialogo.CriarDialogo(MENSAGEM);
  try
    Assert.AreEqual('CadCli', LDialogo.Caption, 'O título do diálogo de erro deve estar em português.');
    LRotulo := LDialogo.FindComponent('Message');
    Assert.IsTrue(LRotulo is TLabel, 'O diálogo deve apresentar a mensagem em um rótulo.');
    Assert.AreEqual(MENSAGEM, TLabel(LRotulo).Caption);
  finally
    LDialogo.Free;
  end;

  LFormsAntes := Screen.FormCount;
  FExibicoes := 0;
  FTituloJanela := '';
  FMensagemExibida := '';
  LVigia := TThread.CreateAnonymousThread(
    procedure
    var
      LJanela: HWND;
      I: Integer;
    begin
      for I := 1 to LIMITE_TENTATIVAS do
      begin
        if FExibicoes > 0 then
          Exit;
        Sleep(50);
      end;
      LJanela := JanelaDoProcesso(GetCurrentProcessId, 'TMessageForm', True);
      if LJanela <> 0 then
        PostMessage(LJanela, WM_CLOSE, 0, 0);
    end);
  LVigia.FreeOnTerminate := False;
  Application.OnIdle := CapturarDialogoExibido;
  LVigia.Start;
  try
    LApresentador := TApresentadorErroDialogo.Create;
    LApresentador.ApresentarErro(MENSAGEM);
    LVigia.WaitFor;
  finally
    Application.OnIdle := nil;
    LVigia.Free;
  end;
  Assert.AreEqual(1, FExibicoes, 'O diálogo real deve ser exibido exatamente uma vez.');
  Assert.AreEqual('CadCli', FTituloJanela, 'O diálogo real deve ser exibido com o título CadCli.');
  Assert.AreEqual(MENSAGEM, FMensagemExibida,
    'O diálogo real deve exibir exatamente a mensagem recebida.');
  Assert.AreEqual(LFormsAntes, Screen.FormCount, 'O diálogo deve ser liberado ao fechar.');
end;

procedure TTestesApresentadorErro.CapturarDialogoExibido(Sender: TObject; var ADone: Boolean);
var
  I: Integer;
  LForm: TForm;
  LRotulo: TComponent;
begin
  if FExibicoes > 0 then
    Exit;
  for I := 0 to Screen.FormCount - 1 do
  begin
    LForm := Screen.Forms[I];
    if (LForm.ClassName = 'TMessageForm') and LForm.Visible and (fsModal in LForm.FormState) then
    begin
      FTituloJanela := TextoJanela(LForm.Handle);
      LRotulo := LForm.FindComponent('Message');
      if LRotulo is TLabel then
        FMensagemExibida := TLabel(LRotulo).Caption;
      Inc(FExibicoes);
      PostMessage(LForm.Handle, WM_CLOSE, 0, 0);
      Exit;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesFormPrincipal);
  TDUnitX.RegisterTestFixture(TTestesApresentadorErro);

end.

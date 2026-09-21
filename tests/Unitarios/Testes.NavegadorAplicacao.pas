unit Testes.NavegadorAplicacao;

interface

uses
  DUnitX.TestFramework,
  Vcl.Forms;

type
  [TestFixture]
  TTestesNavegadorAplicacao = class
  private
    FFormPrincipal: TForm;
    FPesquisasExibidas: Integer;
    FPesquisaModal: Boolean;
    FLinhasNaGrade: Integer;
    FDialogosInesperados: Integer;
    FFormsDuranteExibicao: Integer;
    procedure InspecionarPesquisa(Sender: TObject; var ADone: Boolean);
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure AbrirClientesExibeUmaInstanciaModalELibera;
    [Test]
    procedure AbrirRelatorioExibeUmaInstanciaModalELibera;
    [Test]
    procedure AcionamentosConsecutivosNuncaMantemDuasInstancias;
    [Test]
    procedure EncerrarAplicacaoFechaFormPrincipalComCodigoZero;
    [Test]
    procedure DestinoSemTelaRegistradaFalhaSemCriarForm;
    [Test]
    procedure ClientesAbrePesquisaRealSobreABase;
  end;

implementation

uses
  Winapi.Messages,
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.Math,
  System.SysUtils,
  Aplicacao.CatalogoMigracoes,
  Aplicacao.ControladorPrincipal,
  Aplicacao.NavegadorAplicacao,
  Infraestrutura.CatalogoPadraoMigracoes,
  Infraestrutura.InicializadorBancoFireDAC,
  Visao.ComposicaoAplicacao,
  Visao.FormPesquisaCliente,
  Visao.NavegadorAplicacao,
  Suporte.CaminhosTeste,
  Suporte.FakesFormPrincipal;

type
  TTelaDestinoTeste = class(TForm)
  private
    FSerie: Integer;
  protected
    procedure DoShow; override;
  public
    class var FormPrincipal: HWND;
    class var Criadas: Integer;
    class var Vivas: Integer;
    class var MaximoVivas: Integer;
    class var Exibicoes: Integer;
    class var FormPrincipalHabilitadoDuranteExibicao: Boolean;
    class var ModalDuranteExibicao: Boolean;
    class var SeriesExibidas: string;
    class procedure Reiniciar(AFormPrincipal: HWND);
    constructor Criar;
    destructor Destroy; override;
  end;

  TFormPrincipalTeste = class(TForm)
  protected
    procedure DoClose(var AAcao: TCloseAction); override;
  public
    Fechamentos: Integer;
  end;

class procedure TTelaDestinoTeste.Reiniciar(AFormPrincipal: HWND);
begin
  FormPrincipal := AFormPrincipal;
  Criadas := 0;
  Vivas := 0;
  MaximoVivas := 0;
  Exibicoes := 0;
  FormPrincipalHabilitadoDuranteExibicao := True;
  ModalDuranteExibicao := False;
  SeriesExibidas := '';
end;

constructor TTelaDestinoTeste.Criar;
begin
  inherited CreateNew(nil);
  Inc(Criadas);
  FSerie := Criadas;
  Inc(Vivas);
  MaximoVivas := Max(MaximoVivas, Vivas);
end;

destructor TTelaDestinoTeste.Destroy;
begin
  Dec(Vivas);
  inherited;
end;

procedure TTelaDestinoTeste.DoShow;
begin
  inherited;
  Inc(Exibicoes);
  FormPrincipalHabilitadoDuranteExibicao := IsWindowEnabled(FormPrincipal);
  ModalDuranteExibicao := fsModal in FormState;
  SeriesExibidas := SeriesExibidas + IntToStr(FSerie) + ';';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TFormPrincipalTeste.DoClose(var AAcao: TCloseAction);
begin
  Inc(Fechamentos);
  inherited;
end;

function CriarTelaDestino: TForm;
begin
  Result := TTelaDestinoTeste.Criar;
end;

procedure TTestesNavegadorAplicacao.Preparar;
begin
  FFormPrincipal := TFormPrincipalTeste.CreateNew(nil);
  FFormPrincipal.Show;
  TTelaDestinoTeste.Reiniciar(FFormPrincipal.Handle);
end;

procedure TTestesNavegadorAplicacao.Limpar;
begin
  FreeAndNil(FFormPrincipal);
end;

procedure TTestesNavegadorAplicacao.AbrirClientesExibeUmaInstanciaModalELibera;
var
  LNavegadorObjeto: TNavegadorAplicacao;
  LNavegador: INavegadorAplicacao;
  LFormsAntes: Integer;
begin
  LNavegadorObjeto := TNavegadorAplicacao.Create(FFormPrincipal);
  LNavegador := LNavegadorObjeto;
  LNavegadorObjeto.RegistrarTelaClientes(CriarTelaDestino);
  LFormsAntes := Screen.FormCount;
  LNavegador.AbrirClientes;
  Assert.AreEqual(1, TTelaDestinoTeste.Criadas, 'Deve ser criada exatamente uma tela.');
  Assert.AreEqual(1, TTelaDestinoTeste.Exibicoes, 'A tela deve ser exibida uma vez.');
  Assert.IsTrue(TTelaDestinoTeste.ModalDuranteExibicao, 'A tela deve ser exibida modalmente.');
  Assert.IsFalse(TTelaDestinoTeste.FormPrincipalHabilitadoDuranteExibicao,
    'A form principal deve ficar desabilitada durante a exibição modal.');
  Assert.AreEqual(0, TTelaDestinoTeste.Vivas, 'A tela deve ser destruída ao fechar.');
  Assert.AreEqual(LFormsAntes, Screen.FormCount);
end;

procedure TTestesNavegadorAplicacao.AbrirRelatorioExibeUmaInstanciaModalELibera;
var
  LNavegadorObjeto: TNavegadorAplicacao;
  LNavegador: INavegadorAplicacao;
  LFormsAntes: Integer;
begin
  LNavegadorObjeto := TNavegadorAplicacao.Create(FFormPrincipal);
  LNavegador := LNavegadorObjeto;
  LNavegadorObjeto.RegistrarTelaRelatorio(CriarTelaDestino);
  LFormsAntes := Screen.FormCount;
  LNavegador.AbrirRelatorio;
  Assert.AreEqual(1, TTelaDestinoTeste.Criadas, 'Deve ser criada exatamente uma tela.');
  Assert.AreEqual(1, TTelaDestinoTeste.Exibicoes, 'A tela deve ser exibida uma vez.');
  Assert.IsTrue(TTelaDestinoTeste.ModalDuranteExibicao, 'A tela deve ser exibida modalmente.');
  Assert.IsFalse(TTelaDestinoTeste.FormPrincipalHabilitadoDuranteExibicao,
    'A form principal deve ficar desabilitada durante a exibição modal.');
  Assert.AreEqual(0, TTelaDestinoTeste.Vivas, 'A tela deve ser destruída ao fechar.');
  Assert.AreEqual(LFormsAntes, Screen.FormCount);
end;

procedure TTestesNavegadorAplicacao.AcionamentosConsecutivosNuncaMantemDuasInstancias;
var
  LNavegadorObjeto: TNavegadorAplicacao;
  LNavegador: INavegadorAplicacao;
begin
  LNavegadorObjeto := TNavegadorAplicacao.Create(FFormPrincipal);
  LNavegador := LNavegadorObjeto;
  LNavegadorObjeto.RegistrarTelaClientes(CriarTelaDestino);
  LNavegador.AbrirClientes;
  LNavegador.AbrirClientes;
  Assert.AreEqual(2, TTelaDestinoTeste.Criadas, 'Cada acionamento cria uma nova instância.');
  Assert.AreEqual('1;2;', TTelaDestinoTeste.SeriesExibidas,
    'As duas exibições devem ser de instâncias distintas, em sequência.');
  Assert.AreEqual(1, TTelaDestinoTeste.MaximoVivas,
    'Nunca pode haver duas instâncias vivas ao mesmo tempo.');
  Assert.AreEqual(0, TTelaDestinoTeste.Vivas);
end;

procedure TTestesNavegadorAplicacao.EncerrarAplicacaoFechaFormPrincipalComCodigoZero;
var
  LNavegador: INavegadorAplicacao;
  LCodigoAnterior: Integer;
begin
  LCodigoAnterior := ExitCode;
  try
    ExitCode := 7;
    LNavegador := TNavegadorAplicacao.Create(FFormPrincipal);
    LNavegador.EncerrarAplicacao;
    Assert.AreEqual(1, TFormPrincipalTeste(FFormPrincipal).Fechamentos, 'A form principal entregue deve ser fechada.');
    Assert.IsFalse(FFormPrincipal.Visible, 'A form principal deve deixar de estar visível.');
    Assert.AreEqual(0, ExitCode, 'O encerramento deve deixar código de saída 0.');
  finally
    ExitCode := LCodigoAnterior;
  end;
end;

procedure TTestesNavegadorAplicacao.DestinoSemTelaRegistradaFalhaSemCriarForm;
var
  LNavegador: INavegadorAplicacao;
  LVisaoObjeto: TVisaoPrincipalFake;
  LVisao: IVisaoPrincipal;
  LControlador: TControladorPrincipal;
  LFormsAntes: Integer;
begin
  LNavegador := ComporNavegador(FFormPrincipal, nil);
  LFormsAntes := Screen.FormCount;
  Assert.WillRaise(
    procedure
    begin
      LNavegador.AbrirRelatorio;
    end, ENavegacaoSemTela);
  Assert.AreEqual(LFormsAntes, Screen.FormCount, 'Nenhuma form pode ser criada.');

  LVisaoObjeto := TVisaoPrincipalFake.Create;
  LVisao := LVisaoObjeto;
  LControlador := TControladorPrincipal.Create(LVisao, LNavegador);
  try
    LControlador.Executar(apRelatorio);
  finally
    LControlador.Free;
  end;
  Assert.AreEqual(1, LVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível abrir o relatório de clientes.', LVisaoObjeto.Erros[0]);
  Assert.AreEqual(LFormsAntes, Screen.FormCount, 'Nenhuma form pode ser criada.');
end;

procedure TTestesNavegadorAplicacao.InspecionarPesquisa(Sender: TObject; var ADone: Boolean);
var
  I: Integer;
  LForm: TForm;
begin
  for I := 0 to Screen.FormCount - 1 do
  begin
    LForm := Screen.Forms[I];
    if not LForm.Visible then
      Continue;
    if LForm is TFormPesquisaCliente then
    begin
      Inc(FPesquisasExibidas);
      FPesquisaModal := fsModal in LForm.FormState;
      FLinhasNaGrade := TFormPesquisaCliente(LForm).ListaClientes.Items.Count;
      FFormsDuranteExibicao := Screen.FormCount;
      PostMessage(LForm.Handle, WM_CLOSE, 0, 0);
      Exit;
    end;
    if LForm.ClassName = 'TMessageForm' then
    begin
      Inc(FDialogosInesperados);
      PostMessage(LForm.Handle, WM_CLOSE, 0, 0);
      Exit;
    end;
  end;
end;

procedure TTestesNavegadorAplicacao.ClientesAbrePesquisaRealSobreABase;
var
  LDiretorio: string;
  LCatalogo: TCatalogoMigracoes;
  LBanco: TInicializadorBanco;
  LMensagem: string;
  LNavegador: INavegadorAplicacao;
  LFormsAntes: Integer;
begin
  LDiretorio := CriarDiretorioTemporario;
  LCatalogo := CriarCatalogoPadrao;
  LBanco := TInicializadorBanco.Create(TPath.Combine(LDiretorio, 'cadcli.fdb'), LCatalogo);
  try
    Assert.IsTrue(LBanco.Preparar(LMensagem), LMensagem);
    LNavegador := ComporNavegador(FFormPrincipal, LBanco.Conexao);
    LFormsAntes := Screen.FormCount;
    FPesquisasExibidas := 0;
    FDialogosInesperados := 0;
    FLinhasNaGrade := -1;
    Application.OnIdle := InspecionarPesquisa;
    try
      LNavegador.AbrirClientes;
    finally
      Application.OnIdle := nil;
    end;
    Assert.AreEqual(0, FDialogosInesperados, 'Nenhum diálogo de erro pode aparecer.');
    Assert.AreEqual(1, FPesquisasExibidas, 'Deve ser exibida exatamente 1 TFormPesquisaCliente.');
    Assert.IsTrue(FPesquisaModal, 'A pesquisa deve ser exibida modalmente.');
    Assert.AreEqual(LFormsAntes + 1, FFormsDuranteExibicao, 'Somente a pesquisa pode ser criada.');
    Assert.AreEqual(0, FLinhasNaGrade, 'A pesquisa deve listar os 0 clientes da base.');
    Assert.AreEqual(LFormsAntes, Screen.FormCount, 'A pesquisa deve ser liberada ao fechar.');
    LNavegador := nil;
  finally
    LBanco.Free;
    LCatalogo.Free;
    TDirectory.Delete(LDiretorio, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesNavegadorAplicacao);

end.

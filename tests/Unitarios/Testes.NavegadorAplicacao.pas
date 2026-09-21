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
  end;

implementation

uses
  Winapi.Messages,
  Winapi.Windows,
  System.Classes,
  System.Math,
  System.SysUtils,
  Aplicacao.ControladorPrincipal,
  Aplicacao.NavegadorAplicacao,
  Visao.ComposicaoAplicacao,
  Visao.NavegadorAplicacao,
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
  LNavegador := ComporNavegador(FFormPrincipal);
  LFormsAntes := Screen.FormCount;
  Assert.WillRaiseAny(
    procedure
    begin
      LNavegador.AbrirClientes;
    end);
  Assert.WillRaiseAny(
    procedure
    begin
      LNavegador.AbrirRelatorio;
    end);
  Assert.AreEqual(LFormsAntes, Screen.FormCount, 'Nenhuma form pode ser criada.');

  LVisaoObjeto := TVisaoPrincipalFake.Create;
  LVisao := LVisaoObjeto;
  LControlador := TControladorPrincipal.Create(LVisao, LNavegador);
  try
    LControlador.Executar(apCliente);
    LControlador.Executar(apRelatorio);
  finally
    LControlador.Free;
  end;
  Assert.AreEqual(2, LVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível abrir o cadastro de clientes.', LVisaoObjeto.Erros[0]);
  Assert.AreEqual('Não foi possível abrir o relatório de clientes.', LVisaoObjeto.Erros[1]);
  Assert.AreEqual(LFormsAntes, Screen.FormCount, 'Nenhuma form pode ser criada.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesNavegadorAplicacao);

end.

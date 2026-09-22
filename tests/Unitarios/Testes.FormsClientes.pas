unit Testes.FormsClientes;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  Visao.FormCadastroCliente,
  Visao.FormPesquisaCliente,
  Suporte.FakesClientes,
  Suporte.FakesFormPrincipal;

type
  [TestFixture]
  TTestesFormPesquisaCliente = class
  private
    FForm: TFormPesquisaCliente;
    FRepositorioObjeto: TRepositorioClienteFake;
    FRepositorio: IInterface;
    FNavegadorObjeto: TNavegadorClientesFake;
    FNavegador: IInterface;
    FConfirmacao: IInterface;
    FApresentadorObjeto: TApresentadorErroFake;
    FApresentador: IInterface;
    FTransacao: IInterface;
    procedure Criar;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure RotuloDeLimiteAbaixoDaListaEmFonteMenor;
    [Test]
    procedure PesquisarEnterELimparConsultamORepositorioComOFiltroDaTela;
    [Test]
    procedure ListaExibeClientesNaOrdemDevolvida;
    [Test]
    procedure LimparVoltaOrdenacaoParaNomeCrescente;
    [Test]
    procedure CliqueNoCabecalhoOrdenaEMarcaASetaDaColuna;
    [Test]
    procedure AberturaMarcaNomeCrescenteECabecalhosClicaveis;
    [Test]
    procedure CamposPadraoSaoIdENome;
    [Test]
    procedure EnterNosFiltrosAcionaAPesquisa;
    [Test]
    procedure LimparRestauraFiltrosEPesquisaSemFiltro;
    [Test]
    procedure FalhaNaCargaMantemFiltrosEEsvaziaGrade;
    [Test]
    procedure TextosDaPesquisaSaoOsDefinidos;
    [Test]
    procedure ArranjoFiltrosGradeEAcoes;
  end;

  [TestFixture]
  TTestesFormCadastroCliente = class
  private
    FForm: TFormCadastroCliente;
    FRepositorioObjeto: TRepositorioClienteFake;
    FRepositorio: IInterface;
    FConfirmacaoObjeto: TConfirmacaoFake;
    FConfirmacao: IInterface;
    FApresentadorObjeto: TApresentadorErroFake;
    FApresentador: IInterface;
    FTransacao: IInterface;
    FViaCep: IInterface;
    FRelogio: IInterface;
    procedure Criar;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure FecharComAlteracoesPassaPelaConfirmacaoDoControlador;
    [Test]
    procedure EnterAvancaNaOrdemDeTabulacaoAteSalvar;
    [Test]
    procedure TextosDoCadastroSaoOsDefinidos;
    [Test]
    procedure ArranjoCamposEBotoes;
    [Test]
    procedure EditoresRespeitamOTamanhoDasColunas;
    [Test]
    procedure CepEUfDaTelaAcionamOControlador;
  end;

  TAcaoCadastro = (acSalvar, acCancelar);

  [TestFixture]
  TTestesNavegadorClientes = class
  private
    FAcao: TAcaoCadastro;
    FExibicoes: Integer;
    FModal: Boolean;
    FTitulo: string;
    procedure ConduzirCadastro(Sender: TObject; var ADone: Boolean);
  public
    [Test]
    procedure AbreCadastroModalNoModoEDevolveSeSalvou;
  end;

  [TestFixture]
  TTestesArquiteturaClientes = class
  public
    [Test]
    procedure FormsDeClientesSoUsamControlesDevExpress;
    [Test]
    procedure ControladorDeCadastroSoConheceTEnderecoViaCep;
    [Test]
    procedure CadaFormTemSeuControladorESemInfraestrutura;
    [Test]
    procedure PesquisaSoPeloRepositorioSemFiltroEmMemoria;
  end;

implementation

uses
  Winapi.Messages,
  Winapi.Windows,
  System.Generics.Collections,
  System.IOUtils,
  System.RegularExpressions,
  System.Rtti,
  System.StrUtils,
  System.SysUtils,
  System.TypInfo,
  System.Types,
  System.UITypes,
  Vcl.Controls,
  Vcl.Forms,
  cxButtons,
  cxCheckComboBox,
  cxDateUtils,
  cxDropDownEdit,
  cxEdit,
  cxHeader,
  cxLabel,
  cxLookAndFeelPainters,
  cxTextEdit,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Dominio.UnidadesFederativas,
  dxCore,
  Aplicacao.ControladorCadastroCliente,
  Aplicacao.ControladorPesquisaCliente,
  Aplicacao.NavegadorClientes,
  Aplicacao.ServicoViaCep,
  Visao.ApresentadorErro,
  Visao.NavegadorClientes,
  Suporte.CaminhosTeste;

function IdsDaLista(AForm: TFormPesquisaCliente): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to AForm.ListaClientes.Items.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + AForm.ListaClientes.Items[I].Split([AForm.ListaClientes.Delimiter])[0];
  end;
end;

procedure MarcarSomente(AForm: TFormPesquisaCliente; ACampos: TCamposPesquisa);
var
  LCampo: TCampoPesquisa;
begin
  for LCampo := Low(TCampoPesquisa) to High(TCampoPesquisa) do
    if LCampo in ACampos then
      AForm.ComboCampos.States[Ord(LCampo)] := cbsChecked
    else
      AForm.ComboCampos.States[Ord(LCampo)] := cbsUnchecked;
end;

function CamposDoCombo(AForm: TFormPesquisaCliente): TCamposPesquisa;
var
  LCampo: TCampoPesquisa;
begin
  Result := [];
  for LCampo := Low(TCampoPesquisa) to High(TCampoPesquisa) do
    if AForm.ComboCampos.States[Ord(LCampo)] = cbsChecked then
      Include(Result, LCampo);
end;

function TextosDaClasse(AForm: TForm; AClasse: TClass): TArray<string>;
var
  I: Integer;
  LComponente: TComponent;
begin
  Result := [];
  for I := 0 to AForm.ComponentCount - 1 do
  begin
    LComponente := AForm.Components[I];
    if not (LComponente is AClasse) then
      Continue;
    if LComponente is TcxLabel then
      Result := Result + [TcxLabel(LComponente).Caption]
    else if LComponente is TcxButton then
      Result := Result + [TcxButton(LComponente).Caption];
  end;
  TArray.Sort<string>(Result);
end;

function Ordenados(const AValores: array of string): string;
var
  LLista: TArray<string>;
  I: Integer;
begin
  SetLength(LLista, Length(AValores));
  for I := 0 to High(AValores) do
    LLista[I] := AValores[I];
  TArray.Sort<string>(LLista);
  Result := string.Join('|', LLista);
end;

procedure TTestesFormPesquisaCliente.Preparar;
begin
  FRepositorioObjeto := TRepositorioClienteFake.Create;
  FRepositorio := FRepositorioObjeto as IInterface;
  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FNavegadorObjeto := TNavegadorClientesFake.Create;
  FNavegador := FNavegadorObjeto as IInterface;
  FConfirmacao := TConfirmacaoFake.Create as IInterface;
  FApresentadorObjeto := TApresentadorErroFake.Create;
  FApresentador := FApresentadorObjeto as IApresentadorErro;
  FTransacao := TTransacaoFake.Create as IInterface;
end;

procedure TTestesFormPesquisaCliente.Criar;
begin
  FForm := TFormPesquisaCliente.Create(nil);
  FForm.Conectar(FRepositorioObjeto, TTransacaoFake(FTransacao as TObject), FNavegadorObjeto,
    TConfirmacaoFake(FConfirmacao as TObject), FApresentadorObjeto);
  FForm.Show;
  Application.ProcessMessages;
end;

procedure TTestesFormPesquisaCliente.Limpar;
begin
  FreeAndNil(FForm);
  FRepositorio := nil;
  FNavegador := nil;
  FConfirmacao := nil;
  FApresentador := nil;
  FTransacao := nil;
end;

procedure ClicarSecao(AForm: TFormPesquisaCliente; AIndice: Integer);
var
  LCabecalho: TWinControl;
  LSecao: TcxHeaderSection;
  LCentro: TPoint;
  LTela: TPoint;
  LPonto: LPARAM;
begin
  LCabecalho := AForm.ListaClientes.HeaderSections[AIndice].HeaderControl;
  LSecao := AForm.ListaClientes.HeaderSections[AIndice];
  LCentro := Point((LSecao.Left + LSecao.Right) div 2, LCabecalho.Height div 2);
  LTela := LCabecalho.ClientToScreen(LCentro);
  SetCursorPos(LTela.X, LTela.Y);
  LPonto := MakeLParam(LCentro.X, LCentro.Y);
  SendMessage(LCabecalho.Handle, WM_MOUSEMOVE, 0, LPonto);
  SendMessage(LCabecalho.Handle, WM_LBUTTONDOWN, MK_LBUTTON, LPonto);
  SendMessage(LCabecalho.Handle, WM_LBUTTONUP, 0, LPonto);
  Application.ProcessMessages;
end;

function Setas(AForm: TFormPesquisaCliente): string;
const
  NOMES: array[TcxHeaderSortOrder] of string = ('-', 'asc', 'desc');
var
  I: Integer;
begin
  Result := '';
  for I := 0 to AForm.ListaClientes.HeaderSections.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + NOMES[AForm.ListaClientes.HeaderSections[I].SortOrder];
  end;
end;

function SetasSomente(AIndice: Integer; const ASeta: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to 7 do
  begin
    if Result <> '' then
      Result := Result + ',';
    if I = AIndice then
      Result := Result + ASeta
    else
      Result := Result + '-';
  end;
end;

procedure TTestesFormPesquisaCliente.RotuloDeLimiteAbaixoDaListaEmFonteMenor;
begin
  FRepositorioObjeto.Clientes := [];
  Criar;
  Assert.AreEqual('TcxLabel', FForm.RotuloLimite.ClassName);
  Assert.AreEqual('A pesquisa lista no máximo 50 clientes.', FForm.RotuloLimite.Caption);
  Assert.IsTrue(FForm.RotuloLimite.Style.Font.Size < FForm.Font.Size,
    'A fonte do rótulo deve ser menor que a da form.');
  Assert.AreEqual(0, FForm.ListaClientes.Items.Count);
  Assert.IsTrue(FForm.RotuloLimite.Visible and FForm.RotuloLimite.Showing, 'Visível sem resultados.');

  FRepositorioObjeto.Clientes := [ClientesDaFixture[0], ClientesDaFixture[1], ClientesDaFixture[2]];
  FForm.BotaoPesquisar.Click;
  Assert.AreEqual(3, FForm.ListaClientes.Items.Count);
  Assert.IsTrue(FForm.RotuloLimite.Visible and FForm.RotuloLimite.Showing, 'Visível com resultados.');

  Assert.IsTrue(FForm.ListaClientes.Top + FForm.ListaClientes.Height <= FForm.RotuloLimite.Top,
    'O rótulo fica abaixo da lista.');
  Assert.IsTrue(FForm.RotuloLimite.Top + FForm.RotuloLimite.Height <= FForm.BarraAcoes.Top,
    'O rótulo fica acima da barra de ações.');
end;

procedure TTestesFormPesquisaCliente.PesquisarEnterELimparConsultamORepositorioComOFiltroDaTela;
var
  LChamadas: Integer;
  LTecla: Char;
  LCampo: TCampoPesquisa;

  procedure AssegurarFiltroDaTela(const AAcao: string);
  begin
    Assert.AreEqual(LChamadas + 1, FRepositorioObjeto.ChamadasPesquisar, AAcao + ' gera 1 chamada.');
    Assert.AreEqual('silva', FRepositorioObjeto.UltimoFiltro.Texto, AAcao);
    Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [cpNome, cpCidade], AAcao);
    Assert.AreEqual('15/03/1990', FRepositorioObjeto.UltimoFiltro.DataNascimento, AAcao);
    Assert.AreEqual(50, FRepositorioObjeto.Limites[High(FRepositorioObjeto.Limites)], AAcao);
  end;

begin
  Criar;
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasPesquisar, 'A abertura pesquisa uma vez.');
  FForm.EditorPesquisa.Text := 'silva';
  MarcarSomente(FForm, [cpNome, cpCidade]);
  FForm.EditorDataNascimento.Date := EncodeDate(1990, 3, 15);

  LChamadas := FRepositorioObjeto.ChamadasPesquisar;
  FForm.BotaoPesquisar.Click;
  AssegurarFiltroDaTela('Pesquisar');

  LChamadas := FRepositorioObjeto.ChamadasPesquisar;
  LTecla := #13;
  FForm.EditorPesquisa.OnKeyPress(FForm.EditorPesquisa, LTecla);
  AssegurarFiltroDaTela('Enter');

  LChamadas := FRepositorioObjeto.ChamadasPesquisar;
  FForm.BotaoLimpar.Click;
  Assert.AreEqual(LChamadas + 1, FRepositorioObjeto.ChamadasPesquisar, 'Limpar gera 1 chamada.');
  Assert.AreEqual('', FRepositorioObjeto.UltimoFiltro.Texto);
  Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [cpId, cpNome]);
  Assert.AreEqual('', FRepositorioObjeto.UltimoFiltro.DataNascimento);

  for LCampo := Low(TCampoPesquisa) to High(TCampoPesquisa) do
  begin
    MarcarSomente(FForm, [LCampo]);
    FForm.BotaoPesquisar.Click;
    Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [LCampo],
      'O item ' + IntToStr(Ord(LCampo)) + ' do combo vira o campo de mesmo índice.');
  end;
end;

procedure TTestesFormPesquisaCliente.ListaExibeClientesNaOrdemDevolvida;
begin
  FRepositorioObjeto.Clientes := [
    NovoCliente(8, 'Oito', '52998224725', '30130000', 'Contagem', 'MG', 'Minas Gerais', EncodeDate(1980, 1, 8)),
    NovoCliente(1, 'Um', '52998224725', '30130000', 'Contagem', 'MG', 'Minas Gerais', EncodeDate(1980, 1, 1)),
    NovoCliente(5, 'Cinco', '52998224725', '30130000', 'Contagem', 'MG', 'Minas Gerais', EncodeDate(1980, 1, 5))];
  Criar;
  Assert.AreEqual(3, FForm.ListaClientes.Items.Count);
  Assert.AreEqual('8,1,5', IdsDaLista(FForm), 'As linhas seguem a ordem devolvida.');
  FForm.ListaClientes.ItemIndex := 1;
  Assert.AreEqual(1, FForm.IdSelecionado, 'A segunda linha é o ID 1.');
end;

procedure TTestesFormPesquisaCliente.LimparVoltaOrdenacaoParaNomeCrescente;
begin
  Criar;
  ClicarSecao(FForm, Ord(coCidade));
  ClicarSecao(FForm, Ord(coCidade));
  Assert.AreEqual(SetasSomente(Ord(coCidade), 'desc'), Setas(FForm));
  FForm.BotaoLimpar.Click;
  Assert.AreEqual(SetasSomente(Ord(coNome), 'asc'), Setas(FForm),
    'Limpar deixa Nome crescente e Cidade sem seta.');
end;

procedure TTestesFormPesquisaCliente.CliqueNoCabecalhoOrdenaEMarcaASetaDaColuna;
var
  LCampo: TCampoOrdenacao;
  LChamadas: Integer;
  LPrimeira: string;
  LSegunda: string;
  LVerificados: Integer;
begin
  LVerificados := 0;
  for LCampo := Low(TCampoOrdenacao) to High(TCampoOrdenacao) do
  begin
    FRepositorio := nil;
    FRepositorioObjeto := TRepositorioClienteFake.Create;
    FRepositorio := FRepositorioObjeto as IInterface;
    FRepositorioObjeto.Clientes := ClientesDaFixture;
    Criar;
    if LCampo = coNome then
    begin
      LPrimeira := 'desc';
      LSegunda := 'asc';
    end
    else
    begin
      LPrimeira := 'asc';
      LSegunda := 'desc';
    end;

    LChamadas := FRepositorioObjeto.ChamadasPesquisar;
    ClicarSecao(FForm, Ord(LCampo));
    Assert.AreEqual(LChamadas + 1, FRepositorioObjeto.ChamadasPesquisar,
      'Um clique gera 1 chamada: seção ' + IntToStr(Ord(LCampo)));
    Assert.IsTrue(FRepositorioObjeto.UltimaOrdenacao.Campo = LCampo,
      'A seção ' + IntToStr(Ord(LCampo)) + ' ordena pela coluna de mesmo índice.');
    Assert.AreEqual(LPrimeira = 'desc', FRepositorioObjeto.UltimaOrdenacao.Descendente);
    Assert.AreEqual(SetasSomente(Ord(LCampo), LPrimeira), Setas(FForm),
      'Seta após o primeiro clique na seção ' + IntToStr(Ord(LCampo)));

    ClicarSecao(FForm, Ord(LCampo));
    Assert.AreEqual(LChamadas + 2, FRepositorioObjeto.ChamadasPesquisar,
      'O segundo clique gera 1 chamada: seção ' + IntToStr(Ord(LCampo)));
    Assert.IsTrue(FRepositorioObjeto.UltimaOrdenacao.Campo = LCampo);
    Assert.AreEqual(LSegunda = 'desc', FRepositorioObjeto.UltimaOrdenacao.Descendente);
    Assert.AreEqual(SetasSomente(Ord(LCampo), LSegunda), Setas(FForm),
      'Seta após o segundo clique na seção ' + IntToStr(Ord(LCampo)));
    Assert.AreEqual('1,10,15,150,23', IdsDaLista(FForm), 'A lista não reordena as linhas sozinha.');
    FreeAndNil(FForm);
    Inc(LVerificados);
  end;
  Assert.AreEqual(8, LVerificados);
end;

procedure TTestesFormPesquisaCliente.AberturaMarcaNomeCrescenteECabecalhosClicaveis;
var
  I: Integer;
begin
  Criar;
  Assert.AreEqual('TcxMCListBox', FForm.ListaClientes.ClassName, 'A lista deve ser um TcxMCListBox.');
  Assert.AreEqual(8, FForm.ListaClientes.HeaderSections.Count);
  Assert.AreEqual(SetasSomente(Ord(coNome), 'asc'), Setas(FForm), 'Nome crescente ao abrir.');
  for I := 0 to FForm.ListaClientes.HeaderSections.Count - 1 do
    Assert.IsTrue(FForm.ListaClientes.HeaderSections[I].AllowClick,
      'Toda seção do cabeçalho é clicável: ' + IntToStr(I));
  Assert.IsFalse(FForm.ListaClientes.Sorted, 'A lista não pode reordenar as linhas.');
  for I := 0 to FForm.ComponentCount - 1 do
    Assert.IsFalse(ContainsText(FForm.Components[I].ClassName, 'Grid'),
      'A form não pode conter grade: ' + FForm.Components[I].ClassName);
end;

procedure TTestesFormPesquisaCliente.CamposPadraoSaoIdENome;
begin
  Criar;
  Assert.AreEqual(6, FForm.ComboCampos.Properties.Items.Count);
  Assert.IsTrue(CamposDoCombo(FForm) = [cpId, cpNome], 'Ao abrir, só ID e Nome ficam marcados.');
  FForm.EditorPesquisa.Text := 'campinas';
  FForm.BotaoPesquisar.Click;
  Assert.AreEqual('campinas', FRepositorioObjeto.UltimoFiltro.Texto);
  Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [cpId, cpNome],
    'Com o padrão, a cidade não entra na pesquisa.');
end;

procedure TTestesFormPesquisaCliente.EnterNosFiltrosAcionaAPesquisa;
var
  LTecla: Char;
  LChamadas: Integer;
begin
  Criar;
  Assert.IsTrue(Assigned(FForm.EditorPesquisa.OnKeyPress), 'O texto da pesquisa deve tratar o Enter.');
  Assert.IsTrue(Assigned(FForm.ComboCampos.OnKeyPress), 'O combo de campos deve tratar o Enter.');
  Assert.IsTrue(Assigned(FForm.EditorDataNascimento.OnKeyPress), 'A data deve tratar o Enter.');

  FForm.EditorPesquisa.Text := 'silva';
  LChamadas := FRepositorioObjeto.ChamadasPesquisar;
  LTecla := 'a';
  FForm.EditorPesquisa.OnKeyPress(FForm.EditorPesquisa, LTecla);
  Assert.AreEqual(LChamadas, FRepositorioObjeto.ChamadasPesquisar, 'Outra tecla não pode pesquisar.');
  Assert.AreEqual('a', LTecla);

  LTecla := #13;
  FForm.EditorPesquisa.OnKeyPress(FForm.EditorPesquisa, LTecla);
  Assert.AreEqual(LChamadas + 1, FRepositorioObjeto.ChamadasPesquisar, 'Enter deve acionar a pesquisa.');
  Assert.AreEqual('silva', FRepositorioObjeto.UltimoFiltro.Texto);
  Assert.AreEqual(#0, LTecla, 'O Enter deve ser consumido.');
end;

procedure TTestesFormPesquisaCliente.LimparRestauraFiltrosEPesquisaSemFiltro;
var
  LChamadas: Integer;
begin
  Criar;
  FForm.EditorPesquisa.Text := 'campinas';
  MarcarSomente(FForm, [cpCidade]);
  FForm.EditorDataNascimento.Date := EncodeDate(2000, 11, 30);
  FForm.BotaoPesquisar.Click;
  Assert.AreEqual('campinas', FRepositorioObjeto.UltimoFiltro.Texto);

  LChamadas := FRepositorioObjeto.ChamadasPesquisar;
  FForm.BotaoLimpar.Click;
  Assert.AreEqual('', FForm.EditorPesquisa.Text);
  Assert.IsTrue(CamposDoCombo(FForm) = [cpId, cpNome], 'Limpar volta aos campos padrão.');
  Assert.AreEqual(Double(NullDate), Double(FForm.EditorDataNascimento.Date));
  Assert.AreEqual(LChamadas + 1, FRepositorioObjeto.ChamadasPesquisar, 'Limpar pesquisa de novo.');
  Assert.AreEqual('', FRepositorioObjeto.UltimoFiltro.Texto, 'Limpar pesquisa sem texto.');
  Assert.AreEqual('', FRepositorioObjeto.UltimoFiltro.DataNascimento, 'Limpar pesquisa sem data.');
end;

procedure TTestesFormPesquisaCliente.FalhaNaCargaMantemFiltrosEEsvaziaGrade;
begin
  FRepositorioObjeto.FalharPesquisarAPartirDe := 2;
  Criar;
  Assert.AreEqual(5, FForm.ListaClientes.Items.Count);
  FForm.EditorPesquisa.Text := 'silva';
  MarcarSomente(FForm, [cpCidade]);
  FForm.EditorDataNascimento.Date := EncodeDate(1990, 3, 15);
  FForm.BotaoPesquisar.Click;
  Assert.AreEqual(1, FApresentadorObjeto.Mensagens.Count, 'O erro deve ser apresentado exatamente 1 vez.');
  Assert.AreEqual('Não foi possível carregar os clientes.', FApresentadorObjeto.Mensagens[0]);
  Assert.AreEqual(0, FForm.ListaClientes.Items.Count, 'A lista deve ficar com 0 linhas.');
  Assert.AreEqual('silva', FForm.EditorPesquisa.Text);
  Assert.IsTrue(CamposDoCombo(FForm) = [cpCidade], 'Somente Cidade continua marcado.');
  Assert.AreEqual(Double(EncodeDate(1990, 3, 15)), Double(FForm.EditorDataNascimento.Date));
end;

procedure TTestesFormPesquisaCliente.TextosDaPesquisaSaoOsDefinidos;
const
  COLUNAS: array[0..7] of string = ('ID', 'Nome', 'CPF/CNPJ', 'CEP', 'Cidade', 'UF', 'Estado',
    'Data de nascimento');
  CAMPOS: array[0..5] of string = ('ID', 'Nome', 'CPF/CNPJ', 'CEP', 'Cidade', 'Estado');
var
  I: Integer;
begin
  Criar;
  Assert.AreEqual('Clientes', FForm.Caption);
  Assert.AreEqual('Pesquisar por', FForm.RotuloPesquisa.Caption);
  Assert.AreEqual('Campos da pesquisa', FForm.RotuloCampos.Caption);
  Assert.AreEqual('Data de nascimento', FForm.RotuloDataNascimento.Caption);
  for I := 0 to High(CAMPOS) do
    Assert.AreEqual(CAMPOS[I], FForm.ComboCampos.Properties.Items[I].Description, 'Campo ' + IntToStr(I));
  Assert.AreEqual('&Pesquisar', FForm.BotaoPesquisar.Caption);
  Assert.AreEqual('&Limpar', FForm.BotaoLimpar.Caption);
  Assert.AreEqual('Novo', FForm.BotaoNovo.Caption);
  Assert.AreEqual('Editar', FForm.BotaoEditar.Caption);
  Assert.AreEqual('Excluir', FForm.BotaoExcluir.Caption);
  Assert.AreEqual(8, FForm.ListaClientes.HeaderSections.Count);
  for I := 0 to High(COLUNAS) do
    Assert.AreEqual(COLUNAS[I], FForm.ListaClientes.HeaderSections[I].Text, 'Coluna ' + IntToStr(I));
  Assert.AreEqual('Nenhum cliente encontrado...', FForm.RotuloSemResultado.Caption);
  Assert.AreEqual('A pesquisa lista no máximo 50 clientes.', FForm.RotuloLimite.Caption);
  Assert.AreEqual(Ordenados(['Pesquisar por', 'Campos da pesquisa', 'Data de nascimento',
    'Nenhum cliente encontrado...', 'A pesquisa lista no máximo 50 clientes.']),
    string.Join('|', TextosDaClasse(FForm, TcxLabel)), 'Nenhum rótulo além dos definidos.');
  Assert.AreEqual(Ordenados(['&Pesquisar', '&Limpar', 'Novo', 'Editar', 'Excluir']),
    string.Join('|', TextosDaClasse(FForm, TcxButton)), 'Nenhum botão além dos definidos.');
end;

procedure TTestesFormPesquisaCliente.ArranjoFiltrosGradeEAcoes;
begin
  Criar;
  Assert.IsTrue(FForm.PainelFiltros.Align = alTop, 'Filtros devem ter Align = alTop.');
  Assert.IsTrue(FForm.ListaClientes.Align = alClient, 'A grade deve ter Align = alClient.');
  Assert.IsTrue(FForm.BarraAcoes.Align = alBottom, 'A barra de ações deve ter Align = alBottom.');
  Assert.IsTrue(FForm.PainelFiltros.Top < FForm.ListaClientes.Top, 'Filtros acima da grade.');
  Assert.IsTrue(FForm.ListaClientes.Top < FForm.BarraAcoes.Top, 'Grade acima da barra.');
  Assert.IsTrue(FForm.BotaoNovo.Parent = FForm.BarraAcoes);
  Assert.IsTrue(FForm.BotaoEditar.Parent = FForm.BarraAcoes);
  Assert.IsTrue(FForm.BotaoExcluir.Parent = FForm.BarraAcoes);
  Assert.IsTrue(FForm.BotaoNovo.Left < FForm.BotaoEditar.Left, 'Novo à esquerda de Editar.');
  Assert.IsTrue(FForm.BotaoEditar.Left < FForm.BotaoExcluir.Left, 'Editar à esquerda de Excluir.');
  Assert.IsTrue(FForm.BotaoPesquisar.Parent = FForm.PainelFiltros, 'Pesquisar fica no painel de filtros.');
  Assert.IsTrue(FForm.BotaoLimpar.Parent = FForm.PainelFiltros, 'Limpar fica no painel de filtros.');
  Assert.IsTrue(FForm.BotaoPesquisar.Left < FForm.BotaoLimpar.Left, 'Pesquisar à esquerda de Limpar.');
end;

procedure TTestesFormCadastroCliente.Preparar;
begin
  FRepositorioObjeto := TRepositorioClienteFake.Create;
  FRepositorio := FRepositorioObjeto as IInterface;
  FConfirmacaoObjeto := TConfirmacaoFake.Create;
  FConfirmacao := FConfirmacaoObjeto as IInterface;
  FApresentadorObjeto := TApresentadorErroFake.Create;
  FApresentador := FApresentadorObjeto as IApresentadorErro;
  FTransacao := TTransacaoFake.Create as IInterface;
  FViaCep := TServicoViaCepFake.Create as IInterface;
  FRelogio := TRelogioFake.Create(EncodeDate(2026, 9, 21)) as IInterface;
end;

procedure TTestesFormCadastroCliente.Criar;
begin
  FreeAndNil(FForm);
  FForm := TFormCadastroCliente.Create(nil);
  FForm.Conectar(FRepositorioObjeto, TTransacaoFake(FTransacao as TObject),
    TServicoViaCepFake(FViaCep as TObject), TRelogioFake(FRelogio as TObject), FConfirmacaoObjeto,
    FApresentadorObjeto);
end;

procedure TTestesFormCadastroCliente.Limpar;
begin
  FreeAndNil(FForm);
  FRepositorio := nil;
  FConfirmacao := nil;
  FApresentador := nil;
  FTransacao := nil;
  FViaCep := nil;
  FRelogio := nil;
end;

procedure TTestesFormCadastroCliente.FecharComAlteracoesPassaPelaConfirmacaoDoControlador;
begin
  Criar;
  Assert.IsTrue(FForm.Abrir(mcInclusao));
  FForm.Show;
  Application.ProcessMessages;
  FForm.EditorNome.Text := 'Alguém';
  FConfirmacaoObjeto.Resposta := False;
  FForm.Close;
  Assert.AreEqual(1, FConfirmacaoObjeto.Mensagens.Count, 'Fechar com alteração pede 1 confirmação.');
  Assert.AreEqual('Descartar as alterações não salvas?', FConfirmacaoObjeto.Mensagens[0]);
  Assert.IsTrue(FForm.Visible, 'Resposta Não mantém a form aberta.');
  Assert.AreEqual('Alguém', FForm.EditorNome.Text, 'Os valores permanecem.');

  FConfirmacaoObjeto.Resposta := True;
  FForm.BotaoCancelar.Click;
  Assert.AreEqual(2, FConfirmacaoObjeto.Mensagens.Count, 'Cancelar com alteração também confirma.');
  Assert.IsFalse(FForm.Visible, 'Resposta Sim fecha a form.');
  Assert.IsFalse(FForm.Salvo, 'O resultado é não salvo.');
  Assert.AreEqual(0, FRepositorioObjeto.TotalChamadas, 'Descartar não chama o repositório.');

  FConfirmacaoObjeto.Mensagens.Clear;
  Criar;
  Assert.IsTrue(FForm.Abrir(mcInclusao));
  FForm.Show;
  Application.ProcessMessages;
  FForm.Close;
  Assert.AreEqual(0, FConfirmacaoObjeto.Mensagens.Count, 'Sem alterações fecha sem confirmação.');
  Assert.IsFalse(FForm.Visible);
end;

procedure PressionarEnter;
var
  LJanela: HWND;
begin
  LJanela := GetFocus;
  Assert.IsTrue(LJanela <> 0, 'Algum controle deve estar focado.');
  PostMessage(LJanela, WM_KEYDOWN, VK_RETURN, $001C0001);
  PostMessage(LJanela, WM_KEYUP, VK_RETURN, LPARAM($C01C0001));
  Application.ProcessMessages;
  Application.ProcessMessages;
end;

procedure TTestesFormCadastroCliente.EnterAvancaNaOrdemDeTabulacaoAteSalvar;
var
  LOrdem: TArray<TWinControl>;
  I: Integer;
begin
  Criar;
  Assert.IsTrue(FForm.Abrir(mcInclusao));
  FForm.Show;
  Application.ProcessMessages;
  LOrdem := [FForm.EditorNome, FForm.EditorCpfCnpj, FForm.EditorDataNascimento, FForm.EditorCep,
    FForm.EditorEndereco, FForm.EditorNumero, FForm.EditorComplemento, FForm.EditorBairro,
    FForm.EditorCidade, FForm.EditorUf, FForm.BotaoSalvar];
  FForm.EditorNome.SetFocus;
  Application.ProcessMessages;
  Assert.IsTrue(FForm.EditorNome.Focused, 'O foco deve começar em Nome.');
  for I := 1 to High(LOrdem) do
  begin
    PressionarEnter;
    Assert.IsTrue(LOrdem[I].Focused, Format('Enter em %s deve focar %s.', [LOrdem[I - 1].Name, LOrdem[I].Name]));
    Assert.IsTrue(FForm.Visible, 'Enter não pode fechar a form.');
  end;
  Assert.AreEqual(0, FRepositorioObjeto.TotalChamadas, 'Enter não pode salvar.');
  Assert.AreEqual(0, TTransacaoFake(FTransacao as TObject).Iniciadas, 'Enter não pode salvar.');
  Assert.IsFalse(FForm.Salvo);
end;

procedure TTestesFormCadastroCliente.TextosDoCadastroSaoOsDefinidos;
begin
  Criar;
  Assert.IsTrue(FForm.Abrir(mcInclusao));
  Assert.AreEqual('Novo Cliente', FForm.Caption);
  FRepositorioObjeto.Clientes := [NovoCliente(7, 'Ana Silva', '52998224725', '01001000',
    'São Paulo', 'SP', 'São Paulo', EncodeDate(1990, 3, 15))];
  Criar;
  Assert.IsTrue(FForm.Abrir(mcEdicao, 7));
  Assert.AreEqual('Editar Cliente', FForm.Caption);
  Assert.AreEqual('Nome', FForm.RotuloNome.Caption);
  Assert.AreEqual('CPF/CNPJ', FForm.RotuloCpfCnpj.Caption);
  Assert.AreEqual('Data de nascimento', FForm.RotuloDataNascimento.Caption);
  Assert.AreEqual('CEP', FForm.RotuloCep.Caption);
  Assert.AreEqual('Endereço', FForm.RotuloEndereco.Caption);
  Assert.AreEqual('Número', FForm.RotuloNumero.Caption);
  Assert.AreEqual('Complemento', FForm.RotuloComplemento.Caption);
  Assert.AreEqual('Bairro', FForm.RotuloBairro.Caption);
  Assert.AreEqual('Cidade', FForm.RotuloCidade.Caption);
  Assert.AreEqual('UF', FForm.RotuloUf.Caption);
  Assert.AreEqual('Estado', FForm.RotuloEstado.Caption);
  Assert.AreEqual('Salvar', FForm.BotaoSalvar.Caption);
  Assert.AreEqual('Cancelar', FForm.BotaoCancelar.Caption);
  Assert.AreEqual('Consultando CEP...', FForm.RotuloConsultandoCep.Caption);
  Assert.AreEqual(Ordenados(['Nome', 'CPF/CNPJ', 'Data de nascimento', 'CEP', 'Endereço', 'Número',
    'Complemento', 'Bairro', 'Cidade', 'UF', 'Estado', 'Consultando CEP...']),
    string.Join('|', TextosDaClasse(FForm, TcxLabel)), 'Nenhum rótulo além dos definidos.');
  Assert.AreEqual(Ordenados(['Salvar', 'Cancelar']), string.Join('|', TextosDaClasse(FForm, TcxButton)),
    'Nenhum botão além dos definidos.');
end;

procedure TTestesFormCadastroCliente.ArranjoCamposEBotoes;
var
  LOrdem: TArray<TControl>;
  I: Integer;
begin
  Criar;
  Assert.IsTrue(FForm.Abrir(mcInclusao));
  FForm.Show;
  Application.ProcessMessages;
  LOrdem := [FForm.EditorNome, FForm.EditorCpfCnpj, FForm.EditorDataNascimento, FForm.EditorCep,
    FForm.EditorEndereco, FForm.EditorNumero, FForm.EditorComplemento, FForm.EditorBairro,
    FForm.EditorCidade, FForm.EditorUf];
  for I := 1 to High(LOrdem) do
  begin
    Assert.IsTrue(LOrdem[I].Parent = LOrdem[0].Parent, 'Os editores devem compartilhar o painel.');
    Assert.IsTrue(LOrdem[I].Top >= LOrdem[I - 1].Top,
      Format('%s não pode ficar acima de %s.', [LOrdem[I].Name, LOrdem[I - 1].Name]));
  end;
  Assert.AreEqual(FForm.EditorUf.Top, FForm.EditorEstado.Top, 'Estado fica na linha de UF.');
  Assert.IsTrue(FForm.EditorEstado.Left > FForm.EditorUf.Left + FForm.EditorUf.Width - 1,
    'Estado fica ao lado de UF.');
  Assert.IsTrue(FForm.EditorEstado.Properties.ReadOnly, 'Estado é somente leitura.');
  Assert.IsTrue(FForm.BarraBotoes.Align = alBottom, 'A barra de botões deve ter Align = alBottom.');
  Assert.IsTrue(FForm.BotaoSalvar.Parent = FForm.BarraBotoes);
  Assert.IsTrue(FForm.BotaoCancelar.Parent = FForm.BarraBotoes);
  Assert.IsTrue(FForm.BotaoSalvar.Left < FForm.BotaoCancelar.Left, 'Salvar à esquerda de Cancelar.');
  Assert.IsTrue(FForm.PainelCampos.Top + FForm.PainelCampos.Height <= FForm.BarraBotoes.Top);

  Assert.AreEqual('', FForm.EditorNome.Text);
  Assert.AreEqual('', FForm.EditorCpfCnpj.Text);
  Assert.IsTrue(FForm.EditorDataNascimento.Date = NullDate, 'Data de nascimento começa vazia.');
  Assert.AreEqual('', FForm.EditorCep.Text);
  Assert.AreEqual('', FForm.EditorEndereco.Text);
  Assert.AreEqual('', FForm.EditorNumero.Text);
  Assert.AreEqual('', FForm.EditorComplemento.Text);
  Assert.AreEqual('', FForm.EditorBairro.Text);
  Assert.AreEqual('', FForm.EditorCidade.Text);
  Assert.AreEqual('', FForm.EditorUf.Text);
  Assert.AreEqual('', FForm.EditorEstado.Text);
  Assert.IsFalse(FForm.RotuloConsultandoCep.Visible, 'O indicador de CEP começa invisível.');
end;

procedure TTestesFormCadastroCliente.EditoresRespeitamOTamanhoDasColunas;
var
  I: Integer;
  LUnidade: TUnidadeFederativa;
begin
  Criar;
  Assert.AreEqual(80, FForm.EditorNome.Properties.MaxLength);
  Assert.AreEqual(18, FForm.EditorCpfCnpj.Properties.MaxLength);
  Assert.AreEqual(9, FForm.EditorCep.Properties.MaxLength);
  Assert.AreEqual(100, FForm.EditorEndereco.Properties.MaxLength);
  Assert.AreEqual(20, FForm.EditorNumero.Properties.MaxLength);
  Assert.AreEqual(60, FForm.EditorComplemento.Properties.MaxLength);
  Assert.AreEqual(100, FForm.EditorBairro.Properties.MaxLength);
  Assert.AreEqual(50, FForm.EditorCidade.Properties.MaxLength);
  Assert.IsTrue(FForm.EditorUf.Properties.DropDownListStyle = lsFixedList, 'UF deve ser lista fechada.');
  Assert.AreEqual(27, FForm.EditorUf.Properties.Items.Count);
  I := 0;
  for LUnidade in UNIDADES_FEDERATIVAS do
  begin
    Assert.AreEqual(LUnidade.Sigla, FForm.EditorUf.Properties.Items[I]);
    Inc(I);
  end;

  Assert.IsTrue(FForm.Abrir(mcInclusao));
  FForm.EditorNome.Text := 'Fernanda Alves';
  FForm.EditorCpfCnpj.Text := '11.222.333/0001-81';
  FForm.EditorDataNascimento.Date := EncodeDate(1992, 5, 10);
  FForm.EditorCep.Text := '01001-000';
  FForm.EditorEndereco.Text := 'Praça da Sé';
  FForm.EditorNumero.Text := '100';
  FForm.EditorBairro.Text := 'Sé';
  FForm.EditorCidade.Text := 'São Paulo';
  FForm.EditorUf.ItemIndex := FForm.EditorUf.Properties.Items.IndexOf('SP');
  FForm.BotaoSalvar.Click;
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasIncluir, FApresentadorObjeto.Mensagens.Text);
  Assert.AreEqual('11222333000181', FRepositorioObjeto.UltimoIncluido.CpfCnpj, 'Grava 14 dígitos.');
  Assert.AreEqual('01001000', FRepositorioObjeto.UltimoIncluido.Cep, 'Grava 8 dígitos.');
  Assert.AreEqual('São Paulo', FRepositorioObjeto.UltimoEstado, 'Estado derivado da UF.');
end;

procedure TTestesFormCadastroCliente.CepEUfDaTelaAcionamOControlador;
var
  LViaCep: TServicoViaCepFake;
  LIndicadorDuranteConsulta: Boolean;
  LCarregamentoDuranteConsulta: Boolean;
begin
  Criar;
  LViaCep := TServicoViaCepFake(FViaCep as TObject);
  LViaCep.Resultado := ResultadoCep(scEncontrado);
  LIndicadorDuranteConsulta := False;
  LCarregamentoDuranteConsulta := False;
  LViaCep.AoConsultar :=
    procedure
    begin
      LIndicadorDuranteConsulta := FForm.RotuloConsultandoCep.Visible;
      LCarregamentoDuranteConsulta := Screen.Cursor = crHourGlass;
    end;
  Assert.IsTrue(FForm.Abrir(mcInclusao));
  FForm.Show;
  Application.ProcessMessages;
  FForm.EditorNumero.Text := '100';
  FForm.EditorComplemento.Text := 'sala 2';

  FForm.EditorCep.SetFocus;
  Application.ProcessMessages;
  FForm.EditorCep.Text := '01001-000';
  FForm.EditorEndereco.SetFocus;
  Application.ProcessMessages;
  LViaCep.AoConsultar := nil;
  Assert.AreEqual(1, LViaCep.Chamadas, 'Sair do CEP alterado na tela deve consultar o ViaCEP 1 vez.');
  Assert.AreEqual('01001000', LViaCep.UltimoCep);
  Assert.IsTrue(LIndicadorDuranteConsulta, 'Consultando CEP... deve aparecer durante a consulta.');
  Assert.IsTrue(LCarregamentoDuranteConsulta, 'O cursor de espera deve aparecer durante a consulta.');
  Assert.IsFalse(FForm.RotuloConsultandoCep.Visible, 'O indicador some ao fim da consulta.');
  Assert.AreEqual('Praça da Sé', FForm.EditorEndereco.Text);
  Assert.AreEqual('Sé', FForm.EditorBairro.Text);
  Assert.AreEqual('São Paulo', FForm.EditorCidade.Text);
  Assert.AreEqual('SP', FForm.EditorUf.Text);
  Assert.AreEqual('São Paulo', FForm.EditorEstado.Text);
  Assert.AreEqual('100', FForm.EditorNumero.Text, 'Número digitado permanece.');
  Assert.AreEqual('sala 2', FForm.EditorComplemento.Text, 'Complemento digitado permanece.');

  FForm.EditorCep.SetFocus;
  Application.ProcessMessages;
  FForm.EditorEndereco.SetFocus;
  Application.ProcessMessages;
  Assert.AreEqual(1, LViaCep.Chamadas, 'Sair do CEP sem alteração na tela não consulta.');

  FForm.EditorCep.SetFocus;
  Application.ProcessMessages;
  FForm.EditorCep.Text := '0100100';
  FForm.EditorEndereco.SetFocus;
  Application.ProcessMessages;
  Assert.AreEqual(1, LViaCep.Chamadas, 'CEP incompleto na tela não consulta.');
  Assert.AreEqual('CEP inválido', FApresentadorObjeto.Mensagens.Text.Trim);

  FForm.EditorUf.ItemIndex := FForm.EditorUf.Properties.Items.IndexOf('DF');
  Application.ProcessMessages;
  Assert.AreEqual('Distrito Federal', FForm.EditorEstado.Text, 'Trocar a UF na tela atualiza o Estado.');
end;

procedure TTestesNavegadorClientes.ConduzirCadastro(Sender: TObject; var ADone: Boolean);
var
  I: Integer;
  LForm: TFormCadastroCliente;
begin
  for I := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[I] is TFormCadastroCliente) and Screen.Forms[I].Visible and
       (Screen.Forms[I].Tag = 0) then
    begin
      LForm := TFormCadastroCliente(Screen.Forms[I]);
      LForm.Tag := 1;
      Inc(FExibicoes);
      FModal := fsModal in LForm.FormState;
      FTitulo := LForm.Caption;
      if FAcao = acCancelar then
      begin
        LForm.BotaoCancelar.Click;
        Exit;
      end;
      if LForm.EditorNome.Text = '' then
      begin
        LForm.EditorNome.Text := 'Fernanda Alves';
        LForm.EditorCpfCnpj.Text := '529.982.247-25';
        LForm.EditorDataNascimento.Date := EncodeDate(1992, 5, 10);
        LForm.EditorCep.Text := '01001-000';
        LForm.EditorEndereco.Text := 'Praça da Sé';
        LForm.EditorNumero.Text := '100';
        LForm.EditorBairro.Text := 'Sé';
        LForm.EditorCidade.Text := 'São Paulo';
        LForm.EditorUf.ItemIndex := LForm.EditorUf.Properties.Items.IndexOf('SP');
      end;
      LForm.BotaoSalvar.Click;
      Exit;
    end;
end;

procedure TTestesNavegadorClientes.AbreCadastroModalNoModoEDevolveSeSalvou;
type
  TCaso = record
    Edicao: Boolean;
    Acao: TAcaoCadastro;
    Titulo: string;
    Salvo: Boolean;
  end;
const
  CASOS: array[0..3] of TCaso = (
    (Edicao: False; Acao: acSalvar; Titulo: 'Novo Cliente'; Salvo: True),
    (Edicao: False; Acao: acCancelar; Titulo: 'Novo Cliente'; Salvo: False),
    (Edicao: True; Acao: acSalvar; Titulo: 'Editar Cliente'; Salvo: True),
    (Edicao: True; Acao: acCancelar; Titulo: 'Editar Cliente'; Salvo: False));
var
  LCaso: TCaso;
  LRepositorioObjeto: TRepositorioClienteFake;
  LRepositorio: IInterface;
  LApresentadorObjeto: TApresentadorErroFake;
  LApresentador: IInterface;
  LNavegador: INavegadorClientes;
  LResultado: Boolean;
  LFormsAntes: Integer;
begin
  for LCaso in CASOS do
  begin
    LRepositorioObjeto := TRepositorioClienteFake.Create;
    LRepositorio := LRepositorioObjeto as IInterface;
    LRepositorioObjeto.Clientes := [NovoCliente(7, 'Ana Silva', '52998224725', '01001000',
      'São Paulo', 'SP', 'São Paulo', EncodeDate(1990, 3, 15))];
    LApresentadorObjeto := TApresentadorErroFake.Create;
    LApresentador := LApresentadorObjeto as IApresentadorErro;
    LNavegador := TNavegadorClientes.Create(LRepositorioObjeto, TTransacaoFake.Create,
      TServicoViaCepFake.Create, TRelogioFake.Create(EncodeDate(2026, 9, 21)), TConfirmacaoFake.Create,
      LApresentadorObjeto);
    FAcao := LCaso.Acao;
    FExibicoes := 0;
    FModal := False;
    FTitulo := '';
    LFormsAntes := Screen.FormCount;
    Application.OnIdle := ConduzirCadastro;
    try
      if LCaso.Edicao then
        LResultado := LNavegador.AbrirEdicao(7)
      else
        LResultado := LNavegador.AbrirInclusao;
    finally
      Application.OnIdle := nil;
    end;
    Assert.AreEqual(0, LApresentadorObjeto.Mensagens.Count, LApresentadorObjeto.Mensagens.Text);
    Assert.AreEqual(1, FExibicoes, 'Exatamente 1 TFormCadastroCliente deve ser exibida: ' + LCaso.Titulo);
    Assert.IsTrue(FModal, 'O cadastro deve ser modal.');
    Assert.AreEqual(LCaso.Titulo, FTitulo);
    Assert.AreEqual(LCaso.Salvo, LResultado, 'Resultado devolvido pelo navegador: ' + LCaso.Titulo);
    if LCaso.Salvo and LCaso.Edicao then
      Assert.AreEqual(7, LRepositorioObjeto.UltimoAlterado.Id);
    if LCaso.Salvo and not LCaso.Edicao then
      Assert.AreEqual(1, LRepositorioObjeto.ChamadasIncluir);
    if not LCaso.Salvo then
      Assert.AreEqual(0, LRepositorioObjeto.ChamadasIncluir + LRepositorioObjeto.ChamadasAlterar);
    Assert.AreEqual(LFormsAntes, Screen.FormCount, 'O cadastro deve ser liberado ao fechar.');
    LNavegador := nil;
    LRepositorio := nil;
    LApresentador := nil;
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

procedure AssegurarSemReferencias(const AUnit: string; const APrefixos: array of string);
var
  LReferencia: string;
  LPrefixo: string;
  LQuantidade: Integer;
begin
  LQuantidade := 0;
  for LReferencia in UnitsReferenciadas(ArquivoDaUnit(AUnit)) do
  begin
    Inc(LQuantidade);
    for LPrefixo in APrefixos do
      Assert.IsFalse(StartsText(LPrefixo, LReferencia), AUnit + ' não pode referenciar ' + LReferencia);
  end;
  Assert.IsTrue(LQuantidade > 0, 'A análise deve encontrar o uses de ' + AUnit);
end;

function UnitDevExpress(AClasse: TClass): Boolean;
begin
  Result := StartsText('dx', AClasse.UnitName) or StartsText('cx', AClasse.UnitName);
end;

function UnitVclProibida(AClasse: TClass): Boolean;
begin
  Result := MatchText(AClasse.UnitName, ['Vcl.StdCtrls', 'Vcl.ExtCtrls', 'Vcl.ComCtrls', 'Vcl.Mask',
    'Vcl.Grids']);
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

procedure VerificarForm(AForm: TForm; AMinimo: Integer);
var
  I: Integer;
  LVerificados: Integer;
  LProibidos: Integer;
begin
  AForm.Show;
  Application.ProcessMessages;
  LVerificados := 0;
  LProibidos := 0;
  for I := 0 to AForm.ComponentCount - 1 do
  begin
    Inc(LVerificados);
    if UnitVclProibida(AForm.Components[I].ClassType) then
      Inc(LProibidos);
    Assert.IsTrue(UnitDevExpress(AForm.Components[I].ClassType),
      AForm.Components[I].ClassName + ' (' + AForm.Components[I].ClassType.UnitName +
      ') não é um componente DevExpress.');
  end;
  VerificarControles(AForm, LVerificados, LProibidos);
  Assert.AreEqual(0, LProibidos, AForm.ClassName + ' não pode conter controles VCL padrão.');
  Assert.IsTrue(LVerificados >= AMinimo, 'A verificação deve alcançar os controles de ' + AForm.ClassName);
end;

procedure TTestesArquiteturaClientes.FormsDeClientesSoUsamControlesDevExpress;
var
  LPesquisa: TFormPesquisaCliente;
  LCadastro: TFormCadastroCliente;
  LRepositorio: TRepositorioClienteFake;
  LReferencias: IInterface;
  LApresentador: TApresentadorErroFake;
  LReferenciaApresentador: IInterface;
begin
  LRepositorio := TRepositorioClienteFake.Create;
  LReferencias := LRepositorio as IInterface;
  LApresentador := TApresentadorErroFake.Create;
  LReferenciaApresentador := LApresentador as IApresentadorErro;
  LPesquisa := TFormPesquisaCliente.Create(nil);
  try
    LPesquisa.Conectar(LRepositorio, TTransacaoFake.Create, TNavegadorClientesFake.Create,
      TConfirmacaoFake.Create, LApresentador);
    VerificarForm(LPesquisa, 30);
  finally
    LPesquisa.Free;
  end;
  LCadastro := TFormCadastroCliente.Create(nil);
  try
    LCadastro.Conectar(LRepositorio, TTransacaoFake.Create, TServicoViaCepFake.Create,
      TRelogioFake.Create(EncodeDate(2026, 9, 21)), TConfirmacaoFake.Create, LApresentador);
    LCadastro.Abrir(mcInclusao);
    VerificarForm(LCadastro, 30);
  finally
    LCadastro.Free;
  end;
end;

procedure TTestesArquiteturaClientes.ControladorDeCadastroSoConheceTEnderecoViaCep;
var
  LContexto: TRttiContext;
  LResultado: TRttiType;
  LEndereco: TRttiType;
  LCampo: TRttiField;
  LNomes: TArray<string>;
begin
  AssegurarSemReferencias(TControladorCadastroCliente.UnitName,
    ['System.JSON', 'REST.', 'System.Net.', 'Infraestrutura.']);
  Assert.AreEqual(0, Integer(Length(UnitsReferenciadas(ArquivoDaUnit('Aplicacao.ServicoViaCep')))),
    'O contrato de CEP consumido pelo controlador não pode depender de nenhuma unit.');
  LResultado := LContexto.GetType(TypeInfo(TResultadoConsultaCep));
  Assert.AreEqual(2, Integer(Length(LResultado.GetFields)));
  LCampo := LResultado.GetField('Endereco');
  Assert.IsNotNull(LCampo);
  Assert.IsTrue(LCampo.FieldType.Handle = TypeInfo(TEnderecoViaCep),
    'O único endereço externo recebido pelo controlador é TEnderecoViaCep.');
  LEndereco := LContexto.GetType(TypeInfo(TEnderecoViaCep));
  LNomes := [];
  for LCampo in LEndereco.GetFields do
  begin
    Assert.IsTrue(LCampo.FieldType.Handle = TypeInfo(string), LCampo.Name + ' deve ser texto.');
    LNomes := LNomes + [LCampo.Name];
  end;
  Assert.AreEqual('CEP|Logradouro|Complemento|Bairro|Localidade|UF|Estado', string.Join('|', LNomes));
end;

procedure TTestesArquiteturaClientes.CadaFormTemSeuControladorESemInfraestrutura;
const
  PROIBIDOS_FORM: array[0..4] of string = ('FireDAC.', 'Infraestrutura.', 'Repositorio',
    'System.Net.', 'System.JSON');
  PROIBIDOS_CONTROLADOR: array[0..5] of string = ('Vcl.', 'FireDAC.', 'cx', 'dx', 'System.Net.',
    'System.JSON');
var
  LContexto: TRttiContext;
  LCampo: TRttiField;
  LMetodo: TRttiMethod;
  LQuantidade: Integer;
begin
  Assert.IsTrue(Supports(TFormPesquisaCliente, IVisaoPesquisaCliente));
  Assert.IsTrue(Supports(TFormCadastroCliente, IVisaoCadastroCliente));

  LQuantidade := 0;
  for LCampo in LContexto.GetType(TFormPesquisaCliente).GetDeclaredFields do
    if Assigned(LCampo.FieldType) and (LCampo.FieldType.Handle = TypeInfo(TControladorPesquisaCliente)) then
      Inc(LQuantidade);
  Assert.AreEqual(1, LQuantidade, 'TFormPesquisaCliente declara exatamente 1 TControladorPesquisaCliente.');
  LQuantidade := 0;
  for LCampo in LContexto.GetType(TFormCadastroCliente).GetDeclaredFields do
    if Assigned(LCampo.FieldType) and (LCampo.FieldType.Handle = TypeInfo(TControladorCadastroCliente)) then
      Inc(LQuantidade);
  Assert.AreEqual(1, LQuantidade, 'TFormCadastroCliente declara exatamente 1 TControladorCadastroCliente.');

  AssegurarSemReferencias(TFormPesquisaCliente.UnitName, PROIBIDOS_FORM);
  AssegurarSemReferencias(TFormCadastroCliente.UnitName, PROIBIDOS_FORM);
  AssegurarSemReferencias(TControladorPesquisaCliente.UnitName, PROIBIDOS_CONTROLADOR);
  AssegurarSemReferencias(TControladorCadastroCliente.UnitName, PROIBIDOS_CONTROLADOR);

  for LMetodo in LContexto.GetType(TControladorCadastroCliente).GetMethods do
    if LMetodo.Visibility in [mvPublic, mvPublished] then
      Assert.IsFalse(ContainsText(LMetodo.Name, 'Excluir'),
        'TControladorCadastroCliente não pode excluir: ' + LMetodo.Name);
  Assert.IsNotNull(LContexto.GetType(TControladorPesquisaCliente).GetMethod('Excluir'),
    'A exclusão fica em TControladorPesquisaCliente.');
end;

procedure TTestesArquiteturaClientes.PesquisaSoPeloRepositorioSemFiltroEmMemoria;
var
  LArquivo: string;
  LTexto: string;
  LVerificados: Integer;

  function TextoCompacto(const AUnit: string): string;
  begin
    Result := TRegEx.Replace(TFile.ReadAllText(ArquivoDaUnit(AUnit)), '\s+', ' ');
  end;

begin
  LVerificados := 0;
  for LArquivo in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.pas',
    TSearchOption.soAllDirectories) do
  begin
    LTexto := TFile.ReadAllText(LArquivo);
    Assert.IsFalse(ContainsStr(LTexto, 'ListarTodos'), 'ListarTodos não pode existir: ' + LArquivo);
    Assert.IsFalse(ContainsStr(LTexto, 'Atende'), 'Atende não pode existir: ' + LArquivo);
    Inc(LVerificados);
  end;
  Assert.IsTrue(LVerificados > 20, 'A varredura deve alcançar os fontes de src.');

  Assert.IsTrue(ContainsStr(TextoCompacto('Aplicacao.ControladorPesquisaCliente'),
    'LIMITE_PESQUISA_CLIENTES = 50;'), 'O limite da pesquisa é 50.');
  Assert.IsTrue(ContainsStr(TextoCompacto('Aplicacao.RepositorioCliente'),
    'function Pesquisar(const AFiltro: TFiltroCliente; const AOrdenacao: TOrdenacaoCliente; ' +
    'ALimite: Integer): TClientes;'), 'O contrato de pesquisa do repositório é o do door 1.');
  LTexto := TFile.ReadAllText(ArquivoDaUnit('Visao.FormPesquisaCliente'));
  Assert.IsTrue(ContainsStr(LTexto, 'SortOrder'), 'A form marca a seta pelo SortOrder.');
  Assert.IsFalse(ContainsText(StringReplace(LTexto, 'SortOrder', '', [rfReplaceAll]), 'Sort'),
    'A form não pode ordenar as linhas.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesFormPesquisaCliente);
  TDUnitX.RegisterTestFixture(TTestesFormCadastroCliente);
  TDUnitX.RegisterTestFixture(TTestesNavegadorClientes);
  TDUnitX.RegisterTestFixture(TTestesArquiteturaClientes);

end.

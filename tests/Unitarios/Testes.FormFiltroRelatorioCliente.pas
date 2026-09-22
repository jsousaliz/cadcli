unit Testes.FormFiltroRelatorioCliente;

interface

uses
  DUnitX.TestFramework,
  Visao.FormFiltroRelatorioCliente,
  Suporte.FakesClientes,
  Suporte.FakesFormPrincipal,
  Suporte.FakesRelatorioCliente;

type
  [TestFixture]
  TTestesFormFiltroRelatorioCliente = class
  private
    FForm: TFormFiltroRelatorioCliente;
    FRepositorioObjeto: TRepositorioClienteFake;
    FRepositorio: IInterface;
    FGeradorObjeto: TGeradorRelatorioClienteFake;
    FGerador: IInterface;
    FApresentadorObjeto: TApresentadorErroFake;
    FApresentador: IInterface;
    FRelogio: IInterface;
    procedure Criar;
    procedure Abrir;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure ModosHabilitamCamposEEstadoFiltraCidades;
    [Test]
    procedure FiltroInvalidoFocaOEditorNaFormReal;
    [Test]
    procedure TextosEArranjoDaTelaDeFiltro;
    [Test]
    procedure FalhaNaGeracaoMantemFiltroEReabilitaVisualizar;
    [Test]
    procedure VisualizarDesabilitaAcaoDuranteGeracao;
  end;

  [TestFixture]
  TTestesArquiteturaRelatorioCliente = class
  public
    [Test]
    procedure ControladorSemVclEReportBuilderSoNoAdaptador;
    [Test]
    procedure ContratosDoRepositorioEDoGerador;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.Rtti,
  System.StrUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  Vcl.Controls,
  Vcl.Forms,
  cxButtons,
  cxDropDownEdit,
  cxLabel,
  cxRadioGroup,
  cxTextEdit,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.ControladorRelatorioCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.GeradorRelatorioCliente,
  Aplicacao.RepositorioCliente,
  Visao.ApresentadorErro,
  Suporte.CaminhosTeste;

function FocoEstaEm(AForm: TForm; AControle: TWinControl): Boolean;
var
  LAtivo: TWinControl;
begin
  LAtivo := AForm.ActiveControl;
  while Assigned(LAtivo) do
  begin
    if LAtivo = AControle then
      Exit(True);
    LAtivo := LAtivo.Parent;
  end;
  Result := False;
end;

procedure TTestesFormFiltroRelatorioCliente.Preparar;
begin
  FRepositorioObjeto := TRepositorioClienteFake.Create;
  FRepositorio := FRepositorioObjeto as IRepositorioCliente;
  FRepositorioObjeto.Estados := EstadosDaFixture;
  FRepositorioObjeto.Cidades := CidadesDeSaoPaulo;
  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FGeradorObjeto := TGeradorRelatorioClienteFake.Create;
  FGerador := FGeradorObjeto as IGeradorRelatorioCliente;
  FApresentadorObjeto := TApresentadorErroFake.Create;
  FApresentador := FApresentadorObjeto as IApresentadorErro;
  FRelogio := TRelogioFake.Create(EncodeDate(2026, 9, 22)) as IRelogio;
  Criar;
end;

procedure TTestesFormFiltroRelatorioCliente.Limpar;
begin
  FreeAndNil(FForm);
  FRelogio := nil;
  FApresentador := nil;
  FGerador := nil;
  FRepositorio := nil;
end;

procedure TTestesFormFiltroRelatorioCliente.Criar;
begin
  FForm := TFormFiltroRelatorioCliente.Create(nil);
  FForm.Conectar(FRepositorioObjeto, FGeradorObjeto, FRelogio as IRelogio, FApresentadorObjeto);
end;

procedure TTestesFormFiltroRelatorioCliente.Abrir;
begin
  FForm.Show;
  Application.ProcessMessages;
end;

procedure TTestesFormFiltroRelatorioCliente.ModosHabilitamCamposEEstadoFiltraCidades;
var
  I: Integer;
  LNomes: string;
begin
  Abrir;

  Assert.AreEqual(Ord(mrTodos), FForm.GrupoModos.ItemIndex, 'A tela abre no modo Todos.');
  Assert.IsFalse(FForm.EditorIdInicial.Enabled, 'ID Inicial abre desabilitado.');
  Assert.IsFalse(FForm.EditorIdFinal.Enabled, 'ID Final abre desabilitado.');
  Assert.IsFalse(FForm.ComboEstado.Enabled, 'Estado abre desabilitado.');
  Assert.IsFalse(FForm.ComboCidade.Enabled, 'Cidade abre desabilitada.');

  FForm.GrupoModos.ItemIndex := Ord(mrIntervalo);
  Application.ProcessMessages;
  Assert.IsTrue(FForm.EditorIdInicial.Enabled, 'Intervalo habilita ID Inicial.');
  Assert.IsTrue(FForm.EditorIdFinal.Enabled, 'Intervalo habilita ID Final.');
  Assert.IsFalse(FForm.ComboEstado.Enabled, 'Intervalo mantém Estado desabilitado.');
  Assert.IsFalse(FForm.ComboCidade.Enabled, 'Intervalo mantém Cidade desabilitada.');

  FForm.GrupoModos.ItemIndex := Ord(mrCidadeEstado);
  Application.ProcessMessages;
  Assert.IsFalse(FForm.EditorIdInicial.Enabled, 'Cidade/Estado desabilita ID Inicial.');
  Assert.IsFalse(FForm.EditorIdFinal.Enabled, 'Cidade/Estado desabilita ID Final.');
  Assert.IsTrue(FForm.ComboEstado.Enabled, 'Cidade/Estado habilita Estado.');
  Assert.IsTrue(FForm.ComboCidade.Enabled, 'Cidade/Estado habilita Cidade.');

  FForm.GrupoModos.ItemIndex := Ord(mrTodos);
  Application.ProcessMessages;
  Assert.IsFalse(FForm.EditorIdInicial.Enabled, 'Todos desabilita ID Inicial.');
  Assert.IsFalse(FForm.EditorIdFinal.Enabled, 'Todos desabilita ID Final.');
  Assert.IsFalse(FForm.ComboEstado.Enabled, 'Todos desabilita Estado.');
  Assert.IsFalse(FForm.ComboCidade.Enabled, 'Todos desabilita Cidade.');

  Assert.AreEqual(4, FForm.ComboEstado.Properties.Items.Count, 'O combo lista os 4 estados.');
  Assert.AreEqual('Bahia,Minas Gerais,Rio de Janeiro,São Paulo',
    string.Join(',', FForm.ComboEstado.Properties.Items.ToStringArray));

  for I := 0 to FForm.ComboEstado.Properties.Items.Count - 1 do
    if FForm.ComboEstado.Properties.Items[I] = 'São Paulo' then
      FForm.ComboEstado.ItemIndex := I;
  Application.ProcessMessages;
  LNomes := string.Join(',', FForm.ComboCidade.Properties.Items.ToStringArray);
  Assert.AreEqual(4, FForm.ComboCidade.Properties.Items.Count,
    'O combo de cidades lista as de São Paulo e a opção de todas.');
  Assert.AreEqual('Todas as cidades,Campinas,Santos,São Paulo', LNomes);
end;

procedure TTestesFormFiltroRelatorioCliente.FiltroInvalidoFocaOEditorNaFormReal;
begin
  Abrir;
  FForm.GrupoModos.ItemIndex := Ord(mrIntervalo);
  Application.ProcessMessages;
  FForm.EditorIdInicial.Text := 'abc';
  FForm.EditorIdFinal.Text := '4';

  FForm.BotaoVisualizar.Click;
  Application.ProcessMessages;

  Assert.IsTrue(FocoEstaEm(FForm, FForm.EditorIdInicial),
    'O foco fica no editor de ID Inicial.');
  Assert.IsFalse(FocoEstaEm(FForm, FForm.EditorIdFinal),
    'O foco não pode ficar no editor de ID Final.');
  Assert.AreEqual(1, FApresentadorObjeto.Mensagens.Count, 'Um único aviso é apresentado.');
  Assert.AreEqual(MENSAGEM_ID_INICIAL, FApresentadorObjeto.Mensagens[0]);
  Assert.AreEqual(0, FGeradorObjeto.Chamadas, 'Filtro inválido não gera relatório.');

  FForm.GrupoModos.ItemIndex := Ord(mrCidadeEstado);
  Application.ProcessMessages;
  FForm.BotaoVisualizar.Click;
  Application.ProcessMessages;

  Assert.IsTrue(FocoEstaEm(FForm, FForm.ComboEstado), 'O foco fica no combo de Estado.');
  Assert.IsFalse(FocoEstaEm(FForm, FForm.ComboCidade),
    'O foco não pode ficar no combo de Cidade.');
  Assert.AreEqual(2, FApresentadorObjeto.Mensagens.Count);
  Assert.AreEqual(MENSAGEM_ESTADO_OBRIGATORIO, FApresentadorObjeto.Mensagens[1]);
  Assert.AreEqual(0, FGeradorObjeto.Chamadas, 'Filtro inválido não gera relatório.');
end;

procedure TTestesFormFiltroRelatorioCliente.TextosEArranjoDaTelaDeFiltro;
var
  I: Integer;
  LComponente: TComponent;
  LVerificados: Integer;
begin
  Abrir;

  Assert.AreEqual('Relatório de Clientes', FForm.Caption);
  Assert.AreEqual('Filtro', FForm.GrupoModos.Caption);
  Assert.AreEqual(3, FForm.GrupoModos.Properties.Items.Count, 'São três modos.');
  Assert.AreEqual('ID Inicial e ID Final', FForm.GrupoModos.Properties.Items[0].Caption);
  Assert.AreEqual('Cidade/Estado', FForm.GrupoModos.Properties.Items[1].Caption);
  Assert.AreEqual('Todos', FForm.GrupoModos.Properties.Items[2].Caption);
  Assert.AreEqual('ID Inicial', FForm.RotuloIdInicial.Caption);
  Assert.AreEqual('ID Final', FForm.RotuloIdFinal.Caption);
  Assert.AreEqual('Estado', FForm.RotuloEstado.Caption);
  Assert.AreEqual('Cidade', FForm.RotuloCidade.Caption);
  Assert.AreEqual('Visualizar', FForm.BotaoVisualizar.Caption);
  Assert.AreEqual('Fechar', FForm.BotaoFechar.Caption);
  Assert.AreEqual(Integer(mrCancel), Integer(FForm.BotaoFechar.ModalResult),
    'Fechar encerra a tela sem consultar.');

  Assert.IsTrue(FForm.GrupoModos.Top + FForm.GrupoModos.Height <= FForm.EditorIdInicial.Top,
    'Os modos ficam acima dos IDs.');
  Assert.IsTrue(FForm.EditorIdInicial.Top + FForm.EditorIdInicial.Height <=
    FForm.ComboEstado.Top, 'Os IDs ficam acima de estado e cidade.');
  Assert.IsTrue(FForm.ComboCidade.Top + FForm.ComboCidade.Height <= FForm.BotaoVisualizar.Top,
    'Estado e cidade ficam acima dos botões.');

  Assert.IsTrue(FForm.GrupoModos.TabOrder < FForm.EditorIdInicial.TabOrder, 'Modos antes dos IDs.');
  Assert.IsTrue(FForm.EditorIdInicial.TabOrder < FForm.EditorIdFinal.TabOrder,
    'ID Inicial antes de ID Final.');
  Assert.IsTrue(FForm.EditorIdFinal.TabOrder < FForm.ComboEstado.TabOrder,
    'ID Final antes de Estado.');
  Assert.IsTrue(FForm.ComboEstado.TabOrder < FForm.ComboCidade.TabOrder,
    'Estado antes de Cidade.');
  Assert.IsTrue(FForm.ComboCidade.TabOrder < FForm.BotaoVisualizar.TabOrder,
    'Cidade antes de Visualizar.');
  Assert.IsTrue(FForm.BotaoVisualizar.TabOrder < FForm.BotaoFechar.TabOrder,
    'Visualizar antes de Fechar.');

  LVerificados := 0;
  for I := 0 to FForm.ComponentCount - 1 do
  begin
    LComponente := FForm.Components[I];
    Assert.IsTrue(StartsText('cx', LComponente.ClassType.UnitName) or
      StartsText('dx', LComponente.ClassType.UnitName),
      LComponente.ClassName + ' (' + LComponente.ClassType.UnitName +
      ') não é um componente DevExpress.');
    Inc(LVerificados);
  end;
  Assert.AreEqual(11, LVerificados, 'A tela tem exatamente os 11 controles do contrato.');
end;

procedure TTestesFormFiltroRelatorioCliente.FalhaNaGeracaoMantemFiltroEReabilitaVisualizar;
begin
  Abrir;
  FForm.GrupoModos.ItemIndex := Ord(mrIntervalo);
  Application.ProcessMessages;
  FForm.EditorIdInicial.Text := '2';
  FForm.EditorIdFinal.Text := '4';
  FGeradorObjeto.Falhar := True;

  FForm.BotaoVisualizar.Click;
  Application.ProcessMessages;

  Assert.AreEqual(Ord(mrIntervalo), FForm.GrupoModos.ItemIndex, 'O modo escolhido permanece.');
  Assert.AreEqual('2', FForm.EditorIdInicial.Text, 'O ID inicial permanece.');
  Assert.AreEqual('4', FForm.EditorIdFinal.Text, 'O ID final permanece.');
  Assert.IsTrue(FForm.BotaoVisualizar.Enabled, 'Visualizar volta a ficar habilitado.');
  Assert.AreEqual(1, FApresentadorObjeto.Mensagens.Count, 'Um único erro é apresentado.');
  Assert.AreEqual(MENSAGEM_FALHA_GERACAO, FApresentadorObjeto.Mensagens[0]);
end;

procedure TTestesFormFiltroRelatorioCliente.VisualizarDesabilitaAcaoDuranteGeracao;
var
  LHabilitadoDurante: Boolean;
begin
  Abrir;
  LHabilitadoDurante := True;
  FGeradorObjeto.AoVisualizar :=
    procedure
    begin
      LHabilitadoDurante := FForm.BotaoVisualizar.Enabled;
    end;

  FForm.BotaoVisualizar.Click;
  Application.ProcessMessages;

  Assert.AreEqual(1, FGeradorObjeto.Chamadas, 'O gerador é acionado uma vez.');
  Assert.IsFalse(LHabilitadoDurante, 'Visualizar fica desabilitado durante a geração.');
  Assert.IsTrue(FForm.BotaoVisualizar.Enabled, 'Visualizar volta a ficar habilitado.');
end;

function ArquivoDaUnitDeSrc(const AUnit: string): string;
var
  LArquivos: TStringDynArray;
begin
  LArquivos := TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), AUnit + '.pas',
    TSearchOption.soAllDirectories);
  Assert.AreEqual(1, Integer(Length(LArquivos)), 'Unit não encontrada em src: ' + AUnit);
  Result := LArquivos[0];
end;

function ReferenciasDaUnit(const AUnit: string): TArray<string>;
var
  LTexto: string;
  LClausula: TMatch;
  LItem: string;
  LNome: TMatch;
begin
  Result := [];
  LTexto := TFile.ReadAllText(ArquivoDaUnitDeSrc(AUnit));
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

procedure AssegurarSemPrefixos(const AUnit: string; const APrefixos: array of string);
var
  LReferencia: string;
  LPrefixo: string;
  LQuantidade: Integer;
begin
  LQuantidade := 0;
  for LReferencia in ReferenciasDaUnit(AUnit) do
  begin
    Inc(LQuantidade);
    for LPrefixo in APrefixos do
      Assert.IsFalse(StartsText(LPrefixo, LReferencia),
        AUnit + ' não pode referenciar ' + LReferencia);
  end;
  Assert.IsTrue(LQuantidade > 0, 'A análise deve encontrar o uses de ' + AUnit);
end;

function TextoCompacto(const AUnit: string): string;
begin
  Result := TRegEx.Replace(TFile.ReadAllText(ArquivoDaUnitDeSrc(AUnit)), '\s+', ' ');
end;

procedure TTestesArquiteturaRelatorioCliente.ControladorSemVclEReportBuilderSoNoAdaptador;
const
  PROIBIDOS_CONTROLADOR: array[0..4] of string = ('Vcl.', 'FireDAC.', 'cx', 'dx', 'pp');
  PROIBIDOS_FORM: array[0..1] of string = ('FireDAC.', 'pp');
  UNITS_REPORTBUILDER: array[0..3] of string = ('ppReport', 'ppDB', 'ppDBJIT', 'ppCtrls');
var
  LContexto: TRttiContext;
  LCampo: TRttiField;
  LQuantidade: Integer;
  LArquivo: string;
  LAdaptador: string;
  LTexto: string;
  LUnitRb: string;
  LVerificados: Integer;
begin
  AssegurarSemPrefixos('Aplicacao.ControladorRelatorioCliente', PROIBIDOS_CONTROLADOR);
  AssegurarSemPrefixos('Dominio.FiltroRelatorioCliente', PROIBIDOS_CONTROLADOR);
  AssegurarSemPrefixos('Visao.FormFiltroRelatorioCliente', PROIBIDOS_FORM);

  Assert.IsTrue(Supports(TFormFiltroRelatorioCliente, IVisaoRelatorioCliente),
    'A form implementa IVisaoRelatorioCliente.');
  Assert.IsTrue(ContainsStr(TextoCompacto('Visao.FormFiltroRelatorioCliente'),
    'TFormFiltroRelatorioCliente = class(TForm, IVisaoRelatorioCliente)'),
    'A form é declarada como visão do relatório.');
  LQuantidade := 0;
  for LCampo in LContexto.GetType(TFormFiltroRelatorioCliente).GetDeclaredFields do
    if Assigned(LCampo.FieldType) and
      (LCampo.FieldType.Handle = TypeInfo(TControladorRelatorioCliente)) then
      Inc(LQuantidade);
  Assert.AreEqual(1, LQuantidade,
    'TFormFiltroRelatorioCliente declara exatamente 1 TControladorRelatorioCliente.');
  Assert.AreEqual(1, Integer(TRegEx.Matches(TextoCompacto('Visao.FormFiltroRelatorioCliente'),
    'TControladorRelatorioCliente\.Create').Count),
    'A form cria exatamente um controlador.');

  LAdaptador := ArquivoDaUnitDeSrc('Infraestrutura.GeradorRelatorioClienteReportBuilder');
  LVerificados := 0;
  for LArquivo in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'src'), '*.pas',
    TSearchOption.soAllDirectories) do
  begin
    if SameText(LArquivo, LAdaptador) then
      Continue;
    LTexto := TFile.ReadAllText(LArquivo);
    for LUnitRb in UNITS_REPORTBUILDER do
      Assert.IsFalse(ContainsStr(LTexto, LUnitRb),
        LUnitRb + ' só pode aparecer no adaptador: ' + LArquivo);
    Inc(LVerificados);
  end;
  Assert.IsTrue(LVerificados > 20, 'A varredura deve alcançar os fontes de src.');
end;

procedure TTestesArquiteturaRelatorioCliente.ContratosDoRepositorioEDoGerador;
var
  LSql: string;
  LTexto: string;
  LInicio: Integer;
  LFim: Integer;
begin
  Assert.IsTrue(ContainsStr(TextoCompacto('Aplicacao.RepositorioCliente'),
    'function ListarParaRelatorio(const AFiltro: TFiltroRelatorioCliente): TClientes;'),
    'O contrato do relatório é o do door 3.');
  Assert.IsTrue(ContainsStr(TextoCompacto('Aplicacao.RepositorioCliente'),
    'function ListarEstados: TEstados;'), 'O repositório lista os estados.');
  Assert.IsTrue(ContainsStr(TextoCompacto('Aplicacao.RepositorioCliente'),
    'function ListarCidades(AEstadoId: Integer): TCidades;'),
    'O repositório lista as cidades do estado.');

  LTexto := TextoCompacto('Aplicacao.GeradorRelatorioCliente');
  Assert.IsTrue(ContainsStr(LTexto,
    'procedure Visualizar(const ADados: TDadosRelatorioCliente);'),
    'O gerador expõe Visualizar.');
  Assert.AreEqual(1, Integer(TRegEx.Matches(LTexto, '(procedure|function)\s+\w+\(').Count),
    'IGeradorRelatorioCliente declara exatamente um método.');

  LTexto := TFile.ReadAllText(ArquivoDaUnitDeSrc('Infraestrutura.RepositorioClienteFireDAC'));
  LInicio := Pos('function TRepositorioClienteFireDAC.ListarParaRelatorio', LTexto);
  Assert.IsTrue(LInicio > 0, 'ListarParaRelatorio deve existir no repositório FireDAC.');
  LFim := Pos('function TRepositorioClienteFireDAC.ListarEstados', LTexto);
  Assert.IsTrue(LFim > LInicio, 'ListarEstados vem depois de ListarParaRelatorio.');
  LSql := Copy(LTexto, LInicio, LFim - LInicio);
  Assert.IsTrue(ContainsStr(LSql, '''ORDER BY C.ID'''),
    'O SQL do relatório termina em ORDER BY C.ID.');
  Assert.IsFalse(ContainsText(LSql, 'FIRST'), 'O relatório não limita as linhas.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesFormFiltroRelatorioCliente);
  TDUnitX.RegisterTestFixture(TTestesArquiteturaRelatorioCliente);

end.

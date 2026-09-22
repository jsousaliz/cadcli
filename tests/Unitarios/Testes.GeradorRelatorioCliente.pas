unit Testes.GeradorRelatorioCliente;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesGeradorRelatorioClienteReportBuilder = class
  private
    FDiretorio: string;
    FArquivo: string;
    function Conteudo: string;
    function Linhas: TArray<string>;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure PaginaUnicaTemCabecalhoColunasELinhasEmOrdem;
    [Test]
    procedure VariasPaginasNumeradasComCabecalhoRepetido;
    [Test]
    procedure SegundaVisualizacaoReiniciaORelatorio;
    [Test]
    procedure DestinoDeProducaoAbrePreVisualizacaoModal;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.StrUtils,
  System.SysUtils,
  Vcl.Forms,
  ppPrvDlg,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.GeradorRelatorioCliente,
  Infraestrutura.GeradorRelatorioClienteReportBuilder,
  Suporte.CaminhosTeste,
  Suporte.FakesClientes;

function Emissao: TDateTime;
begin
  Result := EncodeDate(2026, 9, 22) + EncodeTime(14, 30, 0, 0);
end;

function Dados(const AClientes: TClientes; const ADescricao: string): TDadosRelatorioCliente;
begin
  Result := Default(TDadosRelatorioCliente);
  Result.Clientes := AClientes;
  Result.DescricaoFiltro := ADescricao;
  Result.Emissao := Emissao;
end;

function ClientesUmTresCinco: TClientes;
begin
  Result := [
    NovoCliente(1, 'Ana Silva', '52998224725', '30130010', 'Belo Horizonte', 'MG',
      'Minas Gerais', 0),
    NovoCliente(3, 'Carlos Silva', '11222333000181', '13010000', 'Campinas', 'SP',
      'São Paulo', 0),
    NovoCliente(5, 'bianca souza', '71428793860', '01001000', '', '', '', 0)];
end;

function LinhaDoId(const ALinhas: TArray<string>; AId: Integer): string;
var
  LLinha: string;
begin
  Result := '';
  for LLinha in ALinhas do
    if TRegEx.IsMatch(LLinha, '^\s*' + IntToStr(AId) + '\s') then
      Exit(LLinha);
end;

function IndiceDaLinhaDoId(const ALinhas: TArray<string>; AId: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(ALinhas) do
    if TRegEx.IsMatch(ALinhas[I], '^\s*' + IntToStr(AId) + '\s') then
      Exit(I);
end;

function OcorrenciasDoId(const ALinhas: TArray<string>; AId: Integer): Integer;
var
  LLinha: string;
begin
  Result := 0;
  for LLinha in ALinhas do
    if TRegEx.IsMatch(LLinha, '^\s*' + IntToStr(AId) + '\s') then
      Inc(Result);
end;

function LinhasDeCabecalho(const ALinhas: TArray<string>): Integer;
var
  LLinha: string;
begin
  Result := 0;
  for LLinha in ALinhas do
    if TRegEx.IsMatch(LLinha,
      'ID\s+NOME\s+CPF/CNPJ\s+CEP\s+BAIRRO\s+CIDADE\s+ESTADO') then
      Inc(Result);
end;

procedure TTestesGeradorRelatorioClienteReportBuilder.Preparar;
begin
  FDiretorio := CriarDiretorioTemporario;
  FArquivo := TPath.Combine(FDiretorio, 'relatorio.txt');
end;

procedure TTestesGeradorRelatorioClienteReportBuilder.Limpar;
begin
  if TDirectory.Exists(FDiretorio) then
    TDirectory.Delete(FDiretorio, True);
end;

function TTestesGeradorRelatorioClienteReportBuilder.Conteudo: string;
begin
  Assert.IsTrue(TFile.Exists(FArquivo), 'O relatório deve gerar o arquivo de texto.');
  Result := TFile.ReadAllText(FArquivo, TEncoding.UTF8);
end;

function TTestesGeradorRelatorioClienteReportBuilder.Linhas: TArray<string>;
begin
  Result := Conteudo.Split([sLineBreak, #10]);
end;

procedure TTestesGeradorRelatorioClienteReportBuilder.PaginaUnicaTemCabecalhoColunasELinhasEmOrdem;
var
  LGerador: IGeradorRelatorioCliente;
  LLinhas: TArray<string>;
  LTexto: string;
  LLinhaTres: string;
  LLinhaCinco: string;
begin
  LGerador := TGeradorRelatorioClienteReportBuilder.Create(drArquivoTexto, FArquivo);

  LGerador.Visualizar(Dados(ClientesUmTresCinco, 'Filtro: Todos'));

  LTexto := Conteudo;
  LLinhas := Linhas;
  Assert.IsTrue(ContainsStr(LTexto, 'Relatório de Clientes'), 'O relatório traz o título.');
  Assert.IsTrue(ContainsStr(LTexto, 'Emitido em 22/09/2026 14:30'),
    'O relatório traz a data e hora de emissão.');
  Assert.IsTrue(ContainsStr(LTexto, 'Filtro: Todos'), 'O relatório traz o filtro aplicado.');
  Assert.IsTrue(ContainsStr(LTexto, 'Página 1 de 1'), 'O relatório traz a paginação.');
  Assert.AreEqual(1, LinhasDeCabecalho(LLinhas),
    'As sete colunas aparecem em ordem numa mesma linha.');

  Assert.IsTrue(IndiceDaLinhaDoId(LLinhas, 1) > 0, 'O cliente 1 deve aparecer.');
  Assert.IsTrue(IndiceDaLinhaDoId(LLinhas, 1) < IndiceDaLinhaDoId(LLinhas, 3),
    'O cliente 1 vem antes do 3.');
  Assert.IsTrue(IndiceDaLinhaDoId(LLinhas, 3) < IndiceDaLinhaDoId(LLinhas, 5),
    'O cliente 3 vem antes do 5.');

  LLinhaTres := LinhaDoId(LLinhas, 3);
  Assert.IsTrue(ContainsStr(LLinhaTres, 'Carlos Silva'), 'Nome do cliente 3: ' + LLinhaTres);
  Assert.IsTrue(ContainsStr(LLinhaTres, '11.222.333/0001-81'),
    'CNPJ formatado do cliente 3: ' + LLinhaTres);
  Assert.IsTrue(ContainsStr(LLinhaTres, '13010-000'), 'CEP formatado do cliente 3: ' + LLinhaTres);
  Assert.IsTrue(ContainsStr(LLinhaTres, 'Centro'), 'Bairro do cliente 3: ' + LLinhaTres);
  Assert.IsTrue(ContainsStr(LLinhaTres, 'Campinas'), 'Cidade do cliente 3: ' + LLinhaTres);
  Assert.IsTrue(ContainsStr(LLinhaTres, 'SP'), 'UF do cliente 3: ' + LLinhaTres);

  LLinhaCinco := LinhaDoId(LLinhas, 5);
  Assert.IsTrue(ContainsStr(LLinhaCinco, 'bianca souza'), 'Nome do cliente 5: ' + LLinhaCinco);
  Assert.IsFalse(ContainsStr(LLinhaCinco, 'Campinas'), 'O cliente 5 não tem cidade.');
  Assert.IsFalse(ContainsStr(LLinhaCinco, 'SP'), 'O cliente 5 não tem UF.');
end;

procedure TTestesGeradorRelatorioClienteReportBuilder.VariasPaginasNumeradasComCabecalhoRepetido;
var
  LGeradorObjeto: TGeradorRelatorioClienteReportBuilder;
  LGerador: IGeradorRelatorioCliente;
  LClientes: TClientes;
  LLinhas: TArray<string>;
  LTexto: string;
  I: Integer;
  LTotal: Integer;
  LAnterior: Integer;
begin
  LClientes := [];
  for I := 1 to 120 do
    LClientes := LClientes + [NovoCliente(I, Format('Cliente %.3d', [I]), '52998224725',
      '13010000', 'Campinas', 'SP', 'São Paulo', 0)];
  LGeradorObjeto := TGeradorRelatorioClienteReportBuilder.Create(drArquivoTexto, FArquivo);
  LGerador := LGeradorObjeto;

  LGerador.Visualizar(Dados(LClientes, 'Filtro: Todos'));

  LTotal := LGeradorObjeto.TotalDePaginas;
  Assert.IsTrue(LTotal >= 2, Format('120 clientes ocupam mais de uma página (%d).', [LTotal]));
  LTexto := Conteudo;
  LLinhas := Linhas;
  for I := 1 to LTotal do
    Assert.IsTrue(ContainsStr(LTexto, Format('Página %d de %d', [I, LTotal])),
      Format('A página %d deve ser numerada.', [I]));
  Assert.AreEqual(LTotal, LinhasDeCabecalho(LLinhas),
    'O cabeçalho das colunas se repete em cada página.');

  LAnterior := -1;
  for I := 1 to 120 do
  begin
    Assert.AreEqual(1, OcorrenciasDoId(LLinhas, I),
      Format('O cliente %d aparece exatamente uma vez.', [I]));
    Assert.IsTrue(IndiceDaLinhaDoId(LLinhas, I) > LAnterior,
      Format('O cliente %d vem depois do anterior.', [I]));
    LAnterior := IndiceDaLinhaDoId(LLinhas, I);
  end;
end;

procedure TTestesGeradorRelatorioClienteReportBuilder.SegundaVisualizacaoReiniciaORelatorio;
var
  LGerador: IGeradorRelatorioCliente;
  LTexto: string;
  LLinhas: TArray<string>;
begin
  LGerador := TGeradorRelatorioClienteReportBuilder.Create(drArquivoTexto, FArquivo);
  LGerador.Visualizar(Dados(ClientesUmTresCinco, 'Filtro: Todos'));

  LGerador.Visualizar(Dados([
    NovoCliente(2, 'Bruno Costa', '11144477735', '35420000', 'Mariana', 'MG', 'Minas Gerais', 0),
    NovoCliente(4, 'Denise D''Avila', '39053344705', '13015000', 'Campinas', 'SP',
      'São Paulo', 0)], 'Filtro: Estado MG'));

  LTexto := Conteudo;
  LLinhas := Linhas;
  Assert.IsTrue(ContainsStr(LTexto, 'Filtro: Estado MG'), 'O segundo filtro aparece.');
  Assert.IsFalse(ContainsStr(LTexto, 'Filtro: Todos'), 'O filtro anterior não permanece.');
  Assert.IsTrue(ContainsStr(LTexto, 'Página 1 de 1'), 'A segunda geração recomeça na página 1.');
  Assert.AreEqual(1, OcorrenciasDoId(LLinhas, 2), 'O cliente 2 aparece uma vez.');
  Assert.AreEqual(1, OcorrenciasDoId(LLinhas, 4), 'O cliente 4 aparece uma vez.');
  Assert.AreEqual(0, OcorrenciasDoId(LLinhas, 1), 'O cliente 1 não pode permanecer.');
  Assert.AreEqual(0, OcorrenciasDoId(LLinhas, 3), 'O cliente 3 não pode permanecer.');
  Assert.AreEqual(0, OcorrenciasDoId(LLinhas, 5), 'O cliente 5 não pode permanecer.');
end;

type
  TFechadorDePreVisualizacao = class
  public
    PreVisualizacoes: Integer;
    Modais: Integer;
    Dialogos: Integer;
    procedure Inspecionar(Sender: TObject; var ADone: Boolean);
  end;

procedure TFechadorDePreVisualizacao.Inspecionar(Sender: TObject; var ADone: Boolean);
var
  I: Integer;
  LForm: TForm;
begin
  ADone := False;
  for I := Screen.FormCount - 1 downto 0 do
  begin
    LForm := Screen.Forms[I];
    if not LForm.Visible then
      Continue;
    if LForm is TppPrintPreview then
    begin
      Inc(PreVisualizacoes);
      if fsModal in LForm.FormState then
        Inc(Modais);
      LForm.Close;
    end
    else if LForm.ClassNameIs('TMessageForm') then
    begin
      Inc(Dialogos);
      LForm.Close;
    end;
  end;
end;

procedure TTestesGeradorRelatorioClienteReportBuilder.DestinoDeProducaoAbrePreVisualizacaoModal;
var
  LGerador: IGeradorRelatorioCliente;
  LFechador: TFechadorDePreVisualizacao;
  LFormsAntes: Integer;
  I: Integer;
  LRemanescentes: Integer;
begin
  LGerador := TGeradorRelatorioClienteReportBuilder.Create(drPreVisualizacao);
  LFechador := TFechadorDePreVisualizacao.Create;
  try
    LFormsAntes := Screen.FormCount;
    Application.OnIdle := LFechador.Inspecionar;
    try
      LGerador.Visualizar(Dados(ClientesUmTresCinco, 'Filtro: Todos'));
    finally
      Application.OnIdle := nil;
    end;
    Application.ProcessMessages;

    Assert.AreEqual(1, LFechador.PreVisualizacoes,
      'Deve ser exibida exatamente 1 pré-visualização.');
    Assert.AreEqual(1, LFechador.Modais, 'A pré-visualização é modal.');
    Assert.AreEqual(0, LFechador.Dialogos, 'Nenhum diálogo de impressão pode aparecer.');
    LRemanescentes := 0;
    for I := 0 to Screen.FormCount - 1 do
      if Screen.Forms[I] is TppPrintPreview then
        Inc(LRemanescentes);
    Assert.AreEqual(0, LRemanescentes, 'Nenhuma pré-visualização permanece aberta.');
    Assert.AreEqual(LFormsAntes, Screen.FormCount, 'A pré-visualização é liberada ao fechar.');
  finally
    LFechador.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesGeradorRelatorioClienteReportBuilder);

end.

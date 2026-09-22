unit Infraestrutura.GeradorRelatorioClienteReportBuilder;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  ppTypes,
  ppClass,
  ppComm,
  ppRelatv,
  ppProd,
  ppReport,
  ppCtrls,
  ppPrnabl,
  ppBands,
  ppVar,
  ppDB,
  ppDBJIT,
  ppFilDev,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.GeradorRelatorioCliente;

type
  TDestinoRelatorio = (drPreVisualizacao, drArquivoTexto);

  TGeradorRelatorioClienteReportBuilder = class(TInterfacedObject, IGeradorRelatorioCliente)
  private
    FDestino: TDestinoRelatorio;
    FNomeArquivo: string;
    FClientes: TClientes;
    FIndice: Integer;
    FTotalDePaginas: Integer;
    function ValorDoCampo(ANomeCampo: string): Variant;
    function Ativo: Boolean;
    function FimDosDados: Boolean;
    function InicioDosDados: Boolean;
    function PosicaoAtual: Integer;
    procedure IrParaPosicao(APosicao: Integer);
    procedure LiberarPosicao(APosicao: Integer);
    procedure IrParaOPrimeiro(Sender: TObject);
    procedure IrParaOUltimo(Sender: TObject);
    procedure Avancar(ADistancia: Integer);
    procedure MontarCabecalho(ARelatorio: TppReport; const ADados: TDadosRelatorioCliente);
    procedure MontarDetalhe(ARelatorio: TppReport; APipeline: TppJITPipeline);
    procedure MontarRodape(ARelatorio: TppReport);
  public
    constructor Create(ADestino: TDestinoRelatorio; const ANomeArquivo: string = '');
    procedure Visualizar(const ADados: TDadosRelatorioCliente);
    property TotalDePaginas: Integer read FTotalDePaginas;
  end;

const
  TITULO_RELATORIO = 'Relatório de Clientes';
  ROTULO_EMISSAO = 'Emitido em %s';
  FORMATO_EMISSAO = 'dd/mm/yyyy hh:nn';
  COLUNAS_RELATORIO: array[0..6] of string = ('ID', 'NOME', 'CPF/CNPJ', 'CEP', 'BAIRRO',
    'CIDADE', 'ESTADO');
  CAMPOS_RELATORIO: array[0..6] of string = ('ID', 'NOME', 'CPFCNPJ', 'CEP', 'BAIRRO',
    'CIDADE', 'ESTADO');
  ESQUERDA_COLUNAS: array[0..6] of Single = (0, 13, 64, 98, 119, 148, 177);
  LARGURA_COLUNAS: array[0..6] of Single = (12, 50, 33, 20, 28, 28, 13);

implementation

const
  MARGEM = 10;
  ALTURA_CABECALHO = 26;
  ALTURA_DETALHE = 5;
  ALTURA_RODAPE = 8;
  TOPO_COLUNAS = 20;
  TAMANHO_FONTE = 7;
  TAMANHO_FONTE_TITULO = 11;

function Rotulo(ABanda: TppCustomBand; const ATexto: string; AEsquerda, ATopo, ALargura: Single;
  ATamanhoFonte: Integer): TppLabel;
begin
  Result := TppLabel.Create(nil);
  Result.Band := ABanda;
  Result.AutoSize := False;
  Result.Font.Size := ATamanhoFonte;
  Result.Caption := ATexto;
  Result.Left := AEsquerda;
  Result.Top := ATopo;
  Result.Width := ALargura;
end;

constructor TGeradorRelatorioClienteReportBuilder.Create(ADestino: TDestinoRelatorio;
  const ANomeArquivo: string);
begin
  inherited Create;
  if (ADestino = drArquivoTexto) and (Trim(ANomeArquivo) = '') then
    raise EArgumentException.Create('O arquivo de saída do relatório deve ser informado.');
  FDestino := ADestino;
  FNomeArquivo := ANomeArquivo;
end;

function TGeradorRelatorioClienteReportBuilder.ValorDoCampo(ANomeCampo: string): Variant;
var
  LCliente: TCliente;
begin
  if (FIndice < 0) or (FIndice > High(FClientes)) then
    Exit('');
  LCliente := FClientes[FIndice];
  if ANomeCampo = 'ID' then
    Result := LCliente.Id
  else if ANomeCampo = 'NOME' then
    Result := LCliente.Nome
  else if ANomeCampo = 'CPFCNPJ' then
    Result := FormatarCpfCnpj(LCliente.CpfCnpj)
  else if ANomeCampo = 'CEP' then
    Result := FormatarCep(LCliente.Cep)
  else if ANomeCampo = 'BAIRRO' then
    Result := LCliente.Bairro
  else if ANomeCampo = 'CIDADE' then
    Result := LCliente.Cidade
  else if ANomeCampo = 'ESTADO' then
    Result := LCliente.Uf
  else
    Result := '';
end;

function TGeradorRelatorioClienteReportBuilder.Ativo: Boolean;
begin
  Result := True;
end;

function TGeradorRelatorioClienteReportBuilder.FimDosDados: Boolean;
begin
  Result := FIndice > High(FClientes);
end;

function TGeradorRelatorioClienteReportBuilder.InicioDosDados: Boolean;
begin
  Result := FIndice < 0;
end;

function TGeradorRelatorioClienteReportBuilder.PosicaoAtual: Integer;
begin
  Result := FIndice;
end;

procedure TGeradorRelatorioClienteReportBuilder.IrParaPosicao(APosicao: Integer);
begin
  FIndice := APosicao;
end;

procedure TGeradorRelatorioClienteReportBuilder.LiberarPosicao(APosicao: Integer);
begin
end;

procedure TGeradorRelatorioClienteReportBuilder.IrParaOPrimeiro(Sender: TObject);
begin
  FIndice := 0;
end;

procedure TGeradorRelatorioClienteReportBuilder.IrParaOUltimo(Sender: TObject);
begin
  FIndice := High(FClientes);
end;

procedure TGeradorRelatorioClienteReportBuilder.Avancar(ADistancia: Integer);
begin
  FIndice := FIndice + ADistancia;
end;

procedure TGeradorRelatorioClienteReportBuilder.MontarCabecalho(ARelatorio: TppReport;
  const ADados: TDadosRelatorioCliente);
var
  LBanda: TppHeaderBand;
  I: Integer;
begin
  LBanda := TppHeaderBand.Create(nil);
  LBanda.Report := ARelatorio;
  LBanda.Height := ALTURA_CABECALHO;
  Rotulo(LBanda, TITULO_RELATORIO, 0, 0, 100, TAMANHO_FONTE_TITULO);
  Rotulo(LBanda, Format(ROTULO_EMISSAO, [FormatDateTime(FORMATO_EMISSAO, ADados.Emissao)]),
    0, 8, 90, TAMANHO_FONTE);
  Rotulo(LBanda, ADados.DescricaoFiltro, 0, 13, 190, TAMANHO_FONTE);
  for I := Low(COLUNAS_RELATORIO) to High(COLUNAS_RELATORIO) do
    Rotulo(LBanda, COLUNAS_RELATORIO[I], ESQUERDA_COLUNAS[I], TOPO_COLUNAS,
      LARGURA_COLUNAS[I], TAMANHO_FONTE);
end;

procedure TGeradorRelatorioClienteReportBuilder.MontarDetalhe(ARelatorio: TppReport;
  APipeline: TppJITPipeline);
var
  LBanda: TppDetailBand;
  LTexto: TppDBText;
  I: Integer;
begin
  LBanda := TppDetailBand.Create(nil);
  LBanda.Report := ARelatorio;
  LBanda.Height := ALTURA_DETALHE;
  for I := Low(CAMPOS_RELATORIO) to High(CAMPOS_RELATORIO) do
  begin
    LTexto := TppDBText.Create(nil);
    LTexto.Band := LBanda;
    LTexto.AutoSize := False;
    LTexto.Font.Size := TAMANHO_FONTE;
    LTexto.DataPipeline := APipeline;
    LTexto.DataField := CAMPOS_RELATORIO[I];
    LTexto.Left := ESQUERDA_COLUNAS[I];
    LTexto.Top := 0;
    LTexto.Width := LARGURA_COLUNAS[I];
  end;
end;

procedure TGeradorRelatorioClienteReportBuilder.MontarRodape(ARelatorio: TppReport);
var
  LBanda: TppFooterBand;
  LVariavel: TppSystemVariable;
begin
  LBanda := TppFooterBand.Create(nil);
  LBanda.Report := ARelatorio;
  LBanda.Height := ALTURA_RODAPE;
  LVariavel := TppSystemVariable.Create(nil);
  LVariavel.Band := LBanda;
  LVariavel.AutoSize := False;
  LVariavel.Font.Size := TAMANHO_FONTE;
  LVariavel.VarType := vtPageSetDesc;
  LVariavel.Left := 0;
  LVariavel.Top := 2;
  LVariavel.Width := 60;
end;

procedure TGeradorRelatorioClienteReportBuilder.Visualizar(
  const ADados: TDadosRelatorioCliente);
var
  LRelatorio: TppReport;
  LPipeline: TppJITPipeline;
  I: Integer;
begin
  FClientes := ADados.Clientes;
  FIndice := 0;
  FTotalDePaginas := 0;
  LRelatorio := TppReport.Create(nil);
  LPipeline := TppJITPipeline.Create(nil);
  try
    LPipeline.UserName := 'ClientesDoRelatorio';
    LPipeline.RecordCount := Length(FClientes);
    LPipeline.OnGetFieldValue := ValorDoCampo;
    LPipeline.OnGetActive := Ativo;
    LPipeline.OnCheckEOF := FimDosDados;
    LPipeline.OnCheckBOF := InicioDosDados;
    LPipeline.OnGotoFirstRecord := IrParaOPrimeiro;
    LPipeline.OnGotoLastRecord := IrParaOUltimo;
    LPipeline.OnTraverseBy := Avancar;
    LPipeline.OnGetBookmark := PosicaoAtual;
    LPipeline.OnGotoBookmark := IrParaPosicao;
    LPipeline.OnFreeBookmark := LiberarPosicao;
    for I := Low(CAMPOS_RELATORIO) to High(CAMPOS_RELATORIO) do
      if CAMPOS_RELATORIO[I] = 'ID' then
        LPipeline.DefineField(CAMPOS_RELATORIO[I], dtInteger, 8)
      else
        LPipeline.DefineField(CAMPOS_RELATORIO[I], dtString, 60);

    LRelatorio.Units := utMillimeters;
    LRelatorio.DataPipeline := LPipeline;
    LRelatorio.PrinterSetup.PaperName := 'A4';
    LRelatorio.PrinterSetup.Orientation := poPortrait;
    LRelatorio.PrinterSetup.MarginLeft := MARGEM;
    LRelatorio.PrinterSetup.MarginRight := MARGEM;
    LRelatorio.PrinterSetup.MarginTop := MARGEM;
    LRelatorio.PrinterSetup.MarginBottom := MARGEM;
    LRelatorio.ShowPrintDialog := False;
    LRelatorio.ShowCancelDialog := False;

    MontarCabecalho(LRelatorio, ADados);
    MontarDetalhe(LRelatorio, LPipeline);
    MontarRodape(LRelatorio);

    if FDestino = drArquivoTexto then
    begin
      LRelatorio.AllowPrintToFile := True;
      LRelatorio.DeviceType := dtReportTextFile;
      LRelatorio.TextFileName := FNomeArquivo;
    end
    else
    begin
      LRelatorio.DeviceType := dtScreen;
      LRelatorio.ModalPreview := True;
    end;

    LRelatorio.Print;
    FTotalDePaginas := LRelatorio.AbsolutePageCount;
  finally
    LPipeline.Free;
    LRelatorio.Free;
    FClientes := nil;
  end;
end;

end.

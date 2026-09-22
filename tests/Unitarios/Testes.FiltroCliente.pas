unit Testes.FiltroCliente;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesFiltroCliente = class
  public
    [Test]
    procedure CadaCampoAceitaERejeitaOsCasosDaTabela;
    [Test]
    procedure CamposMarcadosCombinamPorOr;
    [Test]
    procedure NenhumCampoMarcadoPesquisaEmTodos;
    [Test]
    procedure TextoVazioAceitaTodosEDataCombinaPorAnd;
  end;

implementation

uses
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Suporte.FakesClientes;

type
  TCasoFiltro = record
    Campo: TCampoPesquisa;
    Valor: string;
    IdCliente: Integer;
    Aceita: Boolean;
  end;

function Caso(ACampo: TCampoPesquisa; const AValor: string; AIdCliente: Integer;
  AAceita: Boolean): TCasoFiltro;
begin
  Result.Campo := ACampo;
  Result.Valor := AValor;
  Result.IdCliente := AIdCliente;
  Result.Aceita := AAceita;
end;

function FiltroCom(const ATexto: string; ACampos: TCamposPesquisa): TFiltroCliente;
begin
  Result := Default(TFiltroCliente);
  Result.Texto := ATexto;
  Result.Campos := ACampos;
end;

function ClientePorId(AId: Integer): TCliente;
var
  LCliente: TCliente;
begin
  for LCliente in ClientesDaFixture do
    if LCliente.Id = AId then
      Exit(LCliente);
  raise Exception.CreateFmt('Cliente %d fora da fixture.', [AId]);
end;

function IdsAceitos(const AFiltro: TFiltroCliente): string;
var
  LCliente: TCliente;
begin
  Result := '';
  for LCliente in ClientesDaFixture do
    if AFiltro.Atende(LCliente) then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + IntToStr(LCliente.Id);
    end;
end;

procedure TTestesFiltroCliente.CadaCampoAceitaERejeitaOsCasosDaTabela;
var
  LCasos: TArray<TCasoFiltro>;
  LCaso: TCasoFiltro;
begin
  LCasos := [
    Caso(cpId, '1', 1, True),
    Caso(cpId, '1', 10, False),
    Caso(cpId, '1', 15, False),
    Caso(cpNome, 'SIL', 1, True),
    Caso(cpNome, 'SIL', 10, False),
    Caso(cpCpfCnpj, '529.982.247-25', 1, True),
    Caso(cpCpfCnpj, '529982247', 1, False),
    Caso(cpCpfCnpj, 'abc', 1, False),
    Caso(cpCep, '01001-000', 23, True),
    Caso(cpCep, '0100100', 23, False),
    Caso(cpCidade, 'campi', 15, True),
    Caso(cpCidade, 'campi', 1, False),
    Caso(cpEstado, 'sp', 15, True),
    Caso(cpEstado, 'paulo', 15, True),
    Caso(cpEstado, 'MG', 15, False)];
  for LCaso in LCasos do
    Assert.AreEqual(LCaso.Aceita, FiltroCom(LCaso.Valor, [LCaso.Campo]).Atende(ClientePorId(LCaso.IdCliente)),
      Format('Campo %d com "%s" sobre o cliente %d.', [Ord(LCaso.Campo), LCaso.Valor, LCaso.IdCliente]));
  Assert.AreEqual('1,15', IdsAceitos(FiltroCom('  silva   ', [cpNome])),
    'O texto deve ser comparado sem os espaços das pontas.');
end;

procedure TTestesFiltroCliente.CamposMarcadosCombinamPorOr;
begin
  Assert.AreEqual('15,150', IdsAceitos(FiltroCom('campinas', [cpNome, cpCidade])),
    'Campinas deve ser achada pela cidade mesmo sem casar com o nome.');
  Assert.AreEqual('', IdsAceitos(FiltroCom('campinas', [cpId, cpNome])),
    'Campos desmarcados não podem ser considerados.');
  Assert.AreEqual('1,15', IdsAceitos(FiltroCom('silva', [cpId, cpNome])));
  Assert.AreEqual('1', IdsAceitos(FiltroCom('1', [cpId, cpNome])),
    'ID continua exato quando combinado com outros campos.');
end;

procedure TTestesFiltroCliente.NenhumCampoMarcadoPesquisaEmTodos;
begin
  Assert.AreEqual(IdsAceitos(FiltroCom('campinas', [Low(TCampoPesquisa)..High(TCampoPesquisa)])),
    IdsAceitos(FiltroCom('campinas', [])));
  Assert.AreEqual('15,150', IdsAceitos(FiltroCom('campinas', [])));
  Assert.AreEqual('1,10', IdsAceitos(FiltroCom('MG', [])));
end;

procedure TTestesFiltroCliente.TextoVazioAceitaTodosEDataCombinaPorAnd;
var
  LFiltro: TFiltroCliente;
begin
  Assert.AreEqual('1,10,15,150,23', IdsAceitos(Default(TFiltroCliente)),
    'Filtro vazio deve aceitar os 5 clientes.');
  Assert.AreEqual('1,10,15,150,23', IdsAceitos(FiltroCom('   ', [cpNome])),
    'Texto só com espaços deve aceitar os 5 clientes.');

  LFiltro := Default(TFiltroCliente);
  LFiltro.DataNascimento := '15/03/1990';
  Assert.AreEqual('1', IdsAceitos(LFiltro), 'A data de nascimento deve aceitar somente o nascimento exato.');

  LFiltro := FiltroCom('silva', [cpNome]);
  LFiltro.DataNascimento := '02/01/1978';
  Assert.AreEqual('15', IdsAceitos(LFiltro), 'Texto e data devem combinar por AND.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesFiltroCliente);

end.

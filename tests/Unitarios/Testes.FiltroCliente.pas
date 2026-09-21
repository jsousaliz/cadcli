unit Testes.FiltroCliente;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesFiltroCliente = class
  public
    [Test]
    procedure FiltrosPorCampoAceitamERejeitamOsCasosDaTabela;
    [Test]
    procedure FiltrosPreenchidosCombinamPorAndEVaziosAceitamTodos;
    [Test]
    procedure BuscaGeralAlcancaCadaCampo;
    [Test]
    procedure BuscaGeralExigeCadaPalavraEDigitosSoComparamDigitos;
  end;

implementation

uses
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Suporte.FakesClientes;

type
  TCampoFiltro = (cfId, cfNome, cfCpfCnpj, cfCep, cfCidade, cfEstado, cfDataNascimento, cfBusca);

  TCasoFiltro = record
    Campo: TCampoFiltro;
    Valor: string;
    IdCliente: Integer;
    Aceita: Boolean;
  end;

function Caso(ACampo: TCampoFiltro; const AValor: string; AIdCliente: Integer;
  AAceita: Boolean): TCasoFiltro;
begin
  Result.Campo := ACampo;
  Result.Valor := AValor;
  Result.IdCliente := AIdCliente;
  Result.Aceita := AAceita;
end;

function FiltroCom(ACampo: TCampoFiltro; const AValor: string): TFiltroCliente;
begin
  Result := Default(TFiltroCliente);
  case ACampo of
    cfId: Result.Id := AValor;
    cfNome: Result.Nome := AValor;
    cfCpfCnpj: Result.CpfCnpj := AValor;
    cfCep: Result.Cep := AValor;
    cfCidade: Result.Cidade := AValor;
    cfEstado: Result.Estado := AValor;
    cfDataNascimento: Result.DataNascimento := AValor;
    cfBusca: Result.BuscaGeral := AValor;
  end;
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

function ClienteNeutro: TCliente;
begin
  Result := NovoCliente(2, 'Zé Teste', '11144477735', '99999999', 'Natal', 'RN',
    'Rio Grande do Norte', EncodeDate(2001, 1, 1));
end;

procedure TTestesFiltroCliente.FiltrosPorCampoAceitamERejeitamOsCasosDaTabela;
var
  LCasos: TArray<TCasoFiltro>;
  LCaso: TCasoFiltro;
begin
  LCasos := [
    Caso(cfId, '1', 1, True),
    Caso(cfId, '1', 10, False),
    Caso(cfId, '1', 15, False),
    Caso(cfNome, 'SIL', 1, True),
    Caso(cfNome, 'SIL', 10, False),
    Caso(cfCpfCnpj, '529.982.247-25', 1, True),
    Caso(cfCpfCnpj, '529982247', 1, False),
    Caso(cfCep, '01001-000', 23, True),
    Caso(cfCep, '0100100', 23, False),
    Caso(cfCidade, 'campi', 15, True),
    Caso(cfCidade, 'campi', 1, False),
    Caso(cfEstado, 'sp', 15, True),
    Caso(cfEstado, 'paulo', 15, True),
    Caso(cfEstado, 'MG', 15, False),
    Caso(cfDataNascimento, '15/03/1990', 1, True)];
  for LCaso in LCasos do
    Assert.AreEqual(LCaso.Aceita, FiltroCom(LCaso.Campo, LCaso.Valor).Atende(ClientePorId(LCaso.IdCliente)),
      Format('Filtro %d com "%s" sobre o cliente %d.', [Ord(LCaso.Campo), LCaso.Valor, LCaso.IdCliente]));
  Assert.AreEqual('1', IdsAceitos(FiltroCom(cfDataNascimento, '15/03/1990')),
    'A data de nascimento deve aceitar somente o nascimento exato.');
end;

procedure TTestesFiltroCliente.FiltrosPreenchidosCombinamPorAndEVaziosAceitamTodos;
var
  LFiltro: TFiltroCliente;
begin
  LFiltro := Default(TFiltroCliente);
  LFiltro.Nome := 'silva';
  LFiltro.Estado := 'MG';
  Assert.IsTrue(LFiltro.Atende(ClientePorId(1)), 'Ana Silva de Belo Horizonte/MG deve ser aceita.');
  Assert.IsFalse(LFiltro.Atende(ClientePorId(15)), 'Carlos Silva de Campinas/SP deve ser rejeitado.');
  Assert.IsFalse(LFiltro.Atende(ClientePorId(10)), 'Bruno Costa de Contagem/MG deve ser rejeitado.');
  Assert.AreEqual('1', IdsAceitos(LFiltro));
  Assert.AreEqual('1,10,15,150,23', IdsAceitos(Default(TFiltroCliente)),
    'Filtros e busca geral vazios devem aceitar os 5 clientes.');
end;

procedure TTestesFiltroCliente.BuscaGeralAlcancaCadaCampo;
var
  LCliente: TCliente;
  LBusca: TFiltroCliente;
begin
  Assert.IsFalse(FiltroCom(cfBusca, '15').Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.Id := 15;
  Assert.IsTrue(FiltroCom(cfBusca, '15').Atende(LCliente), 'ID 15 deve ser encontrado por 15.');
  LCliente.Id := 150;
  Assert.IsTrue(FiltroCom(cfBusca, '15').Atende(LCliente), 'ID 150 deve ser encontrado por 15.');

  LBusca := FiltroCom(cfBusca, 'SILVA');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.Nome := 'Ana Silva';
  Assert.IsTrue(LBusca.Atende(LCliente), 'Nome deve ser alcançado.');

  LBusca := FiltroCom(cfBusca, '247-25');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.CpfCnpj := '52998224725';
  Assert.IsTrue(LBusca.Atende(LCliente), 'CPF/CNPJ deve ser alcançado pelos dígitos.');

  LBusca := FiltroCom(cfBusca, '01001');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.Cep := '01001000';
  Assert.IsTrue(LBusca.Atende(LCliente), 'CEP deve ser alcançado pelos dígitos.');

  LBusca := FiltroCom(cfBusca, 'campinas');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.Cidade := 'Campinas';
  Assert.IsTrue(LBusca.Atende(LCliente), 'Cidade deve ser alcançada.');

  LBusca := FiltroCom(cfBusca, 'sp');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.Uf := 'SP';
  Assert.IsTrue(LBusca.Atende(LCliente), 'UF deve ser alcançada.');

  LBusca := FiltroCom(cfBusca, 'paulo');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.Estado := 'São Paulo';
  Assert.IsTrue(LBusca.Atende(LCliente), 'Estado deve ser alcançado.');

  LBusca := FiltroCom(cfBusca, '03/1990');
  Assert.IsFalse(LBusca.Atende(ClienteNeutro));
  LCliente := ClienteNeutro;
  LCliente.DataNascimento := EncodeDate(1990, 3, 15);
  Assert.IsTrue(LBusca.Atende(LCliente), 'Data de nascimento deve ser alcançada em dd/mm/aaaa.');
end;

procedure TTestesFiltroCliente.BuscaGeralExigeCadaPalavraEDigitosSoComparamDigitos;
var
  LFiltro: TFiltroCliente;
  LCliente: TCliente;
begin
  LFiltro := FiltroCom(cfBusca, 'silva campinas');
  Assert.IsTrue(LFiltro.Atende(ClientePorId(15)), 'Carlos Silva de Campinas deve ser aceito.');
  Assert.IsFalse(LFiltro.Atende(ClientePorId(1)), 'Ana Silva de Belo Horizonte deve ser rejeitada.');
  Assert.IsFalse(LFiltro.Atende(ClientePorId(150)), 'Denise Rocha de Campinas deve ser rejeitada.');
  Assert.AreEqual('15', IdsAceitos(LFiltro));

  LCliente := ClienteNeutro;
  Assert.IsFalse(FiltroCom(cfBusca, 'abc').Atende(LCliente),
    'Uma palavra sem dígitos não pode ser aceita por CPF/CNPJ nem por CEP.');

  Assert.AreEqual(IdsAceitos(FiltroCom(cfBusca, 'silva')), IdsAceitos(FiltroCom(cfBusca, '  silva   ')));
  Assert.AreEqual('1,15', IdsAceitos(FiltroCom(cfBusca, '  silva   ')));

  LFiltro := FiltroCom(cfBusca, 'silva');
  LFiltro.Estado := 'SP';
  Assert.AreEqual('15', IdsAceitos(LFiltro), 'A busca geral deve combinar por AND com o estado.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesFiltroCliente);

end.

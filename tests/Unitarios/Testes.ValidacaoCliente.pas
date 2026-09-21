unit Testes.ValidacaoCliente;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesValidacaoCliente = class
  public
    [Test]
    procedure CpfCnpjValidaTamanhoEDigitosVerificadores;
  end;

  [TestFixture]
  TTestesTabelaUfs = class
  public
    [Test]
    procedure VinteESeteUfsComNomes;
  end;

implementation

uses
  System.SysUtils,
  Aplicacao.ControladorCadastroCliente,
  Dominio.UnidadesFederativas,
  Dominio.ValidacaoCliente,
  Suporte.FakesClientes;

type
  TResultadoSalvamento = record
    Iniciadas: Integer;
    Mensagens: string;
    CpfGravado: string;
  end;

function SalvarComDocumento(const ADocumento: string): TResultadoSalvamento;
var
  LVisaoObjeto: TVisaoCadastroClienteFake;
  LVisao: IVisaoCadastroCliente;
  LRepositorioObjeto: TRepositorioClienteFake;
  LRepositorio: IInterface;
  LTransacaoObjeto: TTransacaoFake;
  LTransacao: IInterface;
  LControlador: TControladorCadastroCliente;
begin
  LVisaoObjeto := TVisaoCadastroClienteFake.Create;
  LVisao := LVisaoObjeto;
  LRepositorioObjeto := TRepositorioClienteFake.Create;
  LRepositorio := LRepositorioObjeto as IInterface;
  LTransacaoObjeto := TTransacaoFake.Create;
  LTransacao := LTransacaoObjeto as IInterface;
  LControlador := TControladorCadastroCliente.Create(LVisao, LRepositorioObjeto, LTransacaoObjeto,
    TServicoViaCepFake.Create, TRelogioFake.Create(EncodeDate(2026, 9, 21)), TConfirmacaoFake.Create);
  try
    LControlador.Abrir(mcInclusao);
    LVisaoObjeto.Dados := DadosValidos;
    LVisaoObjeto.Dados.CpfCnpj := ADocumento;
    LControlador.Salvar;
    Result.Iniciadas := LTransacaoObjeto.Iniciadas;
    Result.Mensagens := LVisaoObjeto.Mensagens.Text.Trim;
    Result.CpfGravado := LRepositorioObjeto.UltimoIncluido.CpfCnpj;
  finally
    LControlador.Free;
  end;
end;

procedure TTestesValidacaoCliente.CpfCnpjValidaTamanhoEDigitosVerificadores;
const
  VALIDOS: array[0..1] of string = ('529.982.247-25', '11.222.333/0001-81');
  GRAVADOS: array[0..1] of string = ('52998224725', '11222333000181');
  INVALIDOS: array[0..6] of string = ('529.982.247-24', '11.222.333/0001-80', '111.111.111-11',
    '00.000.000/0000-00', '5299822472', '112223330001', '112223330001810');
var
  I: Integer;
  LResultado: TResultadoSalvamento;
begin
  for I := Low(VALIDOS) to High(VALIDOS) do
  begin
    LResultado := SalvarComDocumento(VALIDOS[I]);
    Assert.AreEqual(1, LResultado.Iniciadas, VALIDOS[I] + ' deve prosseguir para o salvamento.');
    Assert.AreEqual('', LResultado.Mensagens, VALIDOS[I] + ' não pode gerar mensagem.');
    Assert.AreEqual(GRAVADOS[I], LResultado.CpfGravado, 'Somente os dígitos devem ser gravados.');
  end;
  for I := Low(INVALIDOS) to High(INVALIDOS) do
  begin
    LResultado := SalvarComDocumento(INVALIDOS[I]);
    Assert.AreEqual(0, LResultado.Iniciadas, INVALIDOS[I] + ' não pode iniciar transação.');
    Assert.AreEqual('CPF/CNPJ inválido', LResultado.Mensagens, INVALIDOS[I]);
  end;
  Assert.AreEqual(10, Length('5299822472'));
  Assert.AreEqual(12, Length('112223330001'));
  Assert.AreEqual(15, Length('112223330001810'));
  Assert.IsTrue(CpfCnpjValido('52998224725'));
  Assert.IsTrue(CpfCnpjValido('11222333000181'));
  Assert.IsFalse(CpfCnpjValido('00000000000'));
end;

procedure TTestesTabelaUfs.VinteESeteUfsComNomes;
const
  ESPERADAS: array[0..26] of string = (
    'AC=Acre', 'AL=Alagoas', 'AP=Amapá', 'AM=Amazonas', 'BA=Bahia', 'CE=Ceará',
    'DF=Distrito Federal', 'ES=Espírito Santo', 'GO=Goiás', 'MA=Maranhão', 'MT=Mato Grosso',
    'MS=Mato Grosso do Sul', 'MG=Minas Gerais', 'PA=Pará', 'PB=Paraíba', 'PR=Paraná',
    'PE=Pernambuco', 'PI=Piauí', 'RJ=Rio de Janeiro', 'RN=Rio Grande do Norte',
    'RS=Rio Grande do Sul', 'RO=Rondônia', 'RR=Roraima', 'SC=Santa Catarina', 'SP=São Paulo',
    'SE=Sergipe', 'TO=Tocantins');
var
  LEsperada: string;
  LPartes: TArray<string>;
begin
  Assert.AreEqual(27, Integer(Length(UNIDADES_FEDERATIVAS)), 'A tabela deve ter exatamente 27 UFs.');
  for LEsperada in ESPERADAS do
  begin
    LPartes := LEsperada.Split(['=']);
    Assert.AreEqual(LPartes[1], NomeDaUf(LPartes[0]), 'Nome da UF ' + LPartes[0]);
  end;
  Assert.AreEqual('', NomeDaUf('XX'), 'Uma sigla desconhecida não tem nome.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesValidacaoCliente);
  TDUnitX.RegisterTestFixture(TTestesTabelaUfs);

end.

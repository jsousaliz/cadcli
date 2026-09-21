unit Testes.ServicoViaCep;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesServicoViaCep = class
  public
    [Test]
    procedure MontaUrlEConverteCorpoRealEmEndereco;
    [Test]
    procedure TraduzCadaRespostaParaUmResultadoTipado;
  end;

  [TestFixture]
  TTestesTransporteHttp = class
  public
    [Test]
    procedure ServidorLocalSemRespostaEsgotaEmDezSegundos;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.Winsock2,
  System.SysUtils,
  Aplicacao.ServicoViaCep,
  Infraestrutura.ServicoViaCep,
  Infraestrutura.TransporteHttp;

const
  CORPO_REAL_01001000 =
    '{' + sLineBreak +
    '  "cep": "01001-000",' + sLineBreak +
    '  "logradouro": "Praça da Sé",' + sLineBreak +
    '  "complemento": "lado ímpar",' + sLineBreak +
    '  "unidade": "",' + sLineBreak +
    '  "bairro": "Sé",' + sLineBreak +
    '  "localidade": "São Paulo",' + sLineBreak +
    '  "uf": "SP",' + sLineBreak +
    '  "estado": "São Paulo",' + sLineBreak +
    '  "regiao": "Sudeste",' + sLineBreak +
    '  "ibge": "3550308",' + sLineBreak +
    '  "gia": "1004",' + sLineBreak +
    '  "ddd": "11",' + sLineBreak +
    '  "siafi": "7107"' + sLineBreak +
    '}';

type
  TComportamentoTransporte = (ctResponder, ctLancarExcecao);

  TTransporteHttpFake = class(TInterfacedObject, ITransporteHttp)
  public
    Resposta: TRespostaHttp;
    Comportamento: TComportamentoTransporte;
    Urls: TArray<string>;
    function Obter(const AUrl: string): TRespostaHttp;
  end;

function TTransporteHttpFake.Obter(const AUrl: string): TRespostaHttp;
begin
  Urls := Urls + [AUrl];
  if Comportamento = ctLancarExcecao then
    raise Exception.Create('falha simulada do transporte');
  Result := Resposta;
end;

function Resposta(ASituacao: TSituacaoRespostaHttp; ACodigo: Integer;
  const ACorpo: string): TRespostaHttp;
begin
  Result.Situacao := ASituacao;
  Result.Codigo := ACodigo;
  Result.Corpo := ACorpo;
end;

procedure TTestesServicoViaCep.MontaUrlEConverteCorpoRealEmEndereco;
var
  LTransporteObjeto: TTransporteHttpFake;
  LTransporte: ITransporteHttp;
  LServico: IServicoViaCep;
  LResultado: TResultadoConsultaCep;
begin
  LTransporteObjeto := TTransporteHttpFake.Create;
  LTransporte := LTransporteObjeto;
  LTransporteObjeto.Resposta := Resposta(srRespondida, 200, CORPO_REAL_01001000);
  LServico := TServicoViaCep.Create(LTransporte);
  LResultado := LServico.Consultar('01001000');
  Assert.AreEqual(1, Integer(Length(LTransporteObjeto.Urls)));
  Assert.AreEqual('https://viacep.com.br/ws/01001000/json/', LTransporteObjeto.Urls[0]);
  Assert.IsTrue(LResultado.Situacao = scEncontrado, 'O corpo real deve resultar em encontrado.');
  Assert.AreEqual('01001-000', LResultado.Endereco.CEP);
  Assert.AreEqual('Praça da Sé', LResultado.Endereco.Logradouro);
  Assert.AreEqual('lado ímpar', LResultado.Endereco.Complemento);
  Assert.AreEqual('Sé', LResultado.Endereco.Bairro);
  Assert.AreEqual('São Paulo', LResultado.Endereco.Localidade);
  Assert.AreEqual('SP', LResultado.Endereco.UF);
  Assert.AreEqual('São Paulo', LResultado.Endereco.Estado);
end;

procedure TTestesServicoViaCep.TraduzCadaRespostaParaUmResultadoTipado;
type
  TCaso = record
    Descricao: string;
    Comportamento: TComportamentoTransporte;
    Resposta: TRespostaHttp;
    Esperado: TSituacaoConsultaCep;
  end;

  function Caso(const ADescricao: string; AComportamento: TComportamentoTransporte;
    const AResposta: TRespostaHttp; AEsperado: TSituacaoConsultaCep): TCaso;
  begin
    Result.Descricao := ADescricao;
    Result.Comportamento := AComportamento;
    Result.Resposta := AResposta;
    Result.Esperado := AEsperado;
  end;

  function SemChave(const AChave: string): string;
  begin
    Result := CORPO_REAL_01001000.Replace('"' + AChave + '":', '"' + AChave + '_removida":');
  end;

var
  LCasos: TArray<TCaso>;
  LCaso: TCaso;
  LTransporteObjeto: TTransporteHttpFake;
  LTransporte: ITransporteHttp;
  LServico: IServicoViaCep;
  LResultado: TResultadoConsultaCep;
begin
  LCasos := [
    Caso('HTTP 400', ctResponder, Resposta(srRespondida, 400, '<html>Bad Request</html>'), scNaoEncontrado),
    Caso('erro texto', ctResponder, Resposta(srRespondida, 200, '{"erro": "true"}'), scNaoEncontrado),
    Caso('erro booleano', ctResponder, Resposta(srRespondida, 200, '{"erro": true}'), scNaoEncontrado),
    Caso('HTTP 500', ctResponder, Resposta(srRespondida, 500, 'Internal Server Error'), scIndisponivel),
    Caso('exceção do transporte', ctLancarExcecao, Resposta(srRespondida, 0, ''), scIndisponivel),
    Caso('falha do transporte', ctResponder, Resposta(srFalha, 0, ''), scIndisponivel),
    Caso('tempo esgotado', ctResponder, Resposta(srTempoEsgotado, 0, ''), scIndisponivel),
    Caso('corpo html', ctResponder, Resposta(srRespondida, 200, '<html></html>'), scRespostaInvalida),
    Caso('corpo array', ctResponder, Resposta(srRespondida, 200, '[]'), scRespostaInvalida),
    Caso('sem logradouro', ctResponder, Resposta(srRespondida, 200, SemChave('logradouro')), scRespostaInvalida),
    Caso('sem bairro', ctResponder, Resposta(srRespondida, 200, SemChave('bairro')), scRespostaInvalida),
    Caso('sem localidade', ctResponder, Resposta(srRespondida, 200, SemChave('localidade')), scRespostaInvalida),
    Caso('sem uf', ctResponder, Resposta(srRespondida, 200, SemChave('uf')), scRespostaInvalida)];
  for LCaso in LCasos do
  begin
    LTransporteObjeto := TTransporteHttpFake.Create;
    LTransporte := LTransporteObjeto;
    LTransporteObjeto.Comportamento := LCaso.Comportamento;
    LTransporteObjeto.Resposta := LCaso.Resposta;
    LServico := TServicoViaCep.Create(LTransporte);
    try
      LResultado := LServico.Consultar('01001000');
    except
      on E: Exception do
        Assert.Fail(LCaso.Descricao + ' propagou ' + E.ClassName);
    end;
    Assert.AreEqual(1, Integer(Length(LTransporteObjeto.Urls)), LCaso.Descricao);
    Assert.AreEqual(Ord(LCaso.Esperado), Ord(LResultado.Situacao), LCaso.Descricao);
  end;
  Assert.AreEqual(13, Integer(Length(LCasos)));
end;

procedure TTestesTransporteHttp.ServidorLocalSemRespostaEsgotaEmDezSegundos;
var
  LDados: TWSAData;
  LSocket: TSocket;
  LEndereco: TSockAddrIn;
  LTamanho: Integer;
  LPorta: Integer;
  LTransporte: ITransporteHttp;
  LInicio: UInt64;
  LDecorrido: UInt64;
  LResposta: TRespostaHttp;
begin
  Assert.AreEqual(0, WSAStartup($0202, LDados), 'Winsock indisponível.');
  try
    LSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    Assert.IsTrue(LSocket <> INVALID_SOCKET, 'Não foi possível criar o socket local.');
    try
      FillChar(LEndereco, SizeOf(LEndereco), 0);
      LEndereco.sin_family := AF_INET;
      LEndereco.sin_addr.S_addr := htonl(INADDR_LOOPBACK);
      LEndereco.sin_port := 0;
      Assert.AreEqual(0, bind(LSocket, PSockAddr(@LEndereco)^, SizeOf(LEndereco)));
      Assert.AreEqual(0, listen(LSocket, 1), 'O socket local deve aceitar conexões.');
      LTamanho := SizeOf(LEndereco);
      Assert.AreEqual(0, getsockname(LSocket, PSockAddr(@LEndereco)^, LTamanho));
      LPorta := ntohs(LEndereco.sin_port);

      LTransporte := TTransporteHttpNet.Create;
      LInicio := GetTickCount64;
      LResposta := LTransporte.Obter(Format('http://127.0.0.1:%d/ws/01001000/json/', [LPorta]));
      LDecorrido := GetTickCount64 - LInicio;
    finally
      closesocket(LSocket);
    end;
  finally
    WSACleanup;
  end;
  Assert.AreEqual(Ord(srTempoEsgotado), Ord(LResposta.Situacao), 'O transporte deve devolver tempo esgotado.');
  Assert.IsTrue(LDecorrido >= 9500, Format('Esgotou cedo demais: %d ms.', [LDecorrido]));
  Assert.IsTrue(LDecorrido <= 13000, Format('Esgotou tarde demais: %d ms.', [LDecorrido]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesServicoViaCep);
  TDUnitX.RegisterTestFixture(TTestesTransporteHttp);

end.

unit Infraestrutura.ServicoViaCep;

interface

uses
  Aplicacao.ServicoViaCep,
  Infraestrutura.TransporteHttp;

type
  TServicoViaCep = class(TInterfacedObject, IServicoViaCep)
  private
    FTransporte: ITransporteHttp;
    function Converter(const ACorpo: string): TResultadoConsultaCep;
  public
    constructor Create(const ATransporte: ITransporteHttp);
    function Consultar(const ACep: string): TResultadoConsultaCep;
  end;

const
  URL_VIACEP = 'https://viacep.com.br/ws/%s/json/';
  HTTP_OK = 200;
  HTTP_REQUISICAO_INVALIDA = 400;

implementation

uses
  System.JSON,
  System.SysUtils,
  Dominio.Cliente;

const
  CHAVES_OBRIGATORIAS: array[0..3] of string = ('logradouro', 'bairro', 'localidade', 'uf');

function Situacao(ASituacao: TSituacaoConsultaCep): TResultadoConsultaCep;
begin
  Result := Default(TResultadoConsultaCep);
  Result.Situacao := ASituacao;
end;

function Texto(AObjeto: TJSONObject; const AChave: string): string;
var
  LValor: TJSONValue;
begin
  LValor := AObjeto.GetValue(AChave);
  if Assigned(LValor) and not (LValor is TJSONNull) then
    Result := LValor.Value
  else
    Result := '';
end;

function IndicaErro(AObjeto: TJSONObject): Boolean;
var
  LErro: TJSONValue;
begin
  LErro := AObjeto.GetValue('erro');
  Result := Assigned(LErro) and ((LErro is TJSONTrue) or SameText(LErro.Value, 'true'));
end;

constructor TServicoViaCep.Create(const ATransporte: ITransporteHttp);
begin
  inherited Create;
  if not Assigned(ATransporte) then
    raise EArgumentNilException.Create('O transporte HTTP deve ser informado.');
  FTransporte := ATransporte;
end;

function TServicoViaCep.Converter(const ACorpo: string): TResultadoConsultaCep;
var
  LValor: TJSONValue;
  LObjeto: TJSONObject;
  LChave: string;
begin
  LValor := TJSONObject.ParseJSONValue(ACorpo);
  try
    if not (LValor is TJSONObject) then
      Exit(Situacao(scRespostaInvalida));
    LObjeto := TJSONObject(LValor);
    if IndicaErro(LObjeto) then
      Exit(Situacao(scNaoEncontrado));
    for LChave in CHAVES_OBRIGATORIAS do
      if not Assigned(LObjeto.GetValue(LChave)) then
        Exit(Situacao(scRespostaInvalida));
    Result := Situacao(scEncontrado);
    Result.Endereco.CEP := Texto(LObjeto, 'cep');
    Result.Endereco.Logradouro := Texto(LObjeto, 'logradouro');
    Result.Endereco.Complemento := Texto(LObjeto, 'complemento');
    Result.Endereco.Bairro := Texto(LObjeto, 'bairro');
    Result.Endereco.Localidade := Texto(LObjeto, 'localidade');
    Result.Endereco.UF := Texto(LObjeto, 'uf');
    Result.Endereco.Estado := Texto(LObjeto, 'estado');
  finally
    LValor.Free;
  end;
end;

function TServicoViaCep.Consultar(const ACep: string): TResultadoConsultaCep;
var
  LCep: string;
  LResposta: TRespostaHttp;
begin
  LCep := SomenteDigitos(ACep);
  if Length(LCep) <> TAMANHO_CEP then
    Exit(Situacao(scFormatoInvalido));
  try
    LResposta := FTransporte.Obter(Format(URL_VIACEP, [LCep]));
  except
    on Exception do
      Exit(Situacao(scIndisponivel));
  end;
  if LResposta.Situacao <> srRespondida then
    Exit(Situacao(scIndisponivel));
  case LResposta.Codigo of
    HTTP_OK:
      Result := Converter(LResposta.Corpo);
    HTTP_REQUISICAO_INVALIDA:
      Result := Situacao(scNaoEncontrado);
  else
    Result := Situacao(scIndisponivel);
  end;
end;

end.

unit Infraestrutura.TransporteHttp;

interface

type
  TSituacaoRespostaHttp = (srRespondida, srTempoEsgotado, srFalha);

  TRespostaHttp = record
    Situacao: TSituacaoRespostaHttp;
    Codigo: Integer;
    Corpo: string;
  end;

  ITransporteHttp = interface
    ['{0CDE0771-4381-4D99-A6A7-F465FF399D40}']
    function Obter(const AUrl: string): TRespostaHttp;
  end;

  TTransporteHttpNet = class(TInterfacedObject, ITransporteHttp)
  private
    FTempoLimiteMs: Integer;
  public
    constructor Create(ATempoLimiteMs: Integer = 10000);
    function Obter(const AUrl: string): TRespostaHttp;
  end;

implementation

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  System.Types,
  System.Net.HttpClient,
  System.Net.URLClient;

const
  ERRO_WINHTTP_TEMPO_ESGOTADO = '(12002)';

constructor TTransporteHttpNet.Create(ATempoLimiteMs: Integer);
begin
  inherited Create;
  FTempoLimiteMs := ATempoLimiteMs;
end;

function TTransporteHttpNet.Obter(const AUrl: string): TRespostaHttp;
var
  LCliente: THTTPClient;
  LAssincrono: IAsyncResult;
  LResposta: IHTTPResponse;
begin
  Result := Default(TRespostaHttp);
  LCliente := THTTPClient.Create;
  try
    LCliente.ConnectionTimeout := FTempoLimiteMs;
    LCliente.SendTimeout := FTempoLimiteMs;
    LCliente.ResponseTimeout := FTempoLimiteMs;
    try
      LAssincrono := LCliente.BeginGet(AUrl);
      if LAssincrono.AsyncWaitEvent.WaitFor(FTempoLimiteMs) <> wrSignaled then
      begin
        LAssincrono.Cancel;
        LAssincrono.AsyncWaitEvent.WaitFor(INFINITE);
        Result.Situacao := srTempoEsgotado;
        Exit;
      end;
      LResposta := THTTPClient.EndAsyncHTTP(LAssincrono);
      Result.Situacao := srRespondida;
      Result.Codigo := LResposta.StatusCode;
      Result.Corpo := LResposta.ContentAsString(TEncoding.UTF8);
    except
      on E: Exception do
        if E.Message.Contains(ERRO_WINHTTP_TEMPO_ESGOTADO) then
          Result.Situacao := srTempoEsgotado
        else
          Result.Situacao := srFalha;
    end;
  finally
    LAssincrono := nil;
    LResposta := nil;
    LCliente.Free;
  end;
end;

end.

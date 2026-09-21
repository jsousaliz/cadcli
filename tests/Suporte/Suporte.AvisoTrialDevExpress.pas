unit Suporte.AvisoTrialDevExpress;

interface

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Suporte.ProcessoAplicacao;

const
  LIMITE_VIGIA_MS = 60000;
  INTERVALO_VIGIA_MS = 50;

procedure VigiarAvisoTrial;
var
  LInicio: UInt64;
begin
  LInicio := GetTickCount64;
  while (GetTickCount64 - LInicio < LIMITE_VIGIA_MS) and
        not FecharAvisoTrial(GetCurrentProcessId) do
    Sleep(INTERVALO_VIGIA_MS);
end;

initialization
  TThread.CreateAnonymousThread(VigiarAvisoTrial).Start;

end.

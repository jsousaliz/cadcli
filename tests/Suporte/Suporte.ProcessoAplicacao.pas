unit Suporte.ProcessoAplicacao;

interface

uses
  Winapi.Windows;

const
  CLASSE_AVISO_TRIAL = 'TfrmNewTrialDialog';
  CLASSE_FORM_PRINCIPAL = 'TFormPrincipal';

function JanelaDoProcesso(AProcessoId: DWORD; const AClasse: string;
  ASomenteVisivel: Boolean): HWND;
function FecharAvisoTrial(AProcessoId: DWORD): Boolean;
function TextoJanela(AJanela: HWND): string;
function IniciarProcesso(const ACaminho, ADiretorio: string; const AArgumentos: string = '';
  const AAmbiente: string = ''): TProcessInformation;
procedure LiberarProcesso(var AProcesso: TProcessInformation);
function AguardarFormPrincipal(const AProcesso: TProcessInformation; ALimiteMs: Cardinal): HWND;
function AguardarEncerramento(const AProcesso: TProcessInformation; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal; out AFormPrincipalExistiu: Boolean): Boolean; overload;
function AguardarEncerramento(const AProcesso: TProcessInformation; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal): Boolean; overload;
function ExecutarEAguardar(const ACaminho, ADiretorio: string; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal; const AArgumentos: string = ''): Boolean;
function ExecutarFechandoFormPrincipal(const ACaminho, ADiretorio: string; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal): Boolean;
function PathSemDelphiNemDevExpress: string;
function AmbienteComPath(const APath: string): string;

implementation

uses
  Winapi.Messages,
  System.Classes,
  System.StrUtils,
  System.SysUtils;

const
  INTERVALO_SONDAGEM_MS = 50;

type
  TBuscaJanela = record
    ProcessoId: DWORD;
    Classe: string;
    SomenteVisivel: Boolean;
    Encontrada: HWND;
  end;
  PBuscaJanela = ^TBuscaJanela;

function ClasseJanela(AJanela: HWND): string;
var
  LBuffer: array[0..255] of Char;
begin
  SetString(Result, LBuffer, GetClassName(AJanela, LBuffer, Length(LBuffer)));
end;

function TextoJanela(AJanela: HWND): string;
var
  LBuffer: array[0..511] of Char;
begin
  SetString(Result, LBuffer, GetWindowText(AJanela, LBuffer, Length(LBuffer)));
end;

function VerificarJanela(AJanela: HWND; AParametro: LPARAM): BOOL; stdcall;
var
  LBusca: PBuscaJanela;
  LProcessoId: DWORD;
begin
  Result := True;
  LBusca := PBuscaJanela(AParametro);
  GetWindowThreadProcessId(AJanela, LProcessoId);
  if (LProcessoId = LBusca.ProcessoId) and (ClasseJanela(AJanela) = LBusca.Classe) and
     (not LBusca.SomenteVisivel or IsWindowVisible(AJanela)) then
  begin
    LBusca.Encontrada := AJanela;
    Result := False;
  end;
end;

function JanelaDoProcesso(AProcessoId: DWORD; const AClasse: string;
  ASomenteVisivel: Boolean): HWND;
var
  LBusca: TBuscaJanela;
begin
  LBusca.ProcessoId := AProcessoId;
  LBusca.Classe := AClasse;
  LBusca.SomenteVisivel := ASomenteVisivel;
  LBusca.Encontrada := 0;
  EnumWindows(@VerificarJanela, LPARAM(@LBusca));
  Result := LBusca.Encontrada;
end;

function FecharAvisoTrial(AProcessoId: DWORD): Boolean;
var
  LAviso: HWND;
begin
  LAviso := JanelaDoProcesso(AProcessoId, CLASSE_AVISO_TRIAL, True);
  Result := LAviso <> 0;
  if Result then
    PostMessage(LAviso, WM_CLOSE, 0, 0);
end;

function IniciarProcesso(const ACaminho, ADiretorio: string; const AArgumentos: string;
  const AAmbiente: string): TProcessInformation;
var
  LInfo: TStartupInfo;
  LComando: string;
  LAmbiente: Pointer;
begin
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.cb := SizeOf(LInfo);
  FillChar(Result, SizeOf(Result), 0);
  LComando := Trim('"' + ACaminho + '" ' + AArgumentos);
  UniqueString(LComando);
  if AAmbiente = '' then
    LAmbiente := nil
  else
    LAmbiente := PChar(AAmbiente);
  if not CreateProcess(nil, PChar(LComando), nil, nil, False, CREATE_UNICODE_ENVIRONMENT,
    LAmbiente, PChar(ADiretorio), LInfo, Result) then
    RaiseLastOSError;
end;

procedure LiberarProcesso(var AProcesso: TProcessInformation);
var
  LCodigo: Cardinal;
begin
  if AProcesso.hProcess = 0 then
    Exit;
  if GetExitCodeProcess(AProcesso.hProcess, LCodigo) and (LCodigo = STILL_ACTIVE) then
  begin
    TerminateProcess(AProcesso.hProcess, 1);
    WaitForSingleObject(AProcesso.hProcess, 5000);
  end;
  CloseHandle(AProcesso.hThread);
  CloseHandle(AProcesso.hProcess);
  FillChar(AProcesso, SizeOf(AProcesso), 0);
end;

function AguardarFormPrincipal(const AProcesso: TProcessInformation; ALimiteMs: Cardinal): HWND;
var
  LInicio: UInt64;
begin
  LInicio := GetTickCount64;
  repeat
    FecharAvisoTrial(AProcesso.dwProcessId);
    Result := JanelaDoProcesso(AProcesso.dwProcessId, CLASSE_FORM_PRINCIPAL, True);
    if Result <> 0 then
      Exit;
    if WaitForSingleObject(AProcesso.hProcess, INTERVALO_SONDAGEM_MS) = WAIT_OBJECT_0 then
      Exit(0);
  until GetTickCount64 - LInicio >= ALimiteMs;
  Result := 0;
end;

function AguardarEncerramento(const AProcesso: TProcessInformation; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal; out AFormPrincipalExistiu: Boolean): Boolean;
var
  LInicio: UInt64;
begin
  AFormPrincipalExistiu := False;
  LInicio := GetTickCount64;
  repeat
    FecharAvisoTrial(AProcesso.dwProcessId);
    if JanelaDoProcesso(AProcesso.dwProcessId, CLASSE_FORM_PRINCIPAL, False) <> 0 then
      AFormPrincipalExistiu := True;
    if WaitForSingleObject(AProcesso.hProcess, INTERVALO_SONDAGEM_MS) = WAIT_OBJECT_0 then
    begin
      GetExitCodeProcess(AProcesso.hProcess, ACodigoSaida);
      Exit(True);
    end;
  until GetTickCount64 - LInicio >= ALimiteMs;
  ACodigoSaida := High(Cardinal);
  Result := False;
end;

function AguardarEncerramento(const AProcesso: TProcessInformation; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal): Boolean;
var
  LFormPrincipalExistiu: Boolean;
begin
  Result := AguardarEncerramento(AProcesso, ALimiteMs, ACodigoSaida, LFormPrincipalExistiu);
end;

function ExecutarEAguardar(const ACaminho, ADiretorio: string; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal; const AArgumentos: string): Boolean;
var
  LProcesso: TProcessInformation;
begin
  LProcesso := IniciarProcesso(ACaminho, ADiretorio, AArgumentos);
  try
    Result := AguardarEncerramento(LProcesso, ALimiteMs, ACodigoSaida);
  finally
    LiberarProcesso(LProcesso);
  end;
end;

function ExecutarFechandoFormPrincipal(const ACaminho, ADiretorio: string; ALimiteMs: Cardinal;
  out ACodigoSaida: Cardinal): Boolean;
var
  LProcesso: TProcessInformation;
  LFormPrincipal: HWND;
begin
  LProcesso := IniciarProcesso(ACaminho, ADiretorio);
  try
    LFormPrincipal := AguardarFormPrincipal(LProcesso, ALimiteMs);
    if LFormPrincipal <> 0 then
      PostMessage(LFormPrincipal, WM_CLOSE, 0, 0);
    Result := AguardarEncerramento(LProcesso, ALimiteMs, ACodigoSaida);
  finally
    LiberarProcesso(LProcesso);
  end;
end;

function PathSemDelphiNemDevExpress: string;
var
  LEntradas: TStringList;
  I: Integer;
begin
  LEntradas := TStringList.Create;
  try
    LEntradas.StrictDelimiter := True;
    LEntradas.Delimiter := ';';
    LEntradas.DelimitedText := GetEnvironmentVariable('PATH');
    for I := LEntradas.Count - 1 downto 0 do
      if ContainsText(LEntradas[I], 'Embarcadero') or ContainsText(LEntradas[I], 'DevExpress') or
         (Trim(LEntradas[I]) = '') then
        LEntradas.Delete(I);
    Result := String.Join(';', LEntradas.ToStringArray);
  finally
    LEntradas.Free;
  end;
end;

function AmbienteComPath(const APath: string): string;
var
  LBloco: PChar;
  LAtual: PChar;
  LEntrada: string;
begin
  Result := '';
  LBloco := GetEnvironmentStrings;
  try
    LAtual := LBloco;
    while LAtual^ <> #0 do
    begin
      LEntrada := LAtual;
      Inc(LAtual, Length(LEntrada) + 1);
      if not StartsText('PATH=', LEntrada) then
        Result := Result + LEntrada + #0;
    end;
  finally
    FreeEnvironmentStrings(LBloco);
  end;
  Result := Result + 'PATH=' + APath + #0 + #0;
end;

end.

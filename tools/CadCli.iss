#ifndef Versao
  #define Versao "0.0.0"
#endif

#define NomeAplicacao "CadCli"
#define ExecutavelAplicacao "CadCli.exe"
#define Publicador "Jean Sousa Liz"
#define DiretorioEntrega "..\bin\Win64\Release"

[Setup]
AppId={{9F2C7A54-3B1E-4D86-9C0A-5E7B41D6F208}
AppName={#NomeAplicacao}
AppVersion={#Versao}
AppVerName={#NomeAplicacao} {#Versao}
AppPublisher={#Publicador}
VersionInfoVersion={#Versao}
DefaultDirName={localappdata}\Programs\CadCli
DefaultGroupName={#NomeAplicacao}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
UsedUserAreasWarning=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=CadCli-Setup-x64
SetupIconFile=..\assets\marca\CadCli.ico
UninstallDisplayName={#NomeAplicacao}
UninstallDisplayIcon={app}\{#ExecutavelAplicacao}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "instalarfirebird"; Description: "Instalar Firebird 3"; GroupDescription: "Banco de dados:"
Name: "desktopicon"; Description: "Criar um atalho na área de trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[Files]
Source: "{#DiretorioEntrega}\{#ExecutavelAplicacao}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DiretorioEntrega}\*.bpl"; DestDir: "{app}"; Flags: ignoreversion
Source: "Firebird3.exe"; DestDir: "{tmp}"; Tasks: instalarfirebird; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#NomeAplicacao}"; Filename: "{app}\{#ExecutavelAplicacao}"
Name: "{group}\Desinstalar {#NomeAplicacao}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#NomeAplicacao}"; Filename: "{app}\{#ExecutavelAplicacao}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExecutavelAplicacao}"; Description: "Executar o {#NomeAplicacao}"; Flags: nowait postinstall skipifsilent

[Code]
const
  PARAMETROS_FIREBIRD =
    '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' +
    ' /TASKS="UseSuperServerTask,UseServiceTask,AutoStartTask,CopyFbClientToSysTask"' +
    ' /SYSDBAPASSWORD="masterkey"';
  MENSAGEM_FALHA_FIREBIRD =
    'Não foi possível instalar o Firebird 3. O instalador oficial terminou com o código %1.';
  MENSAGEM_BANCO_PRESERVADO =
    'O banco de dados do CadCli foi preservado em:';

procedure InstalarFirebird;
var
  LCodigoSaida: Integer;
begin
  WizardForm.StatusLabel.Caption := 'Instalando o Firebird 3...';
  if Exec(ExpandConstant('{tmp}\Firebird3.exe'), PARAMETROS_FIREBIRD, '',
       SW_HIDE, ewWaitUntilTerminated, LCodigoSaida) and (LCodigoSaida = 0) then
    Exit;
  SuppressibleMsgBox(FmtMessage(MENSAGEM_FALHA_FIREBIRD, [IntToStr(LCodigoSaida)]),
    mbCriticalError, MB_OK, IDOK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('instalarfirebird') then
    InstalarFirebird;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  LCaminhoBanco: string;
begin
  if CurUninstallStep <> usPostUninstall then
    Exit;
  LCaminhoBanco := ExpandConstant('{app}\cadcli.fdb');
  if FileExists(LCaminhoBanco) then
    SuppressibleMsgBox(MENSAGEM_BANCO_PRESERVADO + #13#10 + LCaminhoBanco,
      mbInformation, MB_OK, IDOK);
end;

unit Suporte.CaminhosTeste;

interface

function RaizRepositorio: string;
function CaminhoExecutavelRelease: string;
function CriarDiretorioTemporario: string;

implementation

uses
  System.IOUtils,
  System.SysUtils;

function RaizRepositorio: string;
begin
  Result := ExpandFileName(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..\..'));
end;

function CaminhoExecutavelRelease: string;
begin
  Result := TPath.Combine(RaizRepositorio, 'bin\Win64\Release\CadCli.exe');
end;

function CriarDiretorioTemporario: string;
var
  LId: TGUID;
begin
  CreateGUID(LId);
  Result := TPath.Combine(RaizRepositorio,
    'tmp\tests\CadCli-' + GUIDToString(LId));
  TDirectory.CreateDirectory(Result);
end;

end.

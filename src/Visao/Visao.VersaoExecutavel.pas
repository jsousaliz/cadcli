unit Visao.VersaoExecutavel;

interface

function VersaoArquivo(const ACaminho: string): string;
function VersaoExecutavelEmExecucao: string;

implementation

uses
  Winapi.Windows,
  System.SysUtils;

type
  TTraducao = record
    Idioma: Word;
    PaginaCodigo: Word;
  end;
  PTraducao = ^TTraducao;

function VersaoArquivo(const ACaminho: string): string;
var
  LTamanho: DWORD;
  LDescarte: DWORD;
  LDados: TBytes;
  LTraducao: PTraducao;
  LValor: PChar;
  LComprimento: UINT;
begin
  Result := '';
  LTamanho := GetFileVersionInfoSize(PChar(ACaminho), LDescarte);
  if LTamanho = 0 then
    Exit;
  SetLength(LDados, LTamanho);
  if not GetFileVersionInfo(PChar(ACaminho), 0, LTamanho, LDados) then
    Exit;
  if not VerQueryValue(LDados, '\VarFileInfo\Translation', Pointer(LTraducao), LComprimento) or
     (LComprimento < SizeOf(TTraducao)) then
    Exit;
  if VerQueryValue(LDados, PChar(Format('\StringFileInfo\%.4x%.4x\FileVersion',
    [LTraducao.Idioma, LTraducao.PaginaCodigo])), Pointer(LValor), LComprimento) and
    (LComprimento > 0) then
    Result := Trim(LValor);
end;

function VersaoExecutavelEmExecucao: string;
begin
  Result := VersaoArquivo(ParamStr(0));
end;

end.

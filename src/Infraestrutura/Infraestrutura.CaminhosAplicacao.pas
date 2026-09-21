unit Infraestrutura.CaminhosAplicacao;

interface

const
  ARQUIVO_BANCO = 'cadcli.fdb';

function DiretorioAplicacao: string;
function CaminhoBancoAplicacao: string;

implementation

uses
  System.SysUtils;

function DiretorioAplicacao: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function CaminhoBancoAplicacao: string;
begin
  Result := DiretorioAplicacao + ARQUIVO_BANCO;
end;

end.

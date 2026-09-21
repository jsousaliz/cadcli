unit Infraestrutura.RegistroErroInicializacao;

interface

procedure RegistrarErroInicializacao(const AMensagem: string);
function CaminhoRegistroErro: string;
function ExibeDialogoDeErro: Boolean;

const
  VARIAVEL_SEM_INTERACAO = 'CADCLI_SEM_INTERACAO';
  ARQUIVO_REGISTRO_ERRO = 'cadcli-erro.log';

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Infraestrutura.CaminhosAplicacao;

function CaminhoRegistroErro: string;
begin
  Result := DiretorioAplicacao + ARQUIVO_REGISTRO_ERRO;
end;

function ExibeDialogoDeErro: Boolean;
begin
  Result := (GetEnvironmentVariable(VARIAVEL_SEM_INTERACAO) = '') and
    not FindCmdLineSwitch('sem-interacao', True);
end;

procedure RegistrarErroInicializacao(const AMensagem: string);
var
  LLinha: string;
begin
  LLinha := Format('%s	Falha ao inicializar o CadCli: %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMensagem]);
  try
    TFile.AppendAllText(CaminhoRegistroErro, LLinha + sLineBreak, TEncoding.UTF8);
  except
    on Exception do
      ;
  end;
end;

end.

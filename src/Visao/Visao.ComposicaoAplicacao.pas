unit Visao.ComposicaoAplicacao;

interface

uses
  Vcl.Forms,
  Aplicacao.NavegadorAplicacao;

function ComporNavegador(AShell: TForm): INavegadorAplicacao;

implementation

uses
  Visao.NavegadorAplicacao;

function ComporNavegador(AShell: TForm): INavegadorAplicacao;
begin
  Result := TNavegadorAplicacao.Create(AShell);
end;

end.

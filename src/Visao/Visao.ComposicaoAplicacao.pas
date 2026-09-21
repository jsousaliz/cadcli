unit Visao.ComposicaoAplicacao;

interface

uses
  Vcl.Forms,
  Aplicacao.NavegadorAplicacao;

function ComporNavegador(AFormPrincipal: TForm): INavegadorAplicacao;

implementation

uses
  Visao.NavegadorAplicacao;

function ComporNavegador(AFormPrincipal: TForm): INavegadorAplicacao;
begin
  Result := TNavegadorAplicacao.Create(AFormPrincipal);
end;

end.

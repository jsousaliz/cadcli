unit Dominio.UnidadesFederativas;

interface

type
  TUnidadeFederativa = record
    Sigla: string;
    Nome: string;
  end;

const
  UNIDADES_FEDERATIVAS: array[0..26] of TUnidadeFederativa = (
    (Sigla: 'AC'; Nome: 'Acre'),
    (Sigla: 'AL'; Nome: 'Alagoas'),
    (Sigla: 'AP'; Nome: 'Amapá'),
    (Sigla: 'AM'; Nome: 'Amazonas'),
    (Sigla: 'BA'; Nome: 'Bahia'),
    (Sigla: 'CE'; Nome: 'Ceará'),
    (Sigla: 'DF'; Nome: 'Distrito Federal'),
    (Sigla: 'ES'; Nome: 'Espírito Santo'),
    (Sigla: 'GO'; Nome: 'Goiás'),
    (Sigla: 'MA'; Nome: 'Maranhão'),
    (Sigla: 'MT'; Nome: 'Mato Grosso'),
    (Sigla: 'MS'; Nome: 'Mato Grosso do Sul'),
    (Sigla: 'MG'; Nome: 'Minas Gerais'),
    (Sigla: 'PA'; Nome: 'Pará'),
    (Sigla: 'PB'; Nome: 'Paraíba'),
    (Sigla: 'PR'; Nome: 'Paraná'),
    (Sigla: 'PE'; Nome: 'Pernambuco'),
    (Sigla: 'PI'; Nome: 'Piauí'),
    (Sigla: 'RJ'; Nome: 'Rio de Janeiro'),
    (Sigla: 'RN'; Nome: 'Rio Grande do Norte'),
    (Sigla: 'RS'; Nome: 'Rio Grande do Sul'),
    (Sigla: 'RO'; Nome: 'Rondônia'),
    (Sigla: 'RR'; Nome: 'Roraima'),
    (Sigla: 'SC'; Nome: 'Santa Catarina'),
    (Sigla: 'SP'; Nome: 'São Paulo'),
    (Sigla: 'SE'; Nome: 'Sergipe'),
    (Sigla: 'TO'; Nome: 'Tocantins'));

function NomeDaUf(const AUf: string): string;

implementation

uses
  System.SysUtils;

function NomeDaUf(const AUf: string): string;
var
  LUnidade: TUnidadeFederativa;
begin
  for LUnidade in UNIDADES_FEDERATIVAS do
    if SameText(LUnidade.Sigla, Trim(AUf)) then
      Exit(LUnidade.Nome);
  Result := '';
end;

end.

unit Infraestrutura.CatalogoPadraoMigracoes;

interface

uses
  Aplicacao.CatalogoMigracoes;

function CriarCatalogoPadrao: TCatalogoMigracoes;

implementation

uses
  Migracao.V001.EsquemaInicial,
  Migracao.V002.DadosReferencia,
  Migracao.V003.ClientesProtegidos;

function CriarCatalogoPadrao: TCatalogoMigracoes;
begin
  Result := TCatalogoMigracoes.Create;
  Result.Registrar(TMigracao001EsquemaInicial);
  Result.Registrar(TMigracao002DadosReferencia);
  Result.Registrar(TMigracao003ClientesProtegidos);
end;

end.

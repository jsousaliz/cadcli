unit Aplicacao.GeradorRelatorioCliente;

interface

uses
  Dominio.FiltroRelatorioCliente;

type
  IGeradorRelatorioCliente = interface
    ['{2B9E0C4A-8D1F-4A6E-9C33-7A5D6E41B028}']
    procedure Visualizar(const ADados: TDadosRelatorioCliente);
  end;

implementation

end.

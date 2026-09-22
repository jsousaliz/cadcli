unit Aplicacao.RepositorioCliente;

interface

uses
  Dominio.Cliente,
  Dominio.FiltroCliente;

type
  IRepositorioCliente = interface
    ['{6439BAD9-518D-4E1C-BBAE-AC3405A41570}']
    function Incluir(const ACliente: TCliente): Integer;
    procedure Alterar(const ACliente: TCliente);
    procedure Excluir(AId: Integer);
    function ObterPorId(AId: Integer): TCliente;
    function Pesquisar(const AFiltro: TFiltroCliente; const AOrdenacao: TOrdenacaoCliente;
      ALimite: Integer): TClientes;
    function ResolverCidade(const ANomeCidade, AUf, ANomeEstado: string): Integer;
  end;

implementation

end.

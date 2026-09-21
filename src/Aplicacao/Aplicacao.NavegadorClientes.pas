unit Aplicacao.NavegadorClientes;

interface

type
  INavegadorClientes = interface
    ['{3ECA21A5-B70B-40C1-B935-99326DF9ADD7}']
    function AbrirInclusao: Boolean;
    function AbrirEdicao(AId: Integer): Boolean;
  end;

implementation

end.

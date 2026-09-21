unit Aplicacao.Confirmacao;

interface

type
  IConfirmacao = interface
    ['{DFE75CC2-0A83-4A3D-A9EE-7D706038A9C6}']
    function Confirmar(const AMensagem: string): Boolean;
  end;

implementation

end.

unit Aplicacao.Transacao;

interface

type
  ITransacao = interface
    ['{167A7C98-8385-40BD-86F0-20A2B938244B}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Reverter;
  end;

implementation

end.

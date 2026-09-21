unit Aplicacao.ServicoViaCep;

interface

type
  TEnderecoViaCep = record
    CEP: string;
    Logradouro: string;
    Complemento: string;
    Bairro: string;
    Localidade: string;
    UF: string;
    Estado: string;
  end;

  TSituacaoConsultaCep = (scEncontrado, scNaoEncontrado, scIndisponivel, scRespostaInvalida,
    scFormatoInvalido);

  TResultadoConsultaCep = record
    Situacao: TSituacaoConsultaCep;
    Endereco: TEnderecoViaCep;
  end;

  IServicoViaCep = interface
    ['{2E50E411-80A8-4607-967D-2B83CF81253B}']
    function Consultar(const ACep: string): TResultadoConsultaCep;
  end;

implementation

end.

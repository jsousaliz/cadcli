unit Dominio.FiltroCliente;

interface

type
  TCampoPesquisa = (cpId, cpNome, cpCpfCnpj, cpCep, cpCidade, cpEstado);
  TCamposPesquisa = set of TCampoPesquisa;

  TFiltroCliente = record
    Texto: string;
    Campos: TCamposPesquisa;
    DataNascimento: string;
  end;

  TCampoOrdenacao = (coId, coNome, coCpfCnpj, coCep, coCidade, coUf, coEstado, coDataNascimento);

  TOrdenacaoCliente = record
    Campo: TCampoOrdenacao;
    Descendente: Boolean;
  end;

implementation

end.

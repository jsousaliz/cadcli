unit Migracao.V002.DadosReferencia;

interface

uses
  Dominio.Migracao;

type
  TMigracao002DadosReferencia = class(TMigracaoBanco)
  private
    procedure InserirEstadoECidades(const AContexto: IContextoMigracao;
      AIdEstado: Integer; const ANomeEstado, AUf: string;
      const ACidade1, ACidade2, ACidade3: string);
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

implementation

function TMigracao002DadosReferencia.Versao: Integer;
begin
  Result := 2;
end;

function TMigracao002DadosReferencia.Descricao: string;
begin
  Result := 'Insere estados e cidades de referência';
end;

procedure TMigracao002DadosReferencia.InserirEstadoECidades(
  const AContexto: IContextoMigracao; AIdEstado: Integer;
  const ANomeEstado, AUf, ACidade1, ACidade2, ACidade3: string);
var
  LPrimeiroIdCidade: Integer;
begin
  AContexto.ExecutarParametrizado(
    'INSERT INTO ESTADO (ID, NOME, UF) VALUES (?, ?, ?)',
    [AIdEstado, ANomeEstado, AUf]);
  LPrimeiroIdCidade := ((AIdEstado - 1) * 3) + 1;
  AContexto.ExecutarParametrizado(
    'INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (?, ?, ?)',
    [LPrimeiroIdCidade, ACidade1, AIdEstado]);
  AContexto.ExecutarParametrizado(
    'INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (?, ?, ?)',
    [LPrimeiroIdCidade + 1, ACidade2, AIdEstado]);
  AContexto.ExecutarParametrizado(
    'INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (?, ?, ?)',
    [LPrimeiroIdCidade + 2, ACidade3, AIdEstado]);
end;

procedure TMigracao002DadosReferencia.Executar(const AContexto: IContextoMigracao);
begin
  InserirEstadoECidades(AContexto, 1, 'Minas Gerais', 'MG',
    'Belo Horizonte', 'Uberlândia', 'Contagem');
  InserirEstadoECidades(AContexto, 2, 'São Paulo', 'SP',
    'São Paulo', 'Campinas', 'Santos');
  InserirEstadoECidades(AContexto, 3, 'Rio de Janeiro', 'RJ',
    'Rio de Janeiro', 'Niterói', 'Petrópolis');
  InserirEstadoECidades(AContexto, 4, 'Bahia', 'BA',
    'Salvador', 'Feira de Santana', 'Vitória da Conquista');
  AContexto.Executar('ALTER SEQUENCE SEQ_ESTADO RESTART WITH 5');
  AContexto.Executar('ALTER SEQUENCE SEQ_CIDADE RESTART WITH 13');
end;

end.

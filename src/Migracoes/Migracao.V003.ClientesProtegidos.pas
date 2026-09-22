unit Migracao.V003.ClientesProtegidos;

interface

uses
  Dominio.Migracao;

type
  TMigracao003ClientesProtegidos = class(TMigracaoBanco)
  private
    procedure InserirClienteProtegido(const AContexto: IContextoMigracao;
      AId: Integer; const ACpf: string; AIdCidade: Integer; ANascimento: TDate);
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

implementation

uses
  System.SysUtils;

const
  ID_ESTADO_SC = 5;
  ID_CIDADE_LAGES = 13;
  NOME_CLIENTE_PROTEGIDO = 'Cliente código protegido';
  CPFS_PROTEGIDOS: array[0..4] of string = (
    '51808188004', '19760893282', '88183624456', '41651116431', '73315402205');
  IDS_PROTEGIDOS: array[0..4] of Integer = (1, 5, 8, 10, 15);

function TMigracao003ClientesProtegidos.Versao: Integer;
begin
  Result := 3;
end;

function TMigracao003ClientesProtegidos.Descricao: string;
begin
  Result := 'Insere os clientes de IDs protegidos';
end;

procedure TMigracao003ClientesProtegidos.InserirClienteProtegido(
  const AContexto: IContextoMigracao; AId: Integer; const ACpf: string;
  AIdCidade: Integer; ANascimento: TDate);
begin
  AContexto.ExecutarParametrizado(
    'INSERT INTO CLIENTE (ID, NOME, CPF_CNPJ, CIDADEID, DATANASCIMENTO) ' +
    'VALUES (?, ?, ?, ?, CAST(? AS DATE))',
    [AId, NOME_CLIENTE_PROTEGIDO, ACpf, AIdCidade, FormatDateTime('yyyy-mm-dd', ANascimento)]);
end;

procedure TMigracao003ClientesProtegidos.Executar(const AContexto: IContextoMigracao);
var
  LIndice: Integer;
  LNascimento: TDate;
begin
  LNascimento := EncodeDate(2026, 9, 22);
  AContexto.ExecutarParametrizado(
    'INSERT INTO ESTADO (ID, NOME, UF) VALUES (?, ?, ?)',
    [ID_ESTADO_SC, 'Santa Catarina', 'SC']);
  AContexto.ExecutarParametrizado(
    'INSERT INTO CIDADE (ID, NOME, ESTADOID) VALUES (?, ?, ?)',
    [ID_CIDADE_LAGES, 'Lages', ID_ESTADO_SC]);
  for LIndice := Low(IDS_PROTEGIDOS) to High(IDS_PROTEGIDOS) do
    InserirClienteProtegido(AContexto, IDS_PROTEGIDOS[LIndice],
      CPFS_PROTEGIDOS[LIndice], ID_CIDADE_LAGES, LNascimento);
  AContexto.Executar('ALTER SEQUENCE SEQ_ESTADO RESTART WITH 6');
  AContexto.Executar('ALTER SEQUENCE SEQ_CIDADE RESTART WITH 14');
  AContexto.Executar('ALTER SEQUENCE SEQ_CLIENTE RESTART WITH 16');
end;

end.

unit Migracao.V001.EsquemaInicial;

interface

uses
  Dominio.Migracao;

type
  TMigracao001EsquemaInicial = class(TMigracaoBanco)
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

implementation

function TMigracao001EsquemaInicial.Versao: Integer;
begin
  Result := 1;
end;

function TMigracao001EsquemaInicial.Descricao: string;
begin
  Result := 'Cria esquema inicial';
end;

procedure TMigracao001EsquemaInicial.Executar(const AContexto: IContextoMigracao);
begin
  AContexto.Executar('CREATE SEQUENCE SEQ_CLIENTE');
  AContexto.Executar('CREATE SEQUENCE SEQ_ESTADO');
  AContexto.Executar('CREATE SEQUENCE SEQ_CIDADE');
  AContexto.Executar(
    'CREATE TABLE ESTADO (' +
    'ID INTEGER NOT NULL, NOME VARCHAR(50) NOT NULL, UF CHAR(2) NOT NULL, ' +
    'CONSTRAINT PK_ESTADO PRIMARY KEY (ID), CONSTRAINT UQ_ESTADO_UF UNIQUE (UF))');
  AContexto.Executar(
    'CREATE TABLE CIDADE (' +
    'ID INTEGER NOT NULL, NOME VARCHAR(50) NOT NULL, ESTADOID INTEGER NOT NULL, ' +
    'CONSTRAINT PK_CIDADE PRIMARY KEY (ID), ' +
    'CONSTRAINT FK_CIDADE_ESTADO FOREIGN KEY (ESTADOID) REFERENCES ESTADO (ID), ' +
    'CONSTRAINT UQ_CIDADE_ESTADO_NOME UNIQUE (ESTADOID, NOME))');
  AContexto.Executar(
    'CREATE TABLE CLIENTE (' +
    'ID INTEGER NOT NULL, NOME VARCHAR(80), CEP CHAR(8), CPF_CNPJ VARCHAR(14), ' +
    'ENDERECO VARCHAR(100), NUMERO VARCHAR(20), COMPLEMENTO VARCHAR(60), ' +
    'BAIRRO VARCHAR(100), CIDADE INTEGER, DATANASCIMENTO DATE, ' +
    'CONSTRAINT PK_CLIENTE PRIMARY KEY (ID), ' +
    'CONSTRAINT FK_CLIENTE_CIDADE FOREIGN KEY (CIDADE) REFERENCES CIDADE (ID))');
end;

end.

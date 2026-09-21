unit Dominio.Migracao;

interface

uses
  System.SysUtils;

type
  IContextoMigracao = interface
    ['{D4239F9D-97D5-42BB-B0C5-00A2A1487435}']
    procedure IniciarTransacao;
    procedure ConfirmarTransacao;
    procedure ReverterTransacao;
    procedure Executar(const ASql: string);
    procedure ExecutarParametrizado(const ASql: string; const AValores: array of Variant);
    function TabelaExiste(const ANome: string): Boolean;
    function MaiorVersaoInstalada: Integer;
    function VersaoInstalada(AVersao: Integer): Boolean;
    procedure RegistrarMigracao(AVersao: Integer; const ADescricao: string; AAplicadaEm: TDateTime);
  end;

  IMigracaoBanco = interface
    ['{7F9FCA93-34D5-45CC-B311-B4232986D51B}']
    function Versao: Integer;
    function Descricao: string;
    procedure Executar(const AContexto: IContextoMigracao);
  end;

  TMigracaoBanco = class abstract(TInterfacedObject, IMigracaoBanco)
  public
    function Versao: Integer; virtual; abstract;
    function Descricao: string; virtual; abstract;
    procedure Executar(const AContexto: IContextoMigracao); virtual; abstract;
  end;

  TClasseMigracao = class of TMigracaoBanco;

implementation

end.

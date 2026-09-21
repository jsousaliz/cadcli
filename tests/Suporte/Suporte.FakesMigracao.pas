unit Suporte.FakesMigracao;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.InicializadorAplicacao,
  Dominio.Migracao;

type
  TContextoMigracaoFake = class(TInterfacedObject, IContextoMigracao)
  private
    FVersoes: TList<Integer>;
    FOperacoes: TStringList;
    FEmTransacao: Boolean;
    FQuantidadeOperacoesAntesTransacao: Integer;
    FQuantidadeVersoesAntesTransacao: Integer;
    FFalharAoExecutar: Boolean;
    FFalharAoConfirmar: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure IniciarTransacao;
    procedure ConfirmarTransacao;
    procedure ReverterTransacao;
    procedure Executar(const ASql: string);
    procedure ExecutarParametrizado(const ASql: string; const AValores: array of Variant);
    function TabelaExiste(const ANome: string): Boolean;
    function MaiorVersaoInstalada: Integer;
    function VersaoInstalada(AVersao: Integer): Boolean;
    procedure RegistrarMigracao(AVersao: Integer; const ADescricao: string; AAplicadaEm: TDateTime);
    procedure AdicionarVersaoInstalada(AVersao: Integer);
    property Operacoes: TStringList read FOperacoes;
    property FalharAoExecutar: Boolean read FFalharAoExecutar write FFalharAoExecutar;
    property FalharAoConfirmar: Boolean read FFalharAoConfirmar write FFalharAoConfirmar;
  end;

  TRelogioFake = class(TInterfacedObject, IRelogio)
  private
    FAgora: TDateTime;
  public
    constructor Create(ANow: TDateTime);
    function Agora: TDateTime;
  end;

  TMigracaoTeste001 = class(TMigracaoBanco)
  public
    class var Execucoes: Integer;
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

  TMigracaoTeste002 = class(TMigracaoBanco)
  public
    class var Execucoes: Integer;
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

  TMigracaoTeste002Duplicada = class(TMigracaoTeste002);

  TMigracaoTeste004 = class(TMigracaoBanco)
  public
    class var Execucoes: Integer;
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

  TMigracaoTeste003Falha = class(TMigracaoBanco)
  public
    function Versao: Integer; override;
    function Descricao: string; override;
    procedure Executar(const AContexto: IContextoMigracao); override;
  end;

  TPersistenciaFake = class(TInterfacedObject, IInicializadorPersistencia)
  public
    Preparado: Boolean;
    Resultado: Boolean;
    Mensagem: string;
    function Preparar(out AMensagemErro: string): Boolean;
  end;

  TAutorizadorInterfaceFake = class(TInterfacedObject, IAutorizadorInterface)
  public
    Autorizado: Boolean;
    procedure AutorizarAbertura;
  end;

implementation

constructor TContextoMigracaoFake.Create;
begin
  inherited;
  FVersoes := TList<Integer>.Create;
  FOperacoes := TStringList.Create;
end;

destructor TContextoMigracaoFake.Destroy;
begin
  FOperacoes.Free;
  FVersoes.Free;
  inherited;
end;

procedure TContextoMigracaoFake.IniciarTransacao;
begin
  FEmTransacao := True;
  FQuantidadeOperacoesAntesTransacao := FOperacoes.Count;
  FQuantidadeVersoesAntesTransacao := FVersoes.Count;
  FOperacoes.Add('INICIAR');
end;

procedure TContextoMigracaoFake.ConfirmarTransacao;
begin
  if FFalharAoConfirmar then
    raise Exception.Create('falha simulada ao confirmar');
  FOperacoes.Add('CONFIRMAR');
  FEmTransacao := False;
end;

procedure TContextoMigracaoFake.ReverterTransacao;
begin
  while FOperacoes.Count > FQuantidadeOperacoesAntesTransacao do
    FOperacoes.Delete(FOperacoes.Count - 1);
  while FVersoes.Count > FQuantidadeVersoesAntesTransacao do
    FVersoes.Delete(FVersoes.Count - 1);
  FOperacoes.Add('REVERTER');
  FEmTransacao := False;
end;

procedure TContextoMigracaoFake.Executar(const ASql: string);
begin
  FOperacoes.Add(ASql);
  if FFalharAoExecutar or SameText(ASql, 'FALHAR') then
    raise Exception.Create('falha simulada');
end;

procedure TContextoMigracaoFake.ExecutarParametrizado(const ASql: string;
  const AValores: array of Variant);
begin
  Executar(ASql);
end;

function TContextoMigracaoFake.TabelaExiste(const ANome: string): Boolean;
begin
  Result := SameText(ANome, 'SCHEMA_VERSION') and (FVersoes.Count > 0);
end;

function TContextoMigracaoFake.MaiorVersaoInstalada: Integer;
var
  LVersao: Integer;
begin
  Result := 0;
  for LVersao in FVersoes do
    if LVersao > Result then
      Result := LVersao;
end;

function TContextoMigracaoFake.VersaoInstalada(AVersao: Integer): Boolean;
begin
  Result := FVersoes.Contains(AVersao);
end;

procedure TContextoMigracaoFake.RegistrarMigracao(AVersao: Integer;
  const ADescricao: string; AAplicadaEm: TDateTime);
begin
  FOperacoes.Add(Format('REGISTRAR:%d:%s:%s',
    [AVersao, ADescricao, FormatDateTime('yyyy-mm-dd hh:nn:ss', AAplicadaEm)]));
  FVersoes.Add(AVersao);
end;

procedure TContextoMigracaoFake.AdicionarVersaoInstalada(AVersao: Integer);
begin
  FVersoes.Add(AVersao);
end;

constructor TRelogioFake.Create(ANow: TDateTime);
begin
  inherited Create;
  FAgora := ANow;
end;

function TRelogioFake.Agora: TDateTime;
begin
  Result := FAgora;
end;

function TMigracaoTeste001.Versao: Integer;
begin
  Result := 1;
end;

function TMigracaoTeste001.Descricao: string;
begin
  Result := 'migração um';
end;

procedure TMigracaoTeste001.Executar(const AContexto: IContextoMigracao);
begin
  Inc(Execucoes);
  AContexto.Executar('EXECUTAR:1');
end;

function TMigracaoTeste002.Versao: Integer;
begin
  Result := 2;
end;

function TMigracaoTeste002.Descricao: string;
begin
  Result := 'migração dois';
end;

procedure TMigracaoTeste002.Executar(const AContexto: IContextoMigracao);
begin
  Inc(Execucoes);
  AContexto.Executar('EXECUTAR:2');
end;

function TMigracaoTeste004.Versao: Integer;
begin
  Result := 4;
end;

function TMigracaoTeste004.Descricao: string;
begin
  Result := 'migração quatro';
end;

procedure TMigracaoTeste004.Executar(const AContexto: IContextoMigracao);
begin
  Inc(Execucoes);
  AContexto.Executar('EXECUTAR:4');
end;

function TMigracaoTeste003Falha.Versao: Integer;
begin
  Result := 3;
end;

function TMigracaoTeste003Falha.Descricao: string;
begin
  Result := 'migração com falha';
end;

procedure TMigracaoTeste003Falha.Executar(const AContexto: IContextoMigracao);
begin
  AContexto.Executar('ALTERACAO:3');
  AContexto.Executar('FALHAR');
end;

function TPersistenciaFake.Preparar(out AMensagemErro: string): Boolean;
begin
  Preparado := True;
  AMensagemErro := Mensagem;
  Result := Resultado;
end;

procedure TAutorizadorInterfaceFake.AutorizarAbertura;
begin
  Autorizado := True;
end;

end.

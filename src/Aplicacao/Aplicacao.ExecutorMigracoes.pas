unit Aplicacao.ExecutorMigracoes;

interface

uses
  System.SysUtils,
  Aplicacao.CatalogoMigracoes,
  Dominio.Migracao;

type
  EErroMigracao = class(Exception)
  private
    FVersao: Integer;
  public
    constructor Create(AVersao: Integer; const AMensagem: string);
    property Versao: Integer read FVersao;
  end;

  EVersaoBancoFutura = class(Exception);

  IRelogio = interface
    ['{6DB63818-4E70-4DB0-B49C-97D4FE88D24E}']
    function Agora: TDateTime;
  end;

  TRelogioSistema = class(TInterfacedObject, IRelogio)
  public
    function Agora: TDateTime;
  end;

  TExecutorMigracoes = class
  private
    FCatalogo: TCatalogoMigracoes;
    FRelogio: IRelogio;
  public
    constructor Create(ACatalogo: TCatalogoMigracoes; const ARelogio: IRelogio);
    procedure Executar(const AContexto: IContextoMigracao);
  end;

implementation

constructor EErroMigracao.Create(AVersao: Integer; const AMensagem: string);
begin
  FVersao := AVersao;
  inherited CreateFmt('Falha ao aplicar a migração %d: %s', [AVersao, AMensagem]);
end;

function TRelogioSistema.Agora: TDateTime;
begin
  Result := Now;
end;

constructor TExecutorMigracoes.Create(ACatalogo: TCatalogoMigracoes; const ARelogio: IRelogio);
begin
  inherited Create;
  if not Assigned(ACatalogo) then
    raise EArgumentNilException.Create('O catálogo de migrações deve ser informado.');
  if not Assigned(ARelogio) then
    raise EArgumentNilException.Create('O relógio deve ser informado.');
  FCatalogo := ACatalogo;
  FRelogio := ARelogio;
end;

procedure TExecutorMigracoes.Executar(const AContexto: IContextoMigracao);
var
  I: Integer;
  LMigracao: IMigracaoBanco;
  LVersaoInstalada: Integer;
begin
  if not Assigned(AContexto) then
    raise EArgumentNilException.Create('O contexto de migração deve ser informado.');

  LVersaoInstalada := AContexto.MaiorVersaoInstalada;
  if LVersaoInstalada > FCatalogo.MaiorVersao then
    raise EVersaoBancoFutura.CreateFmt(
      'A base está na versão %d, superior à versão %d suportada. Atualize o CadCli.exe.',
      [LVersaoInstalada, FCatalogo.MaiorVersao]);

  for I := 0 to FCatalogo.Quantidade - 1 do
  begin
    LMigracao := FCatalogo.ClasseNaPosicao(I).Create;
    if AContexto.VersaoInstalada(LMigracao.Versao) then
      Continue;

    AContexto.IniciarTransacao;
    try
      LMigracao.Executar(AContexto);
      AContexto.RegistrarMigracao(LMigracao.Versao, LMigracao.Descricao, FRelogio.Agora);
      AContexto.ConfirmarTransacao;
    except
      on E: Exception do
      begin
        AContexto.ReverterTransacao;
        raise EErroMigracao.Create(LMigracao.Versao, E.Message);
      end;
    end;
  end;
end;

end.

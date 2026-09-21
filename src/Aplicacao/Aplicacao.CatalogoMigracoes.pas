unit Aplicacao.CatalogoMigracoes;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Dominio.Migracao;

type
  EMigracaoDuplicada = class(Exception);

  TCatalogoMigracoes = class
  private
    FClasses: TList<TClasseMigracao>;
    function ObterVersao(AClasse: TClasseMigracao): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Registrar(AClasse: TClasseMigracao);
    function Quantidade: Integer;
    function ClasseNaPosicao(AIndice: Integer): TClasseMigracao;
    function MaiorVersao: Integer;
  end;

implementation

constructor TCatalogoMigracoes.Create;
begin
  inherited Create;
  FClasses := TList<TClasseMigracao>.Create;
end;

destructor TCatalogoMigracoes.Destroy;
begin
  FClasses.Free;
  inherited;
end;

function TCatalogoMigracoes.ObterVersao(AClasse: TClasseMigracao): Integer;
var
  LMigracao: IMigracaoBanco;
begin
  LMigracao := AClasse.Create;
  Result := LMigracao.Versao;
end;

procedure TCatalogoMigracoes.Registrar(AClasse: TClasseMigracao);
var
  I: Integer;
  LVersao: Integer;
  LVersaoExistente: Integer;
begin
  if not Assigned(AClasse) then
    raise EArgumentNilException.Create('A classe de migração deve ser informada.');

  LVersao := ObterVersao(AClasse);
  for I := 0 to FClasses.Count - 1 do
  begin
    LVersaoExistente := ObterVersao(FClasses[I]);
    if LVersaoExistente = LVersao then
      raise EMigracaoDuplicada.CreateFmt('A versão de migração %d já foi registrada.', [LVersao]);
    if LVersaoExistente > LVersao then
    begin
      FClasses.Insert(I, AClasse);
      Exit;
    end;
  end;
  FClasses.Add(AClasse);
end;

function TCatalogoMigracoes.Quantidade: Integer;
begin
  Result := FClasses.Count;
end;

function TCatalogoMigracoes.ClasseNaPosicao(AIndice: Integer): TClasseMigracao;
begin
  Result := FClasses[AIndice];
end;

function TCatalogoMigracoes.MaiorVersao: Integer;
begin
  if FClasses.Count = 0 then
    Exit(0);
  Result := ObterVersao(FClasses.Last);
end;

end.

unit Testes.FiltroRelatorioCliente;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesFiltroRelatorioCliente = class
  public
    [Test]
    procedure ValidaENormalizaAsVinteEntradasDaTabela;
  end;

implementation

uses
  System.SysUtils,
  Dominio.FiltroRelatorioCliente,
  Suporte.FakesRelatorioCliente;

type
  TCasoFiltro = record
    Modo: TModoRelatorio;
    IdInicial: string;
    IdFinal: string;
    EstadoId: Integer;
    CidadeId: Integer;
    Valido: Boolean;
    Campo: TCampoFiltroRelatorio;
    Mensagem: string;
    De: Integer;
    Ate: Integer;
    Estado: Integer;
    Cidade: Integer;
  end;

const
  CASOS: array[1..20] of TCasoFiltro = (
    (Modo: mrIntervalo; IdInicial: '2'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: True; Campo: cfIdInicial; Mensagem: ''; De: 2; Ate: 4; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: ' 2 '; IdFinal: ' 4 '; EstadoId: 0; CidadeId: 0;
      Valido: True; Campo: cfIdInicial; Mensagem: ''; De: 2; Ate: 4; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '3'; IdFinal: '3'; EstadoId: 0; CidadeId: 0;
      Valido: True; Campo: cfIdInicial; Mensagem: ''; De: 3; Ate: 3; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: ''; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '0'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '-1'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: 'abc'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '1,5'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '2147483648'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '2'; IdFinal: ''; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdFinal; Mensagem: MENSAGEM_ID_FINAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '2'; IdFinal: 'x'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdFinal; Mensagem: MENSAGEM_ID_FINAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: ''; IdFinal: ''; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdInicial; Mensagem: MENSAGEM_ID_INICIAL;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '5'; IdFinal: '4'; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfIdFinal; Mensagem: MENSAGEM_INTERVALO_INVERTIDO;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrCidadeEstado; IdInicial: ''; IdFinal: ''; EstadoId: 0; CidadeId: 0;
      Valido: False; Campo: cfEstado; Mensagem: MENSAGEM_ESTADO_OBRIGATORIO;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrCidadeEstado; IdInicial: ''; IdFinal: ''; EstadoId: 1; CidadeId: 0;
      Valido: True; Campo: cfEstado; Mensagem: ''; De: 0; Ate: 0; Estado: 1; Cidade: 0),
    (Modo: mrCidadeEstado; IdInicial: ''; IdFinal: ''; EstadoId: 2; CidadeId: 5;
      Valido: True; Campo: cfEstado; Mensagem: ''; De: 0; Ate: 0; Estado: 2; Cidade: 5),
    (Modo: mrCidadeEstado; IdInicial: ''; IdFinal: ''; EstadoId: 0; CidadeId: 5;
      Valido: False; Campo: cfEstado; Mensagem: MENSAGEM_ESTADO_OBRIGATORIO;
      De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrTodos; IdInicial: 'abc'; IdFinal: 'x'; EstadoId: 0; CidadeId: 5;
      Valido: True; Campo: cfIdInicial; Mensagem: ''; De: 0; Ate: 0; Estado: 0; Cidade: 0),
    (Modo: mrIntervalo; IdInicial: '2'; IdFinal: '4'; EstadoId: 2; CidadeId: 5;
      Valido: True; Campo: cfIdInicial; Mensagem: ''; De: 2; Ate: 4; Estado: 0; Cidade: 0),
    (Modo: mrCidadeEstado; IdInicial: 'abc'; IdFinal: '-1'; EstadoId: 2; CidadeId: 0;
      Valido: True; Campo: cfEstado; Mensagem: ''; De: 0; Ate: 0; Estado: 2; Cidade: 0));

procedure TTestesFiltroRelatorioCliente.ValidaENormalizaAsVinteEntradasDaTabela;
var
  I: Integer;
  LCaso: TCasoFiltro;
  LResultado: TResultadoFiltroRelatorio;
  LRotulo: string;
  LVerificados: Integer;
begin
  LVerificados := 0;
  for I := Low(CASOS) to High(CASOS) do
  begin
    LCaso := CASOS[I];
    LRotulo := Format('Linha %d: modo %d, "%s".."%s", estado %d, cidade %d',
      [I, Ord(LCaso.Modo), LCaso.IdInicial, LCaso.IdFinal, LCaso.EstadoId, LCaso.CidadeId]);
    LResultado := TValidacaoFiltroRelatorio.Validar(EntradaDoFiltro(LCaso.Modo, LCaso.IdInicial,
      LCaso.IdFinal, LCaso.EstadoId, LCaso.CidadeId));
    Assert.AreEqual(LCaso.Valido, LResultado.Valido, LRotulo);
    if LCaso.Valido then
    begin
      Assert.AreEqual(Ord(LCaso.Modo), Ord(LResultado.Filtro.Modo), LRotulo + ' - modo');
      Assert.AreEqual(LCaso.De, LResultado.Filtro.IdInicial, LRotulo + ' - ID inicial');
      Assert.AreEqual(LCaso.Ate, LResultado.Filtro.IdFinal, LRotulo + ' - ID final');
      Assert.AreEqual(LCaso.Estado, LResultado.Filtro.EstadoId, LRotulo + ' - estado');
      Assert.AreEqual(LCaso.Cidade, LResultado.Filtro.CidadeId, LRotulo + ' - cidade');
      Assert.AreEqual('', LResultado.Mensagem, LRotulo + ' - sem mensagem');
    end
    else
    begin
      Assert.AreEqual(Ord(LCaso.Campo), Ord(LResultado.Campo), LRotulo + ' - campo indicado');
      Assert.AreEqual(LCaso.Mensagem, LResultado.Mensagem, LRotulo + ' - mensagem');
    end;
    Inc(LVerificados);
  end;
  Assert.AreEqual(20, LVerificados, 'A tabela deve ter exatamente 20 entradas asseridas.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesFiltroRelatorioCliente);

end.

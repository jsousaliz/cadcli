unit Dominio.FiltroRelatorioCliente;

interface

uses
  Dominio.Cliente;

type
  TModoRelatorio = (mrIntervalo, mrCidadeEstado, mrTodos);

  TCampoFiltroRelatorio = (cfIdInicial, cfIdFinal, cfEstado);

  TEntradaFiltroRelatorio = record
    Modo: TModoRelatorio;
    IdInicial: string;
    IdFinal: string;
    EstadoId: Integer;
    CidadeId: Integer;
  end;

  TFiltroRelatorioCliente = record
    Modo: TModoRelatorio;
    IdInicial: Integer;
    IdFinal: Integer;
    EstadoId: Integer;
    CidadeId: Integer;
  end;

  TResultadoFiltroRelatorio = record
    Valido: Boolean;
    Campo: TCampoFiltroRelatorio;
    Mensagem: string;
    Filtro: TFiltroRelatorioCliente;
  end;

  TDadosRelatorioCliente = record
    Clientes: TClientes;
    DescricaoFiltro: string;
    Emissao: TDateTime;
  end;

  TValidacaoFiltroRelatorio = class
  public
    class function Validar(const AEntrada: TEntradaFiltroRelatorio): TResultadoFiltroRelatorio;
  end;

const
  MENSAGEM_ID_INICIAL = 'Informe um ID inicial inteiro maior que zero.';
  MENSAGEM_ID_FINAL = 'Informe um ID final inteiro maior que zero.';
  MENSAGEM_INTERVALO_INVERTIDO = 'O ID inicial deve ser menor ou igual ao ID final.';
  MENSAGEM_ESTADO_OBRIGATORIO = 'Selecione um estado.';

implementation

uses
  System.SysUtils;

function LerId(const ATexto: string; out AId: Integer): Boolean;
begin
  Result := TryStrToInt(Trim(ATexto), AId) and (AId > 0);
end;

function Recusar(ACampo: TCampoFiltroRelatorio;
  const AMensagem: string): TResultadoFiltroRelatorio;
begin
  Result := Default(TResultadoFiltroRelatorio);
  Result.Valido := False;
  Result.Campo := ACampo;
  Result.Mensagem := AMensagem;
end;

class function TValidacaoFiltroRelatorio.Validar(
  const AEntrada: TEntradaFiltroRelatorio): TResultadoFiltroRelatorio;
var
  LInicial: Integer;
  LFinal: Integer;
begin
  Result := Default(TResultadoFiltroRelatorio);
  Result.Valido := True;
  Result.Filtro.Modo := AEntrada.Modo;
  case AEntrada.Modo of
    mrIntervalo:
      begin
        if not LerId(AEntrada.IdInicial, LInicial) then
          Exit(Recusar(cfIdInicial, MENSAGEM_ID_INICIAL));
        if not LerId(AEntrada.IdFinal, LFinal) then
          Exit(Recusar(cfIdFinal, MENSAGEM_ID_FINAL));
        if LInicial > LFinal then
          Exit(Recusar(cfIdFinal, MENSAGEM_INTERVALO_INVERTIDO));
        Result.Filtro.IdInicial := LInicial;
        Result.Filtro.IdFinal := LFinal;
      end;
    mrCidadeEstado:
      begin
        if AEntrada.EstadoId <= 0 then
          Exit(Recusar(cfEstado, MENSAGEM_ESTADO_OBRIGATORIO));
        Result.Filtro.EstadoId := AEntrada.EstadoId;
        if AEntrada.CidadeId > 0 then
          Result.Filtro.CidadeId := AEntrada.CidadeId;
      end;
  end;
end;

end.

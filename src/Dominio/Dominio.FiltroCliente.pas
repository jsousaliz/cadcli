unit Dominio.FiltroCliente;

interface

uses
  Dominio.Cliente;

type
  TCampoPesquisa = (cpId, cpNome, cpCpfCnpj, cpCep, cpCidade, cpEstado);
  TCamposPesquisa = set of TCampoPesquisa;

  TFiltroCliente = record
    Texto: string;
    Campos: TCamposPesquisa;
    DataNascimento: string;
    function Atende(const ACliente: TCliente): Boolean;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils;

function AtendeId(const AFiltro: string; const ACliente: TCliente): Boolean;
begin
  Result := StrToIntDef(AFiltro, -1) = ACliente.Id;
end;

function AtendeCep(const AFiltro: string; const ACliente: TCliente): Boolean;
var
  LDigitos: string;
begin
  LDigitos := SomenteDigitos(AFiltro);
  Result := (Length(LDigitos) = TAMANHO_CEP) and (LDigitos = SomenteDigitos(ACliente.Cep));
end;

function AtendeEstado(const AFiltro: string; const ACliente: TCliente): Boolean;
begin
  Result := SameText(AFiltro, ACliente.Uf) or ContainsText(ACliente.Estado, AFiltro);
end;

function AtendeCampo(ACampo: TCampoPesquisa; const ATexto: string;
  const ACliente: TCliente): Boolean;
var
  LDigitos: string;
begin
  case ACampo of
    cpId:
      Result := AtendeId(ATexto, ACliente);
    cpNome:
      Result := ContainsText(ACliente.Nome, ATexto);
    cpCpfCnpj:
      begin
        LDigitos := SomenteDigitos(ATexto);
        Result := (LDigitos <> '') and (LDigitos = SomenteDigitos(ACliente.CpfCnpj));
      end;
    cpCep:
      Result := AtendeCep(ATexto, ACliente);
    cpCidade:
      Result := ContainsText(ACliente.Cidade, ATexto);
    cpEstado:
      Result := AtendeEstado(ATexto, ACliente);
  else
    Result := False;
  end;
end;

function AtendeTexto(const ATexto: string; ACampos: TCamposPesquisa;
  const ACliente: TCliente): Boolean;
var
  LCampo: TCampoPesquisa;
begin
  if ACampos = [] then
    ACampos := [Low(TCampoPesquisa)..High(TCampoPesquisa)];
  for LCampo in ACampos do
    if AtendeCampo(LCampo, ATexto, ACliente) then
      Exit(True);
  Result := False;
end;

function TFiltroCliente.Atende(const ACliente: TCliente): Boolean;
begin
  Result := False;
  if (Trim(DataNascimento) <> '') and
     (Trim(DataNascimento) <> FormatarData(ACliente.DataNascimento)) then
    Exit;
  Result := (Trim(Texto) = '') or AtendeTexto(Trim(Texto), Campos, ACliente);
end;

end.

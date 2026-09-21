unit Dominio.FiltroCliente;

interface

uses
  Dominio.Cliente;

type
  TFiltroCliente = record
    Id: string;
    Nome: string;
    CpfCnpj: string;
    Cep: string;
    Cidade: string;
    Estado: string;
    DataNascimento: string;
    BuscaGeral: string;
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

function PalavraEncontrada(const APalavra: string; const ACliente: TCliente): Boolean;
var
  LDigitos: string;
begin
  Result := ContainsStr(IntToStr(ACliente.Id), APalavra) or
    ContainsText(ACliente.Nome, APalavra) or
    ContainsText(ACliente.Cidade, APalavra) or
    ContainsText(ACliente.Uf, APalavra) or
    ContainsText(ACliente.Estado, APalavra) or
    ContainsStr(FormatarData(ACliente.DataNascimento), APalavra);
  if Result then
    Exit;
  LDigitos := SomenteDigitos(APalavra);
  Result := (LDigitos <> '') and
    (ContainsStr(SomenteDigitos(ACliente.CpfCnpj), LDigitos) or
     ContainsStr(SomenteDigitos(ACliente.Cep), LDigitos));
end;

function AtendeBuscaGeral(const ABusca: string; const ACliente: TCliente): Boolean;
var
  LPalavra: string;
begin
  for LPalavra in ABusca.Split([' '], TStringSplitOptions.ExcludeEmpty) do
    if not PalavraEncontrada(LPalavra, ACliente) then
      Exit(False);
  Result := True;
end;

function TFiltroCliente.Atende(const ACliente: TCliente): Boolean;
begin
  Result := False;
  if (Trim(Id) <> '') and not AtendeId(Trim(Id), ACliente) then
    Exit;
  if (Trim(Nome) <> '') and not ContainsText(ACliente.Nome, Trim(Nome)) then
    Exit;
  if (Trim(CpfCnpj) <> '') and
     (SomenteDigitos(CpfCnpj) <> SomenteDigitos(ACliente.CpfCnpj)) then
    Exit;
  if (Trim(Cep) <> '') and not AtendeCep(Cep, ACliente) then
    Exit;
  if (Trim(Cidade) <> '') and not ContainsText(ACliente.Cidade, Trim(Cidade)) then
    Exit;
  if (Trim(Estado) <> '') and not AtendeEstado(Trim(Estado), ACliente) then
    Exit;
  if (Trim(DataNascimento) <> '') and
     (Trim(DataNascimento) <> FormatarData(ACliente.DataNascimento)) then
    Exit;
  Result := AtendeBuscaGeral(BuscaGeral, ACliente);
end;

end.

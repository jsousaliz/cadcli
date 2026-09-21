unit Dominio.ValidacaoCliente;

interface

function CpfCnpjValido(const ADigitos: string): Boolean;

implementation

uses
  System.SysUtils,
  Dominio.Cliente;

const
  PESOS_CNPJ: array[0..12] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);

function Digito(const ADigitos: string; APosicao: Integer): Integer;
begin
  Result := Ord(ADigitos[APosicao]) - Ord('0');
end;

function TodosIguais(const ADigitos: string): Boolean;
begin
  Result := StringOfChar(ADigitos[1], Length(ADigitos)) = ADigitos;
end;

function DigitoCpf(const ADigitos: string; AQuantidade: Integer): Integer;
var
  I: Integer;
  LSoma: Integer;
begin
  LSoma := 0;
  for I := 1 to AQuantidade do
    LSoma := LSoma + Digito(ADigitos, I) * (AQuantidade + 2 - I);
  Result := (LSoma * 10) mod 11;
  if Result = 10 then
    Result := 0;
end;

function DigitoCnpj(const ADigitos: string; AQuantidade: Integer): Integer;
var
  I: Integer;
  LSoma: Integer;
  LDeslocamento: Integer;
begin
  LSoma := 0;
  LDeslocamento := Length(PESOS_CNPJ) - AQuantidade;
  for I := 1 to AQuantidade do
    LSoma := LSoma + Digito(ADigitos, I) * PESOS_CNPJ[LDeslocamento + I - 1];
  Result := LSoma mod 11;
  if Result < 2 then
    Result := 0
  else
    Result := 11 - Result;
end;

function CpfValido(const ADigitos: string): Boolean;
begin
  Result := (DigitoCpf(ADigitos, 9) = Digito(ADigitos, 10)) and
    (DigitoCpf(ADigitos, 10) = Digito(ADigitos, 11));
end;

function CnpjValido(const ADigitos: string): Boolean;
begin
  Result := (DigitoCnpj(ADigitos, 12) = Digito(ADigitos, 13)) and
    (DigitoCnpj(ADigitos, 13) = Digito(ADigitos, 14));
end;

function CpfCnpjValido(const ADigitos: string): Boolean;
begin
  if (SomenteDigitos(ADigitos) <> ADigitos) or
     not (Length(ADigitos) in [TAMANHO_CPF, TAMANHO_CNPJ]) or TodosIguais(ADigitos) then
    Exit(False);
  if Length(ADigitos) = TAMANHO_CPF then
    Result := CpfValido(ADigitos)
  else
    Result := CnpjValido(ADigitos);
end;

end.

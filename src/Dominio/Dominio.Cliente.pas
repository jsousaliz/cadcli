unit Dominio.Cliente;

interface

type
  TCliente = record
    Id: Integer;
    Nome: string;
    CpfCnpj: string;
    Cep: string;
    Endereco: string;
    Numero: string;
    Complemento: string;
    Bairro: string;
    CidadeId: Integer;
    Cidade: string;
    Uf: string;
    Estado: string;
    DataNascimento: TDate;
  end;

  TClientes = TArray<TCliente>;

const
  TAMANHO_CEP = 8;
  TAMANHO_CPF = 11;
  TAMANHO_CNPJ = 14;
  FORMATO_DATA = 'dd/mm/yyyy';

function SomenteDigitos(const ATexto: string): string;
function FormatarData(AData: TDate): string;
function TentarLerData(const ATexto: string; out AData: TDate): Boolean;
function FormatarCpfCnpj(const ADigitos: string): string;
function FormatarCep(const ADigitos: string): string;

implementation

uses
  System.SysUtils;

function ConfiguracaoData: TFormatSettings;
begin
  Result := TFormatSettings.Create;
  Result.DateSeparator := '/';
  Result.ShortDateFormat := FORMATO_DATA;
end;

function SomenteDigitos(const ATexto: string): string;
var
  LCaractere: Char;
begin
  Result := '';
  for LCaractere in ATexto do
    if CharInSet(LCaractere, ['0'..'9']) then
      Result := Result + LCaractere;
end;

function FormatarData(AData: TDate): string;
begin
  Result := FormatDateTime(FORMATO_DATA, AData, ConfiguracaoData);
end;

function TentarLerData(const ATexto: string; out AData: TDate): Boolean;
var
  LData: TDateTime;
begin
  Result := TryStrToDate(Trim(ATexto), LData, ConfiguracaoData);
  if Result then
    AData := Trunc(LData);
end;

function FormatarCpfCnpj(const ADigitos: string): string;
begin
  case Length(ADigitos) of
    TAMANHO_CPF:
      Result := Format('%s.%s.%s-%s', [Copy(ADigitos, 1, 3), Copy(ADigitos, 4, 3),
        Copy(ADigitos, 7, 3), Copy(ADigitos, 10, 2)]);
    TAMANHO_CNPJ:
      Result := Format('%s.%s.%s/%s-%s', [Copy(ADigitos, 1, 2), Copy(ADigitos, 3, 3),
        Copy(ADigitos, 6, 3), Copy(ADigitos, 9, 4), Copy(ADigitos, 13, 2)]);
  else
    Result := ADigitos;
  end;
end;

function FormatarCep(const ADigitos: string): string;
begin
  if Length(ADigitos) = TAMANHO_CEP then
    Result := Copy(ADigitos, 1, 5) + '-' + Copy(ADigitos, 6, 3)
  else
    Result := ADigitos;
end;

end.

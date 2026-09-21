unit Aplicacao.ControladorCadastroCliente;

interface

uses
  System.SysUtils,
  Dominio.Cliente,
  Aplicacao.Confirmacao,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.RepositorioCliente,
  Aplicacao.ServicoViaCep,
  Aplicacao.Transacao;

type
  TModoCadastro = (mcInclusao, mcEdicao);

  TCampoCliente = (ccNome, ccCpfCnpj, ccDataNascimento, ccCep, ccEndereco, ccNumero,
    ccComplemento, ccBairro, ccCidade, ccUf);

  TDadosCadastroCliente = record
    Nome: string;
    CpfCnpj: string;
    DataNascimento: string;
    Cep: string;
    Endereco: string;
    Numero: string;
    Complemento: string;
    Bairro: string;
    Cidade: string;
    Uf: string;
    Estado: string;
    class operator Equal(const AEsquerdo, ADireito: TDadosCadastroCliente): Boolean;
  end;

  IVisaoCadastroCliente = interface
    ['{4A4AE0F8-BBDF-4709-8BAB-F2E9AD9E2CF8}']
    procedure DefinirTitulo(const ATitulo: string);
    function ObterDados: TDadosCadastroCliente;
    procedure ExibirDados(const ADados: TDadosCadastroCliente);
    procedure PreencherEndereco(const AEndereco, ABairro, ACidade, AUf, AEstado: string);
    procedure ExibirEstado(const AEstado: string);
    procedure ExibirId(AId: Integer);
    procedure SinalizarCarregamento(AAtivo: Boolean);
    procedure ExibirMensagem(const AMensagem: string);
    procedure FocarCampo(ACampo: TCampoCliente);
    procedure Fechar;
  end;

  TControladorCadastroCliente = class
  private
    FVisao: IVisaoCadastroCliente;
    FRepositorio: IRepositorioCliente;
    FTransacao: ITransacao;
    FServicoViaCep: IServicoViaCep;
    FRelogio: IRelogio;
    FConfirmacao: IConfirmacao;
    FModo: TModoCadastro;
    FId: Integer;
    FSalvo: Boolean;
    FDadosIniciais: TDadosCadastroCliente;
    FCepAoReceberFoco: string;
    function Validar(const ADados: TDadosCadastroCliente): Boolean;
    function Recusar(ACampo: TCampoCliente; const AMensagem: string): Boolean;
    function ParaCliente(const ADados: TDadosCadastroCliente): TCliente;
    procedure ConsultarCep(const ACep: string);
  public
    constructor Create(const AVisao: IVisaoCadastroCliente; const ARepositorio: IRepositorioCliente;
      const ATransacao: ITransacao; const AServicoViaCep: IServicoViaCep;
      const ARelogio: IRelogio; const AConfirmacao: IConfirmacao);
    function Abrir(AModo: TModoCadastro; AId: Integer = 0): Boolean;
    procedure CepRecebeuFoco;
    procedure CepPerdeuFoco;
    procedure UfAlterada;
    procedure Salvar;
    function PodeFechar: Boolean;
    property Salvo: Boolean read FSalvo;
  end;

const
  TITULO_INCLUSAO = 'Novo Cliente';
  TITULO_EDICAO = 'Editar Cliente';
  ROTULOS_CAMPOS: array[TCampoCliente] of string = ('Nome', 'CPF/CNPJ', 'Data de nascimento',
    'CEP', 'Endereço', 'Número', 'Complemento', 'Bairro', 'Cidade', 'UF');
  MENSAGEM_CAMPO_OBRIGATORIO = 'O campo %s é obrigatório.';
  MENSAGEM_CPF_CNPJ_INVALIDO = 'CPF/CNPJ inválido';
  MENSAGEM_DATA_INVALIDA = 'Data de nascimento inválida';
  MENSAGEM_NASCIMENTO_FUTURO = 'Data de nascimento não pode estar no futuro';
  MENSAGEM_CEP_INVALIDO = 'CEP inválido';
  MENSAGEM_CEP_NAO_ENCONTRADO = 'CEP não encontrado';
  MENSAGEM_CEP_INDISPONIVEL = 'Serviço de CEP indisponível. Preencha o endereço manualmente.';
  MENSAGEM_CEP_RESPOSTA_INVALIDA = 'Resposta inválida do serviço de CEP';
  MENSAGEM_FALHA_SALVAR = 'Não foi possível salvar o cliente.';
  MENSAGEM_FALHA_CARREGAR_CLIENTE = 'Não foi possível carregar o cliente.';
  MENSAGEM_DESCARTAR = 'Descartar as alterações não salvas?';

implementation

uses
  Dominio.UnidadesFederativas,
  Dominio.ValidacaoCliente;

class operator TDadosCadastroCliente.Equal(const AEsquerdo,
  ADireito: TDadosCadastroCliente): Boolean;
begin
  Result := (AEsquerdo.Nome = ADireito.Nome) and (AEsquerdo.CpfCnpj = ADireito.CpfCnpj) and
    (AEsquerdo.DataNascimento = ADireito.DataNascimento) and (AEsquerdo.Cep = ADireito.Cep) and
    (AEsquerdo.Endereco = ADireito.Endereco) and (AEsquerdo.Numero = ADireito.Numero) and
    (AEsquerdo.Complemento = ADireito.Complemento) and (AEsquerdo.Bairro = ADireito.Bairro) and
    (AEsquerdo.Cidade = ADireito.Cidade) and (AEsquerdo.Uf = ADireito.Uf) and
    (AEsquerdo.Estado = ADireito.Estado);
end;

function ValorDoCampo(const ADados: TDadosCadastroCliente; ACampo: TCampoCliente): string;
begin
  case ACampo of
    ccNome: Result := ADados.Nome;
    ccCpfCnpj: Result := ADados.CpfCnpj;
    ccDataNascimento: Result := ADados.DataNascimento;
    ccCep: Result := ADados.Cep;
    ccEndereco: Result := ADados.Endereco;
    ccNumero: Result := ADados.Numero;
    ccComplemento: Result := ADados.Complemento;
    ccBairro: Result := ADados.Bairro;
    ccCidade: Result := ADados.Cidade;
    ccUf: Result := ADados.Uf;
  end;
end;

function ParaDados(const ACliente: TCliente): TDadosCadastroCliente;
begin
  Result.Nome := ACliente.Nome;
  Result.CpfCnpj := FormatarCpfCnpj(ACliente.CpfCnpj);
  Result.DataNascimento := FormatarData(ACliente.DataNascimento);
  Result.Cep := FormatarCep(ACliente.Cep);
  Result.Endereco := ACliente.Endereco;
  Result.Numero := ACliente.Numero;
  Result.Complemento := ACliente.Complemento;
  Result.Bairro := ACliente.Bairro;
  Result.Cidade := ACliente.Cidade;
  Result.Uf := ACliente.Uf;
  Result.Estado := ACliente.Estado;
end;

constructor TControladorCadastroCliente.Create(const AVisao: IVisaoCadastroCliente;
  const ARepositorio: IRepositorioCliente; const ATransacao: ITransacao;
  const AServicoViaCep: IServicoViaCep; const ARelogio: IRelogio;
  const AConfirmacao: IConfirmacao);
begin
  inherited Create;
  if not Assigned(AVisao) then
    raise EArgumentNilException.Create('A visão de cadastro deve ser informada.');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('O repositório de clientes deve ser informado.');
  if not Assigned(ATransacao) then
    raise EArgumentNilException.Create('A transação deve ser informada.');
  if not Assigned(AServicoViaCep) then
    raise EArgumentNilException.Create('O serviço de CEP deve ser informado.');
  if not Assigned(ARelogio) then
    raise EArgumentNilException.Create('O relógio deve ser informado.');
  if not Assigned(AConfirmacao) then
    raise EArgumentNilException.Create('A confirmação deve ser informada.');
  FVisao := AVisao;
  FRepositorio := ARepositorio;
  FTransacao := ATransacao;
  FServicoViaCep := AServicoViaCep;
  FRelogio := ARelogio;
  FConfirmacao := AConfirmacao;
end;

function TControladorCadastroCliente.Abrir(AModo: TModoCadastro; AId: Integer): Boolean;
begin
  FModo := AModo;
  FId := 0;
  FSalvo := False;
  if AModo = mcInclusao then
    FVisao.DefinirTitulo(TITULO_INCLUSAO)
  else
  begin
    FVisao.DefinirTitulo(TITULO_EDICAO);
    try
      FVisao.ExibirDados(ParaDados(FRepositorio.ObterPorId(AId)));
    except
      on Exception do
      begin
        FVisao.ExibirMensagem(MENSAGEM_FALHA_CARREGAR_CLIENTE);
        Exit(False);
      end;
    end;
    FId := AId;
  end;
  FDadosIniciais := FVisao.ObterDados;
  FCepAoReceberFoco := SomenteDigitos(FDadosIniciais.Cep);
  Result := True;
end;

procedure TControladorCadastroCliente.CepRecebeuFoco;
begin
  FCepAoReceberFoco := SomenteDigitos(FVisao.ObterDados.Cep);
end;

procedure TControladorCadastroCliente.CepPerdeuFoco;
var
  LCep: string;
begin
  LCep := SomenteDigitos(FVisao.ObterDados.Cep);
  if LCep = FCepAoReceberFoco then
    Exit;
  FCepAoReceberFoco := LCep;
  if Length(LCep) <> TAMANHO_CEP then
  begin
    FVisao.ExibirMensagem(MENSAGEM_CEP_INVALIDO);
    Exit;
  end;
  ConsultarCep(LCep);
end;

procedure TControladorCadastroCliente.ConsultarCep(const ACep: string);
var
  LResultado: TResultadoConsultaCep;
  LEstado: string;
begin
  FVisao.SinalizarCarregamento(True);
  try
    try
      LResultado := FServicoViaCep.Consultar(ACep);
    except
      on Exception do
        LResultado.Situacao := scIndisponivel;
    end;
    case LResultado.Situacao of
      scEncontrado:
        begin
          LEstado := Trim(LResultado.Endereco.Estado);
          if LEstado = '' then
            LEstado := NomeDaUf(LResultado.Endereco.UF);
          FVisao.PreencherEndereco(LResultado.Endereco.Logradouro, LResultado.Endereco.Bairro,
            LResultado.Endereco.Localidade, LResultado.Endereco.UF, LEstado);
        end;
      scNaoEncontrado:
        FVisao.ExibirMensagem(MENSAGEM_CEP_NAO_ENCONTRADO);
      scIndisponivel:
        FVisao.ExibirMensagem(MENSAGEM_CEP_INDISPONIVEL);
      scRespostaInvalida:
        FVisao.ExibirMensagem(MENSAGEM_CEP_RESPOSTA_INVALIDA);
      scFormatoInvalido:
        FVisao.ExibirMensagem(MENSAGEM_CEP_INVALIDO);
    end;
  finally
    FVisao.SinalizarCarregamento(False);
  end;
end;

procedure TControladorCadastroCliente.UfAlterada;
begin
  FVisao.ExibirEstado(NomeDaUf(FVisao.ObterDados.Uf));
end;

function TControladorCadastroCliente.Recusar(ACampo: TCampoCliente;
  const AMensagem: string): Boolean;
begin
  FVisao.ExibirMensagem(AMensagem);
  FVisao.FocarCampo(ACampo);
  Result := False;
end;

function TControladorCadastroCliente.Validar(const ADados: TDadosCadastroCliente): Boolean;
var
  LCampo: TCampoCliente;
  LNascimento: TDate;
begin
  for LCampo := Low(TCampoCliente) to High(TCampoCliente) do
    if (LCampo <> ccComplemento) and (Trim(ValorDoCampo(ADados, LCampo)) = '') then
      Exit(Recusar(LCampo, Format(MENSAGEM_CAMPO_OBRIGATORIO, [ROTULOS_CAMPOS[LCampo]])));
  if not CpfCnpjValido(SomenteDigitos(ADados.CpfCnpj)) then
    Exit(Recusar(ccCpfCnpj, MENSAGEM_CPF_CNPJ_INVALIDO));
  if not TentarLerData(ADados.DataNascimento, LNascimento) then
    Exit(Recusar(ccDataNascimento, MENSAGEM_DATA_INVALIDA));
  if LNascimento > Trunc(FRelogio.Agora) then
    Exit(Recusar(ccDataNascimento, MENSAGEM_NASCIMENTO_FUTURO));
  if Length(SomenteDigitos(ADados.Cep)) <> TAMANHO_CEP then
    Exit(Recusar(ccCep, MENSAGEM_CEP_INVALIDO));
  Result := True;
end;

function TControladorCadastroCliente.ParaCliente(const ADados: TDadosCadastroCliente): TCliente;
begin
  Result := Default(TCliente);
  Result.Id := FId;
  Result.Nome := Trim(ADados.Nome);
  Result.CpfCnpj := SomenteDigitos(ADados.CpfCnpj);
  Result.Cep := SomenteDigitos(ADados.Cep);
  Result.Endereco := Trim(ADados.Endereco);
  Result.Numero := Trim(ADados.Numero);
  Result.Complemento := Trim(ADados.Complemento);
  Result.Bairro := Trim(ADados.Bairro);
  Result.Cidade := Trim(ADados.Cidade);
  Result.Uf := UpperCase(Trim(ADados.Uf));
  Result.Estado := Trim(ADados.Estado);
  if Result.Estado = '' then
    Result.Estado := NomeDaUf(Result.Uf);
  TentarLerData(ADados.DataNascimento, Result.DataNascimento);
end;

procedure TControladorCadastroCliente.Salvar;
var
  LDados: TDadosCadastroCliente;
  LCliente: TCliente;
  LId: Integer;
begin
  LDados := FVisao.ObterDados;
  if not Validar(LDados) then
    Exit;
  LCliente := ParaCliente(LDados);
  try
    FTransacao.Iniciar;
    LCliente.CidadeId := FRepositorio.ResolverCidade(LCliente.Cidade, LCliente.Uf, LCliente.Estado);
    if FModo = mcInclusao then
      LId := FRepositorio.Incluir(LCliente)
    else
    begin
      FRepositorio.Alterar(LCliente);
      LId := FId;
    end;
    FTransacao.Confirmar;
  except
    on Exception do
    begin
      FTransacao.Reverter;
      FVisao.ExibirMensagem(MENSAGEM_FALHA_SALVAR);
      Exit;
    end;
  end;
  FId := LId;
  FSalvo := True;
  FVisao.ExibirId(FId);
  FVisao.Fechar;
end;

function TControladorCadastroCliente.PodeFechar: Boolean;
begin
  Result := FSalvo or (FVisao.ObterDados = FDadosIniciais) or
    FConfirmacao.Confirmar(MENSAGEM_DESCARTAR);
end;

end.

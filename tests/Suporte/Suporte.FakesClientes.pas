unit Suporte.FakesClientes;

interface

uses
  System.Classes,
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Aplicacao.Confirmacao,
  Aplicacao.ControladorCadastroCliente,
  Aplicacao.ControladorPesquisaCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.NavegadorClientes,
  Aplicacao.RepositorioCliente,
  Aplicacao.ServicoViaCep,
  Aplicacao.Transacao;

type
  TRepositorioClienteFake = class(TInterfacedObject, IRepositorioCliente)
  private
    FRegistro: TStrings;
  public
    Clientes: TClientes;
    ChamadasListarTodos: Integer;
    ChamadasIncluir: Integer;
    ChamadasAlterar: Integer;
    ChamadasExcluir: Integer;
    ChamadasResolverCidade: Integer;
    FalharListarAPartirDe: Integer;
    FalharIncluir: Boolean;
    FalharAlterar: Boolean;
    FalharExcluir: Boolean;
    FalharObter: Boolean;
    MensagemFalha: string;
    IdGerado: Integer;
    CidadeResolvida: Integer;
    UltimoIncluido: TCliente;
    UltimoAlterado: TCliente;
    UltimoIdExcluido: Integer;
    UltimaCidade: string;
    UltimaUf: string;
    UltimoEstado: string;
    constructor Create(ARegistro: TStrings = nil);
    function Incluir(const ACliente: TCliente): Integer;
    procedure Alterar(const ACliente: TCliente);
    procedure Excluir(AId: Integer);
    function ObterPorId(AId: Integer): TCliente;
    function ListarTodos: TClientes;
    function ResolverCidade(const ANomeCidade, AUf, ANomeEstado: string): Integer;
    function TotalChamadas: Integer;
  end;

  TTransacaoFake = class(TInterfacedObject, ITransacao)
  private
    FRegistro: TStrings;
  public
    Iniciadas: Integer;
    Confirmadas: Integer;
    Revertidas: Integer;
    constructor Create(ARegistro: TStrings = nil);
    procedure Iniciar;
    procedure Confirmar;
    procedure Reverter;
  end;

  TConfirmacaoFake = class(TInterfacedObject, IConfirmacao)
  private
    FRegistro: TStrings;
    FMensagens: TStringList;
  public
    Resposta: Boolean;
    constructor Create(ARegistro: TStrings = nil);
    destructor Destroy; override;
    function Confirmar(const AMensagem: string): Boolean;
    property Mensagens: TStringList read FMensagens;
  end;

  TAoSalvarFake = reference to procedure;

  TNavegadorClientesFake = class(TInterfacedObject, INavegadorClientes)
  public
    ChamadasInclusao: Integer;
    ChamadasEdicao: Integer;
    UltimoIdEdicao: Integer;
    Salvar: Boolean;
    AoSalvar: TAoSalvarFake;
    function AbrirInclusao: Boolean;
    function AbrirEdicao(AId: Integer): Boolean;
  end;

  TVisaoPesquisaClienteFake = class(TInterfacedObject, IVisaoPesquisaCliente)
  private
    FErros: TStringList;
    FAvisos: TStringList;
    FSemResultado: TStringList;
  public
    Exibidos: TClientes;
    Exibicoes: Integer;
    AcoesHabilitadas: Boolean;
    Selecionado: Integer;
    Carregando: Boolean;
    CargasSinalizadas: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure SinalizarCarregamento(AAtivo: Boolean);
    procedure ExibirClientes(const AClientes: TClientes);
    procedure ExibirSemResultado(const AMensagem: string);
    procedure HabilitarEdicaoEExclusao(AHabilitar: Boolean);
    function IdSelecionado: Integer;
    procedure ExibirErro(const AMensagem: string);
    procedure ExibirAviso(const AMensagem: string);
    function IdsExibidos: string;
    property Erros: TStringList read FErros;
    property Avisos: TStringList read FAvisos;
    property SemResultado: TStringList read FSemResultado;
  end;

  TVisaoCadastroClienteFake = class(TInterfacedObject, IVisaoCadastroCliente)
  private
    FRegistro: TStringList;
    FMensagens: TStringList;
  public
    Dados: TDadosCadastroCliente;
    Titulo: string;
    IdExibido: Integer;
    CampoFocado: TCampoCliente;
    Focos: Integer;
    Fechamentos: Integer;
    Preenchimentos: Integer;
    constructor Create;
    destructor Destroy; override;
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
    property Registro: TStringList read FRegistro;
    property Mensagens: TStringList read FMensagens;
  end;

  TServicoViaCepFake = class(TInterfacedObject, IServicoViaCep)
  public
    Resultado: TResultadoConsultaCep;
    Chamadas: Integer;
    UltimoCep: string;
    AoConsultar: TProc;
    function Consultar(const ACep: string): TResultadoConsultaCep;
  end;

  TRelogioFake = class(TInterfacedObject, IRelogio)
  public
    Instante: TDateTime;
    constructor Create(AInstante: TDateTime);
    function Agora: TDateTime;
  end;

function NovoCliente(AId: Integer; const ANome, ACpfCnpj, ACep, ACidade, AUf, AEstado: string;
  ADataNascimento: TDate): TCliente;
function ClientesDaFixture: TClientes;
function DadosValidos: TDadosCadastroCliente;
function EnderecoSe: TEnderecoViaCep;
function ResultadoCep(ASituacao: TSituacaoConsultaCep): TResultadoConsultaCep;

implementation

uses
  System.DateUtils;

function NovoCliente(AId: Integer; const ANome, ACpfCnpj, ACep, ACidade, AUf, AEstado: string;
  ADataNascimento: TDate): TCliente;
begin
  Result := Default(TCliente);
  Result.Id := AId;
  Result.Nome := ANome;
  Result.CpfCnpj := ACpfCnpj;
  Result.Cep := ACep;
  Result.Endereco := 'Rua ' + ANome;
  Result.Numero := '10';
  Result.Bairro := 'Centro';
  Result.CidadeId := 1;
  Result.Cidade := ACidade;
  Result.Uf := AUf;
  Result.Estado := AEstado;
  Result.DataNascimento := ADataNascimento;
end;

function ClientesDaFixture: TClientes;
begin
  Result := [
    NovoCliente(1, 'Ana Silva', '52998224725', '30130000', 'Belo Horizonte', 'MG',
      'Minas Gerais', EncodeDate(1990, 3, 15)),
    NovoCliente(10, 'Bruno Costa', '11144477735', '32010000', 'Contagem', 'MG',
      'Minas Gerais', EncodeDate(1985, 7, 20)),
    NovoCliente(15, 'Carlos Silva', '11222333000181', '13010000', 'Campinas', 'SP',
      'São Paulo', EncodeDate(1978, 1, 2)),
    NovoCliente(150, 'Denise Rocha', '12345678909', '13015000', 'Campinas', 'SP',
      'São Paulo', EncodeDate(2000, 11, 30)),
    NovoCliente(23, 'Eduardo Lima', '98765432100', '01001000', 'Salvador', 'BA',
      'Bahia', EncodeDate(1968, 8, 8))];
end;

function DadosValidos: TDadosCadastroCliente;
begin
  Result.Nome := 'Fernanda Alves';
  Result.CpfCnpj := '529.982.247-25';
  Result.DataNascimento := '10/05/1992';
  Result.Cep := '01001-000';
  Result.Endereco := 'Praça da Sé';
  Result.Numero := '100';
  Result.Complemento := 'sala 2';
  Result.Bairro := 'Sé';
  Result.Cidade := 'São Paulo';
  Result.Uf := 'SP';
  Result.Estado := 'São Paulo';
end;

function EnderecoSe: TEnderecoViaCep;
begin
  Result.CEP := '01001-000';
  Result.Logradouro := 'Praça da Sé';
  Result.Complemento := 'lado ímpar';
  Result.Bairro := 'Sé';
  Result.Localidade := 'São Paulo';
  Result.UF := 'SP';
  Result.Estado := 'São Paulo';
end;

function ResultadoCep(ASituacao: TSituacaoConsultaCep): TResultadoConsultaCep;
begin
  Result := Default(TResultadoConsultaCep);
  Result.Situacao := ASituacao;
  if ASituacao = scEncontrado then
    Result.Endereco := EnderecoSe;
end;

procedure Registrar(ARegistro: TStrings; const ATexto: string);
begin
  if Assigned(ARegistro) then
    ARegistro.Add(ATexto);
end;

constructor TRepositorioClienteFake.Create(ARegistro: TStrings);
begin
  inherited Create;
  FRegistro := ARegistro;
  MensagemFalha := 'falha simulada';
  IdGerado := 42;
  CidadeResolvida := 5;
end;

function TRepositorioClienteFake.Incluir(const ACliente: TCliente): Integer;
begin
  Inc(ChamadasIncluir);
  Registrar(FRegistro, 'Incluir');
  if FalharIncluir then
    raise Exception.Create(MensagemFalha);
  UltimoIncluido := ACliente;
  Result := IdGerado;
end;

procedure TRepositorioClienteFake.Alterar(const ACliente: TCliente);
begin
  Inc(ChamadasAlterar);
  Registrar(FRegistro, 'Alterar:' + IntToStr(ACliente.Id));
  if FalharAlterar then
    raise Exception.Create(MensagemFalha);
  UltimoAlterado := ACliente;
end;

procedure TRepositorioClienteFake.Excluir(AId: Integer);
var
  LRestantes: TClientes;
  LCliente: TCliente;
begin
  Inc(ChamadasExcluir);
  Registrar(FRegistro, 'Excluir:' + IntToStr(AId));
  if FalharExcluir then
    raise Exception.Create(MensagemFalha);
  UltimoIdExcluido := AId;
  LRestantes := [];
  for LCliente in Clientes do
    if LCliente.Id <> AId then
      LRestantes := LRestantes + [LCliente];
  Clientes := LRestantes;
end;

function TRepositorioClienteFake.ObterPorId(AId: Integer): TCliente;
var
  LCliente: TCliente;
begin
  Registrar(FRegistro, 'ObterPorId:' + IntToStr(AId));
  if FalharObter then
    raise Exception.Create(MensagemFalha);
  for LCliente in Clientes do
    if LCliente.Id = AId then
      Exit(LCliente);
  raise Exception.CreateFmt('Cliente %d inexistente.', [AId]);
end;

function TRepositorioClienteFake.ListarTodos: TClientes;
begin
  Inc(ChamadasListarTodos);
  Registrar(FRegistro, 'ListarTodos');
  if (FalharListarAPartirDe > 0) and (ChamadasListarTodos >= FalharListarAPartirDe) then
    raise Exception.Create(MensagemFalha);
  Result := Copy(Clientes);
end;

function TRepositorioClienteFake.ResolverCidade(const ANomeCidade, AUf,
  ANomeEstado: string): Integer;
begin
  Inc(ChamadasResolverCidade);
  Registrar(FRegistro, 'ResolverCidade');
  UltimaCidade := ANomeCidade;
  UltimaUf := AUf;
  UltimoEstado := ANomeEstado;
  Result := CidadeResolvida;
end;

function TRepositorioClienteFake.TotalChamadas: Integer;
begin
  Result := ChamadasListarTodos + ChamadasIncluir + ChamadasAlterar + ChamadasExcluir +
    ChamadasResolverCidade;
end;

constructor TTransacaoFake.Create(ARegistro: TStrings);
begin
  inherited Create;
  FRegistro := ARegistro;
end;

procedure TTransacaoFake.Iniciar;
begin
  Inc(Iniciadas);
  Registrar(FRegistro, 'Iniciar');
end;

procedure TTransacaoFake.Confirmar;
begin
  Inc(Confirmadas);
  Registrar(FRegistro, 'Confirmar');
end;

procedure TTransacaoFake.Reverter;
begin
  Inc(Revertidas);
  Registrar(FRegistro, 'Reverter');
end;

constructor TConfirmacaoFake.Create(ARegistro: TStrings);
begin
  inherited Create;
  FRegistro := ARegistro;
  FMensagens := TStringList.Create;
end;

destructor TConfirmacaoFake.Destroy;
begin
  FMensagens.Free;
  inherited;
end;

function TConfirmacaoFake.Confirmar(const AMensagem: string): Boolean;
begin
  FMensagens.Add(AMensagem);
  Registrar(FRegistro, 'Confirmacao');
  Result := Resposta;
end;

function TNavegadorClientesFake.AbrirInclusao: Boolean;
begin
  Inc(ChamadasInclusao);
  Result := Salvar;
  if Result and Assigned(AoSalvar) then
    AoSalvar;
end;

function TNavegadorClientesFake.AbrirEdicao(AId: Integer): Boolean;
begin
  Inc(ChamadasEdicao);
  UltimoIdEdicao := AId;
  Result := Salvar;
  if Result and Assigned(AoSalvar) then
    AoSalvar;
end;

constructor TVisaoPesquisaClienteFake.Create;
begin
  inherited Create;
  FErros := TStringList.Create;
  FAvisos := TStringList.Create;
  FSemResultado := TStringList.Create;
end;

destructor TVisaoPesquisaClienteFake.Destroy;
begin
  FSemResultado.Free;
  FAvisos.Free;
  FErros.Free;
  inherited;
end;

procedure TVisaoPesquisaClienteFake.SinalizarCarregamento(AAtivo: Boolean);
begin
  Carregando := AAtivo;
  if AAtivo then
    Inc(CargasSinalizadas);
end;

procedure TVisaoPesquisaClienteFake.ExibirClientes(const AClientes: TClientes);
begin
  Inc(Exibicoes);
  Exibidos := Copy(AClientes);
  FSemResultado.Clear;
end;

procedure TVisaoPesquisaClienteFake.ExibirSemResultado(const AMensagem: string);
begin
  FSemResultado.Add(AMensagem);
end;

procedure TVisaoPesquisaClienteFake.HabilitarEdicaoEExclusao(AHabilitar: Boolean);
begin
  AcoesHabilitadas := AHabilitar;
end;

function TVisaoPesquisaClienteFake.IdSelecionado: Integer;
begin
  Result := Selecionado;
end;

procedure TVisaoPesquisaClienteFake.ExibirErro(const AMensagem: string);
begin
  FErros.Add(AMensagem);
end;

procedure TVisaoPesquisaClienteFake.ExibirAviso(const AMensagem: string);
begin
  FAvisos.Add(AMensagem);
end;

function TVisaoPesquisaClienteFake.IdsExibidos: string;
var
  LCliente: TCliente;
begin
  Result := '';
  for LCliente in Exibidos do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(LCliente.Id);
  end;
end;

constructor TVisaoCadastroClienteFake.Create;
begin
  inherited Create;
  FRegistro := TStringList.Create;
  FMensagens := TStringList.Create;
end;

destructor TVisaoCadastroClienteFake.Destroy;
begin
  FMensagens.Free;
  FRegistro.Free;
  inherited;
end;

procedure TVisaoCadastroClienteFake.DefinirTitulo(const ATitulo: string);
begin
  Titulo := ATitulo;
end;

function TVisaoCadastroClienteFake.ObterDados: TDadosCadastroCliente;
begin
  Result := Dados;
end;

procedure TVisaoCadastroClienteFake.ExibirDados(const ADados: TDadosCadastroCliente);
begin
  FRegistro.Add('ExibirDados');
  Dados := ADados;
end;

procedure TVisaoCadastroClienteFake.PreencherEndereco(const AEndereco, ABairro, ACidade, AUf,
  AEstado: string);
begin
  Inc(Preenchimentos);
  FRegistro.Add('PreencherEndereco');
  Dados.Endereco := AEndereco;
  Dados.Bairro := ABairro;
  Dados.Cidade := ACidade;
  Dados.Uf := AUf;
  Dados.Estado := AEstado;
end;

procedure TVisaoCadastroClienteFake.ExibirEstado(const AEstado: string);
begin
  FRegistro.Add('ExibirEstado');
  Dados.Estado := AEstado;
end;

procedure TVisaoCadastroClienteFake.ExibirId(AId: Integer);
begin
  FRegistro.Add('ExibirId');
  IdExibido := AId;
end;

procedure TVisaoCadastroClienteFake.SinalizarCarregamento(AAtivo: Boolean);
begin
  FRegistro.Add('Carregamento:' + BoolToStr(AAtivo, True));
end;

procedure TVisaoCadastroClienteFake.ExibirMensagem(const AMensagem: string);
begin
  FRegistro.Add('Mensagem');
  FMensagens.Add(AMensagem);
end;

procedure TVisaoCadastroClienteFake.FocarCampo(ACampo: TCampoCliente);
begin
  Inc(Focos);
  CampoFocado := ACampo;
end;

procedure TVisaoCadastroClienteFake.Fechar;
begin
  Inc(Fechamentos);
  FRegistro.Add('Fechar');
end;

function TServicoViaCepFake.Consultar(const ACep: string): TResultadoConsultaCep;
begin
  Inc(Chamadas);
  UltimoCep := ACep;
  if Assigned(AoConsultar) then
    AoConsultar;
  Result := Resultado;
end;

constructor TRelogioFake.Create(AInstante: TDateTime);
begin
  inherited Create;
  Instante := AInstante;
end;

function TRelogioFake.Agora: TDateTime;
begin
  Result := Instante;
end;

end.

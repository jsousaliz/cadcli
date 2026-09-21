unit Testes.ControladorCadastroCliente;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  Aplicacao.ControladorCadastroCliente,
  Suporte.FakesClientes;

type
  [TestFixture]
  TTestesControladorCadastroCliente = class
  private
    FRegistro: TStringList;
    FVisaoObjeto: TVisaoCadastroClienteFake;
    FVisao: IInterface;
    FRepositorioObjeto: TRepositorioClienteFake;
    FRepositorio: IInterface;
    FTransacaoObjeto: TTransacaoFake;
    FTransacao: IInterface;
    FViaCepObjeto: TServicoViaCepFake;
    FViaCep: IInterface;
    FRelogioObjeto: TRelogioFake;
    FRelogio: IInterface;
    FConfirmacaoObjeto: TConfirmacaoFake;
    FConfirmacao: IInterface;
    FControlador: TControladorCadastroCliente;
    procedure AbrirEdicaoDoSete;
    procedure SairDoCepCom(const ACepNovo: string);
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure InclusaoValidaPersisteEmTransacaoERetornaId;
    [Test]
    procedure AlteracaoValidaAlteraOMesmoIdEmTransacao;
    [Test]
    procedure CampoObrigatorioVazioImpedeSalvarEFocaOPrimeiro;
    [Test]
    procedure NascimentoFuturoImpedeSalvarPeloRelogioInjetado;
    [Test]
    procedure CepComTamanhoErradoImpedeSalvar;
    [Test]
    procedure FalhaAoSalvarReverteEMantemValores;
    [Test]
    procedure DescarteDeAlteracoesPedeConfirmacao;
    [Test]
    procedure CepAlteradoConsultaUmaVezSinalizandoCarregamento;
    [Test]
    procedure CepSemAlteracaoNaoConsulta;
    [Test]
    procedure CepEncontradoPreencheEnderecoEPreservaNumeroEComplemento;
    [Test]
    procedure CepAlteradoComTamanhoErradoNaoConsulta;
    [Test]
    procedure CepNaoEncontradoMantemCamposEditaveis;
    [Test]
    procedure CepIndisponivelPreservaValores;
    [Test]
    procedure CepComRespostaInvalidaNaoPreencheCampos;
    [Test]
    procedure NomeDoEstadoVemDoViaCepOuDaTabela;
  end;

implementation

uses
  System.SysUtils,
  Dominio.Cliente,
  Aplicacao.ServicoViaCep,
  Infraestrutura.ServicoViaCep,
  Infraestrutura.TransporteHttp;

type
  TTransporteSemEstado = class(TInterfacedObject, ITransporteHttp)
  public
    function Obter(const AUrl: string): TRespostaHttp;
  end;

function TTransporteSemEstado.Obter(const AUrl: string): TRespostaHttp;
begin
  Result.Situacao := srRespondida;
  Result.Codigo := 200;
  Result.Corpo := '{"cep": "88015-600", "logradouro": "Rua Almirante Lamego", "complemento": "", ' +
    '"bairro": "Centro", "localidade": "Florianópolis", "uf": "SC", "ibge": "4205407"}';
end;

procedure TTestesControladorCadastroCliente.Preparar;
begin
  FRegistro := TStringList.Create;
  FVisaoObjeto := TVisaoCadastroClienteFake.Create;
  FVisao := FVisaoObjeto as IVisaoCadastroCliente;
  FRepositorioObjeto := TRepositorioClienteFake.Create(FRegistro);
  FRepositorio := FRepositorioObjeto as IInterface;
  FTransacaoObjeto := TTransacaoFake.Create(FRegistro);
  FTransacao := FTransacaoObjeto as IInterface;
  FViaCepObjeto := TServicoViaCepFake.Create;
  FViaCep := FViaCepObjeto as IInterface;
  FRelogioObjeto := TRelogioFake.Create(EncodeDate(2026, 9, 21) + EncodeTime(15, 30, 0, 0));
  FRelogio := FRelogioObjeto as IInterface;
  FConfirmacaoObjeto := TConfirmacaoFake.Create;
  FConfirmacao := FConfirmacaoObjeto as IInterface;
  FControlador := TControladorCadastroCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FViaCepObjeto, FRelogioObjeto, FConfirmacaoObjeto);
end;

procedure TTestesControladorCadastroCliente.Limpar;
begin
  FreeAndNil(FControlador);
  FVisao := nil;
  FRepositorio := nil;
  FTransacao := nil;
  FViaCep := nil;
  FRelogio := nil;
  FConfirmacao := nil;
  FreeAndNil(FRegistro);
end;

procedure TTestesControladorCadastroCliente.AbrirEdicaoDoSete;
var
  LCliente: TCliente;
begin
  LCliente := NovoCliente(7, 'Ana Silva', '52998224725', '01001000', 'São Paulo', 'SP',
    'São Paulo', EncodeDate(1990, 3, 15));
  LCliente.Complemento := 'casa';
  FRepositorioObjeto.Clientes := [LCliente];
  Assert.IsTrue(FControlador.Abrir(mcEdicao, 7));
  FRegistro.Clear;
  FVisaoObjeto.Registro.Clear;
end;

procedure TTestesControladorCadastroCliente.SairDoCepCom(const ACepNovo: string);
begin
  FControlador.CepRecebeuFoco;
  FVisaoObjeto.Dados.Cep := ACepNovo;
  FControlador.CepPerdeuFoco;
end;

procedure TTestesControladorCadastroCliente.InclusaoValidaPersisteEmTransacaoERetornaId;
begin
  FControlador.Abrir(mcInclusao);
  Assert.AreEqual('Novo Cliente', FVisaoObjeto.Titulo);
  FVisaoObjeto.Dados := DadosValidos;
  FRepositorioObjeto.IdGerado := 42;
  FControlador.Salvar;
  Assert.AreEqual('Iniciar|ResolverCidade|Incluir|Confirmar', string.Join('|', FRegistro.ToStringArray));
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasIncluir);
  Assert.AreEqual(1, FTransacaoObjeto.Confirmadas);
  Assert.AreEqual(0, FTransacaoObjeto.Revertidas);
  Assert.AreEqual(42, FVisaoObjeto.IdExibido, 'O ID devolvido deve ser informado à visão.');
  Assert.IsTrue(FControlador.Salvo, 'O resultado do cadastro deve ser salvo.');
  Assert.AreEqual(1, FVisaoObjeto.Fechamentos);
  Assert.AreEqual('São Paulo', FRepositorioObjeto.UltimaCidade);
  Assert.AreEqual('SP', FRepositorioObjeto.UltimaUf);
  Assert.AreEqual(FRepositorioObjeto.CidadeResolvida, FRepositorioObjeto.UltimoIncluido.CidadeId);
  Assert.AreEqual('Fernanda Alves', FRepositorioObjeto.UltimoIncluido.Nome);
  Assert.AreEqual('01001000', FRepositorioObjeto.UltimoIncluido.Cep);
  Assert.AreEqual(Double(EncodeDate(1992, 5, 10)), Double(FRepositorioObjeto.UltimoIncluido.DataNascimento));
end;

procedure TTestesControladorCadastroCliente.AlteracaoValidaAlteraOMesmoIdEmTransacao;
begin
  AbrirEdicaoDoSete;
  Assert.AreEqual('Editar Cliente', FVisaoObjeto.Titulo);
  FVisaoObjeto.Dados.Nome := 'Ana Silva Souza';
  FControlador.Salvar;
  Assert.AreEqual('Iniciar|ResolverCidade|Alterar:7|Confirmar', string.Join('|', FRegistro.ToStringArray));
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasAlterar);
  Assert.AreEqual(0, FRepositorioObjeto.ChamadasIncluir);
  Assert.AreEqual(7, FRepositorioObjeto.UltimoAlterado.Id);
  Assert.AreEqual('Ana Silva Souza', FRepositorioObjeto.UltimoAlterado.Nome);
  Assert.AreEqual(7, FVisaoObjeto.IdExibido, 'O ID informado à visão continua 7.');
  Assert.IsTrue(FControlador.Salvo);
end;

procedure TTestesControladorCadastroCliente.CampoObrigatorioVazioImpedeSalvarEFocaOPrimeiro;
const
  ROTULOS: array[TCampoCliente] of string = ('Nome', 'CPF/CNPJ', 'Data de nascimento', 'CEP',
    'Endereço', 'Número', 'Complemento', 'Bairro', 'Cidade', 'UF');
var
  LCampo: TCampoCliente;
  LVazio: string;
  LDados: TDadosCadastroCliente;
begin
  FControlador.Abrir(mcInclusao);
  for LCampo := Low(TCampoCliente) to High(TCampoCliente) do
  begin
    if LCampo = ccComplemento then
      Continue;
    for LVazio in TArray<string>.Create('', '   ') do
    begin
      LDados := DadosValidos;
      case LCampo of
        ccNome: LDados.Nome := LVazio;
        ccCpfCnpj: LDados.CpfCnpj := LVazio;
        ccDataNascimento: LDados.DataNascimento := LVazio;
        ccCep: LDados.Cep := LVazio;
        ccEndereco: LDados.Endereco := LVazio;
        ccNumero: LDados.Numero := LVazio;
        ccBairro: LDados.Bairro := LVazio;
        ccCidade: LDados.Cidade := LVazio;
        ccUf: LDados.Uf := LVazio;
      end;
      FVisaoObjeto.Dados := LDados;
      FVisaoObjeto.Mensagens.Clear;
      FVisaoObjeto.CampoFocado := ccComplemento;
      FControlador.Salvar;
      Assert.AreEqual(0, FTransacaoObjeto.Iniciadas, ROTULOS[LCampo] + ' vazio não pode iniciar transação.');
      Assert.AreEqual('O campo ' + ROTULOS[LCampo] + ' é obrigatório.', FVisaoObjeto.Mensagens.Text.Trim);
      Assert.IsTrue(FVisaoObjeto.CampoFocado = LCampo, 'O foco deve ir para ' + ROTULOS[LCampo]);
    end;
  end;

  LDados := DadosValidos;
  LDados.Nome := '';
  LDados.Bairro := '';
  FVisaoObjeto.Dados := LDados;
  FVisaoObjeto.Mensagens.Clear;
  FVisaoObjeto.CampoFocado := ccComplemento;
  FControlador.Salvar;
  Assert.AreEqual('O campo Nome é obrigatório.', FVisaoObjeto.Mensagens.Text.Trim);
  Assert.IsTrue(FVisaoObjeto.CampoFocado = ccNome);
  Assert.AreEqual(0, FTransacaoObjeto.Iniciadas);

  LDados := DadosValidos;
  LDados.Complemento := '';
  FVisaoObjeto.Dados := LDados;
  FVisaoObjeto.Mensagens.Clear;
  FControlador.Salvar;
  Assert.AreEqual(1, FTransacaoObjeto.Iniciadas, 'Complemento vazio não impede salvar.');
  Assert.AreEqual(0, FVisaoObjeto.Mensagens.Count);
end;

procedure TTestesControladorCadastroCliente.NascimentoFuturoImpedeSalvarPeloRelogioInjetado;
begin
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.DataNascimento := '22/09/2026';
  FControlador.Salvar;
  Assert.AreEqual('Data de nascimento não pode estar no futuro', FVisaoObjeto.Mensagens.Text.Trim);
  Assert.AreEqual(0, FTransacaoObjeto.Iniciadas);

  FVisaoObjeto.Mensagens.Clear;
  FVisaoObjeto.Dados.DataNascimento := '21/09/2026';
  FControlador.Salvar;
  Assert.AreEqual(0, FVisaoObjeto.Mensagens.Count, 'O nascimento na data atual é aceito.');
  Assert.AreEqual(1, FTransacaoObjeto.Iniciadas);
end;

procedure TTestesControladorCadastroCliente.CepComTamanhoErradoImpedeSalvar;
begin
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '0100100';
  FControlador.Salvar;
  Assert.AreEqual(0, FTransacaoObjeto.Iniciadas);
  Assert.AreEqual('CEP inválido', FVisaoObjeto.Mensagens.Text.Trim);

  FVisaoObjeto.Mensagens.Clear;
  FVisaoObjeto.Dados.Cep := '01001-000';
  FControlador.Salvar;
  Assert.AreEqual(1, FTransacaoObjeto.Iniciadas);
  Assert.AreEqual('01001000', FRepositorioObjeto.UltimoIncluido.Cep);
end;

procedure TTestesControladorCadastroCliente.FalhaAoSalvarReverteEMantemValores;
var
  LAntes: TDadosCadastroCliente;
begin
  FRepositorioObjeto.MensagemFalha := 'Falha em SYSDBA masterkey localhost:3050';
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  LAntes := FVisaoObjeto.Dados;
  FVisaoObjeto.Registro.Clear;
  FRepositorioObjeto.FalharIncluir := True;
  FControlador.Salvar;
  Assert.AreEqual(1, FTransacaoObjeto.Revertidas);
  Assert.AreEqual(0, FTransacaoObjeto.Confirmadas);
  Assert.AreEqual('Não foi possível salvar o cliente.', FVisaoObjeto.Mensagens.Text.Trim);
  Assert.IsTrue(FVisaoObjeto.Dados = LAntes, 'Nenhum valor da visão pode mudar.');
  Assert.AreEqual('Mensagem', FVisaoObjeto.Registro.Text.Trim, 'A visão só recebe a mensagem.');
  Assert.IsFalse(FControlador.Salvo, 'O cadastro continua aberto.');
  Assert.AreEqual(0, FVisaoObjeto.Fechamentos);

  FreeAndNil(FControlador);
  FControlador := TControladorCadastroCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FViaCepObjeto, FRelogioObjeto, FConfirmacaoObjeto);
  AbrirEdicaoDoSete;
  FVisaoObjeto.Dados.Nome := 'Outro nome';
  LAntes := FVisaoObjeto.Dados;
  FVisaoObjeto.Mensagens.Clear;
  FRepositorioObjeto.FalharAlterar := True;
  FControlador.Salvar;
  Assert.AreEqual(2, FTransacaoObjeto.Revertidas);
  Assert.AreEqual(0, FTransacaoObjeto.Confirmadas);
  Assert.AreEqual('Não foi possível salvar o cliente.', FVisaoObjeto.Mensagens.Text.Trim);
  Assert.IsTrue(FVisaoObjeto.Dados = LAntes);
  Assert.IsFalse(FControlador.Salvo);
end;

procedure TTestesControladorCadastroCliente.DescarteDeAlteracoesPedeConfirmacao;
begin
  FControlador.Abrir(mcInclusao);
  Assert.IsTrue(FControlador.PodeFechar, 'Sem alterações fecha sem pedir confirmação.');
  Assert.AreEqual(0, FConfirmacaoObjeto.Mensagens.Count);

  FVisaoObjeto.Dados.Nome := 'Alguém';
  FConfirmacaoObjeto.Resposta := False;
  Assert.IsFalse(FControlador.PodeFechar, 'Resposta Não mantém a form aberta.');
  Assert.AreEqual(1, FConfirmacaoObjeto.Mensagens.Count);
  Assert.AreEqual('Descartar as alterações não salvas?', FConfirmacaoObjeto.Mensagens[0]);
  Assert.AreEqual('Alguém', FVisaoObjeto.Dados.Nome);

  FConfirmacaoObjeto.Mensagens.Clear;
  FConfirmacaoObjeto.Resposta := True;
  Assert.IsTrue(FControlador.PodeFechar, 'Resposta Sim fecha.');
  Assert.AreEqual(1, FConfirmacaoObjeto.Mensagens.Count);
  Assert.IsFalse(FControlador.Salvo, 'O resultado é não salvo.');
  Assert.AreEqual(0, FRepositorioObjeto.TotalChamadas, 'Descartar não chama o repositório.');

  FreeAndNil(FControlador);
  FControlador := TControladorCadastroCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FViaCepObjeto, FRelogioObjeto, FConfirmacaoObjeto);
  AbrirEdicaoDoSete;
  FConfirmacaoObjeto.Mensagens.Clear;
  Assert.IsTrue(FControlador.PodeFechar, 'Edição sem alterações fecha sem confirmação.');
  Assert.AreEqual(0, FConfirmacaoObjeto.Mensagens.Count);
end;

procedure TTestesControladorCadastroCliente.CepAlteradoConsultaUmaVezSinalizandoCarregamento;
begin
  FControlador.Abrir(mcInclusao);
  FViaCepObjeto.Resultado := ResultadoCep(scEncontrado);
  FVisaoObjeto.Registro.Clear;
  SairDoCepCom('01001-000');
  Assert.AreEqual(1, FViaCepObjeto.Chamadas);
  Assert.AreEqual('01001000', FViaCepObjeto.UltimoCep);
  Assert.AreEqual('Carregamento:True|PreencherEndereco|Carregamento:False',
    string.Join('|', FVisaoObjeto.Registro.ToStringArray),
    'A visão deve receber, em ordem, carregamento ligado, a resposta e carregamento desligado.');
end;

procedure TTestesControladorCadastroCliente.CepSemAlteracaoNaoConsulta;
var
  LAntes: TDadosCadastroCliente;
begin
  AbrirEdicaoDoSete;
  LAntes := FVisaoObjeto.Dados;
  FControlador.CepRecebeuFoco;
  FControlador.CepPerdeuFoco;
  Assert.AreEqual(0, FViaCepObjeto.Chamadas, 'Abrir em edição e sair do CEP não consulta.');
  Assert.AreEqual(0, FVisaoObjeto.Preenchimentos);
  Assert.IsTrue(FVisaoObjeto.Dados = LAntes);

  FControlador.CepPerdeuFoco;
  Assert.AreEqual(0, FViaCepObjeto.Chamadas, 'Sair sem ter entrado também não consulta.');

  FVisaoObjeto.Dados.Cep := '01001-000';
  FControlador.CepRecebeuFoco;
  FVisaoObjeto.Dados.Cep := '01001000';
  FControlador.CepPerdeuFoco;
  Assert.AreEqual(0, FViaCepObjeto.Chamadas, 'Trocar só a máscara não consulta.');
  Assert.AreEqual(0, FVisaoObjeto.Preenchimentos);
  Assert.AreEqual(0, FVisaoObjeto.Mensagens.Count);
end;

procedure TTestesControladorCadastroCliente.CepEncontradoPreencheEnderecoEPreservaNumeroEComplemento;
begin
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados.Numero := '100';
  FVisaoObjeto.Dados.Complemento := 'sala 2';
  FViaCepObjeto.Resultado := ResultadoCep(scEncontrado);
  SairDoCepCom('01001-000');
  Assert.AreEqual(1, FVisaoObjeto.Preenchimentos);
  Assert.AreEqual('Praça da Sé', FVisaoObjeto.Dados.Endereco);
  Assert.AreEqual('Sé', FVisaoObjeto.Dados.Bairro);
  Assert.AreEqual('São Paulo', FVisaoObjeto.Dados.Cidade);
  Assert.AreEqual('SP', FVisaoObjeto.Dados.Uf);
  Assert.AreEqual('São Paulo', FVisaoObjeto.Dados.Estado);
  Assert.AreEqual('100', FVisaoObjeto.Dados.Numero);
  Assert.AreEqual('sala 2', FVisaoObjeto.Dados.Complemento);
  Assert.AreEqual(0, FVisaoObjeto.Mensagens.Count);
end;

procedure TTestesControladorCadastroCliente.CepAlteradoComTamanhoErradoNaoConsulta;
var
  LCep: string;
begin
  for LCep in TArray<string>.Create('0100100', '010010001') do
  begin
    FControlador.Abrir(mcInclusao);
    FVisaoObjeto.Dados := Default(TDadosCadastroCliente);
    FVisaoObjeto.Mensagens.Clear;
    SairDoCepCom(LCep);
    Assert.AreEqual(0, FViaCepObjeto.Chamadas, LCep + ' não pode consultar o ViaCEP.');
    Assert.AreEqual(1, FVisaoObjeto.Mensagens.Count);
    Assert.AreEqual('CEP inválido', FVisaoObjeto.Mensagens[0]);
  end;
end;

procedure TTestesControladorCadastroCliente.CepNaoEncontradoMantemCamposEditaveis;
var
  LAntes: TDadosCadastroCliente;
begin
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '';
  LAntes := FVisaoObjeto.Dados;
  FViaCepObjeto.Resultado := ResultadoCep(scNaoEncontrado);
  FVisaoObjeto.Registro.Clear;
  SairDoCepCom('99999-999');
  LAntes.Cep := '99999-999';
  Assert.AreEqual(1, FViaCepObjeto.Chamadas);
  Assert.AreEqual('CEP não encontrado', FVisaoObjeto.Mensagens.Text.Trim);
  Assert.IsTrue(FVisaoObjeto.Dados = LAntes, 'Os campos de endereço mantêm os valores anteriores.');
  Assert.AreEqual(0, FVisaoObjeto.Preenchimentos);
  Assert.AreEqual('Carregamento:True|Mensagem|Carregamento:False',
    string.Join('|', FVisaoObjeto.Registro.ToStringArray), 'O carregamento termina desligado.');
end;

procedure TTestesControladorCadastroCliente.CepIndisponivelPreservaValores;
var
  LAntes: TDadosCadastroCliente;
begin
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '';
  FViaCepObjeto.Resultado := ResultadoCep(scIndisponivel);
  FVisaoObjeto.Registro.Clear;
  SairDoCepCom('01001-000');
  LAntes := DadosValidos;
  Assert.AreEqual('Serviço de CEP indisponível. Preencha o endereço manualmente.',
    FVisaoObjeto.Mensagens.Text.Trim);
  Assert.AreEqual('Carregamento:True|Mensagem|Carregamento:False',
    string.Join('|', FVisaoObjeto.Registro.ToStringArray));
  Assert.IsTrue(FVisaoObjeto.Dados = LAntes, 'Os 10 valores digitados continuam iguais.');
end;

procedure TTestesControladorCadastroCliente.CepComRespostaInvalidaNaoPreencheCampos;
var
  LAntes: TDadosCadastroCliente;
begin
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '';
  FViaCepObjeto.Resultado := ResultadoCep(scRespostaInvalida);
  FViaCepObjeto.Resultado.Endereco := EnderecoSe;
  FViaCepObjeto.Resultado.Endereco.Logradouro := 'Não deve aparecer';
  SairDoCepCom('01001-000');
  LAntes := DadosValidos;
  Assert.AreEqual('Resposta inválida do serviço de CEP', FVisaoObjeto.Mensagens.Text.Trim);
  Assert.AreEqual(0, FVisaoObjeto.Preenchimentos, 'Nenhum campo pode ser preenchido.');
  Assert.IsTrue(FVisaoObjeto.Dados = LAntes);
end;

procedure TTestesControladorCadastroCliente.NomeDoEstadoVemDoViaCepOuDaTabela;
var
  LResultado: TResultadoConsultaCep;
  LTransporte: ITransporteHttp;
begin
  FControlador.Abrir(mcInclusao);
  LResultado := ResultadoCep(scEncontrado);
  LResultado.Endereco.Localidade := 'Florianópolis';
  LResultado.Endereco.UF := 'SC';
  LResultado.Endereco.Estado := 'Santa Catarina (ViaCEP)';
  FViaCepObjeto.Resultado := LResultado;
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '';
  SairDoCepCom('88010-000');
  FControlador.Salvar;
  Assert.AreEqual('Santa Catarina (ViaCEP)', FRepositorioObjeto.UltimoEstado,
    'Com estado preenchido, o nome vem do ViaCEP.');
  Assert.AreEqual('SC', FRepositorioObjeto.UltimaUf);
  Assert.AreEqual('Florianópolis', FRepositorioObjeto.UltimaCidade);

  FreeAndNil(FControlador);
  FControlador := TControladorCadastroCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FViaCepObjeto, FRelogioObjeto, FConfirmacaoObjeto);
  FControlador.Abrir(mcInclusao);
  LResultado.Endereco.Estado := '';
  FViaCepObjeto.Resultado := LResultado;
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '';
  FVisaoObjeto.Dados.Estado := '';
  SairDoCepCom('88010-000');
  Assert.AreEqual('Santa Catarina', FVisaoObjeto.Dados.Estado);
  FControlador.Salvar;
  Assert.AreEqual('Santa Catarina', FRepositorioObjeto.UltimoEstado,
    'Com estado vazio, o nome vem da tabela fixa.');

  FreeAndNil(FControlador);
  FControlador := TControladorCadastroCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FViaCepObjeto, FRelogioObjeto, FConfirmacaoObjeto);
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Uf := 'DF';
  FVisaoObjeto.Dados.Estado := '';
  FControlador.UfAlterada;
  Assert.AreEqual('Distrito Federal', FVisaoObjeto.Dados.Estado);
  FVisaoObjeto.Dados.Estado := '';
  FControlador.Salvar;
  Assert.AreEqual('Distrito Federal', FRepositorioObjeto.UltimoEstado,
    'Sem estado informado, o nome vem da tabela fixa.');

  FreeAndNil(FControlador);
  LTransporte := TTransporteSemEstado.Create;
  FControlador := TControladorCadastroCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, TServicoViaCep.Create(LTransporte), FRelogioObjeto, FConfirmacaoObjeto);
  FControlador.Abrir(mcInclusao);
  FVisaoObjeto.Dados := DadosValidos;
  FVisaoObjeto.Dados.Cep := '';
  FVisaoObjeto.Dados.Estado := '';
  FVisaoObjeto.Mensagens.Clear;
  SairDoCepCom('88015-600');
  Assert.AreEqual(0, FVisaoObjeto.Mensagens.Count, 'JSON sem estado não é resposta inválida.');
  Assert.AreEqual('Florianópolis', FVisaoObjeto.Dados.Cidade);
  Assert.AreEqual('SC', FVisaoObjeto.Dados.Uf);
  Assert.AreEqual('Santa Catarina', FVisaoObjeto.Dados.Estado, 'JSON sem estado usa a tabela fixa.');
  FControlador.Salvar;
  Assert.AreEqual('Santa Catarina', FRepositorioObjeto.UltimoEstado,
    'O estado inserido a partir de JSON sem estado vem da tabela fixa.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesControladorCadastroCliente);

end.

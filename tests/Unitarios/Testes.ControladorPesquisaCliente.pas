unit Testes.ControladorPesquisaCliente;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  Aplicacao.ControladorPesquisaCliente,
  Suporte.FakesClientes;

type
  [TestFixture]
  TTestesControladorPesquisaCliente = class
  private
    FRegistro: TStringList;
    FVisaoObjeto: TVisaoPesquisaClienteFake;
    FVisao: IInterface;
    FRepositorioObjeto: TRepositorioClienteFake;
    FRepositorio: IInterface;
    FTransacaoObjeto: TTransacaoFake;
    FTransacao: IInterface;
    FNavegadorObjeto: TNavegadorClientesFake;
    FNavegador: IInterface;
    FConfirmacaoObjeto: TConfirmacaoFake;
    FConfirmacao: IInterface;
    FControlador: TControladorPesquisaCliente;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure AberturaCarregaUmaVezEExibePorIdCrescente;
    [Test]
    procedure FiltrarNaoConsultaORepositorio;
    [Test]
    procedure SemResultadoExibeMensagemEDesabilitaAcoes;
    [Test]
    procedure FalhaNaCargaExibeErroEEsvaziaAListaEmMemoria;
    [Test]
    procedure NovoAbreInclusaoERecarregaComFiltroSoQuandoSalvo;
    [Test]
    procedure EditarAbreEdicaoDoSelecionadoERecarregaSoQuandoSalvo;
    [Test]
    procedure ExclusaoPedeConfirmacaoComIdENome;
    [Test]
    procedure ExclusaoConfirmadaExcluiEmTransacaoERecarrega;
    [Test]
    procedure IdsProtegidosNaoAbremTransacao;
    [Test]
    procedure FalhaNaExclusaoReverteEMantemRegistro;
  end;

implementation

uses
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroCliente;

function FiltroNome(const ANome: string): TFiltroCliente;
begin
  Result := Default(TFiltroCliente);
  Result.Nome := ANome;
end;

procedure TTestesControladorPesquisaCliente.Preparar;
begin
  FRegistro := TStringList.Create;
  FVisaoObjeto := TVisaoPesquisaClienteFake.Create;
  FVisao := FVisaoObjeto as IVisaoPesquisaCliente;
  FRepositorioObjeto := TRepositorioClienteFake.Create(FRegistro);
  FRepositorio := FRepositorioObjeto as IInterface;
  FTransacaoObjeto := TTransacaoFake.Create(FRegistro);
  FTransacao := FTransacaoObjeto as IInterface;
  FNavegadorObjeto := TNavegadorClientesFake.Create;
  FNavegador := FNavegadorObjeto as IInterface;
  FConfirmacaoObjeto := TConfirmacaoFake.Create(FRegistro);
  FConfirmacao := FConfirmacaoObjeto as IInterface;
  FControlador := TControladorPesquisaCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FNavegadorObjeto, FConfirmacaoObjeto);
end;

procedure TTestesControladorPesquisaCliente.Limpar;
begin
  FreeAndNil(FControlador);
  FVisao := nil;
  FRepositorio := nil;
  FTransacao := nil;
  FNavegador := nil;
  FConfirmacao := nil;
  FreeAndNil(FRegistro);
end;

procedure TTestesControladorPesquisaCliente.AberturaCarregaUmaVezEExibePorIdCrescente;
var
  LEsperados: TClientes;
  I: Integer;
begin
  LEsperados := [
    NovoCliente(8, 'Oito', '52998224725', '30130000', 'Belo Horizonte', 'MG', 'Minas Gerais',
      EncodeDate(1980, 1, 8)),
    NovoCliente(1, 'Um', '11144477735', '01001000', 'Campinas', 'SP', 'São Paulo',
      EncodeDate(1981, 2, 1)),
    NovoCliente(5, 'Cinco', '11222333000181', '40010000', 'Salvador', 'BA', 'Bahia',
      EncodeDate(1982, 3, 5))];
  FRepositorioObjeto.Clientes := LEsperados;
  FControlador.Abrir;
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasListarTodos, 'A abertura deve carregar uma única vez.');
  Assert.AreEqual(3, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual('1,5,8', FVisaoObjeto.IdsExibidos, 'A grade deve vir por ID crescente.');
  for I := 0 to 2 do
  begin
    Assert.AreEqual(LEsperados[(I + 1) mod 3].Id, FVisaoObjeto.Exibidos[I].Id);
    Assert.AreEqual(LEsperados[(I + 1) mod 3].Nome, FVisaoObjeto.Exibidos[I].Nome);
    Assert.AreEqual(LEsperados[(I + 1) mod 3].CpfCnpj, FVisaoObjeto.Exibidos[I].CpfCnpj);
    Assert.AreEqual(LEsperados[(I + 1) mod 3].Cep, FVisaoObjeto.Exibidos[I].Cep);
    Assert.AreEqual(LEsperados[(I + 1) mod 3].Cidade, FVisaoObjeto.Exibidos[I].Cidade);
    Assert.AreEqual(LEsperados[(I + 1) mod 3].Uf, FVisaoObjeto.Exibidos[I].Uf);
    Assert.AreEqual(LEsperados[(I + 1) mod 3].Estado, FVisaoObjeto.Exibidos[I].Estado);
    Assert.AreEqual(Double(LEsperados[(I + 1) mod 3].DataNascimento),
      Double(FVisaoObjeto.Exibidos[I].DataNascimento));
  end;
  Assert.IsFalse(FVisaoObjeto.Carregando, 'O carregamento deve terminar desligado.');
  Assert.AreEqual(1, FVisaoObjeto.CargasSinalizadas);
end;

procedure TTestesControladorPesquisaCliente.FiltrarNaoConsultaORepositorio;
var
  LFiltro: TFiltroCliente;
begin
  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FControlador.Abrir;
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasListarTodos);

  FControlador.Pesquisar(FiltroNome('silva'));
  Assert.AreEqual('1,15', FVisaoObjeto.IdsExibidos);
  LFiltro := Default(TFiltroCliente);
  LFiltro.Cidade := 'campinas';
  FControlador.Pesquisar(LFiltro);
  Assert.AreEqual('15,150', FVisaoObjeto.IdsExibidos);
  LFiltro := Default(TFiltroCliente);
  LFiltro.Estado := 'MG';
  FControlador.Pesquisar(LFiltro);
  Assert.AreEqual('1,10', FVisaoObjeto.IdsExibidos);

  Assert.AreEqual(1, FRepositorioObjeto.ChamadasListarTodos,
    'Filtrar não pode consultar o repositório de novo.');
  Assert.AreEqual(1, FRepositorioObjeto.TotalChamadas, 'Filtrar não pode chamar o repositório.');
end;

procedure TTestesControladorPesquisaCliente.SemResultadoExibeMensagemEDesabilitaAcoes;
begin
  FRepositorioObjeto.Clientes := [];
  FControlador.Abrir;
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual('Nenhum cliente encontrado', FVisaoObjeto.SemResultado.Text.Trim);
  Assert.IsFalse(FVisaoObjeto.AcoesHabilitadas, 'Editar e Excluir devem ficar desabilitadas.');
  FreeAndNil(FControlador);

  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FControlador := TControladorPesquisaCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FNavegadorObjeto, FConfirmacaoObjeto);
  FControlador.Abrir;
  Assert.AreEqual(5, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual(0, FVisaoObjeto.SemResultado.Count, 'Com resultados não há aviso de vazio.');
  Assert.IsTrue(FVisaoObjeto.AcoesHabilitadas, 'Editar e Excluir devem ficar habilitadas.');

  FControlador.Pesquisar(FiltroNome('inexistente'));
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual('Nenhum cliente encontrado', FVisaoObjeto.SemResultado.Text.Trim);
  Assert.IsFalse(FVisaoObjeto.AcoesHabilitadas);

  FControlador.Pesquisar(FiltroNome('ana'));
  Assert.AreEqual(1, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.IsTrue(FVisaoObjeto.AcoesHabilitadas, 'Com 1 cliente exibido as ações ficam habilitadas.');
end;

procedure TTestesControladorPesquisaCliente.FalhaNaCargaExibeErroEEsvaziaAListaEmMemoria;
begin
  FRepositorioObjeto.FalharListarAPartirDe := 1;
  FRepositorioObjeto.MensagemFalha := 'SYSDBA masterkey localhost:3050';
  FControlador.Abrir;
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count, 'O erro deve ser exibido exatamente uma vez.');
  Assert.AreEqual('Não foi possível carregar os clientes.', FVisaoObjeto.Erros[0]);
  Assert.IsFalse(FVisaoObjeto.Erros[0].Contains('masterkey'));
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)));
  FreeAndNil(FControlador);

  FVisaoObjeto.Erros.Clear;
  FRepositorioObjeto.ChamadasListarTodos := 0;
  FRepositorioObjeto.FalharListarAPartirDe := 2;
  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FNavegadorObjeto.Salvar := True;
  FControlador := TControladorPesquisaCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FNavegadorObjeto, FConfirmacaoObjeto);
  FControlador.Abrir;
  Assert.AreEqual(5, Integer(Length(FVisaoObjeto.Exibidos)));
  FControlador.Novo;
  Assert.AreEqual(2, FRepositorioObjeto.ChamadasListarTodos);
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível carregar os clientes.', FVisaoObjeto.Erros[0]);
  FControlador.Pesquisar(Default(TFiltroCliente));
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)),
    'Depois da recarga que falha, a lista em memória deve estar vazia.');
end;

procedure TTestesControladorPesquisaCliente.NovoAbreInclusaoERecarregaComFiltroSoQuandoSalvo;
var
  LRepositorio: TRepositorioClienteFake;
begin
  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FControlador.Abrir;
  FControlador.Pesquisar(FiltroNome('silva'));

  FNavegadorObjeto.Salvar := False;
  FControlador.Novo;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasInclusao);
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasListarTodos, 'Sem salvar não há recarga.');

  LRepositorio := FRepositorioObjeto;
  FNavegadorObjeto.Salvar := True;
  FNavegadorObjeto.AoSalvar :=
    procedure
    begin
      LRepositorio.Clientes := LRepositorio.Clientes + [NovoCliente(200, 'Eva Silva',
        '12345678909', '13010000', 'Campinas', 'SP', 'São Paulo', EncodeDate(1995, 5, 5))];
    end;
  FControlador.Novo;
  Assert.AreEqual(2, FNavegadorObjeto.ChamadasInclusao);
  Assert.AreEqual(2, FRepositorioObjeto.ChamadasListarTodos, 'Salvo deve recarregar uma vez.');
  Assert.AreEqual('1,15,200', FVisaoObjeto.IdsExibidos,
    'O filtro vigente deve ser reaplicado: Eva Silva aparece e Bruno Costa não.');
  FNavegadorObjeto.AoSalvar := nil;
end;

procedure TTestesControladorPesquisaCliente.EditarAbreEdicaoDoSelecionadoERecarregaSoQuandoSalvo;
begin
  FRepositorioObjeto.Clientes := ClientesDaFixture + [NovoCliente(7, 'Ana Silva', '52998224725',
    '30130000', 'Belo Horizonte', 'MG', 'Minas Gerais', EncodeDate(1990, 3, 15))];
  FControlador.Abrir;
  FControlador.Pesquisar(FiltroNome('silva'));
  FVisaoObjeto.Selecionado := 7;

  FNavegadorObjeto.Salvar := False;
  FControlador.Editar;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasEdicao);
  Assert.AreEqual(0, FNavegadorObjeto.ChamadasInclusao);
  Assert.AreEqual(7, FNavegadorObjeto.UltimoIdEdicao);
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasListarTodos, 'Sem salvar não há recarga.');

  FNavegadorObjeto.Salvar := True;
  FControlador.Editar;
  Assert.AreEqual(2, FNavegadorObjeto.ChamadasEdicao);
  Assert.AreEqual(7, FNavegadorObjeto.UltimoIdEdicao);
  Assert.AreEqual(2, FRepositorioObjeto.ChamadasListarTodos, 'Salvo deve recarregar uma vez.');
  Assert.AreEqual('1,7,15', FVisaoObjeto.IdsExibidos, 'O filtro vigente deve ser reaplicado.');
end;

procedure TTestesControladorPesquisaCliente.ExclusaoPedeConfirmacaoComIdENome;
begin
  FRepositorioObjeto.Clientes := [NovoCliente(7, 'Ana Silva', '52998224725', '30130000',
    'Belo Horizonte', 'MG', 'Minas Gerais', EncodeDate(1990, 3, 15))];
  FControlador.Abrir;
  FRegistro.Clear;
  FVisaoObjeto.Selecionado := 7;
  FConfirmacaoObjeto.Resposta := False;
  FControlador.Excluir;
  Assert.AreEqual(1, FConfirmacaoObjeto.Mensagens.Count);
  Assert.AreEqual('Excluir o cliente 7 - Ana Silva?', FConfirmacaoObjeto.Mensagens[0]);
  Assert.AreEqual('Confirmacao', FRegistro.Text.Trim, 'A confirmação deve vir antes de qualquer transação.');
  Assert.AreEqual(0, FTransacaoObjeto.Iniciadas);
  Assert.AreEqual(0, FRepositorioObjeto.ChamadasExcluir);
  Assert.AreEqual('7', FVisaoObjeto.IdsExibidos);
end;

procedure TTestesControladorPesquisaCliente.ExclusaoConfirmadaExcluiEmTransacaoERecarrega;
begin
  FRepositorioObjeto.Clientes := ClientesDaFixture + [NovoCliente(7, 'Ana Silva', '52998224725',
    '30130000', 'Belo Horizonte', 'MG', 'Minas Gerais', EncodeDate(1990, 3, 15))];
  FControlador.Abrir;
  FControlador.Pesquisar(FiltroNome('silva'));
  Assert.AreEqual('1,7,15', FVisaoObjeto.IdsExibidos);
  FRegistro.Clear;
  FVisaoObjeto.Selecionado := 7;
  FConfirmacaoObjeto.Resposta := True;
  FControlador.Excluir;
  Assert.AreEqual('Confirmacao|Iniciar|Excluir:7|Confirmar|ListarTodos',
    string.Join('|', FRegistro.ToStringArray));
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasExcluir);
  Assert.AreEqual(7, FRepositorioObjeto.UltimoIdExcluido);
  Assert.AreEqual(0, FTransacaoObjeto.Revertidas);
  Assert.AreEqual('1,15', FVisaoObjeto.IdsExibidos,
    'O ID 7 some e os demais aceitos pelo filtro vigente continuam.');
end;

procedure TTestesControladorPesquisaCliente.IdsProtegidosNaoAbremTransacao;
const
  PROTEGIDOS: array[0..4] of Integer = (1, 5, 8, 10, 15);
  LIVRES: array[0..2] of Integer = (2, 9, 16);
var
  LId: Integer;
  LClientes: TClientes;
begin
  LClientes := [];
  for LId in PROTEGIDOS do
    LClientes := LClientes + [NovoCliente(LId, 'Cliente ' + IntToStr(LId), '52998224725',
      '30130000', 'Contagem', 'MG', 'Minas Gerais', EncodeDate(1990, 1, 1))];
  for LId in LIVRES do
    LClientes := LClientes + [NovoCliente(LId, 'Cliente ' + IntToStr(LId), '52998224725',
      '30130000', 'Contagem', 'MG', 'Minas Gerais', EncodeDate(1990, 1, 1))];
  FRepositorioObjeto.Clientes := LClientes;
  FControlador.Abrir;
  FConfirmacaoObjeto.Resposta := False;
  for LId in PROTEGIDOS do
  begin
    FVisaoObjeto.Avisos.Clear;
    FVisaoObjeto.Selecionado := LId;
    FControlador.Excluir;
    Assert.AreEqual(0, FConfirmacaoObjeto.Mensagens.Count, 'ID protegido não pede confirmação: ' + IntToStr(LId));
    Assert.AreEqual(0, FTransacaoObjeto.Iniciadas, 'ID protegido não abre transação: ' + IntToStr(LId));
    Assert.AreEqual(0, FRepositorioObjeto.ChamadasExcluir);
    Assert.AreEqual(1, FVisaoObjeto.Avisos.Count);
    Assert.AreEqual('Cliente protegido não pode ser excluído', FVisaoObjeto.Avisos[0]);
  end;
  for LId in LIVRES do
  begin
    FConfirmacaoObjeto.Mensagens.Clear;
    FVisaoObjeto.Selecionado := LId;
    FControlador.Excluir;
    Assert.AreEqual(1, FConfirmacaoObjeto.Mensagens.Count, 'ID livre segue para a confirmação: ' + IntToStr(LId));
  end;
end;

procedure TTestesControladorPesquisaCliente.FalhaNaExclusaoReverteEMantemRegistro;
begin
  FRepositorioObjeto.Clientes := [NovoCliente(7, 'Ana Silva', '52998224725', '30130000',
    'Belo Horizonte', 'MG', 'Minas Gerais', EncodeDate(1990, 3, 15))];
  FControlador.Abrir;
  FVisaoObjeto.Selecionado := 7;
  FConfirmacaoObjeto.Resposta := True;
  FRepositorioObjeto.FalharExcluir := True;
  FRepositorioObjeto.MensagemFalha := 'lock conflict SYSDBA masterkey';
  FControlador.Excluir;
  Assert.AreEqual(1, FTransacaoObjeto.Revertidas);
  Assert.AreEqual(0, FTransacaoObjeto.Confirmadas);
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível excluir o cliente.', FVisaoObjeto.Erros[0]);
  Assert.AreEqual('7', FVisaoObjeto.IdsExibidos, 'O registro deve continuar na grade.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesControladorPesquisaCliente);

end.

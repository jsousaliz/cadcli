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
    procedure AberturaPesquisaUmaVezPorNomeComLimiteEExibeNaOrdemDevolvida;
    [Test]
    procedure PesquisarRepassaFiltroOrdenacaoELimiteUmaVezPorAcao;
    [Test]
    procedure RepositorioFalsoNaoFiltraNemOrdena;
    [Test]
    procedure RecargaAposSalvarOuExcluirRepeteFiltroEOrdenacaoVigentes;
    [Test]
    procedure FalhaNaPesquisaExibeErroEsvaziaEDesabilitaAcoes;
    [Test]
    procedure SemResultadoExibeMensagemEDesabilitaAcoes;
    [Test]
    procedure AberturaExibeOrdenacaoPadraoPorNomeCrescente;
    [Test]
    procedure OrdenarPorOutraColunaPesquisaEmOrdemCrescente;
    [Test]
    procedure OrdenarPelaColunaVigenteInverteADirecao;
    [Test]
    procedure LimparRestauraOrdenacaoPorNomeCrescente;
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
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  System.TypInfo,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Aplicacao.RepositorioCliente,
  Suporte.CaminhosTeste;

function FiltroPor(ACampo: TCampoPesquisa; const ATexto: string): TFiltroCliente;
begin
  Result := Default(TFiltroCliente);
  Result.Texto := ATexto;
  Result.Campos := [ACampo];
end;

function FiltroNome(const ANome: string): TFiltroCliente;
begin
  Result := FiltroPor(cpNome, ANome);
end;

function Descrever(const AOrdenacao: TOrdenacaoCliente): string;
const
  DIRECOES: array[Boolean] of string = ('crescente', 'decrescente');
begin
  Result := GetEnumName(TypeInfo(TCampoOrdenacao), Ord(AOrdenacao.Campo)) + ' ' +
    DIRECOES[AOrdenacao.Descendente];
end;

function DescreverTodas(const AOrdenacoes: TArray<TOrdenacaoCliente>; AInicio: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := AInicio to High(AOrdenacoes) do
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + Descrever(AOrdenacoes[I]);
  end;
end;

function TresClientes: TClientes;
begin
  Result := [
    NovoCliente(8, 'Oito', '52998224725', '30130000', 'Belo Horizonte', 'MG', 'Minas Gerais',
      EncodeDate(1980, 1, 8)),
    NovoCliente(1, 'Um', '11144477735', '01001000', 'Campinas', 'SP', 'São Paulo',
      EncodeDate(1981, 2, 1)),
    NovoCliente(5, 'Cinco', '11222333000181', '40010000', 'Salvador', 'BA', 'Bahia',
      EncodeDate(1982, 3, 5))];
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
  FVisaoObjeto.Registro := nil;
  FVisao := nil;
  FRepositorio := nil;
  FTransacao := nil;
  FNavegador := nil;
  FConfirmacao := nil;
  FreeAndNil(FRegistro);
end;

procedure TTestesControladorPesquisaCliente.AberturaPesquisaUmaVezPorNomeComLimiteEExibeNaOrdemDevolvida;
var
  LEsperados: TClientes;
  I: Integer;
begin
  LEsperados := TresClientes;
  FRepositorioObjeto.Clientes := LEsperados;
  FControlador.Abrir;
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasPesquisar, 'A abertura deve pesquisar uma única vez.');
  Assert.AreEqual('', FRepositorioObjeto.Filtros[0].Texto);
  Assert.IsTrue(FRepositorioObjeto.Filtros[0].Campos = [], 'A abertura não marca campos.');
  Assert.AreEqual('', FRepositorioObjeto.Filtros[0].DataNascimento);
  Assert.AreEqual('coNome crescente', Descrever(FRepositorioObjeto.Ordenacoes[0]));
  Assert.AreEqual(50, FRepositorioObjeto.Limites[0]);
  Assert.AreEqual(3, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual('8,1,5', FVisaoObjeto.IdsExibidos, 'A visão recebe a ordem devolvida.');
  for I := 0 to 2 do
  begin
    Assert.AreEqual(LEsperados[I].Nome, FVisaoObjeto.Exibidos[I].Nome);
    Assert.AreEqual(LEsperados[I].Cidade, FVisaoObjeto.Exibidos[I].Cidade);
  end;
  Assert.IsFalse(FVisaoObjeto.Carregando, 'O carregamento deve terminar desligado.');
end;

procedure TTestesControladorPesquisaCliente.PesquisarRepassaFiltroOrdenacaoELimiteUmaVezPorAcao;
var
  LFiltro: TFiltroCliente;
  LSequencia: string;
  LLinha: string;
begin
  FRepositorioObjeto.Clientes := TresClientes;
  FControlador.Abrir;
  LFiltro := Default(TFiltroCliente);
  LFiltro.Texto := 'silva';
  LFiltro.Campos := [cpNome, cpCidade];
  LFiltro.DataNascimento := '15/03/1990';
  FRegistro.Clear;
  FVisaoObjeto.Registro := FRegistro;

  FControlador.Pesquisar(LFiltro);
  Assert.AreEqual(2, FRepositorioObjeto.ChamadasPesquisar, 'Pesquisar gera exatamente 1 chamada nova.');
  Assert.AreEqual('silva', FRepositorioObjeto.UltimoFiltro.Texto);
  Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [cpNome, cpCidade]);
  Assert.AreEqual('15/03/1990', FRepositorioObjeto.UltimoFiltro.DataNascimento);
  Assert.AreEqual('coNome crescente', Descrever(FRepositorioObjeto.UltimaOrdenacao));
  Assert.AreEqual(50, FRepositorioObjeto.Limites[High(FRepositorioObjeto.Limites)]);

  FControlador.Pesquisar(LFiltro);
  FControlador.Pesquisar(LFiltro);
  Assert.AreEqual(4, FRepositorioObjeto.ChamadasPesquisar, '3 pesquisas geram exatamente 3 chamadas.');

  LSequencia := '';
  for LLinha in FRegistro do
    if StartsText('Carregamento:', LLinha) or (LLinha = 'Pesquisar') then
    begin
      if LSequencia <> '' then
        LSequencia := LSequencia + '|';
      LSequencia := LSequencia + LLinha;
    end;
  Assert.AreEqual(
    'Carregamento:True|Pesquisar|Carregamento:False|' +
    'Carregamento:True|Pesquisar|Carregamento:False|' +
    'Carregamento:True|Pesquisar|Carregamento:False', LSequencia,
    'Cada pesquisa sinaliza o carregamento antes e depois da chamada ao repositório.');
end;

procedure TTestesControladorPesquisaCliente.RepositorioFalsoNaoFiltraNemOrdena;
var
  LRegra: string;
  LArquivo: string;
begin
  FRepositorioObjeto.Clientes := TresClientes;
  Assert.AreEqual(3, Integer(Length((FRepositorioObjeto as IRepositorioCliente).Pesquisar(
    FiltroNome('zzz'), Default(TOrdenacaoCliente), 50))), 'O repositório falso não filtra.');
  FControlador.Pesquisar(FiltroNome('zzz'));
  Assert.AreEqual('8,1,5', FVisaoObjeto.IdsExibidos, 'O repositório falso não filtra nem reordena.');

  LRegra := '.Aten' + 'de(';
  for LArquivo in TDirectory.GetFiles(TPath.Combine(RaizRepositorio, 'tests'), '*.pas',
    TSearchOption.soAllDirectories) do
    Assert.IsFalse(ContainsText(TFile.ReadAllText(LArquivo), LRegra),
      'Nenhuma unit de teste pode chamar regra de filtro em memória: ' + LArquivo);
end;

procedure TTestesControladorPesquisaCliente.RecargaAposSalvarOuExcluirRepeteFiltroEOrdenacaoVigentes;

  procedure AssegurarChamadaVigente(AChamadas: Integer; const AAcao: string);
  begin
    Assert.AreEqual(AChamadas, FRepositorioObjeto.ChamadasPesquisar, AAcao);
    Assert.AreEqual('silva', FRepositorioObjeto.UltimoFiltro.Texto, AAcao);
    Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [cpNome], AAcao);
    Assert.AreEqual('coCidade crescente', Descrever(FRepositorioObjeto.UltimaOrdenacao), AAcao);
    Assert.AreEqual(50, FRepositorioObjeto.Limites[High(FRepositorioObjeto.Limites)], AAcao);
  end;

var
  LChamadas: Integer;
begin
  FRepositorioObjeto.Clientes := TresClientes + [NovoCliente(7, 'Ana Silva', '52998224725',
    '30130000', 'Belo Horizonte', 'MG', 'Minas Gerais', EncodeDate(1990, 3, 15))];
  FControlador.Abrir;
  FControlador.Pesquisar(FiltroNome('silva'));
  FControlador.Ordenar(coCidade);
  LChamadas := FRepositorioObjeto.ChamadasPesquisar;
  AssegurarChamadaVigente(LChamadas, 'Estado vigente antes das recargas.');

  FNavegadorObjeto.Salvar := False;
  FControlador.Novo;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasInclusao, 'Novo abre a inclusão uma vez.');
  Assert.AreEqual(LChamadas, FRepositorioObjeto.ChamadasPesquisar, 'Novo não salvo não pesquisa.');

  FVisaoObjeto.Selecionado := 7;
  FControlador.Editar;
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasEdicao, 'Editar abre a edição uma vez.');
  Assert.AreEqual(1, FNavegadorObjeto.ChamadasInclusao, 'Editar não abre a inclusão.');
  Assert.AreEqual(7, FNavegadorObjeto.UltimoIdEdicao);
  Assert.AreEqual(LChamadas, FRepositorioObjeto.ChamadasPesquisar, 'Edição não salva não pesquisa.');

  FNavegadorObjeto.Salvar := True;
  FControlador.Novo;
  Assert.AreEqual(2, FNavegadorObjeto.ChamadasInclusao);
  Inc(LChamadas);
  AssegurarChamadaVigente(LChamadas, 'Novo salvo repete a pesquisa vigente.');

  FControlador.Editar;
  Assert.AreEqual(2, FNavegadorObjeto.ChamadasEdicao);
  Assert.AreEqual(7, FNavegadorObjeto.UltimoIdEdicao);
  Inc(LChamadas);
  AssegurarChamadaVigente(LChamadas, 'Edição salva repete a pesquisa vigente.');

  FConfirmacaoObjeto.Resposta := True;
  FControlador.Excluir;
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasExcluir);
  Assert.AreEqual(7, FRepositorioObjeto.UltimoIdExcluido);
  Inc(LChamadas);
  AssegurarChamadaVigente(LChamadas, 'Exclusão confirmada repete a pesquisa vigente.');
end;

procedure TTestesControladorPesquisaCliente.FalhaNaPesquisaExibeErroEsvaziaEDesabilitaAcoes;
begin
  FRepositorioObjeto.FalharPesquisarAPartirDe := 1;
  FRepositorioObjeto.MensagemFalha := 'SYSDBA masterkey localhost:3050';
  FControlador.Abrir;
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count, 'O erro deve ser exibido exatamente uma vez.');
  Assert.AreEqual('Não foi possível carregar os clientes.', FVisaoObjeto.Erros[0]);
  Assert.IsFalse(FVisaoObjeto.Erros[0].Contains('masterkey'), 'O texto da exceção não aparece.');
  Assert.AreEqual(1, FVisaoObjeto.Exibicoes, 'A visão recebe a lista vazia.');
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.IsFalse(FVisaoObjeto.AcoesHabilitadas, 'Editar e Excluir ficam desabilitadas.');
  Assert.IsFalse(FVisaoObjeto.Carregando, 'O carregamento deve ser desligado.');
  FreeAndNil(FControlador);

  FVisaoObjeto.Erros.Clear;
  FRepositorioObjeto.ChamadasPesquisar := 0;
  FRepositorioObjeto.FalharPesquisarAPartirDe := 2;
  FRepositorioObjeto.Clientes := TresClientes;
  FControlador := TControladorPesquisaCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FTransacaoObjeto, FNavegadorObjeto, FConfirmacaoObjeto);
  FControlador.Abrir;
  Assert.AreEqual(3, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.IsTrue(FVisaoObjeto.AcoesHabilitadas);
  FControlador.Pesquisar(FiltroNome('um'));
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count);
  Assert.AreEqual('Não foi possível carregar os clientes.', FVisaoObjeto.Erros[0]);
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.IsFalse(FVisaoObjeto.AcoesHabilitadas);
  Assert.IsFalse(FVisaoObjeto.Carregando);

  FVisaoObjeto.Selecionado := 8;
  FConfirmacaoObjeto.Resposta := True;
  FControlador.Excluir;
  Assert.AreEqual(0, FConfirmacaoObjeto.Mensagens.Count,
    'Depois da falha, Excluir não abre confirmação.');
  Assert.AreEqual(0, FRepositorioObjeto.ChamadasExcluir);
end;

procedure TTestesControladorPesquisaCliente.SemResultadoExibeMensagemEDesabilitaAcoes;
begin
  FRepositorioObjeto.Clientes := [];
  FControlador.Abrir;
  Assert.AreEqual(1, FVisaoObjeto.Exibicoes);
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual('Nenhum cliente encontrado', FVisaoObjeto.SemResultado.Text.Trim);
  Assert.IsFalse(FVisaoObjeto.AcoesHabilitadas, 'Editar e Excluir devem ficar desabilitadas.');

  FRepositorioObjeto.Clientes := [TresClientes[1]];
  FControlador.Pesquisar(FiltroNome('um'));
  Assert.AreEqual(1, Integer(Length(FVisaoObjeto.Exibidos)));
  Assert.AreEqual(0, FVisaoObjeto.SemResultado.Count, 'Com resultado não há aviso de vazio.');
  Assert.IsTrue(FVisaoObjeto.AcoesHabilitadas, 'Com 1 cliente as ações ficam habilitadas.');
end;

procedure TTestesControladorPesquisaCliente.AberturaExibeOrdenacaoPadraoPorNomeCrescente;
begin
  FRepositorioObjeto.Clientes := TresClientes;
  FVisaoObjeto.Registro := FRegistro;
  FControlador.Abrir;
  Assert.AreEqual(1, Integer(Length(FVisaoObjeto.Ordenacoes)), 'A abertura exibe a ordenação uma vez.');
  Assert.AreEqual('coNome crescente', Descrever(FVisaoObjeto.Ordenacoes[0]));
  Assert.IsTrue(FRegistro.IndexOf('ExibirOrdenacao') >= 0);
  Assert.IsTrue(FRegistro.IndexOf('ExibirOrdenacao') < FRegistro.IndexOf('ExibirClientes'),
    'A ordenação é exibida antes dos clientes.');
  Assert.AreEqual('coNome crescente', Descrever(FRepositorioObjeto.Ordenacoes[0]));
end;

procedure TTestesControladorPesquisaCliente.OrdenarPorOutraColunaPesquisaEmOrdemCrescente;
begin
  FRepositorioObjeto.Clientes := TresClientes;
  FControlador.Abrir;
  FControlador.Pesquisar(FiltroNome('silva'));
  Assert.AreEqual(2, FRepositorioObjeto.ChamadasPesquisar);

  FControlador.Ordenar(coCidade);
  Assert.AreEqual(3, FRepositorioObjeto.ChamadasPesquisar, 'Ordenar gera exatamente 1 chamada.');
  Assert.AreEqual('silva', FRepositorioObjeto.UltimoFiltro.Texto, 'O filtro vigente é mantido.');
  Assert.IsTrue(FRepositorioObjeto.UltimoFiltro.Campos = [cpNome]);
  Assert.AreEqual('coCidade crescente', Descrever(FRepositorioObjeto.UltimaOrdenacao));
  Assert.AreEqual(50, FRepositorioObjeto.Limites[High(FRepositorioObjeto.Limites)]);
  Assert.AreEqual('coCidade crescente',
    Descrever(FVisaoObjeto.Ordenacoes[High(FVisaoObjeto.Ordenacoes)]));
end;

procedure TTestesControladorPesquisaCliente.OrdenarPelaColunaVigenteInverteADirecao;
const
  ESPERADO = 'coNome decrescente|coNome crescente|coNome decrescente|coCidade crescente';
begin
  FRepositorioObjeto.Clientes := TresClientes;
  FControlador.Abrir;
  FControlador.Ordenar(coNome);
  FControlador.Ordenar(coNome);
  FControlador.Ordenar(coNome);
  FControlador.Ordenar(coCidade);
  Assert.AreEqual(5, FRepositorioObjeto.ChamadasPesquisar);
  Assert.AreEqual(ESPERADO, DescreverTodas(FRepositorioObjeto.Ordenacoes, 1),
    'Ordenações passadas ao repositório.');
  Assert.AreEqual(ESPERADO, DescreverTodas(FVisaoObjeto.Ordenacoes, 1),
    'Ordenações exibidas pela visão.');
end;

procedure TTestesControladorPesquisaCliente.LimparRestauraOrdenacaoPorNomeCrescente;
begin
  FRepositorioObjeto.Clientes := TresClientes;
  FControlador.Abrir;
  FControlador.Ordenar(coCidade);
  FControlador.Ordenar(coCidade);
  Assert.AreEqual('coCidade decrescente', Descrever(FRepositorioObjeto.UltimaOrdenacao));
  Assert.AreEqual(3, FRepositorioObjeto.ChamadasPesquisar);

  FControlador.Limpar(Default(TFiltroCliente));
  Assert.AreEqual(4, FRepositorioObjeto.ChamadasPesquisar, 'Limpar gera exatamente 1 chamada.');
  Assert.AreEqual('coNome crescente', Descrever(FRepositorioObjeto.UltimaOrdenacao));
  Assert.AreEqual('coNome crescente',
    Descrever(FVisaoObjeto.Ordenacoes[High(FVisaoObjeto.Ordenacoes)]));
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
  FRepositorioObjeto.Clientes := [
    NovoCliente(1, 'Ana Souza Silva', '52998224725', '30130000', 'Belo Horizonte', 'MG',
      'Minas Gerais', EncodeDate(1990, 3, 15)),
    NovoCliente(7, 'Ana Silva', '52998224725', '30130000', 'Belo Horizonte', 'MG', 'Minas Gerais',
      EncodeDate(1990, 3, 15)),
    NovoCliente(15, 'Carlos Silva', '11222333000181', '13010000', 'Campinas', 'SP', 'São Paulo',
      EncodeDate(1978, 1, 2))];
  FControlador.Abrir;
  FControlador.Pesquisar(FiltroNome('silva'));
  Assert.AreEqual('1,7,15', FVisaoObjeto.IdsExibidos);
  FRegistro.Clear;
  FVisaoObjeto.Selecionado := 7;
  FConfirmacaoObjeto.Resposta := True;
  FControlador.Excluir;
  Assert.AreEqual('Confirmacao|Iniciar|Excluir:7|Confirmar|Pesquisar',
    string.Join('|', FRegistro.ToStringArray));
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasExcluir);
  Assert.AreEqual(7, FRepositorioObjeto.UltimoIdExcluido);
  Assert.AreEqual(0, FTransacaoObjeto.Revertidas);
  Assert.AreEqual('silva', FRepositorioObjeto.UltimoFiltro.Texto, 'A recarga usa o filtro vigente.');
  Assert.AreEqual('1,15', FVisaoObjeto.IdsExibidos,
    'O ID 7 some e os demais devolvidos pela recarga continuam.');
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

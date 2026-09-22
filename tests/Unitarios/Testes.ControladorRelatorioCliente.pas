unit Testes.ControladorRelatorioCliente;

interface

uses
  DUnitX.TestFramework,
  Aplicacao.ControladorRelatorioCliente,
  Suporte.FakesClientes,
  Suporte.FakesRelatorioCliente;

type
  [TestFixture]
  TTestesControladorRelatorioCliente = class
  private
    FVisaoObjeto: TVisaoRelatorioClienteFake;
    FVisao: IInterface;
    FRepositorioObjeto: TRepositorioClienteFake;
    FRepositorio: IInterface;
    FGeradorObjeto: TGeradorRelatorioClienteFake;
    FGerador: IInterface;
    FRelogio: IInterface;
    FControlador: TControladorRelatorioCliente;
    function IdDeSaoPaulo: Integer;
    function IdDeMinasGerais: Integer;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpar;
    [Test]
    procedure IniciarSelecionaTodosDesabilitaCamposECarregaEstados;
    [Test]
    procedure CadaModoHabilitaSomenteSeusCampos;
    [Test]
    procedure EstadoSelecionadoLimitaCidadesAsDesseEstado;
    [Test]
    procedure FiltroInvalidoFocaPrimeiroCampoSemConsultar;
    [Test]
    procedure FalhaAoCarregarEstadosMantemModoTodosUtilizavel;
    [Test]
    procedure VisualizarConsultaUmaVezEEntregaDadosAoGerador;
    [Test]
    procedure SemResultadoAvisaSemAbrirPreVisualizacao;
    [Test]
    procedure FalhaNaConsultaOuNoGeradorExibeErroEPreservaFiltro;
  end;

implementation

uses
  System.DateUtils,
  System.StrUtils,
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroRelatorioCliente,
  Aplicacao.ExecutorMigracoes,
  Aplicacao.GeradorRelatorioCliente,
  Aplicacao.RepositorioCliente;

function InstanteFixo: TDateTime;
begin
  Result := EncodeDate(2026, 9, 22) + EncodeTime(14, 30, 0, 0);
end;

procedure TTestesControladorRelatorioCliente.Preparar;
begin
  FVisaoObjeto := TVisaoRelatorioClienteFake.Create;
  FVisao := FVisaoObjeto as IVisaoRelatorioCliente;
  FRepositorioObjeto := TRepositorioClienteFake.Create(FVisaoObjeto.Registro);
  FRepositorio := FRepositorioObjeto as IRepositorioCliente;
  FRepositorioObjeto.Estados := EstadosDaFixture;
  FRepositorioObjeto.Cidades := CidadesDeSaoPaulo;
  FGeradorObjeto := TGeradorRelatorioClienteFake.Create(FVisaoObjeto.Registro);
  FGerador := FGeradorObjeto as IGeradorRelatorioCliente;
  FRelogio := TRelogioFake.Create(InstanteFixo) as IRelogio;
  FControlador := TControladorRelatorioCliente.Create(FVisaoObjeto, FRepositorioObjeto,
    FGeradorObjeto, FRelogio as IRelogio);
end;

procedure TTestesControladorRelatorioCliente.Limpar;
begin
  FreeAndNil(FControlador);
  FRelogio := nil;
  FGerador := nil;
  FRepositorio := nil;
  FVisao := nil;
end;

function TTestesControladorRelatorioCliente.IdDeSaoPaulo: Integer;
begin
  Result := IdDoEstado(EstadosDaFixture, 'SP');
end;

function TTestesControladorRelatorioCliente.IdDeMinasGerais: Integer;
begin
  Result := IdDoEstado(EstadosDaFixture, 'MG');
end;

procedure TTestesControladorRelatorioCliente.IniciarSelecionaTodosDesabilitaCamposECarregaEstados;
begin
  FControlador.Iniciar;

  Assert.AreEqual(1, Integer(Length(FVisaoObjeto.ModosExibidos)), 'Um único modo exibido.');
  Assert.AreEqual(Ord(mrTodos), Ord(FVisaoObjeto.ModosExibidos[0]), 'O modo inicial é Todos.');
  Assert.IsFalse(FVisaoObjeto.IntervaloHabilitado, 'O intervalo abre desabilitado.');
  Assert.IsFalse(FVisaoObjeto.CidadeEstadoHabilitado, 'Cidade/Estado abre desabilitado.');
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasEstados, 'ListarEstados é chamado 1 vez.');
  Assert.AreEqual(1, FVisaoObjeto.ExibicoesDeEstados, 'Os estados são entregues 1 vez.');
  Assert.AreEqual('Bahia,Minas Gerais,Rio de Janeiro,São Paulo', FVisaoObjeto.NomesDosEstados);
  Assert.AreEqual(0, FRepositorioObjeto.ChamadasRelatorio, 'Abrir não consulta o relatório.');
  Assert.AreEqual(0, FGeradorObjeto.Chamadas, 'Abrir não aciona o gerador.');
end;

procedure TTestesControladorRelatorioCliente.CadaModoHabilitaSomenteSeusCampos;
begin
  FControlador.SelecionarModo(mrIntervalo);
  Assert.IsTrue(FVisaoObjeto.IntervaloHabilitado, 'Intervalo habilita os IDs.');
  Assert.IsFalse(FVisaoObjeto.CidadeEstadoHabilitado, 'Intervalo desabilita cidade/estado.');

  FControlador.SelecionarModo(mrCidadeEstado);
  Assert.IsFalse(FVisaoObjeto.IntervaloHabilitado, 'Cidade/Estado desabilita os IDs.');
  Assert.IsTrue(FVisaoObjeto.CidadeEstadoHabilitado, 'Cidade/Estado habilita seus campos.');

  FControlador.SelecionarModo(mrTodos);
  Assert.IsFalse(FVisaoObjeto.IntervaloHabilitado, 'Todos desabilita os IDs.');
  Assert.IsFalse(FVisaoObjeto.CidadeEstadoHabilitado, 'Todos desabilita cidade/estado.');
  Assert.AreEqual(3, FVisaoObjeto.HabilitacoesIntervalo, 'Cada modo decide o intervalo.');
  Assert.AreEqual(3, FVisaoObjeto.HabilitacoesCidadeEstado, 'Cada modo decide cidade/estado.');
end;

procedure TTestesControladorRelatorioCliente.EstadoSelecionadoLimitaCidadesAsDesseEstado;
begin
  FControlador.SelecionarEstado(IdDeSaoPaulo);
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasCidades, 'ListarCidades é chamado 1 vez.');
  Assert.AreEqual(IdDeSaoPaulo, FRepositorioObjeto.EstadosConsultados[0],
    'ListarCidades recebe o estado escolhido.');
  Assert.AreEqual('Todas as cidades,Campinas,Santos,São Paulo', FVisaoObjeto.NomesDasCidades);
  Assert.AreEqual(0, FVisaoObjeto.CidadeSelecionada, 'Todas as cidades fica selecionada.');

  FControlador.SelecionarEstado(0);
  Assert.AreEqual(1, FRepositorioObjeto.ChamadasCidades, 'Sem estado não consulta cidades.');
  Assert.AreEqual('Todas as cidades', FVisaoObjeto.NomesDasCidades,
    'Sem estado resta somente a opção de todas.');
  Assert.AreEqual(0, FVisaoObjeto.CidadeSelecionada);
end;

procedure TTestesControladorRelatorioCliente.FiltroInvalidoFocaPrimeiroCampoSemConsultar;
type
  TCasoInvalido = record
    Entrada: TEntradaFiltroRelatorio;
    Campo: TCampoFiltroRelatorio;
    Mensagem: string;
  end;
var
  LCasos: TArray<TCasoInvalido>;
  LCaso: TCasoInvalido;
  LVerificados: Integer;
begin
  LCasos := [];
  LCasos := LCasos + [Default(TCasoInvalido)];
  LCasos[0].Entrada := EntradaDoFiltro(mrIntervalo, '', '4');
  LCasos[0].Campo := cfIdInicial;
  LCasos[0].Mensagem := MENSAGEM_ID_INICIAL;
  LCasos := LCasos + [Default(TCasoInvalido)];
  LCasos[1].Entrada := EntradaDoFiltro(mrIntervalo, '2', '');
  LCasos[1].Campo := cfIdFinal;
  LCasos[1].Mensagem := MENSAGEM_ID_FINAL;
  LCasos := LCasos + [Default(TCasoInvalido)];
  LCasos[2].Entrada := EntradaDoFiltro(mrIntervalo, '5', '4');
  LCasos[2].Campo := cfIdFinal;
  LCasos[2].Mensagem := MENSAGEM_INTERVALO_INVERTIDO;
  LCasos := LCasos + [Default(TCasoInvalido)];
  LCasos[3].Entrada := EntradaDoFiltro(mrCidadeEstado);
  LCasos[3].Campo := cfEstado;
  LCasos[3].Mensagem := MENSAGEM_ESTADO_OBRIGATORIO;

  LVerificados := 0;
  for LCaso in LCasos do
  begin
    FVisaoObjeto.CamposFocados := [];
    FVisaoObjeto.Avisos.Clear;
    FVisaoObjeto.Registro.Clear;
    FVisaoObjeto.Entrada := LCaso.Entrada;

    FControlador.Visualizar;

    Assert.AreEqual(1, Integer(Length(FVisaoObjeto.CamposFocados)),
      LCaso.Mensagem + ' - um único campo focado');
    Assert.AreEqual(Ord(LCaso.Campo), Ord(FVisaoObjeto.UltimoCampoFocado),
      LCaso.Mensagem + ' - campo focado');
    Assert.AreEqual(1, FVisaoObjeto.Avisos.Count, LCaso.Mensagem + ' - um único aviso');
    Assert.AreEqual(LCaso.Mensagem, FVisaoObjeto.Avisos[0]);
    Assert.AreEqual(-1, FVisaoObjeto.Registro.IndexOf('Carregamento:True'),
      LCaso.Mensagem + ' - sem estado de carregamento');
    Inc(LVerificados);
  end;
  Assert.AreEqual(4, LVerificados, 'As quatro entradas inválidas devem ser asseridas.');
  Assert.AreEqual(0, FRepositorioObjeto.ChamadasRelatorio, 'Filtro inválido não consulta.');
  Assert.AreEqual(0, FGeradorObjeto.Chamadas, 'Filtro inválido não gera.');
end;

procedure TTestesControladorRelatorioCliente.FalhaAoCarregarEstadosMantemModoTodosUtilizavel;
begin
  FRepositorioObjeto.FalharEstados := True;
  FRepositorioObjeto.MensagemFalha := 'SELECT ID, NOME, UF FROM ESTADO falhou';

  FControlador.Iniciar;

  Assert.AreEqual(1, FVisaoObjeto.Erros.Count, 'Um único erro é exibido.');
  Assert.AreEqual(MENSAGEM_FALHA_LOCALIDADES, FVisaoObjeto.Erros[0]);
  Assert.IsFalse(ContainsText(FVisaoObjeto.Erros[0], 'SELECT'),
    'A mensagem não pode conter o texto da exceção.');

  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FVisaoObjeto.Entrada := EntradaDoFiltro(mrTodos);
  FControlador.Visualizar;

  Assert.AreEqual(1, FRepositorioObjeto.ChamadasRelatorio,
    'O modo Todos continua utilizável depois da falha.');
end;

procedure TTestesControladorRelatorioCliente.VisualizarConsultaUmaVezEEntregaDadosAoGerador;
type
  TCasoDescricao = record
    Entrada: TEntradaFiltroRelatorio;
    Descricao: string;
    De: Integer;
    Ate: Integer;
    Estado: Integer;
    Cidade: Integer;
  end;
var
  LCasos: TArray<TCasoDescricao>;
  I: Integer;
  LVerificados: Integer;
begin
  FRepositorioObjeto.Clientes := [
    NovoCliente(8, 'Oitavo', '52998224725', '30130010', 'Belo Horizonte', 'MG', 'Minas Gerais', 0),
    NovoCliente(1, 'Primeiro', '11144477735', '35420000', 'Mariana', 'MG', 'Minas Gerais', 0),
    NovoCliente(5, 'Quinto', '11222333000181', '13010000', 'Campinas', 'SP', 'São Paulo', 0)];
  FControlador.Iniciar;
  FControlador.SelecionarEstado(IdDeSaoPaulo);

  LCasos := [];
  LCasos := LCasos + [Default(TCasoDescricao)];
  LCasos[0].Entrada := EntradaDoFiltro(mrTodos);
  LCasos[0].Descricao := 'Filtro: Todos';
  LCasos := LCasos + [Default(TCasoDescricao)];
  LCasos[1].Entrada := EntradaDoFiltro(mrIntervalo, '2', '4');
  LCasos[1].Descricao := 'Filtro: ID Inicial 2 e ID Final 4';
  LCasos[1].De := 2;
  LCasos[1].Ate := 4;
  LCasos := LCasos + [Default(TCasoDescricao)];
  LCasos[2].Entrada := EntradaDoFiltro(mrCidadeEstado, '', '', IdDeMinasGerais, 0);
  LCasos[2].Descricao := 'Filtro: Estado MG';
  LCasos[2].Estado := IdDeMinasGerais;
  LCasos := LCasos + [Default(TCasoDescricao)];
  LCasos[3].Entrada := EntradaDoFiltro(mrCidadeEstado, '', '', IdDeSaoPaulo,
    CidadesDeSaoPaulo[0].Id);
  LCasos[3].Descricao := 'Filtro: Cidade Campinas/SP';
  LCasos[3].Estado := IdDeSaoPaulo;
  LCasos[3].Cidade := CidadesDeSaoPaulo[0].Id;

  LVerificados := 0;
  for I := 0 to High(LCasos) do
  begin
    FRepositorioObjeto.ChamadasRelatorio := 0;
    FRepositorioObjeto.FiltrosRelatorio := [];
    FGeradorObjeto.Chamadas := 0;
    FVisaoObjeto.Registro.Clear;
    FVisaoObjeto.Entrada := LCasos[I].Entrada;

    FControlador.Visualizar;

    Assert.AreEqual(1, FRepositorioObjeto.ChamadasRelatorio,
      LCasos[I].Descricao + ' - consulta 1 vez');
    Assert.AreEqual(Ord(LCasos[I].Entrada.Modo),
      Ord(FRepositorioObjeto.UltimoFiltroRelatorio.Modo), LCasos[I].Descricao + ' - modo');
    Assert.AreEqual(LCasos[I].De, FRepositorioObjeto.UltimoFiltroRelatorio.IdInicial,
      LCasos[I].Descricao + ' - ID inicial normalizado');
    Assert.AreEqual(LCasos[I].Ate, FRepositorioObjeto.UltimoFiltroRelatorio.IdFinal,
      LCasos[I].Descricao + ' - ID final normalizado');
    Assert.AreEqual(LCasos[I].Estado, FRepositorioObjeto.UltimoFiltroRelatorio.EstadoId,
      LCasos[I].Descricao + ' - estado normalizado');
    Assert.AreEqual(LCasos[I].Cidade, FRepositorioObjeto.UltimoFiltroRelatorio.CidadeId,
      LCasos[I].Descricao + ' - cidade normalizada');
    Assert.AreEqual(1, FGeradorObjeto.Chamadas, LCasos[I].Descricao + ' - gera 1 vez');
    Assert.AreEqual('8,1,5', FGeradorObjeto.IdsRecebidos,
      LCasos[I].Descricao + ' - ordem devolvida pelo repositório');
    Assert.AreEqual(LCasos[I].Descricao, FGeradorObjeto.Dados.DescricaoFiltro);
    Assert.AreEqual('22/09/2026 14:30',
      FormatDateTime('dd/mm/yyyy hh:nn', FGeradorObjeto.Dados.Emissao),
      LCasos[I].Descricao + ' - emissão vem do relógio');
    Assert.IsTrue(FVisaoObjeto.Registro.IndexOf('Carregamento:True') <
      FVisaoObjeto.Registro.IndexOf('ListarParaRelatorio'),
      LCasos[I].Descricao + ' - carregamento antes da consulta');
    Assert.IsTrue(FVisaoObjeto.Registro.IndexOf('Gerar') <
      FVisaoObjeto.Registro.IndexOf('Carregamento:False'),
      LCasos[I].Descricao + ' - carregamento encerra depois do gerador');
    Inc(LVerificados);
  end;
  Assert.AreEqual(4, LVerificados, 'As quatro descrições de filtro devem ser asseridas.');
end;

procedure TTestesControladorRelatorioCliente.SemResultadoAvisaSemAbrirPreVisualizacao;
begin
  FControlador.Iniciar;
  FVisaoObjeto.Registro.Clear;
  FVisaoObjeto.ModosExibidos := [];
  FRepositorioObjeto.Clientes := [];
  FVisaoObjeto.Entrada := EntradaDoFiltro(mrTodos);

  FControlador.Visualizar;

  Assert.AreEqual(0, FGeradorObjeto.Chamadas, 'Sem resultado não abre pré-visualização.');
  Assert.AreEqual(1, FVisaoObjeto.Avisos.Count, 'Um único aviso é exibido.');
  Assert.AreEqual(MENSAGEM_SEM_RESULTADO, FVisaoObjeto.Avisos[0]);
  Assert.IsFalse(FVisaoObjeto.Carregando, 'O carregamento é encerrado.');
  Assert.AreEqual(0, FVisaoObjeto.Fechamentos, 'A tela de filtros continua aberta.');
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.ModosExibidos)),
    'O modo escolhido não é redefinido.');
end;

procedure TTestesControladorRelatorioCliente.FalhaNaConsultaOuNoGeradorExibeErroEPreservaFiltro;
var
  LHabilitacoes: Integer;
begin
  FControlador.Iniciar;
  FRepositorioObjeto.Clientes := ClientesDaFixture;
  FRepositorioObjeto.MensagemFalha := 'Firebird indisponível em localhost:3050';
  FVisaoObjeto.Entrada := EntradaDoFiltro(mrIntervalo, '2', '4');
  FVisaoObjeto.ModosExibidos := [];
  LHabilitacoes := FVisaoObjeto.HabilitacoesIntervalo;
  FVisaoObjeto.Erros.Clear;
  FVisaoObjeto.Registro.Clear;
  FRepositorioObjeto.FalharRelatorio := True;

  FControlador.Visualizar;

  Assert.AreEqual(0, FGeradorObjeto.Chamadas, 'Falha na consulta não chega ao gerador.');
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count, 'Um único erro de consulta.');
  Assert.AreEqual(MENSAGEM_FALHA_CONSULTA, FVisaoObjeto.Erros[0]);
  Assert.IsFalse(ContainsText(FVisaoObjeto.Erros[0], 'Firebird'),
    'A mensagem não pode conter o texto da exceção.');
  Assert.AreEqual(FVisaoObjeto.Registro.Count - 1,
    FVisaoObjeto.Registro.IndexOf('Carregamento:False'),
    'O carregamento encerra por último.');

  FRepositorioObjeto.FalharRelatorio := False;
  FGeradorObjeto.Falhar := True;
  FGeradorObjeto.MensagemFalha := 'TppReport.Print falhou';
  FVisaoObjeto.Erros.Clear;
  FVisaoObjeto.Registro.Clear;

  FControlador.Visualizar;

  Assert.AreEqual(1, FGeradorObjeto.Chamadas, 'O gerador é acionado uma vez.');
  Assert.AreEqual(1, FVisaoObjeto.Erros.Count, 'Um único erro de geração.');
  Assert.AreEqual(MENSAGEM_FALHA_GERACAO, FVisaoObjeto.Erros[0]);
  Assert.IsFalse(ContainsText(FVisaoObjeto.Erros[0], 'TppReport'),
    'A mensagem não pode conter o texto da exceção.');
  Assert.AreEqual(FVisaoObjeto.Registro.Count - 1,
    FVisaoObjeto.Registro.IndexOf('Carregamento:False'),
    'O carregamento encerra por último.');
  Assert.AreEqual(0, Integer(Length(FVisaoObjeto.ModosExibidos)),
    'A falha não redefine o modo escolhido.');
  Assert.AreEqual(LHabilitacoes, FVisaoObjeto.HabilitacoesIntervalo,
    'A falha não reconfigura os campos.');

  FGeradorObjeto.Falhar := False;
  FGeradorObjeto.Chamadas := 0;
  FVisaoObjeto.Erros.Clear;

  FControlador.Visualizar;

  Assert.AreEqual(1, FGeradorObjeto.Chamadas, 'A segunda tentativa gera o relatório.');
  Assert.AreEqual(0, FVisaoObjeto.Erros.Count, 'A segunda tentativa não exibe erro.');
  Assert.AreEqual(2, FRepositorioObjeto.UltimoFiltroRelatorio.IdInicial,
    'O filtro preservado continua valendo.');
  Assert.AreEqual(4, FRepositorioObjeto.UltimoFiltroRelatorio.IdFinal,
    'O filtro preservado continua valendo.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesControladorRelatorioCliente);

end.

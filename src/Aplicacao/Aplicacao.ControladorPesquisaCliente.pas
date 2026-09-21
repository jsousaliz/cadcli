unit Aplicacao.ControladorPesquisaCliente;

interface

uses
  System.SysUtils,
  Dominio.Cliente,
  Dominio.FiltroCliente,
  Aplicacao.Confirmacao,
  Aplicacao.NavegadorClientes,
  Aplicacao.RepositorioCliente,
  Aplicacao.Transacao;

type
  IVisaoPesquisaCliente = interface
    ['{CBE0C1BD-FF58-47EB-BF62-172A2FCEB54D}']
    procedure SinalizarCarregamento(AAtivo: Boolean);
    procedure ExibirClientes(const AClientes: TClientes);
    procedure ExibirSemResultado(const AMensagem: string);
    procedure HabilitarEdicaoEExclusao(AHabilitar: Boolean);
    function IdSelecionado: Integer;
    procedure ExibirErro(const AMensagem: string);
    procedure ExibirAviso(const AMensagem: string);
  end;

  TControladorPesquisaCliente = class
  private
    FVisao: IVisaoPesquisaCliente;
    FRepositorio: IRepositorioCliente;
    FTransacao: ITransacao;
    FNavegador: INavegadorClientes;
    FConfirmacao: IConfirmacao;
    FClientes: TClientes;
    FFiltro: TFiltroCliente;
    procedure Carregar;
    procedure AplicarFiltro;
    procedure RecarregarSe(ASalvo: Boolean);
    function ClienteEmMemoria(AId: Integer; out ACliente: TCliente): Boolean;
  public
    constructor Create(const AVisao: IVisaoPesquisaCliente; const ARepositorio: IRepositorioCliente;
      const ATransacao: ITransacao; const ANavegador: INavegadorClientes;
      const AConfirmacao: IConfirmacao);
    procedure Abrir;
    procedure Pesquisar(const AFiltro: TFiltroCliente);
    procedure Novo;
    procedure Editar;
    procedure Excluir;
  end;

const
  IDS_PROTEGIDOS: array[0..4] of Integer = (1, 5, 8, 10, 15);
  MENSAGEM_NENHUM_CLIENTE = 'Nenhum cliente encontrado';
  MENSAGEM_FALHA_CARGA = 'Não foi possível carregar os clientes.';
  MENSAGEM_FALHA_EXCLUSAO = 'Não foi possível excluir o cliente.';
  MENSAGEM_CLIENTE_PROTEGIDO = 'Cliente protegido não pode ser excluído';
  MENSAGEM_CONFIRMAR_EXCLUSAO = 'Excluir o cliente %d - %s?';

function ClienteProtegido(AId: Integer): Boolean;

implementation

uses
  System.Generics.Collections,
  System.Generics.Defaults;

function ClienteProtegido(AId: Integer): Boolean;
var
  LId: Integer;
begin
  for LId in IDS_PROTEGIDOS do
    if LId = AId then
      Exit(True);
  Result := False;
end;

constructor TControladorPesquisaCliente.Create(const AVisao: IVisaoPesquisaCliente;
  const ARepositorio: IRepositorioCliente; const ATransacao: ITransacao;
  const ANavegador: INavegadorClientes; const AConfirmacao: IConfirmacao);
begin
  inherited Create;
  if not Assigned(AVisao) then
    raise EArgumentNilException.Create('A visão de pesquisa deve ser informada.');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('O repositório de clientes deve ser informado.');
  if not Assigned(ATransacao) then
    raise EArgumentNilException.Create('A transação deve ser informada.');
  if not Assigned(ANavegador) then
    raise EArgumentNilException.Create('O navegador de clientes deve ser informado.');
  if not Assigned(AConfirmacao) then
    raise EArgumentNilException.Create('A confirmação deve ser informada.');
  FVisao := AVisao;
  FRepositorio := ARepositorio;
  FTransacao := ATransacao;
  FNavegador := ANavegador;
  FConfirmacao := AConfirmacao;
end;

procedure TControladorPesquisaCliente.Carregar;
begin
  FVisao.SinalizarCarregamento(True);
  try
    try
      FClientes := FRepositorio.ListarTodos;
      TArray.Sort<TCliente>(FClientes, TComparer<TCliente>.Construct(
        function(const AEsquerdo, ADireito: TCliente): Integer
        begin
          Result := AEsquerdo.Id - ADireito.Id;
        end));
    except
      on Exception do
      begin
        FClientes := [];
        FVisao.ExibirErro(MENSAGEM_FALHA_CARGA);
      end;
    end;
  finally
    FVisao.SinalizarCarregamento(False);
  end;
end;

procedure TControladorPesquisaCliente.AplicarFiltro;
var
  LCliente: TCliente;
  LResultado: TClientes;
begin
  LResultado := [];
  for LCliente in FClientes do
    if FFiltro.Atende(LCliente) then
      LResultado := LResultado + [LCliente];
  FVisao.ExibirClientes(LResultado);
  if Length(LResultado) = 0 then
    FVisao.ExibirSemResultado(MENSAGEM_NENHUM_CLIENTE);
  FVisao.HabilitarEdicaoEExclusao(Length(LResultado) > 0);
end;

procedure TControladorPesquisaCliente.RecarregarSe(ASalvo: Boolean);
begin
  if not ASalvo then
    Exit;
  Carregar;
  AplicarFiltro;
end;

function TControladorPesquisaCliente.ClienteEmMemoria(AId: Integer; out ACliente: TCliente): Boolean;
var
  LCliente: TCliente;
begin
  for LCliente in FClientes do
    if LCliente.Id = AId then
    begin
      ACliente := LCliente;
      Exit(True);
    end;
  Result := False;
end;

procedure TControladorPesquisaCliente.Abrir;
begin
  FFiltro := Default(TFiltroCliente);
  Carregar;
  AplicarFiltro;
end;

procedure TControladorPesquisaCliente.Pesquisar(const AFiltro: TFiltroCliente);
begin
  FFiltro := AFiltro;
  AplicarFiltro;
end;

procedure TControladorPesquisaCliente.Novo;
begin
  RecarregarSe(FNavegador.AbrirInclusao);
end;

procedure TControladorPesquisaCliente.Editar;
var
  LId: Integer;
begin
  LId := FVisao.IdSelecionado;
  if LId <= 0 then
    Exit;
  RecarregarSe(FNavegador.AbrirEdicao(LId));
end;

procedure TControladorPesquisaCliente.Excluir;
var
  LCliente: TCliente;
begin
  if not ClienteEmMemoria(FVisao.IdSelecionado, LCliente) then
    Exit;
  if ClienteProtegido(LCliente.Id) then
  begin
    FVisao.ExibirAviso(MENSAGEM_CLIENTE_PROTEGIDO);
    Exit;
  end;
  if not FConfirmacao.Confirmar(Format(MENSAGEM_CONFIRMAR_EXCLUSAO, [LCliente.Id, LCliente.Nome])) then
    Exit;
  try
    FTransacao.Iniciar;
    FRepositorio.Excluir(LCliente.Id);
    FTransacao.Confirmar;
  except
    on Exception do
    begin
      FTransacao.Reverter;
      FVisao.ExibirErro(MENSAGEM_FALHA_EXCLUSAO);
      Exit;
    end;
  end;
  Carregar;
  AplicarFiltro;
end;

end.

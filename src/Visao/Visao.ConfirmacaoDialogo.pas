unit Visao.ConfirmacaoDialogo;

interface

uses
  Vcl.Forms,
  Aplicacao.Confirmacao;

type
  TConfirmacaoDialogo = class(TInterfacedObject, IConfirmacao)
  public
    class function CriarDialogo(const AMensagem: string): TForm;
    function Confirmar(const AMensagem: string): Boolean;
  end;

const
  TITULO_DIALOGO_CONFIRMACAO = 'CadCli';
  LEGENDA_SIM = '&Sim';
  LEGENDA_NAO = '&Não';

implementation

uses
  System.Classes,
  System.UITypes,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.StdCtrls;

class function TConfirmacaoDialogo.CriarDialogo(const AMensagem: string): TForm;
var
  LBotao: TComponent;
begin
  Result := CreateMessageDialog(AMensagem, mtConfirmation, [mbYes, mbNo], mbNo);
  Result.Caption := TITULO_DIALOGO_CONFIRMACAO;
  LBotao := Result.FindComponent('Yes');
  if LBotao is TButton then
    TButton(LBotao).Caption := LEGENDA_SIM;
  LBotao := Result.FindComponent('No');
  if LBotao is TButton then
    TButton(LBotao).Caption := LEGENDA_NAO;
end;

function TConfirmacaoDialogo.Confirmar(const AMensagem: string): Boolean;
var
  LDialogo: TForm;
begin
  LDialogo := CriarDialogo(AMensagem);
  try
    Result := LDialogo.ShowModal = mrYes;
  finally
    LDialogo.Free;
  end;
end;

end.

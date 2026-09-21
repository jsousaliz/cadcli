unit Visao.ApresentadorErro;

interface

uses
  Vcl.Forms;

type
  IApresentadorErro = interface
    ['{B3E4A6C1-2D7F-4E8A-9B15-7F0C3A5D9E24}']
    procedure ApresentarErro(const AMensagem: string);
  end;

  TApresentadorErroDialogo = class(TInterfacedObject, IApresentadorErro)
  public
    class function CriarDialogo(const AMensagem: string): TForm;
    procedure ApresentarErro(const AMensagem: string);
  end;

const
  TITULO_DIALOGO_ERRO = 'CadCli';

implementation

uses
  Vcl.Dialogs;

class function TApresentadorErroDialogo.CriarDialogo(const AMensagem: string): TForm;
begin
  Result := CreateMessageDialog(AMensagem, mtError, [mbOK]);
  Result.Caption := TITULO_DIALOGO_ERRO;
end;

procedure TApresentadorErroDialogo.ApresentarErro(const AMensagem: string);
var
  LDialogo: TForm;
begin
  LDialogo := CriarDialogo(AMensagem);
  try
    LDialogo.ShowModal;
  finally
    LDialogo.Free;
  end;
end;

end.

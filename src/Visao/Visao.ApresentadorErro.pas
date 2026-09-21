unit Visao.ApresentadorErro;

interface

type
  IApresentadorErro = interface
    ['{B3E4A6C1-2D7F-4E8A-9B15-7F0C3A5D9E24}']
    procedure ApresentarErro(const AMensagem: string);
  end;

  TApresentadorErroDialogo = class(TInterfacedObject, IApresentadorErro)
  public
    procedure ApresentarErro(const AMensagem: string);
  end;

implementation

uses
  Vcl.Dialogs;

procedure TApresentadorErroDialogo.ApresentarErro(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtError, [mbOK], 0);
end;

end.

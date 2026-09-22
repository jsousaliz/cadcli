unit Visao.ModuloIconesAcao;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ImgList,
  dxCore,
  cxGraphics,
  cxImageList, System.ImageList;

type
  TModuloIconesAcao = class(TDataModule)
    ListaIconesAcao: TcxImageList;
  end;

var
  ModuloIconesAcao: TModuloIconesAcao;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.

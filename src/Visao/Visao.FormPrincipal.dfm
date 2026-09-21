object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  Caption = 'CadCli'
  ClientHeight = 500
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object RotuloCabecalho: TcxLabel
    Left = 0
    Top = 25
    Align = alTop
    Caption = 'CadCli - Cadastro de Clientes'
    ParentFont = False
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -21
    Style.Font.Name = 'Segoe UI'
    Style.Font.Style = [fsBold]
    Style.IsFontAssigned = True
    Properties.Alignment.Horz = taCenter
    TabOrder = 0
    ExplicitWidth = 798
    AnchorX = 400
  end
  object RotuloBoasVindas: TcxLabel
    Left = 0
    Top = 59
    Align = alClient
    Caption = 
      'Bem-vindo! Use o menu para acessar o cadastro e o relat'#243'rio de c' +
      'lientes.'
    Properties.Alignment.Horz = taCenter
    Properties.Alignment.Vert = taVCenter
    Properties.WordWrap = True
    TabOrder = 1
    ExplicitWidth = 798
    ExplicitHeight = 413
    Width = 800
    AnchorX = 400
    AnchorY = 270
  end
  object BarraStatus: TdxStatusBar
    Left = 0
    Top = 480
    Width = 800
    Height = 20
    Panels = <
      item
        PanelStyleClassName = 'TdxStatusBarTextPanelStyle'
        Text = 'Vers'#227'o'
      end>
    ExplicitTop = 472
    ExplicitWidth = 798
  end
  object GerenciadorBarras: TdxBarManager
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    Categories.Strings = (
      'Default')
    Categories.ItemsVisibles = (
      2)
    Categories.Visibles = (
      True)
    PopupMenuLinks = <>
    UseSystemFont = True
    Left = 40
    Top = 80
    PixelsPerInch = 96
    DockControlHeights = (
      0
      0
      25
      0)
    object BarraMenuPrincipal: TdxBar
      AllowQuickCustomizing = False
      Caption = 'Menu principal'
      CaptionButtons = <>
      DockedDockingStyle = dsTop
      DockedLeft = 0
      DockedTop = 0
      DockingStyle = dsTop
      FloatLeft = 28
      FloatTop = 78
      FloatClientWidth = 0
      FloatClientHeight = 0
      IsMainMenu = True
      ItemLinks = <
        item
          Visible = True
          ItemName = 'MenuSistema'
        end
        item
          Visible = True
          ItemName = 'MenuCadastros'
        end
        item
          Visible = True
          ItemName = 'MenuRelatorios'
        end>
      MultiLine = True
      OneOnRow = True
      Row = 0
      UseOwnFont = False
      Visible = True
      WholeRow = True
    end
    object MenuSistema: TdxBarSubItem
      Caption = '&Sistema'
      Category = 0
      Visible = ivAlways
      ItemLinks = <
        item
          Visible = True
          ItemName = 'ItemSair'
        end>
    end
    object MenuCadastros: TdxBarSubItem
      Caption = '&Cadastros'
      Category = 0
      Visible = ivAlways
      ItemLinks = <
        item
          Visible = True
          ItemName = 'ItemCliente'
        end>
    end
    object MenuRelatorios: TdxBarSubItem
      Caption = '&Relat'#243'rios'
      Category = 0
      Visible = ivAlways
      ItemLinks = <
        item
          Visible = True
          ItemName = 'ItemRelatorio'
        end>
    end
    object ItemSair: TdxBarButton
      Caption = 'Sai&r'
      Category = 0
      Hint = 'Sair'
      Visible = ivAlways
      OnClick = ItemSairClick
    end
    object ItemCliente: TdxBarButton
      Caption = 'C&liente'
      Category = 0
      Hint = 'Cliente'
      Visible = ivAlways
      OnClick = ItemClienteClick
    end
    object ItemRelatorio: TdxBarButton
      Caption = 'R&elat'#243'rio'
      Category = 0
      Hint = 'Relat'#243'rio'
      Visible = ivAlways
      OnClick = ItemRelatorioClick
    end
  end
end

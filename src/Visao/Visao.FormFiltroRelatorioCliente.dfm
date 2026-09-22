object FormFiltroRelatorioCliente: TFormFiltroRelatorioCliente
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Relat'#243'rio de Clientes'
  ClientHeight = 352
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object GrupoModos: TcxRadioGroup
    Left = 12
    Top = 12
    Caption = 'Filtro'
    Properties.Items = <
      item
        Caption = 'ID Inicial e ID Final'
      end
      item
        Caption = 'Cidade/Estado'
      end
      item
        Caption = 'Todos'
      end>
    Properties.OnChange = ModoAlterado
    ItemIndex = 2
    TabOrder = 0
    Height = 100
    Width = 282
  end
  object RotuloIdInicial: TcxLabel
    Left = 12
    Top = 122
    Caption = 'ID Inicial'
    TabOrder = 7
    Transparent = True
  end
  object EditorIdInicial: TcxTextEdit
    Left = 12
    Top = 142
    TabOrder = 1
    Width = 130
  end
  object RotuloIdFinal: TcxLabel
    Left = 164
    Top = 122
    Caption = 'ID Final'
    TabOrder = 8
    Transparent = True
  end
  object EditorIdFinal: TcxTextEdit
    Left = 164
    Top = 142
    TabOrder = 2
    Width = 130
  end
  object RotuloEstado: TcxLabel
    Left = 12
    Top = 180
    Caption = 'Estado'
    TabOrder = 9
    Transparent = True
  end
  object ComboEstado: TcxComboBox
    Left = 12
    Top = 200
    Properties.DropDownListStyle = lsFixedList
    Properties.OnChange = EstadoAlterado
    TabOrder = 3
    Width = 282
  end
  object RotuloCidade: TcxLabel
    Left = 12
    Top = 236
    Caption = 'Cidade'
    TabOrder = 10
    Transparent = True
  end
  object ComboCidade: TcxComboBox
    Left = 12
    Top = 256
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 4
    Width = 282
  end
  object BotaoVisualizar: TcxButton
    Left = 12
    Top = 302
    Width = 130
    Height = 30
    Caption = 'Visualizar'
    TabOrder = 5
    OnClick = BotaoVisualizarClick
  end
  object BotaoFechar: TcxButton
    Left = 164
    Top = 302
    Width = 130
    Height = 30
    Caption = 'Fechar'
    ModalResult = 2
    TabOrder = 6
  end
end

object FormPesquisaCliente: TFormPesquisaCliente
  Left = 0
  Top = 0
  Caption = 'Pesquisa de Clientes'
  ClientHeight = 560
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object PainelFiltros: TcxGroupBox
    Left = 0
    Top = 0
    Align = alTop
    PanelStyle.Active = True
    TabOrder = 0
    ExplicitWidth = 898
    Height = 112
    Width = 900
    object RotuloId: TcxLabel
      Left = 12
      Top = 8
      Caption = 'ID'
      TabOrder = 9
      Transparent = True
    end
    object EditorId: TcxTextEdit
      Left = 12
      Top = 28
      TabOrder = 0
      Width = 70
    end
    object RotuloNome: TcxLabel
      Left = 94
      Top = 8
      Caption = 'Nome'
      TabOrder = 10
      Transparent = True
    end
    object EditorNome: TcxTextEdit
      Left = 94
      Top = 28
      TabOrder = 1
      Width = 260
    end
    object RotuloCpfCnpj: TcxLabel
      Left = 366
      Top = 8
      Caption = 'CPF/CNPJ'
      TabOrder = 11
      Transparent = True
    end
    object EditorCpfCnpj: TcxTextEdit
      Left = 366
      Top = 28
      TabOrder = 2
      Width = 150
    end
    object RotuloCep: TcxLabel
      Left = 528
      Top = 8
      Caption = 'CEP'
      TabOrder = 12
      Transparent = True
    end
    object EditorCep: TcxTextEdit
      Left = 528
      Top = 28
      TabOrder = 3
      Width = 100
    end
    object RotuloCidade: TcxLabel
      Left = 12
      Top = 56
      Caption = 'Cidade'
      TabOrder = 13
      Transparent = True
    end
    object EditorCidade: TcxTextEdit
      Left = 12
      Top = 76
      TabOrder = 4
      Width = 170
    end
    object RotuloEstado: TcxLabel
      Left = 194
      Top = 56
      Caption = 'Estado'
      TabOrder = 14
      Transparent = True
    end
    object EditorEstado: TcxTextEdit
      Left = 194
      Top = 76
      TabOrder = 5
      Width = 160
    end
    object RotuloDataNascimento: TcxLabel
      Left = 366
      Top = 56
      Caption = 'Data de nascimento'
      TabOrder = 15
      Transparent = True
    end
    object EditorDataNascimento: TcxDateEdit
      Left = 366
      Top = 76
      TabOrder = 6
      Width = 150
    end
    object RotuloBuscaGeral: TcxLabel
      Left = 528
      Top = 56
      Caption = 'Buscar em todos os campos'
      TabOrder = 16
      Transparent = True
    end
    object EditorBuscaGeral: TcxTextEdit
      Left = 528
      Top = 76
      TabOrder = 7
      Width = 230
    end
    object BotaoPesquisar: TcxButton
      Left = 770
      Top = 74
      Width = 110
      Height = 27
      Caption = 'Pesquisar'
      TabOrder = 8
      OnClick = BotaoPesquisarClick
    end
  end
  object ListaClientes: TcxMCListBox
    Left = 0
    Top = 112
    Width = 900
    Height = 400
    Align = alClient
    Delimiter = #9
    HeaderSections = <
      item
        Text = 'ID'
      end
      item
        Text = 'Nome'
        Width = 180
      end
      item
        Text = 'CPF/CNPJ'
        Width = 120
      end
      item
        Text = 'CEP'
        Width = 75
      end
      item
        Text = 'Cidade'
        Width = 120
      end
      item
        Text = 'UF'
        Width = 35
      end
      item
        Text = 'Estado'
        Width = 110
      end
      item
        Text = 'Data de nascimento'
        Width = 110
      end>
    TabOrder = 1
    OnDblClick = ListaClientesDblClick
    ExplicitWidth = 898
    ExplicitHeight = 392
  end
  object RotuloSemResultado: TcxLabel
    Left = 16
    Top = 144
    Caption = 'Nenhum cliente encontrado'
    TabOrder = 3
    Transparent = True
    Visible = False
  end
  object BarraAcoes: TcxGroupBox
    Left = 0
    Top = 512
    Align = alBottom
    PanelStyle.Active = True
    TabOrder = 2
    ExplicitTop = 504
    ExplicitWidth = 898
    Height = 48
    Width = 900
    object BotaoNovo: TcxButton
      Left = 12
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Novo'
      TabOrder = 0
      OnClick = BotaoNovoClick
    end
    object BotaoEditar: TcxButton
      Left = 112
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Editar'
      TabOrder = 1
      OnClick = BotaoEditarClick
    end
    object BotaoExcluir: TcxButton
      Left = 212
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Excluir'
      TabOrder = 2
      OnClick = BotaoExcluirClick
    end
  end
end

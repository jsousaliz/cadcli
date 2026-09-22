object FormPesquisaCliente: TFormPesquisaCliente
  Left = 0
  Top = 0
  Caption = 'Cliente'
  ClientHeight = 560
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 15
  object PainelFiltros: TcxGroupBox
    Left = 0
    Top = 0
    Align = alTop
    PanelStyle.Active = True
    TabOrder = 0
    Height = 64
    Width = 900
    object RotuloPesquisa: TcxLabel
      Left = 12
      Top = 8
      Caption = 'Pesquisar por'
      TabOrder = 5
      Transparent = True
    end
    object EditorPesquisa: TcxTextEdit
      Left = 12
      Top = 28
      TabOrder = 0
      OnKeyPress = FiltroKeyPress
      Width = 280
    end
    object RotuloCampos: TcxLabel
      Left = 301
      Top = 8
      Caption = 'Campos da pesquisa'
      TabOrder = 6
      Transparent = True
    end
    object ComboCampos: TcxCheckComboBox
      Left = 301
      Top = 28
      Properties.Delimiter = ' - '
      Properties.EmptySelectionText = 'Todos os campos'
      Properties.Items = <
        item
          Description = 'ID'
        end
        item
          Description = 'Nome'
        end
        item
          Description = 'CPF/CNPJ'
        end
        item
          Description = 'CEP'
        end
        item
          Description = 'Cidade'
        end
        item
          Description = 'Estado'
        end>
      TabOrder = 1
      OnKeyPress = FiltroKeyPress
      Width = 255
    end
    object RotuloDataNascimento: TcxLabel
      Left = 565
      Top = 8
      Caption = 'Data de nascimento'
      TabOrder = 7
      Transparent = True
    end
    object EditorDataNascimento: TcxDateEdit
      Left = 565
      Top = 28
      TabOrder = 2
      OnKeyPress = FiltroKeyPress
      Width = 120
    end
    object BotaoPesquisar: TcxButton
      Left = 695
      Top = 26
      Width = 90
      Height = 27
      Caption = '&Pesquisar'
      OptionsImage.ImageIndex = 3
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 3
      OnClick = BotaoPesquisarClick
    end
    object BotaoLimpar: TcxButton
      Left = 790
      Top = 26
      Width = 90
      Height = 27
      Caption = '&Limpar'
      OptionsImage.ImageIndex = 4
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 4
      OnClick = BotaoLimparClick
    end
  end
  object ListaClientes: TcxMCListBox
    Left = 0
    Top = 64
    Width = 900
    Height = 427
    Align = alClient
    Delimiter = #9
    HeaderSections = <
      item
        AllowClick = True
        Text = 'ID'
      end
      item
        AllowClick = True
        Text = 'Nome'
        Width = 180
      end
      item
        AllowClick = True
        Text = 'CPF/CNPJ'
        Width = 120
      end
      item
        AllowClick = True
        Text = 'CEP'
        Width = 75
      end
      item
        AllowClick = True
        Text = 'Cidade'
        Width = 120
      end
      item
        AllowClick = True
        Text = 'UF'
        Width = 35
      end
      item
        AllowClick = True
        Text = 'Estado'
        Width = 110
      end
      item
        AllowClick = True
        Text = 'Data de nascimento'
        Width = 110
      end>
    TabOrder = 1
    OnDblClick = ListaClientesDblClick
  end
  object RotuloLimite: TcxLabel
    AlignWithMargins = True
    Left = 12
    Top = 493
    Margins.Left = 12
    Margins.Top = 2
    Margins.Right = 12
    Margins.Bottom = 2
    Align = alBottom
    Caption = 'A pesquisa lista no m'#225'ximo 50 clientes.'
    ParentFont = False
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clGrayText
    Style.Font.Height = -11
    Style.Font.Name = 'Segoe UI'
    Style.Font.Style = []
    Style.IsFontAssigned = True
    TabOrder = 4
    Transparent = True
  end
  object BarraAcoes: TcxGroupBox
    Left = 0
    Top = 512
    Align = alBottom
    PanelStyle.Active = True
    TabOrder = 2
    Height = 48
    Width = 900
    object BotaoNovo: TcxButton
      Left = 12
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Novo'
      OptionsImage.ImageIndex = 0
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 0
      OnClick = BotaoNovoClick
    end
    object BotaoEditar: TcxButton
      Left = 112
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Editar'
      OptionsImage.ImageIndex = 1
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 1
      OnClick = BotaoEditarClick
    end
    object BotaoExcluir: TcxButton
      Left = 212
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Excluir'
      OptionsImage.ImageIndex = 2
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 2
      OnClick = BotaoExcluirClick
    end
  end
  object PanelSemResultado: TdxPanel
    Left = 321
    Top = 232
    Width = 210
    Height = 80
    TabOrder = 3
    Visible = False
    object RotuloSemResultado: TcxLabel
      Left = 24
      Top = 28
      Caption = 'Nenhum cliente encontrado...'
      TabOrder = 0
      Transparent = True
    end
  end
end

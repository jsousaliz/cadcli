object FormCadastroCliente: TFormCadastroCliente
  Left = 0
  Top = 0
  ActiveControl = EditorNome
  BorderStyle = bsDialog
  Caption = 'Novo Cliente'
  ClientHeight = 356
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  TextHeight = 15
  object PainelCampos: TcxGroupBox
    Left = 0
    Top = 0
    Align = alClient
    PanelStyle.Active = True
    TabOrder = 0
    Height = 308
    Width = 560
    object RotuloNome: TcxLabel
      Left = 12
      Top = 8
      Caption = 'Nome'
      TabOrder = 11
      Transparent = True
    end
    object EditorNome: TcxTextEdit
      Left = 12
      Top = 28
      Properties.MaxLength = 80
      TabOrder = 0
      Width = 530
    end
    object RotuloCpfCnpj: TcxLabel
      Left = 12
      Top = 56
      Caption = 'CPF/CNPJ'
      TabOrder = 12
      Transparent = True
    end
    object EditorCpfCnpj: TcxTextEdit
      Left = 12
      Top = 76
      Properties.MaxLength = 18
      TabOrder = 1
      Width = 180
    end
    object RotuloDataNascimento: TcxLabel
      Left = 204
      Top = 56
      Caption = 'Data de nascimento'
      TabOrder = 13
      Transparent = True
    end
    object EditorDataNascimento: TcxDateEdit
      Left = 204
      Top = 76
      TabOrder = 2
      Width = 140
    end
    object RotuloCep: TcxLabel
      Left = 12
      Top = 104
      Caption = 'CEP'
      TabOrder = 14
      Transparent = True
    end
    object EditorCep: TcxTextEdit
      Left = 12
      Top = 124
      Properties.MaxLength = 9
      TabOrder = 3
      OnEnter = EditorCepEnter
      OnExit = EditorCepExit
      Width = 110
    end
    object RotuloConsultandoCep: TcxLabel
      Left = 132
      Top = 126
      Caption = 'Consultando CEP...'
      TabOrder = 15
      Transparent = True
      Visible = False
    end
    object RotuloEndereco: TcxLabel
      Left = 12
      Top = 152
      Caption = 'Endere'#231'o'
      TabOrder = 16
      Transparent = True
    end
    object EditorEndereco: TcxTextEdit
      Left = 12
      Top = 172
      Properties.MaxLength = 100
      TabOrder = 4
      Width = 400
    end
    object RotuloNumero: TcxLabel
      Left = 424
      Top = 152
      Caption = 'N'#250'mero'
      TabOrder = 17
      Transparent = True
    end
    object EditorNumero: TcxTextEdit
      Left = 424
      Top = 172
      Properties.MaxLength = 20
      TabOrder = 5
      Width = 118
    end
    object RotuloComplemento: TcxLabel
      Left = 12
      Top = 200
      Caption = 'Complemento'
      TabOrder = 18
      Transparent = True
    end
    object EditorComplemento: TcxTextEdit
      Left = 12
      Top = 220
      Properties.MaxLength = 60
      TabOrder = 6
      Width = 260
    end
    object RotuloBairro: TcxLabel
      Left = 284
      Top = 200
      Caption = 'Bairro'
      TabOrder = 19
      Transparent = True
    end
    object EditorBairro: TcxTextEdit
      Left = 284
      Top = 220
      Properties.MaxLength = 100
      TabOrder = 7
      Width = 258
    end
    object RotuloCidade: TcxLabel
      Left = 12
      Top = 248
      Caption = 'Cidade'
      TabOrder = 20
      Transparent = True
    end
    object EditorCidade: TcxTextEdit
      Left = 12
      Top = 268
      Properties.MaxLength = 50
      TabOrder = 8
      Width = 260
    end
    object RotuloUf: TcxLabel
      Left = 284
      Top = 248
      Caption = 'UF'
      TabOrder = 21
      Transparent = True
    end
    object EditorUf: TcxComboBox
      Left = 284
      Top = 268
      Properties.DropDownListStyle = lsFixedList
      Properties.OnChange = EditorUfPropertiesChange
      TabOrder = 9
      Width = 70
    end
    object RotuloEstado: TcxLabel
      Left = 366
      Top = 248
      Caption = 'Estado'
      TabOrder = 22
      Transparent = True
    end
    object EditorEstado: TcxTextEdit
      Left = 366
      Top = 268
      TabStop = False
      Properties.ReadOnly = True
      TabOrder = 10
      Width = 176
    end
  end
  object BarraBotoes: TcxGroupBox
    Left = 0
    Top = 308
    Align = alBottom
    PanelStyle.Active = True
    TabOrder = 1
    Height = 48
    Width = 560
    object BotaoSalvar: TcxButton
      Left = 332
      Top = 10
      Width = 100
      Height = 28
      Caption = 'Salvar'
      OptionsImage.ImageIndex = 5
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 0
      OnClick = BotaoSalvarClick
    end
    object BotaoCancelar: TcxButton
      Left = 442
      Top = 10
      Width = 100
      Height = 28
      Caption = 'Cancelar'
      OptionsImage.ImageIndex = 6
      OptionsImage.Images = ModuloIconesAcao.ListaIconesAcao
      TabOrder = 1
      OnClick = BotaoCancelarClick
    end
  end
end

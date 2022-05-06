object FormSettings: TFormSettings
  Left = 582
  Top = 263
  BorderStyle = bsDialog
  Caption = 'UIA Settings'
  ClientHeight = 324
  ClientWidth = 321
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  DesignSize = (
    321
    324)
  PixelsPerInch = 96
  TextHeight = 13
  object ButtonClose: TButton
    Left = 120
    Top = 296
    Width = 81
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Close'
    TabOrder = 0
    OnClick = ButtonCloseClick
  end
  object GroupBoxFlags: TGroupBox
    Left = 8
    Top = 128
    Width = 305
    Height = 161
    Caption = 'Options'
    TabOrder = 2
    object ButtonList: TButton
      Left = 248
      Top = 16
      Width = 49
      Height = 17
      Caption = 'List...'
      TabOrder = 1
      OnClick = ButtonListClick
    end
    object CheckBox1: TCheckBox
      Left = 8
      Top = 16
      Width = 233
      Height = 17
      Caption = 'Suppress simple GAME.TXT popups'
      TabOrder = 0
      OnClick = CheckBoxFlagsClick
    end
    object CheckBox2: TCheckBox
      Tag = 1
      Left = 8
      Top = 40
      Width = 289
      Height = 17
      Caption = 'Reset Engineer'#39's order after passing its work to coworker'
      TabOrder = 2
      OnClick = CheckBoxFlagsClick
    end
    object CheckBox3: TCheckBox
      Tag = 2
      Left = 8
      Top = 64
      Width = 289
      Height = 17
      Caption = 'Don'#39't break unit movement on ZOC'
      TabOrder = 3
      OnClick = CheckBoxFlagsClick
    end
    object CheckBox4: TCheckBox
      Tag = 3
      Left = 8
      Top = 88
      Width = 289
      Height = 17
      Hint = 'asdfasf sdaf sdf'
      Caption = 'Reset units Wait flag after activating'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = CheckBoxFlagsClick
    end
    object CheckBox5: TCheckBox
      Tag = 4
      Left = 8
      Top = 112
      Width = 289
      Height = 17
      Caption = 'Radiobuttons hotkeys'
      TabOrder = 5
      OnClick = CheckBoxFlagsClick
    end
    object CheckBox6: TCheckBox
      Tag = 5
      Left = 8
      Top = 136
      Width = 97
      Height = 17
      Caption = 'CheckBox6'
      TabOrder = 6
    end
  end
  object GroupBoxColor: TGroupBox
    Left = 8
    Top = 8
    Width = 305
    Height = 113
    Caption = 'Color correction'
    TabOrder = 1
    object Label1: TLabel
      Left = 8
      Top = 24
      Width = 44
      Height = 13
      Caption = 'Exposure'
    end
    object LabelGamma: TLabel
      Left = 256
      Top = 48
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label3: TLabel
      Left = 8
      Top = 48
      Width = 36
      Height = 13
      Caption = 'Gamma'
    end
    object LabelExposure: TLabel
      Left = 256
      Top = 24
      Width = 6
      Height = 13
      Caption = '0'
    end
    object btn9: TButton
      Tag = 3
      Left = 216
      Top = 72
      Width = 24
      Height = 24
      Caption = '+3'
      TabOrder = 10
      OnClick = ButtonColorPresetClick
    end
    object btn8: TButton
      Tag = 2
      Left = 192
      Top = 72
      Width = 24
      Height = 24
      Caption = '+2'
      TabOrder = 9
      OnClick = ButtonColorPresetClick
    end
    object btn7: TButton
      Tag = 1
      Left = 168
      Top = 72
      Width = 24
      Height = 24
      Caption = '+1'
      TabOrder = 8
      OnClick = ButtonColorPresetClick
    end
    object btn6: TButton
      Left = 144
      Top = 72
      Width = 24
      Height = 24
      Caption = '0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = ButtonColorPresetClick
    end
    object btn5: TButton
      Tag = -1
      Left = 120
      Top = 72
      Width = 24
      Height = 24
      Caption = '-1'
      TabOrder = 6
      OnClick = ButtonColorPresetClick
    end
    object btn4: TButton
      Tag = -2
      Left = 96
      Top = 72
      Width = 24
      Height = 24
      Caption = '-2'
      TabOrder = 5
      OnClick = ButtonColorPresetClick
    end
    object btn3: TButton
      Tag = -3
      Left = 72
      Top = 72
      Width = 24
      Height = 24
      Caption = '-3'
      TabOrder = 4
      OnClick = ButtonColorPresetClick
    end
    object btn2: TButton
      Tag = -4
      Left = 48
      Top = 72
      Width = 24
      Height = 24
      Caption = '-4'
      TabOrder = 3
      OnClick = ButtonColorPresetClick
    end
    object btn11: TButton
      Tag = 5
      Left = 264
      Top = 72
      Width = 24
      Height = 24
      Caption = '+5'
      TabOrder = 12
      OnClick = ButtonColorPresetClick
    end
    object btn10: TButton
      Tag = 4
      Left = 240
      Top = 72
      Width = 24
      Height = 24
      Caption = '+4'
      TabOrder = 11
      OnClick = ButtonColorPresetClick
    end
    object btn1: TButton
      Tag = -5
      Left = 24
      Top = 72
      Width = 24
      Height = 24
      Caption = '-5'
      TabOrder = 2
      OnClick = ButtonColorPresetClick
    end
    object ScrollBar1: TScrollBar
      Left = 64
      Top = 24
      Width = 185
      Height = 16
      LargeChange = 4
      Max = 30
      Min = -30
      PageSize = 0
      TabOrder = 0
      TabStop = False
      OnChange = ScrollBar1Change
    end
    object ScrollBar2: TScrollBar
      Left = 64
      Top = 48
      Width = 185
      Height = 16
      LargeChange = 4
      Max = 50
      Min = 1
      PageSize = 0
      Position = 1
      TabOrder = 1
      TabStop = False
      OnChange = ScrollBar1Change
    end
  end
end

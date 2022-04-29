object FormSettings: TFormSettings
  Left = 709
  Top = 251
  BorderStyle = bsDialog
  Caption = 'UIA Settings'
  ClientHeight = 212
  ClientWidth = 302
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    302
    212)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 44
    Height = 13
    Caption = 'Exposure'
  end
  object Label2: TLabel
    Left = 256
    Top = 8
    Width = 32
    Height = 13
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 8
    Top = 32
    Width = 36
    Height = 13
    Caption = 'Gamma'
  end
  object Label4: TLabel
    Left = 256
    Top = 32
    Width = 32
    Height = 13
    Caption = 'Label4'
  end
  object ScrollBar1: TScrollBar
    Left = 64
    Top = 8
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
    Top = 32
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
  object ButtonClose: TButton
    Left = 112
    Top = 176
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Close'
    TabOrder = 13
    OnClick = ButtonCloseClick
  end
  object btn4: TButton
    Tag = -2
    Left = 96
    Top = 56
    Width = 24
    Height = 24
    Caption = '-2'
    TabOrder = 5
    OnClick = ButtonColorPresetClick
  end
  object btn5: TButton
    Tag = -1
    Left = 120
    Top = 56
    Width = 24
    Height = 24
    Caption = '-1'
    TabOrder = 6
    OnClick = ButtonColorPresetClick
  end
  object btn6: TButton
    Left = 144
    Top = 56
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
  object btn7: TButton
    Tag = 1
    Left = 168
    Top = 56
    Width = 24
    Height = 24
    Caption = '+1'
    TabOrder = 8
    OnClick = ButtonColorPresetClick
  end
  object btn8: TButton
    Tag = 2
    Left = 192
    Top = 56
    Width = 24
    Height = 24
    Caption = '+2'
    TabOrder = 9
    OnClick = ButtonColorPresetClick
  end
  object btn3: TButton
    Tag = -3
    Left = 72
    Top = 56
    Width = 24
    Height = 24
    Caption = '-3'
    TabOrder = 4
    OnClick = ButtonColorPresetClick
  end
  object btn9: TButton
    Tag = 3
    Left = 216
    Top = 56
    Width = 24
    Height = 24
    Caption = '+3'
    TabOrder = 10
    OnClick = ButtonColorPresetClick
  end
  object btn2: TButton
    Tag = -4
    Left = 48
    Top = 56
    Width = 24
    Height = 24
    Caption = '-4'
    TabOrder = 3
    OnClick = ButtonColorPresetClick
  end
  object btn10: TButton
    Tag = 4
    Left = 240
    Top = 56
    Width = 24
    Height = 24
    Caption = '+4'
    TabOrder = 11
    OnClick = ButtonColorPresetClick
  end
  object btn1: TButton
    Tag = -5
    Left = 24
    Top = 56
    Width = 24
    Height = 24
    Caption = '-5'
    TabOrder = 2
    OnClick = ButtonColorPresetClick
  end
  object btn11: TButton
    Tag = 5
    Left = 264
    Top = 56
    Width = 24
    Height = 24
    Caption = '+5'
    TabOrder = 12
    OnClick = ButtonColorPresetClick
  end
end

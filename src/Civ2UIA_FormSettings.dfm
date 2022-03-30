object FormSettings: TFormSettings
  Left = 704
  Top = 267
  BorderStyle = bsDialog
  Caption = 'FormSettings'
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
    TabOrder = 1
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
    TabOrder = 2
    TabStop = False
    OnChange = ScrollBar1Change
  end
  object Button1: TButton
    Left = 112
    Top = 176
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Close'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button3: TButton
    Left = 64
    Top = 56
    Width = 25
    Height = 25
    Caption = '-2'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 104
    Top = 56
    Width = 25
    Height = 25
    Caption = '-1'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 144
    Top = 56
    Width = 25
    Height = 25
    Caption = '0'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 184
    Top = 56
    Width = 25
    Height = 25
    Caption = '+1'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 224
    Top = 56
    Width = 25
    Height = 25
    Caption = '+2'
    TabOrder = 7
    OnClick = Button7Click
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 104
    Width = 97
    Height = 17
    Caption = 'CheckBox1'
    TabOrder = 8
  end
end

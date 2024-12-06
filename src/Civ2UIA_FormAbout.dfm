object FormAbout: TFormAbout
  Left = 665
  Top = 207
  BorderStyle = bsDialog
  Caption = 'About Civ2 UI Additions'
  ClientHeight = 240
  ClientWidth = 353
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
    353
    240)
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 139
    Top = 207
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 4
    Width = 337
    Height = 195
    TabOrder = 1
    DesignSize = (
      337
      195)
    object lbl0001: TLabel
      Left = 69
      Top = 16
      Width = 199
      Height = 19
      Anchors = [akTop]
      Caption = 'User Interface Additions'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lbl0027: TLabel
      Left = 124
      Top = 168
      Width = 48
      Height = 13
      Cursor = crHandPoint
      Caption = 'FoxAhead'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsUnderline]
      ParentFont = False
      OnClick = lbl0027Click
    end
    object lbl0017: TLabel
      Left = 92
      Top = 168
      Width = 24
      Height = 13
      Caption = '2024'
    end
    object lbl0016: TLabel
      Left = 92
      Top = 152
      Width = 230
      Height = 13
      Cursor = crHandPoint
      Caption = 'https://forums.civfanatics.com/threads/623515/'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsUnderline]
      ParentColor = False
      ParentFont = False
      OnClick = lbl0016Click
    end
    object lbl0015: TLabel
      Left = 92
      Top = 136
      Width = 232
      Height = 13
      Cursor = crHandPoint
      Caption = 'https://github.com/FoxAhead/Civ2-UI-Additions/'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsUnderline]
      ParentColor = False
      ParentFont = False
      OnClick = lbl0015Click
    end
    object lbl0014Version: TLabel
      Left = 92
      Top = 120
      Width = 35
      Height = 13
      Caption = 'Version'
    end
    object lbl0007: TLabel
      Left = 44
      Top = 168
      Width = 31
      Height = 13
      Caption = 'Author'
    end
    object lbl0006: TLabel
      Left = 24
      Top = 152
      Width = 51
      Height = 13
      Caption = 'Discussion'
    end
    object lbl0005: TLabel
      Left = 14
      Top = 136
      Width = 61
      Height = 13
      Caption = 'Source code'
    end
    object lbl0004: TLabel
      Left = 40
      Top = 120
      Width = 35
      Height = 13
      Caption = 'Version'
    end
    object lbl0003: TLabel
      Left = 40
      Top = 64
      Width = 256
      Height = 32
      Alignment = taCenter
      Anchors = [akTop]
      Caption = 
        'Sid Meier'#39's Civilization II'#13#10'Multiplayer Gold Edition 5.4.0f (Pa' +
        'tch 3)'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lbl0002: TLabel
      Left = 160
      Top = 40
      Width = 16
      Height = 16
      Anchors = [akTop]
      Caption = 'for'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
end

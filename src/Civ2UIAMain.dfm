object Form1: TForm1
  Left = 526
  Top = 340
  AutoScroll = False
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Form1'
  ClientHeight = 129
  ClientWidth = 385
  Color = clBtnFace
  Constraints.MinHeight = 156
  Constraints.MinWidth = 229
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnCreate = FormCreate
  DesignSize = (
    385
    129)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 40
    Width = 385
    Height = 69
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'MS Serif'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Button2: TButton
    Left = 364
    Top = 0
    Width = 21
    Height = 17
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 0
    Top = 0
    Width = 361
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    Text = 'D:\GAMES\Civilization II Multiplayer Gold Edition\civ2.exe'
  end
  object Button3: TButton
    Left = 304
    Top = 112
    Width = 81
    Height = 17
    Anchors = [akRight, akBottom]
    Caption = 'CreateProcess'
    TabOrder = 3
    OnClick = Button3Click
  end
  object CheckBox1: TCheckBox
    Left = 48
    Top = 112
    Width = 89
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Always on top'
    Checked = True
    State = cbChecked
    TabOrder = 4
    OnClick = CheckBox1Click
  end
  object Edit2: TEdit
    Left = 0
    Top = 20
    Width = 361
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
  object Button4: TButton
    Left = 364
    Top = 20
    Width = 21
    Height = 17
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 6
    OnClick = Button4Click
  end
  object Button1: TButton
    Left = 0
    Top = 112
    Width = 45
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Clear'
    TabOrder = 7
    OnClick = Button1Click
  end
  object OpenDialog1: TOpenDialog
    Filter = '*.exe|*.exe'
    Left = 176
    Top = 8
  end
  object OpenDialog2: TOpenDialog
    Filter = '*.dll|*.dll'
    Left = 220
    Top = 72
  end
end

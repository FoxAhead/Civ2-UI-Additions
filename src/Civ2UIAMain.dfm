object Form1: TForm1
  Left = 731
  Top = 413
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Civilization II UI Additions Launcher'
  ClientHeight = 299
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 12
    Width = 48
    Height = 13
    Caption = 'Game exe'
  end
  object Label2: TLabel
    Left = 8
    Top = 40
    Width = 56
    Height = 13
    Caption = 'Additions dll'
  end
  object Memo1: TMemo
    Left = 4
    Top = 60
    Width = 445
    Height = 153
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object ButtonBrowseExe: TButton
    Left = 388
    Top = 2
    Width = 65
    Height = 25
    Caption = 'Browse...'
    TabOrder = 1
    OnClick = ButtonBrowseExeClick
  end
  object EditExe: TEdit
    Left = 72
    Top = 4
    Width = 313
    Height = 21
    AutoSize = False
    Color = clBtnFace
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 2
    Text = 'D:\GAMES\Civilization II Multiplayer Gold Edition\civ2.exe'
  end
  object ButtonStart: TButton
    Left = 368
    Top = 220
    Width = 85
    Height = 25
    Caption = 'Launch'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = ButtonStartClick
  end
  object CheckBoxOnTop: TCheckBox
    Left = 84
    Top = 220
    Width = 89
    Height = 17
    Caption = 'Always on top'
    TabOrder = 4
    OnClick = CheckBoxOnTopClick
  end
  object EditDll: TEdit
    Left = 72
    Top = 32
    Width = 313
    Height = 21
    AutoSize = False
    Color = clBtnFace
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 5
  end
  object ButtonBrowseDll: TButton
    Left = 388
    Top = 30
    Width = 65
    Height = 25
    Caption = 'Browse...'
    TabOrder = 6
    OnClick = ButtonBrowseDllClick
  end
  object ButtonClear: TButton
    Left = 4
    Top = 220
    Width = 73
    Height = 21
    Caption = 'Clear'
    TabOrder = 7
    OnClick = ButtonClearClick
  end
  object Button1: TButton
    Left = 264
    Top = 220
    Width = 95
    Height = 25
    Caption = 'Create shortcut'
    TabOrder = 8
  end
  object OpenDialogExe: TOpenDialog
    Filter = '*.exe|*.exe'
    Left = 248
    Top = 160
  end
  object OpenDialogDll: TOpenDialog
    Filter = '*.dll|*.dll'
    Left = 52
    Top = 136
  end
end

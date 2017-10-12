object Form1: TForm1
  Left = 503
  Top = 292
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Civilization II UI Additions Launcher'
  ClientHeight = 257
  ClientWidth = 513
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 28
    Height = 13
    Caption = 'Game'
  end
  object Label2: TLabel
    Left = 8
    Top = 36
    Width = 12
    Height = 13
    Caption = 'Dll'
  end
  object Memo1: TMemo
    Left = 4
    Top = 60
    Width = 505
    Height = 161
    TabStop = False
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
    Left = 444
    Top = 2
    Width = 65
    Height = 25
    Caption = 'Browse...'
    TabOrder = 2
    OnClick = ButtonBrowseExeClick
  end
  object EditExe: TEdit
    Left = 44
    Top = 4
    Width = 393
    Height = 21
    TabStop = False
    AutoSize = False
    Color = clBtnFace
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 7
  end
  object ButtonStart: TButton
    Left = 408
    Top = 228
    Width = 101
    Height = 25
    Hint = 'Close and launch game'
    Caption = 'Launch'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = ButtonStartClick
  end
  object CheckBoxOnTop: TCheckBox
    Left = 52
    Top = 232
    Width = 89
    Height = 17
    Caption = 'Always on top'
    TabOrder = 5
    OnClick = CheckBoxOnTopClick
  end
  object EditDll: TEdit
    Left = 44
    Top = 32
    Width = 393
    Height = 21
    TabStop = False
    AutoSize = False
    Color = clBtnFace
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 8
  end
  object ButtonBrowseDll: TButton
    Left = 444
    Top = 30
    Width = 65
    Height = 25
    Caption = 'Browse...'
    TabOrder = 3
    OnClick = ButtonBrowseDllClick
  end
  object ButtonClear: TButton
    Left = 4
    Top = 228
    Width = 45
    Height = 25
    Caption = 'Clear'
    TabOrder = 4
    OnClick = ButtonClearClick
  end
  object Button1: TButton
    Left = 192
    Top = 228
    Width = 109
    Height = 25
    Caption = 'Create shortcut'
    TabOrder = 6
  end
  object OpenDialogExe: TOpenDialog
    Filter = '*.exe|*.exe'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 404
    Top = 28
  end
  object OpenDialogDll: TOpenDialog
    Filter = '*.dll|*.dll'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 404
  end
end

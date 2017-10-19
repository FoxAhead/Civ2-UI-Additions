object Form1: TForm1
  Left = 631
  Top = 308
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Civilization II UI Additions Launcher'
  ClientHeight = 289
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
  object LabelVersion: TLabel
    Left = 470
    Top = 268
    Width = 35
    Height = 13
    Alignment = taRightJustify
    Caption = 'Version'
    Enabled = False
  end
  object Label3: TLabel
    Left = 8
    Top = 260
    Width = 75
    Height = 13
    Caption = '2017 FoxAhead'
    Enabled = False
  end
  object LabelGitHub: TLabel
    Left = 472
    Top = 252
    Width = 33
    Height = 13
    Cursor = crHandPoint
    Alignment = taRightJustify
    Caption = 'GitHub'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = LabelGitHubClick
  end
  object LabelDebug: TLabel
    Left = 404
    Top = 268
    Width = 101
    Height = 13
    AutoSize = False
    Transparent = True
    OnClick = LabelDebugClick
  end
  object Memo1: TMemo
    Left = 4
    Top = 60
    Width = 505
    Height = 189
    TabStop = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Lines.Strings = (
      
        'This launcher will add some enhancements without modifying game ' +
        'executable.'
      'Features added:'
      ' - Mouse wheel support wherever possible'
      ' - Ability to choose any unit in stack beyond limit of 9'
      ' - Work counter for Settlers/Engineers is displayed'
      ' - Click-bounds of specialists sprites corrected in city screen'
      ' - Number of the game turn is displayed'
      ' - Current research numbers are displayed in Science Advisor'
      ' - 64 bit patch included'
      
        'This launcher will search for CIV2.EXE and CIV2UIA.DLL in its cu' +
        'rrent folder and try to set all paths '
      'automatically.'
      
        'You can create shortcut to start game immediately. All selected ' +
        'paths are saved in shortcut.'
      
        'Game version Multiplayer Gold Edition 5.4.0f (Patch 3) supported' +
        ' only.')
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
    TabOrder = 5
  end
  object ButtonStart: TButton
    Left = 260
    Top = 256
    Width = 101
    Height = 25
    Hint = 'Close this screen and start game'
    Caption = 'Play'
    Default = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = ButtonStartClick
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
    TabOrder = 6
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
  object Button1: TButton
    Left = 152
    Top = 256
    Width = 101
    Height = 25
    Caption = 'Create shortcut...'
    TabOrder = 4
    OnClick = Button1Click
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
  object SaveDialogLnk: TSaveDialog
    FileName = 'Civ2 with UI Additions.lnk'
    Filter = '*.lnk|*.lnk'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 120
    Top = 256
  end
end

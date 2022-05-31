object FormStrings: TFormStrings
  Left = 548
  Top = 303
  BorderStyle = bsDialog
  Caption = 'Popup names'
  ClientHeight = 402
  ClientWidth = 305
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  DesignSize = (
    305
    402)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 2
    Top = 2
    Width = 301
    Height = 78
    Caption = 
      'List of popup names from GAME.TXT without first @ symbol.'#13#10'For e' +
      'xample:'#13#10'BOND007'#13#10'BONDGLORY'#13#10'This list is saved in the Civ2UIASu' +
      'ppressPopup.txt file.'#13#10'Suppressed messages will be shown in the ' +
      'map overlay instead.'
  end
  object Memo1: TMemo
    Left = 0
    Top = 88
    Width = 305
    Height = 283
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 0
    OnKeyDown = Memo1KeyDown
  end
  object Button1: TButton
    Left = 116
    Top = 376
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Close'
    TabOrder = 1
    OnClick = Button1Click
  end
end

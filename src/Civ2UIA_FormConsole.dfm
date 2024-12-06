object FormConsole: TFormConsole
  Left = 217
  Top = 243
  AutoScroll = False
  Caption = 'Debug Console'
  ClientHeight = 175
  ClientWidth = 1201
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnDestroy = FormDestroy
  DesignSize = (
    1201
    175)
  PixelsPerInch = 96
  TextHeight = 13
  object LabelFocus: TLabel
    Left = 8
    Top = 4
    Width = 64
    Height = 16
    Caption = '00000000'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Fixedsys'
    Font.Style = []
    ParentFont = False
  end
  object LabelCursor: TLabel
    Left = 88
    Top = 4
    Width = 64
    Height = 16
    Caption = '00000000'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Fixedsys'
    Font.Style = []
    ParentFont = False
  end
  object Memo1: TMemo
    Left = 0
    Top = 24
    Width = 1201
    Height = 151
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clBlack
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clSilver
    Font.Height = -13
    Font.Name = 'Fixedsys'
    Font.Style = []
    HideSelection = False
    Lines.Strings = (
      
        '1. SetFocus(0004050C): 408607 40863C 5C5C20 5EAC35 5EAB47 254BB7' +
        '7 '
      
        '2. SetFocus(00080580): 5F7075 55AE20 4C428B 41FD3A 41F0C2 40BC9A' +
        ' 5A62EF 59DB95 451918 5BD109 254BB77 '
      
        '3. SetFocus(00020590): 408607 40863C 5C5C20 5EAC60 5EAAC2 254BB7' +
        '7 '
      '4. SetFocus(00020590): 5CAD40 254BB77 '
      
        '5. SetFocus(00080580): 5F7075 55AE20 4C428B 41FD3A 41F2E0 4785AE' +
        ' 421EB4 4190E5 419119 419151 51D4B0 40BC9A 5A62EF 59DB95 451918 ' +
        '5BD109 254BB77 '
      
        '6. SetFocus(00080580): 5F7075 55AE20 4C428B 41FD3A 41F2E0 4785AE' +
        ' 421EB4 4190E5 419119 419151 51D54A 59DF9E 59DB95 451918 5BD109 ' +
        '254BB77 '
      
        '7. SetFocus(00080580): 5F7075 55AE20 4C428B 41FD3A 41F685 59DF9E' +
        ' 59DB95 451918 5BD109 254BB77 ')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object Button1: TButton
    Left = 1153
    Top = 0
    Width = 48
    Height = 24
    Anchors = [akTop, akRight]
    Caption = 'Clear'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 1096
    Top = 0
    Width = 48
    Height = 24
    Anchors = [akTop, akRight]
    Caption = 'Snow'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 16
    Top = 40
  end
end

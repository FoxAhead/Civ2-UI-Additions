unit Civ2Proc;

interface

uses
  Civ2Types,
  Windows,
  Civ2UIA_Global;

type
  TCiv2 = class
  private
  protected
  public
    class procedure ClearPopupActive;
    class function CreateScrollbar(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll;
    class procedure DestroyScrollBar(ControlInfoScroll: PControlInfoScroll; Flag: LongBool);
    class function DrawCityWindowSupport(CityWindow: PCityWindow; Flag: LongBool): PCityWindow;
    class function GetInfoOfClickedCitySprite(CitySpritesInfo: PCitySpritesInfo; X, Y: Integer; var SIndex, SType: Integer): Integer;
    class procedure InitControlScrollRange(ControlInfoScroll: PControlInfoScroll; MinPos, MaxPos: Integer);
    class procedure SetScrollPageSize(ControlInfoScroll: PControlInfoScroll; PageSize: Integer);
    class procedure SetScrollPosition(ControlInfoScroll: PControlInfoScroll; Position: Integer);
    class procedure DrawString(ChText: PChar; Left, Top: Integer);
    class procedure DrawStringRight(ChText: PChar; Right, Top, Shift: Integer);
    class procedure RedrawMap(); register;
    class procedure sub_5C0D12(ThisGraphicsInfo: PGraphicsInfo; Palette: Pointer);
    class procedure SetDIBColorTableFromPalette(DrawInfo: PDrawInfo; Palette: Pointer);
    class procedure Palette_SetRandomID(Palette: Pointer);
    class procedure SetTextIntToStr(A1: Integer);
    class procedure SetTextFromLabel(A1: Integer);
    class function DrawInfoCreate(A1: PRect): PDrawInfo;
    class procedure PopupSimpleMessage(A1, A2, A3: Integer);
    class function ScreenToMap(var MapX, MapY: Integer; ScreenX, ScreenY: Integer): LongBool;
    class procedure MapToWindow(var WindowX, WindowY: Integer; MapX, MapY: Integer);
    class function GetCityIndexAtXY(X, Y: Integer): Integer;
    class function GetStringInList(StringIndex: Integer): PChar;
  published
  end;

implementation

{ TCiv2 }

class procedure TCiv2.ClearPopupActive;
asm
    mov   eax, $005A3C58
    call  eax
end;

class function TCiv2.CreateScrollbar(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll;
asm
    push  Flag
    push  Rect
    push  Code
    push  WindowInfo
    mov   ecx, ControlInfoScroll
    mov   eax, A_Q_CreateScrollbar_sub_40FC50
    call  eax
    mov   @Result, eax
end;

class procedure TCiv2.DestroyScrollBar(ControlInfoScroll: PControlInfoScroll; Flag: LongBool);
asm
    push  Flag
    mov   ecx, ControlInfoScroll
    mov   eax, $004BB4F0
    call  eax
end;

class function TCiv2.DrawCityWindowSupport(CityWindow: PCityWindow; Flag: LongBool): PCityWindow;
asm
    push  Flag
    mov   ecx, CityWindow
    mov   eax, $004011A9
    call  eax
    mov   @Result, eax
end;

class function TCiv2.GetInfoOfClickedCitySprite(CitySpritesInfo: PCitySpritesInfo; X, Y: Integer; var SIndex, SType: Integer): Integer;
asm
    push  SType
    push  SIndex
    push  Y
    push  X
    mov   ecx, CitySpritesInfo
    mov   eax, $00403D00
    call  eax
    mov   @Result, eax
end;

class procedure TCiv2.InitControlScrollRange(ControlInfoScroll: PControlInfoScroll; MinPos, MaxPos: Integer);
asm
    push  MaxPos
    push  MinPos
    mov   ecx, ControlInfoScroll
    mov   eax, $00402121
    call  eax
end;

class procedure TCiv2.SetScrollPageSize(ControlInfoScroll: PControlInfoScroll; PageSize: Integer);
asm
    push  PageSize
    mov   ecx, ControlInfoScroll
    mov   eax, $005DB0D0
    call  eax
end;

class procedure TCiv2.SetScrollPosition(ControlInfoScroll: PControlInfoScroll; Position: Integer);
asm
    push  Position
    mov   ecx, ControlInfoScroll
    mov   eax, $004027BB
    call  eax
end;

class procedure TCiv2.DrawString(ChText: PChar; Left, Top: Integer);
asm
    push  Top
    push  Left
    push  ChText
    mov   eax, $00401E0B
    call  eax
    add   esp, $0C
end;

class procedure TCiv2.DrawStringRight(ChText: PChar; Right, Top, Shift: Integer);
asm
    push  Shift
    push  Top
    push  Right
    push  ChText
    mov   eax, $00403607
    call  eax
    add   esp, $10
end;

class procedure TCiv2.RedrawMap(); register;
asm
    push  1
    push  [$006D1DA0]
    mov   ecx, $0066C7A8
    mov   eax, A_j_Q_RedrawMap_sub_47CD51
    call  eax
end;

class procedure TCiv2.sub_5C0D12(ThisGraphicsInfo: PGraphicsInfo; Palette: Pointer);
asm
//
//    if ( Q_Pallete_GetID_sub_5C56F0(a2) != this->PrevPaletteID )
//    {
//      Q_SetDIBColorTableFromPalette_sub_5E3BDC(v2->Unknown2d_DrawInfo, a2);
//      v2->PrevPaletteID = Q_Pallete_GetID_sub_5C56F0(a2);
//    }
    push  Palette
    mov   ecx, ThisGraphicsInfo
    mov   eax, $005C0D12
    call  eax
end;

class procedure TCiv2.SetDIBColorTableFromPalette(DrawInfo: PDrawInfo; Palette: Pointer);
asm
    push  Palette
    push  DrawInfo
    mov   eax, $005E3BDC
    call  eax
    add   esp, 8
end;

class procedure TCiv2.Palette_SetRandomID(Palette: Pointer);
asm
    mov   ecx, Palette
    mov   eax, $005C6A42
    call  eax
end;

class procedure TCiv2.SetTextIntToStr(A1: Integer);
asm
    push  A1
    mov   eax, $00401ED8
    call  eax
    add   esp, 4
end;

class procedure TCiv2.SetTextFromLabel(A1: Integer);
asm
// A1 + 0x11 = Line # in Labels.txt
    push  A1
    mov   eax, $0040BC10
    call  eax
    add   esp, 4
end;

class function TCiv2.DrawInfoCreate(A1: PRect): PDrawInfo;
asm
    push  A1
    mov   eax, $005E35B0
    call  eax
    add   esp, 4
end;

class procedure TCiv2.PopupSimpleMessage(A1, A2, A3: Integer);
asm
    push  A3
    push  A2
    push  A1
    mov   eax, $00410030
    call  eax
    add   esp, $0C
end;

class function TCiv2.ScreenToMap(var MapX, MapY: Integer; ScreenX, ScreenY: Integer): LongBool;
asm
    push  ScreenY
    push  ScreenX
    push  MapY
    push  MapX
    mov   ecx, MapGraphicsInfo
    mov   eax, A_j_Q_ScreenToMap_sub_47A540
    call  eax
    mov   @Result, eax
end;

class function TCiv2.GetCityIndexAtXY(X, Y: Integer): Integer;
asm
    push  Y
    push  X
    mov   eax, $0043CF76
    call  eax
    add   esp, 8
    mov   @Result, eax
end;

class procedure TCiv2.MapToWindow(var WindowX, WindowY: Integer; MapX, MapY: Integer);
asm
    push  MapY
    push  MapX
    push  WindowY
    push  WindowX
    mov   ecx, MapGraphicsInfo
    mov   eax, $0047A6B0
    call  eax
end;

class function TCiv2.GetStringInList(StringIndex: Integer): PChar;
asm
    push  StringIndex
    mov   eax, $00403387
    call  eax
    add   esp, 4
end;

end.


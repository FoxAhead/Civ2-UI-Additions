unit Civ2Proc;

interface

uses
  Civ2Types,
  Windows;

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

end.

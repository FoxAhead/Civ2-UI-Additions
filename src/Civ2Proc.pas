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
    class function CreateScrollbar(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll;
    class procedure DestroyScrollBar(ControlInfoScroll: PControlInfoScroll; Flag: LongBool);
  published
  end;

implementation

{ TCiv2 }

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

end.


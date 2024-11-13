unit UiaPatchArrangeWindows;

interface

uses
  UiaPatch;

type
  TUiaPatchArrangeWindows = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

var
  ArrangeWindowMiniMapWidth: Integer = -1;

implementation

uses
  Math,
  Windows,
  Civ2Proc,
  Civ2UIA_Proc;

procedure PatchSetWinRectMiniMapEx(var Width, Height: Integer); stdcall;
var
  Scale: Integer;
  MaxScale: Integer;
  R: TRect;
begin
  if ArrangeWindowMiniMapWidth > 0 then
  begin
    Width := ArrangeWindowMiniMapWidth;
    GetClientRect(Civ2.MainWindowInfo.WindowStructure.HWindow, R);
    MaxScale := RectHeight(R) div 5 div Civ2.MapHeader.SizeY;
    Scale := Max(Min(Width div Civ2.MapHeader.SizeX, MaxScale), 1);
    Height := Scale * Civ2.MapHeader.SizeY;
  end;
end;

procedure PatchSetWinRectMiniMap(); register;
asm
    lea   eax, [ebp - $14] // int vHeight
    push  eax
    lea   eax, [ebp - $10] // int vWidth
    push  eax
    call  PatchSetWinRectMiniMapEx
    mov   eax, [$0063359C] // int V_CaptionLeft_dword_63359C
    push  $004078DC
    ret
end;

{ TUiaPatchArrangeWindows }

procedure TUiaPatchArrangeWindows.Attach(HProcess: Cardinal);
begin
  // Arrange windows
  WriteMemory(HProcess, $004078D7, [OP_JMP], @PatchSetWinRectMiniMap);

end;

initialization
  TUiaPatchArrangeWindows.RegisterMe();

end.

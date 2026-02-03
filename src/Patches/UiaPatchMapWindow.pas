unit UiaPatchMapWindow;

interface

uses
  UiaPatch;

type
  TUiaPatchMapWindow = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Windows,
  Civ2Types,
  Civ2Proc,
  UiaMain;

const
  LowMapZoom: Byte = $FA;

procedure PatchCopyToScreenBitBlt(SrcDI: PDrawInfo; XSrc, YSrc, Width, Height: Integer; DestWS: PWindowStructure; XDest, YDest: Integer); cdecl;
begin
  if SrcDI <> nil then
  begin
    if DestWS <> nil then
    begin
      if (DestWS.Palette <> 0) and (PInteger($00638B48)^ = 1) then // V_PaletteBasedDevice_dword_638B48
        RealizePalette(DestWS.DeviceContext);
      if not Uia.MapOverlay.CopyToScreenBitBlt(SrcDI, DestWS) then
        BitBlt(DestWS.DeviceContext, XDest, YDest, Width, Height, SrcDI.DeviceContext, XSrc, YSrc, SRCCOPY);
    end;
  end;
end;

// Extend vertical map overscroll
procedure PatchCalcMapRectTopEx(MapWindow: PMapWindow); stdcall;
begin
  if MapWindow.MapRect.Top + 2 * MapWindow.MapHalf.cy > PWord($006D1162)^ + 2 then
  begin
    MapWindow.MapRect.Top := PWord($006D1162)^ + 2 - 2 * MapWindow.MapHalf.cy;
  end;
end;

procedure PatchCalcMapRectTop(); register;
asm
    push  [ebp - $28] // P_MapWindow this
    call  PatchCalcMapRectTopEx
    push  $0047A334
    ret
end;

procedure PatchMapKey1Ex(Dir: Integer); stdcall;
begin
  if Dir >= 0 then
    if Civ2.UnitSelected^ then
    begin
      if (Civ2.Game.ActiveUnitIndex >= 0) and (Civ2.Game.ActiveUnitIndex < Civ2.Game.TotalUnits) then
        if Civ2.Units[Civ2.Game.ActiveUnitIndex].ID <> 0 then
          Civ2.MoveUnit(Civ2.Game.ActiveUnitIndex, Dir, 3);
    end
    else
      Civ2.MoveCursor(Dir);
end;

procedure PatchMapKey1(); register;
asm
    push  [ebp - $04] // aDir
    call  PatchMapKey1Ex
    push  $00413189
    ret
end;

{ TUiaPatchMapWindow}

procedure TUiaPatchMapWindow.Attach(HProcess: Cardinal);
begin
  // Map Overlay
  WriteMemory(HProcess, $005C0A2F, [OP_CALL], @PatchCopyToScreenBitBlt);

  // Extend vertical map overscroll
  WriteMemory(HProcess, $0047A2F2, [OP_JMP], @PatchCalcMapRectTop);

  // MapZoom: keep details on lower zoom levels
  WriteMemory(HProcess, $0047ABA4 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047AD3F + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047AE85 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B004 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B092 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B1C1 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B20A + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B279 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B572 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B794 + 3, [LowMapZoom]);

  // Allow to move white cursor even without active unit
  WriteMemory(HProcess, $00413105, [OP_JMP], @PatchMapKey1);
end;

initialization
  TUiaPatchMapWindow.RegisterMe();

end.

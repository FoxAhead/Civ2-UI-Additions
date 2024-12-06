unit UiaPatchCityWindow;

interface

uses
  Civ2Types,
  Civ2UIA_SortedUnitsList,
  UiaPatch;

type
  TUiaPatchCityWindow = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

  TCityWindowExSupport = record
    ControlInfoScroll: TControlInfoScroll;
    ListTotal: Integer;
    ListStart: Integer;
    Counter: Integer;
    Columns: Integer;
    SortedUnitsList: TSortedUnitsList;
  end;

  TCityWindowExResourceMap = record
    CityIndex: Integer;
    ShowTile: Boolean;
    DX: Integer;
    DY: Integer;
    Tile: array[0..2] of Integer;
  end;

  TCityWindowEx = record
    Support: TCityWindowExSupport;
    ResMap: TCityWindowExResourceMap;
    ChangeSpecialistDown: Boolean;
  end;

var
  CityWindowEx: TCityWindowEx;

implementation

uses
  Graphics,
  Math,
  SysUtils,
  Types,
  Windows,
  UiaMain,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_FormConsole;

procedure ChangeSpecialistUpOrDown(var SpecialistType: Integer); stdcall;
begin
  if CityWindowEx.ChangeSpecialistDown then
    Dec(SpecialistType)
  else
    Inc(SpecialistType);
  if SpecialistType > 3 then
    SpecialistType := 1;
  if SpecialistType < 1 then
    SpecialistType := 3;
end;

procedure PatchCallChangeSpecialist; register;
asm
    lea   eax, [ebp - $0C]
    push  eax
    call  ChangeSpecialistUpOrDown
    push  $00501990
    ret
end;

procedure CallBackCityWindowSupportScroll(A1: Integer); cdecl;
begin
  CityWindowEx.Support.ListStart := A1;
  Civ2.CityWindow_DrawSupport(Civ2.CityWindow, True);
end;

function PatchDrawCityWindowSupportEx1(CityWindow: PCityWindow; SupportedUnits, Rows, Columns: Integer; var DeltaX: Integer): Integer; stdcall;
begin
  CityWindowEx.Support.Counter := 0;
  if SupportedUnits > Rows * Columns then
  begin
    DeltaX := DeltaX - CityWindow.WindowSize;
  end;
  if CityWindowEx.Support.SortedUnitsList <> nil then
    CityWindowEx.Support.SortedUnitsList.Free();
  CityWindowEx.Support.SortedUnitsList := TSortedUnitsList.Create(CityWindow.CityIndex);
  Result := CityWindowEx.Support.SortedUnitsList.GetNextIndex(0);
end;

procedure PatchDrawCityWindowSupport1; register;
asm
// Before loop 'for ( i = 0; ; ++i )'
    lea   eax, [ebp - $44] // vDeltaX
    push  eax
    mov   eax, [ebp - $14] // vColumns
    push  eax
    mov   eax, [ebp - $24] // vRows
    push  eax
    mov   eax, [ebp - $3C] // vSupportedUnits
    push  eax
    mov   eax, [ebp - $C0] // vCityWindow
    push  eax
    call  PatchDrawCityWindowSupportEx1
    mov   [ebp - $6C], eax
    push  $0050598F
    ret
end;

function PatchDrawCityWindowSupportEx1a(): Integer; stdcall;
begin
  // Get next i from UnitsList
  Result := CityWindowEx.Support.SortedUnitsList.GetNextIndex(1);
end;

procedure PatchDrawCityWindowSupport1a(); register;
asm
// Instead of ++i
    call  PatchDrawCityWindowSupportEx1a;
    mov   [ebp - $6C], eax
    push  $0050598F
    ret
end;

function PatchDrawCityWindowSupportEx2(Columns: Integer): LongBool; stdcall;
begin
  CityWindowEx.Support.Counter := CityWindowEx.Support.Counter + 1;
  Result := ((CityWindowEx.Support.Counter - 1) div Columns) >= CityWindowEx.Support.ListStart;
end;

procedure PatchDrawCityWindowSupport2; register;
asm
// In loop, if ( stru_6560F0[i].HomeCity == vCityWindow->CityIndex )
    mov   eax, [ebp - $14] // vColumns
    push  eax
    call  PatchDrawCityWindowSupportEx2
    cmp   eax, 0
    jne   @@LABEL_CAN_SHOW
    push  $005059D7
    ret

@@LABEL_CAN_SHOW:
    push  $005059DC
    ret
end;

procedure PatchDrawCityWindowSupportEx3(SupportedUnits, Rows, Columns: Integer); stdcall;
begin
  CityWindowEx.Support.ListTotal := SupportedUnits;
  CityWindowEx.Support.Columns := Columns;
  Civ2.Scroll_InitControlRange(@CityWindowEx.Support.ControlInfoScroll, 0, Math.Max(0, (SupportedUnits - 1) div Columns) - Rows + 1);
  Civ2.Scroll_SetPageSize(@CityWindowEx.Support.ControlInfoScroll, 4);
  Civ2.Scroll_SetPosition(@CityWindowEx.Support.ControlInfoScroll, CityWindowEx.Support.ListStart);
  if SupportedUnits <= Rows * Columns then
    ShowWindow(CityWindowEx.Support.ControlInfoScroll.ControlInfo.HWindow, SW_HIDE);
end;

procedure PatchDrawCityWindowSupport3; register;
asm
// After loop 'for ( i = 0; ; ++i )'
    mov   eax, [ebp - $14] // vColumns
    push  eax
    mov   eax, [ebp - $24] // vRows
    push  eax
    mov   eax, [ebp - $3C] // vSupportedUnits
    push  eax
    call  PatchDrawCityWindowSupportEx3
    push  $00505D10
    ret
end;

function PatchCityWindowInitRectangles(): LongBool; stdcall; // __thiscall
var
  ACityWindow: PCityWindow;
  ScrollBarWidth: Integer;
  ThisResult: LongBool;
begin
  asm
    mov   ACityWindow, ecx;
    mov   eax, $00508D24 // Q_CityWindowInitRectangles_sub_508D24
    call  eax
    mov   ThisResult, eax
  end;

  Civ2.Scroll_DestroyBar(@CityWindowEx.Support.ControlInfoScroll, False);

  case ACityWindow.WindowSize of
    1:
      ScrollBarWidth := 10;
    2:
      ScrollBarWidth := 16;
  else
    ScrollBarWidth := 16;
  end;

  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect := ACityWindow.RectSupportOut;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Left := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Right - ScrollBarWidth - 1;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Top := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Top + 1;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Bottom := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Bottom - 1;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Right := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Right - 1;

  Civ2.Scroll_CreateControl(@CityWindowEx.Support.ControlInfoScroll, @PGraphicsInfo(ACityWindow).WindowInfo, $62, @CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect, True);
  CityWindowEx.Support.ControlInfoScroll.ProcRedraw := @CallBackCityWindowSupportScroll;
  CityWindowEx.Support.ControlInfoScroll.ProcTrack := @CallBackCityWindowSupportScroll;

  CityWindowEx.Support.ListStart := 0;

  // CaptionHeight
  case ACityWindow.WindowSize of
    1:
      ACityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.CaptionHeight := 19;
    3:
      ACityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.CaptionHeight := 37;
  else
    ACityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.CaptionHeight := 25;
  end;

  Result := ThisResult;
end;

function PatchCalcCitizensSpritesStart(ClickWidth, DummyEDX: Integer; CityWindow: PCityWindow; Size: Integer): Integer; register;
begin
  Result := (CityWindow.WindowSize * (Size + $E) - ClickWidth) div 2 - 1;
end;

procedure GetResMapDXDY(X, Y: Integer; var DX, DY: Integer);
var
  v11, v10, vX, vY, v15: Integer;
begin
  DX := 1000;
  DY := 1000;
  // Code from Q_CityResourcesClicked_sub_5022C0
  v11 := Civ2.ScaleByZoom($40, Civ2.CityWindow.Zoom);
  v10 := Civ2.ScaleByZoom($20, Civ2.CityWindow.Zoom);
  vX := X - (Civ2.CityWindow_ScaleWithSize(Civ2.CityWindow, 5) + Civ2.CityWindow.RectResources.Left);
  vY := Y - ((v10 shr 1) + Civ2.CityWindow_ScaleWithSize(Civ2.CityWindow, $B) + Civ2.CityWindow.RectResources.Top);
  if (vX >= 0) and (4 * v11 > vX) and (vY >= 0) and (4 * v10 > vY) then
  begin
    DX := 2 * (vX div v11) - 3;
    DY := 2 * (vY div v10) - 3;
    vX := vX mod v11;
    vY := vY mod v10;

    if (vX >= 0) and (vY >= 0) then
    begin
      v15 := (Civ2.DrawPort_GetPixel(Pointer($6A9120), vX, vY) - $A) shr 4;
    end
    else
    begin
      v15 := 0;
    end;

    if v15 <> 0 then
    begin
      DX := DX + PShortIntArray($62833B)[v15];
      DY := DY + PShortIntArray($628343)[v15];
    end;
  end;
end;

procedure UpdateCityWindowExResMap(DX, DY: Integer);
var
  SpiralIndex, i, MapX, MapY: Integer;
  City: PCity;
  Visible: Boolean;
begin
  CityWindowEx.ResMap.DX := DX;
  CityWindowEx.ResMap.DY := DY;
  SpiralIndex := -1;
  if (DX <> 1000) and (DY <> 1000) then
    for i := 0 to 20 do
      if (Civ2.CitySpiralDX[i] = DX) and (Civ2.CitySpiralDY[i] = DY) then
      begin
        SpiralIndex := i;
        Break;
      end;
  CityWindowEx.ResMap.CityIndex := Civ2.CityWindow.CityIndex;
  CityWindowEx.ResMap.ShowTile := (SpiralIndex >= 0);
  if SpiralIndex >= 0 then
  begin
    City := @Civ2.Cities[Civ2.CityWindow.CityIndex];
    MapX := Civ2.MapWrapX(City.X + DX);
    MapY := City.Y + DY;
    if not Civ2.MapSquareIsVisibleTo(MapX, MapY, City.Owner) then
      CityWindowEx.ResMap.ShowTile := False;
  end;
  for i := 0 to 2 do
    if CityWindowEx.ResMap.ShowTile then
      CityWindowEx.ResMap.Tile[i] := Civ2.GetResourceInCityTile(Civ2.CityWindow.CityIndex, SpiralIndex, i)
    else
      CityWindowEx.ResMap.Tile[i] := 0;
end;

function PatchDrawCityWindowTopWLTKDEx(j: Integer): Integer; stdcall;
var
  HalfCitySize: Integer;
begin
  HalfCitySize := Civ2.Cities[j].Size div 2;
  if (Civ2.Cities[j].UnHappyCitizens = 0) and ((Civ2.Cities[j].Size - Civ2.Cities[j].HappyCitizens) <= HalfCitySize) then
    Result := $72                         // Yellow
  else if (Civ2.Cities[j].HappyCitizens < Civ2.Cities[j].UnHappyCitizens) then
    Result := $6A                         // Red
  else
    Result := $7C;
end;

procedure PatchDrawCityWindowTopWLTKD(); register;
asm
    mov   eax, [ebp - $2C] // P_CityWindow
    push  [eax + $159C]    // T_CityWindow->CityIndex
    call  PatchDrawCityWindowTopWLTKDEx
    push  $01        // 0x00502109 - Restore overwritten call
    push  $01
    push  $12
    push  eax
    push  $00502111  // call    Q_SetFontColorWithShadow_sub_403BB6
    ret
end;

procedure PatchDrawCityWindowTop2Ex(CityWindow: PCityWindow); stdcall;
var
  Canvas: TCanvasEx;
  City: PCity;
  TextOut: string;
  Color1: Integer;
  R1: TRect;
  P1: TPoint;
  Height: Integer;
begin
  //  PWindowInfo(Pointer($6359C4)^) := @CityWindow.MSWindow.GraphicsInfo.WindowInfo; // Move to ShowCityWindow and Cler after CityWindowClose

  City := @Civ2.Cities[CityWindow.CityIndex];
  TextOut := IntToStr(City.Size);
  Color1 := Civ2.GetCivColor1(City.Owner);
  R1 := CityWindow.RectCitizens;
  R1 := Bounds(R1.Left, R1.Top, 17, 16);

  Height := 11;
  case CityWindow.WindowSize of
    1:
      Height := 7;
    2:
      Height := 11;
    3:
      Height := 16;
  end;

  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);

  //  if Height > 7 then
  //    Canvas.Font.Name := 'Arial'
  //  else
  //    Canvas.Font.Name := 'Small Fonts';

  Canvas.Font.Name := 'Arial';
  Canvas.Font.Height := -Height;

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := Canvas.ColorFromIndex(10);
  Canvas.Brush.Style := bsClear;
  Canvas.Brush.Color := Canvas.ColorFromIndex(Color1);
  //R1 := Bounds(R1.Left, R1.Top, Canvas.TextWidth(TextOut) + 4, Canvas.TextHeight(TextOut));
  R1 := Bounds(R1.Left, R1.Top, Canvas.TextWidth(TextOut) + 4, Height + 3);
  Canvas.Rectangle(R1);

  Canvas.Pen.Style := psClear;
  Canvas.Brush.Style := bsClear;

  P1 := CenterPoint(R1);
  Canvas.MoveTo(P1.X, P1.Y);
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);
  if CityWindow.WindowSize > 1 then
  begin
    Canvas.MoveTo(P1.X + 1, P1.Y);
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);
  end;

  Canvas.Free;
end;

procedure PatchDrawCityWindowTop2(); register;
asm
    mov   eax, [ebp - $2C] // P_CityWindow
    push  eax
    call  PatchDrawCityWindowTop2Ex
    cmp   [ebp + 8], 0               // cmp     [ebp+aCopyToScreen], 0
    jz    @@LABEL_loc_5022B4         // jz      loc_5022B4
    push  $005022A3
    ret

@@LABEL_loc_5022B4:
    push  $005022B4
    ret
end;

procedure PatchDrawCityWindowResources2Ex(CityWindow: PCityWindow); stdcall;
const
  DX                                      : array[1..3, 0..2] of Integer = ((0, 0, 0), // WindowSize = 1
    (3, 2, 0),                            // WindowSize = 2
    (4, 2, 1)                             // WindowSize = 3
    );
var
  i, W1, W2: Integer;
  DX1, DY, DX2: Integer;
  Canvas: TCanvasEx;
  Text: string;
begin
  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.PenOrigin := Point(CityWindow.RectResourceMap.Left + 1, CityWindow.RectResourceMap.Top);
  Canvas.PenReset();
  Canvas.SetSpriteZoom(4 * CityWindow.WindowSize - 8);
  Canvas.Font.Handle := CopyFont(CityWindow.FontInfo.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(124, 57);
  Canvas.FontShadows := SHADOW_BR;
  DY := CityWindow.WindowSize;
  // Total map resources
  for i := 0 to 2 do
  begin
    DX1 := -CityWindow.WindowSize * (i mod 2);
    DX2 := DX[CityWindow.WindowSize][i];
    Canvas.TextOutWithShadows(IntToStr(Uia.CityGlobalsEx.TotalMapRes[i])).CopySprite(@Civ2.SprResS[i], DX1, DY).PenDX(DX2);
  end;
  // Resources from one tile
  if CityWindowEx.ResMap.CityIndex <> Civ2.CityWindow.CityIndex then
    UpdateCityWindowExResMap(CityWindowEx.ResMap.DX, CityWindowEx.ResMap.DY);

  if CityWindowEx.ResMap.ShowTile then
  begin
    Text := Format('%d%d%d', [Uia.CityGlobalsEx.TotalMapRes[0], Uia.CityGlobalsEx.TotalMapRes[1], Uia.CityGlobalsEx.TotalMapRes[2]]);
    W1 := Canvas.TextWidth(Text);
    Text := Format('%d%d%d', [CityWindowEx.ResMap.Tile[0], CityWindowEx.ResMap.Tile[1], CityWindowEx.ResMap.Tile[2]]);
    W2 := Canvas.TextWidth(Text);
    W2 := Canvas.PenPos.X - Canvas.PenOrigin.X - W1 + W2;
    Canvas.PenX(CityWindow.RectResourceMap.Right - 1 - W2);
    for i := 0 to 2 do
    begin
      DX1 := -CityWindow.WindowSize * (i mod 2);
      DX2 := DX[CityWindow.WindowSize][i];
      Canvas.TextOutWithShadows(IntToStr(CityWindowEx.ResMap.Tile[i])).CopySprite(@Civ2.SprResS[i], DX1, DY).PenDX(DX2);
    end;
  end;
  Canvas.Free();
end;

procedure PatchDrawCityWindowResources2(); register;
asm
    mov   eax, Civ2
    call  TCiv2[eax].ResetSpriteZoom
    push  [ebp - $20C] // vCityWindow
    call  PatchDrawCityWindowResources2Ex
    push  $00504BD8
    ret
end;

procedure PatchCalcCityGlobalsResourcesEx(); stdcall;
begin
  Uia.CityGlobalsEx.TotalMapRes[0] := Civ2.CityGlobals.TotalRes[0];
  Uia.CityGlobalsEx.TotalMapRes[1] := Civ2.CityGlobals.TotalRes[1];
  Uia.CityGlobalsEx.TotalMapRes[2] := Civ2.CityGlobals.TotalRes[2];
end;

procedure PatchCalcCityGlobalsResources(); register;
asm
    call  PatchCalcCityGlobalsResourcesEx
    push  $004E9714
    ret
end;

procedure PatchCalcCityEconomicsTradeRouteLevelEx(i, Level: Integer); stdcall;
begin
  Uia.CityGlobalsEx.TradeRouteLevel[i] := Level;
end;

procedure PatchCalcCityEconomicsTradeRouteLevel(); register;
asm
    push  [ebp - $10] // vLevel
    push  [ebp - $04] // i
    call  PatchCalcCityEconomicsTradeRouteLevelEx
    push  $004EA9AE
    ret
end;

procedure PatchDrawCityWindowUnitsPresentEx(i, X, Y: Integer); stdcall;
var
  j: Integer;
begin
  Civ2.ChText^ := #00;
  if Uia.CityGlobalsEx.TradeRouteLevel[i] > 0 then
  begin
    for j := 0 to Uia.CityGlobalsEx.TradeRouteLevel[i] - 1 do
    begin
      StrCat(Civ2.ChText, '+');
    end;
    Civ2.DrawStringCurrDrawPort2(Civ2.ChText, X, Y);
  end;
end;

procedure PatchDrawCityWindowUnitsPresent(); register;
asm
    push  [ebp - $70]            // yTop
    push  TRect[ebp - $84].Right // Rect.Right after drawing trade sprite
    push  [ebp - $2C]            // i - trade route #
    call  PatchDrawCityWindowUnitsPresentEx
    mov   eax, Civ2              // Restore
    call  TCiv2[eax].ResetSpriteZoom
    push  $00507ACA
    ret
end;

procedure PatchWndProcCityWindowMouseMove(X, Y: Integer); cdecl;
var
  DX, DY: Integer;
  SpiralIndex, i: Integer;
begin
  GetResMapDXDY(X, Y, DX, DY);
  if (CityWindowEx.ResMap.DX <> DX) or (CityWindowEx.ResMap.DY <> DY) then
  begin
    UpdateCityWindowExResMap(DX, DY);
    Civ2.CityWindow_DrawResources(Civ2.CityWindow, True);
  end;
end;

procedure PatchCreateCityWindowEx(CityWindow: PCityWindow); stdcall;
var
  Style: Cardinal;
begin
  CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcMouseMove := @PatchWndProcCityWindowMouseMove;
end;

procedure PatchCreateCityWindow(); register;
asm
    push  [ebp - $04] // CityWindow
    call  PatchCreateCityWindowEx
    push  $0050DEA3
    ret
end;

procedure PatchDrawCityWindowBuildingEx(CityWindow: PCityWindow; Rect: PRect); stdcall;
var
  Canvas: TCanvasEx;
  CityBuildInfo: TCityBuildInfo;
  Text: string;
begin
  GetCityBuildInfo(CityWindow.CityIndex, CityBuildInfo);
  Text := ConvertTurnsToString(CityBuildInfo.TurnsToBuild, $21);
  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.Font.Handle := CopyFont(CityWindow.FontInfo.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(74, 10);
  Canvas.FontShadows := SHADOW_ALL;
  Canvas.MoveTo(Rect.Right, Rect.Bottom);
  Canvas.TextOutWithShadows(Text, 0, 0, DT_RIGHT or DT_BOTTOM);
  Canvas.Free();
end;

procedure PatchDrawCityWindowBuilding(); register;
asm
    mov   eax, Civ2
    call  TCiv2[eax].ResetSpriteZoom  // Restore
    lea   eax, [ebp - $10] // vRect
    push  eax
    push  [ebp - $6C] // vCityWindow
    call  PatchDrawCityWindowBuildingEx
    push  $005055B1
    ret
end;

procedure PatchCityResourcesClicked(); register;
asm
    mov   eax, Civ2
    push  1
    push  TCiv2[eax].CityWindow
    call  TCiv2[eax].CityWindow_DrawBuilding
    push  $005025D0
    ret
end;

procedure PatchCityResourcesClicked2Ex(RButton: Integer); stdcall;
var
  i: Integer;
begin
  if RButton = 0 then
    Civ2.Cities[Civ2.CityWindow.CityIndex].Workers := 0
  else
    for i := 0 to 19 do
    begin
      Civ2.SetWorker(Civ2.CityWindow.CityIndex, i, False);
      Inc(Civ2.Cities[Civ2.CityWindow.CityIndex].Workers, $4000000);
    end;
end;

procedure PatchCityResourcesClicked2(); register;
asm
    mov   eax, [ebp]
    push  [eax + $10]
    call  PatchCityResourcesClicked2Ex
    push  $005025BF
    ret
end;

function PatchMapAscii1Ex(Key: Char): Integer; stdcall;
begin
  if (Civ2.LockCityWindow^ = 0) or ((Key = 'c') and (Civ2.Game.MultiType = 0)) then
    Result := $00412058
  else
    Result := $00412015;
end;

procedure PatchMapAscii1(); register;
asm
    push  [ebp + $08] // a1
    call  PatchMapAscii1Ex
    push  eax
    ret
end;

function PatchMapKey1Ex(Key: Integer): Integer; stdcall;
begin
  if (Civ2.LockCityWindow^ = 0) or ((Civ2.Game.MultiType = 0) and ((Key = $43) or (Key = $100))) then
    Result := $004127EB
  else
    Result := $0041279C;
end;

procedure PatchMapKey1(); register;
asm
    push  [ebp + $08] // a1
    call  PatchMapKey1Ex
    push  eax
    ret
end;

procedure PatchWarningCITYMODALEx(); stdcall;
begin
  Civ2.WindowInfo1_SetFocusAndBringToTop(@Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1);
end;

procedure PatchWarningCITYMODAL(); register;
asm
    call  PatchWarningCITYMODALEx
    push  $0050142F
    ret
end;

procedure PatchCitywinCityButtonChange(DummyEAX, DummyEDX: Integer; This: PDialogWindow; SectionName: PChar); register;
begin
  Civ2.Dlg_LoadGAMESimpleL0(This, SectionName, CIV2_DLG_HAS_CANCEL_BUTTON);
end;

procedure PatchCitywinCityMouseImprovements(SectionName: PChar; Improvement, Zoom: Integer); cdecl;
begin
  Civ2.PopupWithImprovementSprite('GAME', SectionName, CIV2_DLG_HAS_CANCEL_BUTTON, Improvement, Zoom);
end;

procedure PatchCitywinCityButtonChangeBeforeEx(); stdcall;
begin
  // Reset City window mouse buttons flags
  Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.LButtonDown := 0;
  Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.RButtonDown := 0;
end;

procedure PatchCitywinCityButtonChangeBefore(); register;
asm
    call  PatchCitywinCityButtonChangeBeforeEx
    push  $8000 // (Overwritten opcodes)
    push  $0050A499
    ret
end;

procedure PatchFocusCityWindow(); stdcall; // __thiscall
var
  ACityWindow: PCityWindow;
  HWindow: HWND;
begin
  asm
    mov   ACityWindow, ecx
    mov   eax, $004085F0
    call  eax
  end;
  HWindow := ACityWindow^.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow;
  if Uia.GuessWindowType(HWindow) = wtCityWindow then
  begin
    //SetFocus(HWindow);
    asm
    push  HWindow
    call  [$006E7D94]
    end;
  end;
end;

function PatchCityWndProcCloseAfter(): Integer; stdcall;
begin
  Result := 0;
  // If there is some Advisor opened
  if Civ2.AdvisorWindow.AdvisorType > 0 then
  begin
    // Then focus and bring it to top
    Civ2.WindowInfo1_SetFocusAndBringToTop(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1);
  end;
  // Reset tile resources info
  CityWindowEx.ResMap.CityIndex := -1;
  CityWindowEx.ResMap.DX := 1000;
end;

procedure PatchStrcatBuildingCost(Cost, Done: Integer); cdecl;
var
  P: PChar;
  Text, TurnsToBuildString: string;
  RealCost: Integer;
begin
  RealCost := Cost * Civ2.CityGlobals.ShieldsInRow;
  P := StrEnd(Civ2.ChText) - 1;
  if P^ = '(' then
    P^ := #00;
  TurnsToBuildString := ConvertTurnsToString(GetTurnsToBuild(RealCost, Done), $22);
  Text := Format('%s%d#644F00:3# (%s', [Civ2.ChText, RealCost, TurnsToBuildString]);
  StrPCopy(Civ2.ChText, Text);
end;

procedure PatchCityChangeListImprovementMaintenanceEx(CivIndex, j: Integer); stdcall;
var
  Upkeep: Integer;
  Text: string;
begin
  //  Upkeep := Civ2.Improvements[j].Upkeep;
  Upkeep := Civ2.GetUpkeep(CivIndex, j);
  if Upkeep >= 0 then
  begin
    Text := string(Civ2.ChText);
    Text := Text + ', ' + IntToStr(Upkeep) + '#648860:1#';
    StrPCopy(Civ2.ChText, Text);
  end;
  StrCat(Civ2.ChText, ')');
end;

procedure PatchCityChangeListImprovementMaintenance(); register;
asm
    push  [ebp - $958] // int j
    push  [ebp - $95C] // int vOwner
    call  PatchCityChangeListImprovementMaintenanceEx
    push  $0050AD85
    ret
end;

procedure PatchCityWindowDrawResourcesEx(CityWindow: PCityWindow); stdcall;
var
  HomeUnits: Integer;
  i: Integer;
  Text: string;
begin
  HomeUnits := 0;
  for i := 0 to Civ2.Game^.TotalUnits - 1 do
  begin
    if Civ2.Units[i].ID > 0 then
      if Civ2.Units[i].HomeCity = CityWindow^.CityIndex then
        HomeUnits := HomeUnits + 1;
  end;
  if HomeUnits > 0 then
  begin
    Text := string(Civ2.ChText);
    Text := Text + ' / ' + IntToStr(HomeUnits);
    StrCopy(Civ2.ChText, PChar(Text));
  end;
end;

procedure PatchCityWindowDrawResources; register;
asm
// Before call    j_Q_DrawStringCurrDrawPort2_sub_43C8D0
    push  [ebp - $20C] // CityWindow
    call  PatchCityWindowDrawResourcesEx
    push  $00401E0B
    ret
end;

procedure FocusCityWindowIfNotHidden(); stdcall;
begin
  if not Civ2.CityWindow.Hidden then
    Civ2.SetFocus(Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow);
end;

procedure PatchCitywinCityButtonAfter(); register;
asm
    mov   large fs:0, eax // Restored
    call  FocusCityWindowIfNotHidden
end;

{ TUiaPatchCityWindow }

procedure TUiaPatchCityWindow.Attach(HProcess: Cardinal);
begin
  // CityWindow
  WriteMemory(HProcess, $00501940, [], @PatchCallChangeSpecialist);
  WriteMemory(HProcess, $004013A2, [OP_JMP], @PatchCityWindowInitRectangles); // Init ScrollBars and CaptionHeight
  WriteMemory(HProcess, $00505987, [OP_JMP], @PatchDrawCityWindowSupport1); // Add scrollbar, sort units list
  WriteMemory(HProcess, $005059B2, [OP_JMP], @PatchDrawCityWindowSupport1a);
  WriteMemory(HProcess, $005059D7, [OP_JMP], @PatchDrawCityWindowSupport1a);
  WriteMemory(HProcess, $00505D0B, [OP_JMP], @PatchDrawCityWindowSupport1a);
  WriteMemory(HProcess, $005059D1 + 2, [], @PatchDrawCityWindowSupport2);
  WriteMemory(HProcess, $00505999 + 2, [], @PatchDrawCityWindowSupport3);
  WriteMemory(HProcess, $00505D06, [OP_JMP], @PatchDrawCityWindowSupport3);

  // Correct Citizens CitySprites bounds
  WriteMemory(HProcess, $00502203, [OP_CALL], @PatchCalcCitizensSpritesStart);

  // Change color in City Window for We Love The King Day
  WriteMemory(HProcess, $00502109, [OP_JMP], @PatchDrawCityWindowTopWLTKD);

  // Draw city size
  WriteMemory(HProcess, $00502299, [OP_JMP], @PatchDrawCityWindowTop2);

  // Draw total tiles resources
  WriteMemory(HProcess, $00504BD3, [OP_JMP], @PatchDrawCityWindowResources2);

  // CityGlobalsEx: Remember total tiles resources before additional multiplications
  WriteMemory(HProcess, $004E970A, [OP_JMP], @PatchCalcCityGlobalsResources);

  // CityGlobalsEx: Remember Trade Route Level
  WriteMemory(HProcess, $004EAB58, [OP_JMP], @PatchCalcCityEconomicsTradeRouteLevel);
  // Draw Trade Route Level
  WriteMemory(HProcess, $00507AC5, [OP_JMP], @PatchDrawCityWindowUnitsPresent);

  // After CreateCityWindow - add ProcMouseMove
  WriteMemory(HProcess, $0050DE9E, [OP_JMP], @PatchCreateCityWindow);

  // Show turns left to complete building
  WriteMemory(HProcess, $005055AC, [OP_JMP], @PatchDrawCityWindowBuilding);

  // Update RectangleBuilding after CityResourcesClicked
  WriteMemory(HProcess, $005025CB, [OP_JMP], @PatchCityResourcesClicked);

  // Right Click on center tile removes all workers
  WriteMemory(HProcess, $005024CA, [OP_JMP], @PatchCityResourcesClicked2);

  // In CityModal mode allow to press 'C'
  WriteMemory(HProcess, $00412008, [OP_JMP], @PatchMapAscii1);
  WriteMemory(HProcess, $0041278F, [OP_JMP], @PatchMapKey1);

  // Focus CityWindow after warning CITYMODAL
  WriteMemory(HProcess, $0050141F + 2, [], @PatchWarningCITYMODAL);

  // Add Cancel button to City Change list
  WriteMemory(HProcess, $0050AA86, [OP_CALL], @PatchCitywinCityButtonChange);

  // Add Cancel button to Sell City Improvement dialog
  WriteMemory(HProcess, $00505F28, [OP_CALL], @PatchCitywinCityMouseImprovements);

  // Reset mouse buttons flags of City window before City Change list
  WriteMemory(HProcess, $0050A494, [OP_JMP], @PatchCitywinCityButtonChangeBefore);

  // Set focus on City Window when opened and back to Advisor when closed
  WriteMemory(HProcess, $0040138E, [OP_JMP], @PatchFocusCityWindow);
  WriteMemory(HProcess, $00509985, [OP_CALL], @PatchCityWndProcCloseAfter);

  // Show Cost shields and Maintenance coins in City Change list and fix Turns calculation for high production numbers
  //WriteMemory(HProcess, $00509AC9, [OP_JMP], @PatchCityChangeListBuildingCost);
  WriteMemory(HProcess, $00401041, [OP_JMP], @PatchStrcatBuildingCost);
  WriteMemory(HProcess, $0050AD80, [OP_JMP], @PatchCityChangeListImprovementMaintenance);

  // Show total number of city units along with supported units
  WriteMemory(HProcess, $00503D7F, [OP_CALL], @PatchCityWindowDrawResources);

  // Set focus back to CityWindow after:
  // Q_CitywinCityButtonChange_sub_50A473 - ChangeProduction dialog
  WriteMemory(HProcess, $0050B669, [OP_NOP, OP_CALL], @PatchCitywinCityButtonAfter);
  // Q_CitywinCityButtonBuy_sub_509B48 - Buy dialog
  WriteMemory(HProcess, $0050A1CB, [OP_NOP, OP_CALL], @PatchCitywinCityButtonAfter);
  // Q_CitywinCityMouse_sub_50C1D1 - Clicking different CityWindow areas
  WriteMemory(HProcess, $0050C3FB, [OP_CALL], @FocusCityWindowIfNotHidden);
  // Q_CitywinCityButtonRename_sub_50B74E - Rename City dialog
  WriteMemory(HProcess, $0050B99A, [OP_CALL], @FocusCityWindowIfNotHidden);
end;

initialization
  TUiaPatchCityWindow.RegisterMe();

end.

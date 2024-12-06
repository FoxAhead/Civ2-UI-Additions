unit UiaPatchCityStatusAdvisor;

interface

uses
  UiaPatch;

type
  TUiaPatchCityStatusAdvisor = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Math,
  Graphics,
  SysUtils,
  Types,
  Windows,
  UiaMain,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_SortedCitiesList;

type
  TAdvisorWindowEx = record
    Rects: array[1..16] of TRect;
    SortedCitiesList: TSortedCitiesList;
    MouseOver: TPoint;
  end;

var
  AdvisorWindowEx: TAdvisorWindowEx;

function AdvisorCityStatusGetListIndex(X, Y: Integer): Integer; stdcall;
var
  Y1: Integer;
  i: Integer;
  ListIndex: Integer;
begin
  Y1 := Y - Civ2.AdvisorWindow.ListTop;
  i := Floor(Y1 / Civ2.AdvisorWindow.LineHeight);
  ListIndex := Civ2.AdvisorWindow.ScrollPosition + i;
  if (i >= 0) and (ListIndex >= 0) and (ListIndex < AdvisorWindowEx.SortedCitiesList.Count) and (i < Civ2.AdvisorWindow.ScrollPageSize) then
    Result := ListIndex
  else if i = -1 then
    Result := -1
  else
    Result := -2;
end;

procedure WndProcAdvisorCityStatusButtonUp(X, Y, Button: Integer); stdcall;
var
  i: Integer;
  ListIndex: Integer;
  SortCriteria, SortSign: Integer;
begin
  ListIndex := AdvisorCityStatusGetListIndex(X, Y);
  if (ListIndex >= 0) and (Button = 0) then
  begin
    Civ2.CityWindow_Show(Civ2.CityWindow, AdvisorWindowEx.SortedCitiesList.GetIndexIndex(ListIndex));
    if X > 370 then
    begin
      Civ2.CitywinCityButtonChange(0);
      Civ2.CityWindowExit();
    end;
  end
  else if ListIndex = -1 then
  begin
    SortCriteria := Abs(Uia.Settings.Dat.AdvisorSorts[1]);
    SortSign := Sign(Uia.Settings.Dat.AdvisorSorts[1]);
    for i := Low(AdvisorWindowEx.Rects) to High(AdvisorWindowEx.Rects) do
    begin
      if PtInRect(AdvisorWindowEx.Rects[i], Point(X, Y)) then
      begin
        if i = SortCriteria then
          if Button = 1 then
            Uia.Settings.Dat.AdvisorSorts[1] := 0
          else
            Uia.Settings.Dat.AdvisorSorts[1] := -Uia.Settings.Dat.AdvisorSorts[1]
        else if Button = 0 then
        begin
          Uia.Settings.Dat.AdvisorSorts[1] := i;
          if SortSign <> 0 then
          begin
            Uia.Settings.Dat.AdvisorSorts[1] := Uia.Settings.Dat.AdvisorSorts[1] * SortSign;
          end;
        end;
        Civ2.UpdateAdvisorCityStatus();
        Break;
      end;
    end;
  end;
end;

procedure PatchWndProcAdvisorCityStatusLButtonUp(X, Y: Integer); cdecl;
begin
  WndProcAdvisorCityStatusButtonUp(X, Y, 0);
end;

procedure PatchWndProcAdvisorCityStatusRButtonUp(X, Y: Integer); cdecl;
begin
  WndProcAdvisorCityStatusButtonUp(X, Y, 1);
end;

procedure PatchWndProcAdvisorCityStatusMouseMove(X, Y: Integer); cdecl;
var
  MSWindow: PMSWindow;
  ListIndex: Integer;
  Row: Integer;
  Part: Integer;
  Canvas: TCanvasEx;
  R: TRect;
  Y1: Integer;
begin
  if X > 370 then
    Part := 2
  else
    Part := 1;
  ListIndex := AdvisorCityStatusGetListIndex(X, Y);
  if (AdvisorWindowEx.MouseOver.Y <> ListIndex) and (Part = 2) or (AdvisorWindowEx.MouseOver.X <> Part) then
  begin
    MSWindow := @Civ2.AdvisorWindow.MSWindow;
    AdvisorWindowEx.MouseOver := Point(Part, ListIndex);
    Civ2.GraphicsInfo_CopyToScreenAndValidateW(@MSWindow.GraphicsInfo);
    if (ListIndex >= 0) and (Part = 2) then
    begin
      Row := ListIndex - Civ2.AdvisorWindow.ScrollPosition;
      Y1 := Civ2.AdvisorWindow.ListTop + Row * Civ2.AdvisorWindow.LineHeight;
      Canvas := TCanvasEx.Create(MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.DeviceContext);
      Canvas.Brush.Color := TColor($C0C0C0); // Canvas.ColorFromIndex(34);
      R := Rect(AdvisorWindowEx.Rects[6].Left - 10, Y1, MSWindow.ClientSize.cx - 11, Y1 + Civ2.AdvisorWindow.LineHeight);
      Canvas.FrameRect(R);
      Canvas.Free();
    end;
  end;
end;

function PatchUpdateAdvisorCityStatusEx(CivIndex, Bottom: Integer; var Cities, Top1: Integer): Integer; stdcall;
var
  Page, MaxScrollPosition, ScrollPos, LineHeight: Integer;
  i, j: Integer;
  X1, X2, Y1, Y2, DX: Integer;
  MSWindow: PMSWindow;
  DrawPort: PDrawPort;
  Text: string;
  Sprite: PSprite;
  R: TRect;
  Canvas: TCanvasEx;
  Building: Integer;
  City: PCity;
  CityIndex: Integer;
  SortCriteria, SortSign: Integer;
  Improvements: array[0..1] of Integer;
  SavedCityGlobals: TCityGlobals;
  CityBuildInfo: TCityBuildInfo;
begin
  //TFormConsole.Log('PatchUpdateAdvisorCityStatusEx');
  Result := 0;                            // Return 1 if processed
  SavedCityGlobals := Civ2.CityGlobals^;
  ZeroMemory(@AdvisorWindowEx.Rects, SizeOf(AdvisorWindowEx.Rects));
  MSWindow := @Civ2.AdvisorWindow.MSWindow;
  DrawPort := @MSWindow.GraphicsInfo.DrawPort;
  SortCriteria := Abs(Uia.Settings.Dat.AdvisorSorts[1]);
  SortSign := Sign(Uia.Settings.Dat.AdvisorSorts[1]);
  if AdvisorWindowEx.SortedCitiesList <> nil then
    AdvisorWindowEx.SortedCitiesList.Free();
  AdvisorWindowEx.SortedCitiesList := TSortedCitiesList.Create(CivIndex, Uia.Settings.Dat.AdvisorSorts[1]);
  Y1 := Top1;
  Top1 := Top1 + 12;
  // DIMENSIONS
  LineHeight := $18;
  Civ2.AdvisorWindow.LineHeight := LineHeight;
  Civ2.AdvisorWindow.ListTop := Top1 + 6;
  Civ2.AdvisorWindow.ListHeight := Bottom - Top1;
  Page := Civ2.Clamp((Bottom - Top1) div LineHeight, 1, $63);
  Civ2.AdvisorWindow.ScrollPageSize := Page;
  Cities := AdvisorWindowEx.SortedCitiesList.Count;
  Civ2.AdvisorWindow._Range := Civ2.Clamp((Cities + Page - 1) div Page, 1, $63);
  MaxScrollPosition := Civ2.Clamp(Cities - 1, 0, $3E7);
  ScrollPos := Civ2.Clamp(Civ2.AdvisorWindow.ScrollPosition, 0, MaxScrollPosition);
  Civ2.AdvisorWindow.ScrollPosition := ScrollPos;
  // HEADER
  if Cities > 0 then
  begin
    X1 := MSWindow.ClientTopLeft.X + 150;
    Civ2.SetCurrFont(Civ2.FontTimes14b);
    Civ2.SetFontColorWithShadow($25, $12, -1, -1);
    Text := Format('%s: %d', [GetLabelString($C5), Cities]); // Cities
    Civ2.DrawStringRightCurrDrawPort2(PChar(Text), MSWindow.ClientSize.cx - 12, Y1 - 3, 0);
    // SORT ARROWS
    Canvas := TCanvasEx.Create(DrawPort);
    Canvas.Brush.Color := Canvas.ColorFromIndex(34);
    X1 := 0;
    for i := 1 to 6 do
    begin
      case i of
        1:
          X1 := 60;
        2:
          X1 := 138;
        3:
          X1 := 270 - 16;
        4:
          X1 := 312 - 14;
        5:
          X1 := 354 - 16;
        6:
          X1 := 381;
      end;
      AdvisorWindowEx.Rects[i] := Rect(X1, Y1, X1 + 12, Y1 + 12);
      Canvas.FrameRect(AdvisorWindowEx.Rects[i]);
    end;
    Canvas.Pen.Color := Canvas.ColorFromIndex(41);
    Canvas.Brush.Color := Canvas.ColorFromIndex(41);
    if SortCriteria <> 0 then
    begin
      R := AdvisorWindowEx.Rects[SortCriteria];
      if SortSign < 0 then
        Canvas.Polygon([Point(R.Left + 2, R.Top + 4), Point(R.Left + 9, R.Top + 4), Point(R.Left + 6, R.Top + 7), Point(R.Left + 5, R.Top + 7)])
      else
        Canvas.Polygon([Point(R.Left + 2, R.Top + 7), Point(R.Left + 9, R.Top + 7), Point(R.Left + 6, R.Top + 4), Point(R.Left + 5, R.Top + 4)]);
    end;
    Canvas.Free();
  end;
  // LIST
  Y1 := Top1;
  for i := 0 to AdvisorWindowEx.SortedCitiesList.Count - 1 do
  begin
    City := AdvisorWindowEx.SortedCitiesList[i];
    if (i >= ScrollPos) and (Page + ScrollPos > i) then
    begin
      X1 := MSWindow.ClientTopLeft.X + (((i + 1) and 1) shl 6) + 2;
      CityIndex := AdvisorWindowEx.SortedCitiesList.GetIndexIndex(i); // (Integer(City) - Integer(Civ2.Cities)) div SizeOf(TCity);
      Civ2.CalcCityGlobals(CityIndex, True);
      Civ2.DrawCitySprite(DrawPort, CityIndex, 0, X1, Y1, 0);

      // Begin Debug CityIndex
      //Text := IntToStr(CityIndex);
      //Civ2.DrawString(PChar(Text), X1, Y1);
      // End Debug CityIndex

      Civ2.SetCurrFont(Civ2.FontTimes14b);
      Civ2.SetFontColorWithShadow($25, $12, 1, 1);

      Y2 := Y1 + 9;
      X1 := MSWindow.ClientTopLeft.X + 130;
      Civ2.DrawStringCurrDrawPort2(City.Name, X1, Y2);

      Improvements[0] := 1;               // Palace
      Improvements[1] := 32;              // Airport
      Civ2.SetSpriteZoom(-4);
      X2 := 270 - 42;
      for j := High(Improvements) downto Low(Improvements) do
      begin
        if Civ2.CityHasImprovement(CityIndex, Improvements[j]) then
        begin
          Civ2.Sprite_CopyToPortNC(@PSprites($645160)^[Improvements[j]], @R, DrawPort, X2, Y2 + 4);
          X2 := X2 - 19;
        end;
      end;
      Civ2.ResetSpriteZoom;

      X1 := X1 + 131;
      X2 := X1;
      for j := 0 to 2 do
      begin
        DX := 0;
        case j of
          0:
            begin
              Text := IntToStr(City.TotalFood);
              DX := -1;
            end;
          1:
            begin
              Text := IntToStr(City.TotalShield);
              DX := 1;
            end;
          2:
            begin
              Text := IntToStr(City.Trade);
              DX := -1;
            end;
        end;
        Civ2.DrawStringRightCurrDrawPort2(PChar(Text), X2, Y2, DX);
        Civ2.Sprite_CopyToPortNC(@Civ2.SprRes[2 * j + 1], @R, DrawPort, X2, Y2 + 2);
        X2 := X2 + 42;
      end;
      // BuildInfo
      GetCityBuildInfo(CityIndex, CityBuildInfo);
      X1 := X1 + 104;
      X2 := X1;
      if City.Building < 0 then
      begin
        Building := -City.Building;
        Text := string(Civ2.GetStringInList(Civ2.Improvements[Building].StringIndex)) + ' ';
        if Building >= 39 then
        begin
          Civ2.SetFontColorWithShadow($5E, $A, -1, -1);
        end;
        Civ2.SetSpriteZoom(-2);
        Civ2.Sprite_CopyToPortNC(@PSprites($645160)^[-City.Building], @R, DrawPort, X2, Y2 + 2);
        Civ2.ResetSpriteZoom();
        X2 := X2 + RectWidth(R) + 1;
      end
      else
      begin
        Civ2.SetFontColorWithShadow($7A, $A, -1, -1);
        Building := City.Building;
        Text := string(Civ2.GetStringInList(Civ2.UnitTypes[Building].StringIndex)) + ' ';
        Civ2.SetSpriteZoom(-2);
        Civ2.Sprite_CopyToPortNC(@Civ2.SprUnits[City.Building], @R, DrawPort, X2 - 10, Y2 - 8);
        Civ2.ResetSpriteZoom();
        X2 := X2 + 28;
      end;
      // Build progress
      X2 := Civ2.DrawStringCurrDrawPort2(PChar(Text), X2, Y2) + 4;
      Text := Format('%s (%d/%d)', [ConvertTurnsToString(CityBuildInfo.TurnsToBuild, $20), City.BuildProgress, CityBuildInfo.RealCost]);
      Civ2.SetFontColorWithShadow($21, $12, -1, -1);
      Civ2.DrawStringRightCurrDrawPort2(PChar(Text), MSWindow.ClientSize.cx - 12, Y2, 0);

      AdvisorWindowEx.MouseOver.Y := -2;

      Y1 := Y1 + LineHeight;
    end;
  end;
  if Civ2.AdvisorWindow.ControlsInitialized = 0 then
  begin
    MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcRButtonUp := @PatchWndProcAdvisorCityStatusRButtonUp;
    MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcMouseMove := @PatchWndProcAdvisorCityStatusMouseMove;
  end;
  Civ2.CityGlobals^ := SavedCityGlobals;
  Result := 1;
end;

procedure PatchUpdateAdvisorCityStatus(); register;
asm
    lea   eax, [ebp - $3C] // int vTop1
    push  eax
    lea   eax, [ebp - $24] // int vCities
    push  eax
    push  [ebp - $50]      // int yBottom
    push  [ebp - $58]      // int vCivIndex
    call  PatchUpdateAdvisorCityStatusEx
    cmp   eax, 1
    je    @@LABEL_PROCESSED
    mov   [ebp - $18], $18 // int vFontHeight
    push  $0042D0A0
    ret

@@LABEL_PROCESSED:
//  if ( !V_AdvisorWindow_stru_63EB10.ControlsInitialized )
    push  $0042D514
    ret
end;

{ TUiaPatchCityStatusAdvisor }

procedure TUiaPatchCityStatusAdvisor.Attach(HProcess: Cardinal);
begin
  // Enhance City Status advisor with additional functionality: total cities, sorting, change production
  WriteMemory(HProcess, $0042D099, [OP_JMP], @PatchUpdateAdvisorCityStatus);
  // Mouse button handler
  WriteMemory(HProcess, $0042D5EB, [], @PatchWndProcAdvisorCityStatusLButtonUp, True);

end;

initialization
  TUiaPatchCityStatusAdvisor.RegisterMe();

end.

unit Civ2UIA_Proc;

interface

uses
  Windows,
  Civ2UIA_Types,
  Civ2Types,
  Civ2Proc;

type
  TCityBuildInfo = record
    Production: Integer;
    RealCost: Integer;
    TurnsToBuild: Integer;
  end;

procedure SendMessageToLoader(WParam: Integer; LParam: Integer); stdcall;

procedure WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer = nil; Abs: Boolean = False);

function FastSwap(Value: Cardinal): Cardinal; register;

function Clamp(Value, MinV, MaxV: Integer): Integer;

//procedure TextOutWithShadows(var Canvas: TCanvas; var TextOut: string; Left, Top: Integer; const MainColor, ShadowColor: TColor; Shadows: Cardinal);

function ScaleByZoom(Value, Zoom: Integer): Integer;

function RectWidth(const R: TRect): Integer;

function RectHeight(const R: TRect): Integer;

procedure OffsetPoint(var Point: TPoint; DX, DY: Integer);

function CopyFont(SourceFontDataHandle: HGLOBAL): HFONT;

function GetLabelString(StringIndex: Integer): string;

function GetProduction(): Integer;

function GetTurnsToComplete(Done, Increment, Total: Integer): Integer;

function ConvertTurnsToString(Turns: Integer; Options: Cardinal = 0): string;

//function GetTurnsToBuild(RealCost, Done: Integer): Integer;

function GetTurnsToBuild(RealCost, Done: Integer): Integer;

function GetTurnsToBuildInCity(CityIndex: Integer): Integer;

procedure GetCityBuildInfo(CityIndex: Integer; out CityBuildInfo: TCityBuildInfo);

function GetTradeConnectionLevel(aCity, i: Integer): Integer;

//procedure GetResMapDXDY(X, Y: Integer; var DX, DY: Integer);

//procedure UpdateCityWindowExResMap(DX, DY: Integer);

function GetCaravanDeliveryRevenue(aUnitIndex: Integer; aCityIndex: Integer): Integer;

function GetCallerChain(): PCallerChain; register;

function GetCallersString(): string;

procedure PopupCaravanDeliveryRevenues(CivIndex: Integer);

procedure SpriteConvertToGray(Sprite: PSprite);

implementation

uses
  Math,
  Messages,
  SysUtils;

procedure SendMessageToLoader(WParam: Integer; LParam: Integer); stdcall;
var
  HWindow: HWND;
begin
  HWindow := FindWindow('TForm1', 'Civilization II UI Additions Launcher');
  if HWindow > 0 then
  begin
    PostMessage(HWindow, WM_APP + 1, WParam, LParam);
  end;
end;

procedure WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer; Abs: Boolean);
var
  SizeOP: Integer;
  BytesWritten: Cardinal;
  Offset: Integer;
begin
  SizeOP := SizeOf(Opcodes);
  if SizeOP > 0 then
    WriteProcessMemory(HProcess, Pointer(Address), @Opcodes, SizeOP, BytesWritten);
  if ProcAddress <> nil then
  begin
    Offset := Integer(ProcAddress);
    if not Abs then
      Offset := Offset - Address - 4 - SizeOP;
    WriteProcessMemory(HProcess, Pointer(Address + SizeOP), @Offset, 4, BytesWritten);
  end;
end;

//

function FastSwap(Value: Cardinal): Cardinal; register;
asm
    bswap eax
end;

function Clamp(Value, MinV, MaxV: Integer): Integer;
begin
  Result := Min(Max(Value, MinV), MaxV);
end;

{procedure TextOutWithShadows(var Canvas: TCanvas; var TextOut: string; Left, Top: Integer; const MainColor, ShadowColor: TColor; Shadows: Cardinal);
var
  dX: Integer;
  dY: Integer;
begin
  if Shadows <> SHADOW_NONE then
  begin
    Canvas.Font.Color := ShadowColor;
    for dY := -1 to 1 do
    begin
      for dX := -1 to 1 do
      begin
        if (dX = 0) and (dY = 0) then
          Continue;
        if (Shadows and 1) = 1 then
          Canvas.TextOut(Left + dX, Top + dY, TextOut);
        Shadows := Shadows shr 1;
        if Shadows = 0 then
          Break;
      end;
    end;
  end;
  Canvas.Font.Color := MainColor;
  Canvas.TextOut(Left, Top, TextOut);
end;}

function ScaleByZoom(Value, Zoom: Integer): Integer;
begin
  Result := Value * (Zoom + 8) div 8;
end;

function RectWidth(const R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

function RectHeight(const R: TRect): Integer;
begin
  Result := R.Bottom - R.Top;
end;

procedure OffsetPoint(var Point: TPoint; DX, DY: Integer);
begin
  Point.X := Point.X + DX;
  Point.Y := Point.Y + DY;
end;

function CopyFont(SourceFontDataHandle: HGLOBAL): HFONT;
var
  LogFont: TLogFont;
  FontData: PFontData;
begin
  ZeroMemory(@LogFont, SizeOf(LogFont));
  FontData := GlobalLock(SourceFontDataHandle);
  GetObject(FontData.FontHandle, SizeOf(LogFont), @LogFont);
  GlobalUnlock(SourceFontDataHandle);
  Result := CreateFontIndirect(LogFont);
end;

function GetLabelString(StringIndex: Integer): string;
begin
  Result := string(Civ2.GetStringInList(PIntegerArray(Pointer($00628420)^)[StringIndex]));
end;

function GetProduction(): Integer;
begin
  Result := Min(Max(0, Civ2.CityGlobals.TotalRes[1] - Civ2.CityGlobals.Support), 1000);
end;

function GetTurnsToComplete(Done, Increment, Total: Integer): Integer;
var
  LeftToDo: Integer;
begin
  Result := 0;
  LeftToDo := Total - Done;
  if LeftToDo <= 0 then
    Result := 1
  else if Increment > 0 then
    Result := (LeftToDo - 1) div Increment + 1;
end;

// Options:
// 0x00000000 - Format: 'N'
// 0x00000001 - Format: 'Turns: N'
// 0x00000002 - Format: 'N Turn(s)'
// 0x00000010 - ''      when Turns <= 0
// 0x00000020 - 'Never' when Turns <= 0
// 0x00000100 - Add 'Every' if Turns > 0 (for science)
function ConvertTurnsToString(Turns: Integer; Options: Cardinal): string;
var
  N1, N2, N3: Byte;
begin
  Result := '';
  N1 := Options and $F;
  N2 := Options shr 4 and $F;
  N3 := Options shr 8 and $F;
  if Turns > 0 then
  begin
    case N1 of
      1:
        Result := Format('%s: %d', [GetLabelString(44), Turns]); // 'Turns'
      2:
        Result := Format('%d %s', [Turns, GetLabelString(44 + Integer(Turns = 1))]); // 'Turns' / 'Turn'
    else
      Result := IntToStr(Turns);
    end;
    if N3 = 1 then
      Result := GetLabelString(44) + ' ' + Result; // 'Every'
  end
  else
  begin
    case N2 of
      1:
        Result := '';
      2:
        Result := GetLabelString(498);    // 'Never'
    else
      Result := IntToStr(Turns);
    end;
  end;
end;

function GetTurnsToBuild(RealCost, Done: Integer): Integer;
begin
  Result := GetTurnsToComplete(Done, GetProduction(), RealCost);
end;

function GetTurnsToBuildInCity(CityIndex: Integer): Integer;
var
  CityBuildInfo: TCityBuildInfo;
begin
  GetCityBuildInfo(CityIndex, CityBuildInfo);
  Result := CityBuildInfo.TurnsToBuild;
end;

procedure GetCityBuildInfo(CityIndex: Integer; out CityBuildInfo: TCityBuildInfo);
var
  City: PCity;
  Cost: Integer;
begin
  City := @Civ2.Cities[CityIndex];
  if City.Building < 0 then
    Cost := Civ2.Improvements[-City.Building].Cost
  else
    Cost := Civ2.UnitTypes[City.Building].Cost;
  CityBuildInfo.Production := GetProduction();
  CityBuildInfo.RealCost := Cost * Civ2.Cosmic.RowsInShieldBox;
  CityBuildInfo.TurnsToBuild := GetTurnsToComplete(City.BuildProgress, CityBuildInfo.Production, CityBuildInfo.RealCost);
end;

function GetTradeConnectionLevel(aCity, i: Integer): Integer;
var
  vPartner, vTrade, vCommodity, v1: Integer;
begin
  vCommodity := Civ2.Cities[aCity].CommodityTraded[i];
  if vCommodity < 0 then
  begin
    Result := 0;
    Exit;
  end;
  vPartner := Civ2.Cities[aCity].TradePartner[i];
  vTrade := (Civ2.Cities[vPartner].BaseTrade + Civ2.Cities[aCity].BaseTrade + 4) shr 3;
  Result := Civ2.PFFindConnection(Civ2.Cities[aCity].Owner, Civ2.Cities[aCity].X, Civ2.Cities[aCity].Y, Civ2.Cities[vPartner].X, Civ2.Cities[vPartner].Y);
  if Civ2.CityHasImprovement(aCity, $20) then // Airport
  begin
    if Civ2.CityHasImprovement(vPartner, $20) then // Airport
    begin
      v1 := Result;
      if Result <= 1 then
      begin
        v1 := 1;
      end;
      Result := v1;
    end;
  end;
  if Civ2.CityHasImprovement(aCity, $19) then // Superhighways
  begin
    Inc(Result);
  end;
end;

function GetCaravanDeliveryRevenue(aUnitIndex: Integer; aCityIndex: Integer): Integer;
var
  vFreight: Integer;
  vCivIndexF, vCivIndexT, vCityIndexF, vRevenue, vMassIndexT, vMassIndexF, vCommodity, vDemandBonus, vAdvanceCost, vMaxRevenue, vRandomMin: Integer;
  i: Integer;
  v11: Integer;
begin
  with Civ2 do
  begin
    // Code from Q_CaravanArrives_sub_440750
    vFreight := 0;
    vCivIndexF := Units[aUnitIndex].CivIndex;
    vCivIndexT := Cities[aCityIndex].Owner;

    if (Units[aUnitIndex].HomeCity = $FF) then
      vCityIndexF := -1
    else
      vCityIndexF := Units[aUnitIndex].HomeCity;

    if (vCityIndexF < 0) then
    begin
      vCityIndexF := FindNearestCity(Units[aUnitIndex].X, Units[aUnitIndex].Y, vCivIndexF, -1, -1);
      if (vCityIndexF < 0) then
        vCityIndexF := 0;
    end;

    vRevenue := Distance(Cities[aCityIndex].X, Cities[aCityIndex].Y, Cities[vCityIndexF].X, Cities[vCityIndexF].Y);

    if (Game.MapFlags and 4 <> 0) then
      vRevenue := 4 * vRevenue div 5;

    if (Game.MapFlags and 8 <> 0) then
      vRevenue := 5 * vRevenue div 4;

    vRevenue := (vRevenue + 10) * (Cities[aCityIndex].BaseTrade + Cities[vCityIndexF].BaseTrade) div 24;

    vMassIndexT := MapGetMassIndex(Cities[aCityIndex].X, Cities[aCityIndex].Y);
    vMassIndexF := MapGetMassIndex(Cities[vCityIndexF].X, Cities[vCityIndexF].Y);

    if (vMassIndexF <> vMassIndexT) then
      vRevenue := vRevenue * 2;

    if (vCivIndexF = vCivIndexT) then
      vRevenue := vRevenue shr 1;

    vCommodity := Units[aUnitIndex].Counter;

    if (Units[aUnitIndex].UnitType = $31) then // Freight
    begin
      vRevenue := vRevenue + (vRevenue shr 1);
      vFreight := 1;
    end;

    v11 := PFFindConnection(vCivIndexF, Cities[aCityIndex].X, Cities[aCityIndex].Y, Cities[vCityIndexF].X, Cities[vCityIndexF].Y);

    if CityHasImprovement(aCityIndex, $20) then
    begin
      if CityHasImprovement(vCityIndexF, $20) then
      begin
        if (vMassIndexF = vMassIndexT) then
          Inc(v11)
        else
          v11 := v11 + 2;
      end;
    end;

    if CityHasImprovement(aCityIndex, $19) then
      Inc(v11);

    if CityHasImprovement(vCityIndexF, $19) then
      Inc(v11);

    vRevenue := vRevenue + (vRevenue * v11) shr 1;
    vDemandBonus := 0;

    case vCommodity of
      3, 5, 8, $A:
        vDemandBonus := vRevenue div 2;
      9, $B, $C, $D:
        vDemandBonus := vRevenue;
      $E:
        vDemandBonus := 3 * vRevenue div 2;
      $F:
        vDemandBonus := 2 * vRevenue;
    end;

    for i := 0 to 2 do
    begin
      if (Cities[aCityIndex].DemandedTradeItem[i] = vCommodity) then
      begin
        if (Units[aUnitIndex].CivIndex = vCivIndexF) then
          vRevenue := vDemandBonus + 2 * vRevenue
        else
          vRevenue := 2 * (vDemandBonus + vRevenue);
      end;
    end;

    if (Game.Turn < 200) and not CivHasTech(vCivIndexF, $26) and not CivHasTech(vCivIndexF, $39) then
      vRevenue := vRevenue * 2;

    if CivHasTech(vCivIndexF, $43) then
      vRevenue := vRevenue - (vRevenue div 3);

    if CivHasTech(vCivIndexF, $1E) then
      vRevenue := vRevenue - (vRevenue div 3);

    vRandomMin := Random(10) + 200;
    vAdvanceCost := GetAdvanceCost(vCivIndexF);
    vMaxRevenue := Clamp(2 * vAdvanceCost div 3, vRandomMin, 30000);
    vRevenue := Clamp(vRevenue, 0, vMaxRevenue);
    Result := vRevenue;
  end;
end;

function GetCallerChain(): PCallerChain; register;
asm
    mov   eax, ebp
end;

function GetCallersString(): string;
var
  CallerChain: PCallerChain;
begin
  CallerChain := GetCallerChain();
  Result := '';
  repeat
    Result := Format('%.6x %s', [Integer(CallerChain.Caller), Result]);
    CallerChain := CallerChain.Prev;
  until Cardinal(CallerChain.Caller) > $30000000;
end;

procedure PopupCaravanDeliveryRevenues(CivIndex: Integer);
var
  Commodity: Integer;
  Unit1: PUnit;
  City: PCity;
  Dlg: TDialogWindow;
  i, k: Integer;
  Text, Text1, Text2: string;
  Revenue: Integer;
  Uncovered, Demands: Boolean;
  Size: Integer;
begin
  with Civ2 do
  begin
    if (UnitSelected^) and (Game.ActiveUnitIndex >= 0) then
    begin
      Unit1 := @Units[Game.ActiveUnitIndex];
      Commodity := Unit1.Counter;
      if (Unit1.ID <> 0) and (Unit1.HomeCity <> $FF) and (Unit1.CivIndex = CivIndex) and (Unit1.Orders = -1) and (UnitTypes[Unit1.UnitType].Role = 7) and (Commodity >= 0) then
      begin
        Dlg_InitWithHeap(@Dlg, $8000);
        DlgParams_SetString(0, Commodities[Commodity]);
        Dlg_LoadGAMESimpleL0(@Dlg, 'SUPPLYSHOW', CIV2_DLG_SORTEDLISTBOX);
        for i := 0 to Game.TotalCities - 1 do
        begin
          City := @Cities[i];
          Uncovered := (City.Owner = CivIndex) or CityHasImprovement(i, 1) or Game.RevealMap;
          if (City.ID <> 0) and (i <> Unit1.HomeCity) and (Uncovered or (City.RevealedSize[CivIndex] <> 0)) then
          begin
            Text1 := '';
            Text2 := '';
            Demands := False;
            Revenue := GetCaravanDeliveryRevenue(Game.ActiveUnitIndex, i);
            if Uncovered or (City.RevealedSize[CivIndex] = 0) then
              Size := City.Size
            else
              Size := City.RevealedSize[CivIndex];
            if City.Owner <> CivIndex then
              Text1 := GetNationAdjectiveText(City.Owner) + ', ';
            for k := 0 to 2 do
              if City.DemandedTradeItem[k] = Commodity then
                Demands := True;
            if Demands then
              Text2 := Format(' %s %s', [GetLabelString($57), GetStringInList(Commodities[Commodity])]);
            Text := Format('%s (%s%d)%s|+%d #648860:1##648860:2#', [City.Name, Text1, Size, Text2, Revenue]);
            Dlg_AddListboxItem(@Dlg, PChar(Text), i, 0);
          end;
        end;
        Dlg_CreateAndWait(@Dlg, 0);
        Dlg_CleanupHeap(@Dlg);
      end;
    end;
  end;
end;

procedure SpriteConvertToGray(Sprite: PSprite);
var
  j, k: Integer;
  MinIndex, MaxIndex: Integer;
  RGB1, RGB2: RGBQuad;
  RGBs: array[0..255] of RGBQuad;
  Gray, MinGray, MaxGray: Integer;
  Delta, MidGray2, MinGray2, MaxGray2: Integer;
  GrayK1, GrayK2: Double;
  Height, Len: Integer;
  Pxl: PByte;
  SumGray, CountGray: Integer;
  MidGray: Double;
begin
  Height := RectHeight(Sprite.Rectangle2);
  MinGray := 31;
  MaxGray := 0;
  SumGray := 0;
  CountGray := 0;
  // First pass
  Pxl := Sprite.pMem;
  for j := 0 to Height - 1 do
  begin
    Inc(Pxl, 4);
    Len := PInteger(Pxl)^;
    Inc(Pxl, 4);
    for k := 0 to Len - 1 do
    begin
      if (Pxl^ >= 10) and (Pxl^ <= 245) then
      begin
        Civ2.Palette_GetRGB(Civ2.Palette, Pxl^, RGB1.rgbRed, RGB1.rgbGreen, RGB1.rgbBlue);
        //RGB1 := RGBs[Pxl^];
        Gray := (RGB1.rgbBlue + RGB1.rgbGreen + RGB1.rgbRed) * 31 div 765;
        Inc(SumGray, Gray);
        Inc(CountGray);
        MinGray := Min(MinGray, Gray);
        MaxGray := Max(MaxGray, Gray);
        Pxl^ := Gray + 10;
      end;
      Inc(Pxl);
    end;
  end;
  if CountGray <> 0 then
    MidGray := SumGray / CountGray
  else
    MidGray := (MinGray + MaxGray) div 2;
  Delta := 4;
  MidGray2 := 16;
  MinGray2 := MidGray2 - Delta;
  MaxGray2 := MidGray2 + Delta;
  GrayK1 := 0;
  GrayK2 := 0;
  if MidGray <> MinGray then
    GrayK1 := (MidGray2 - MinGray2) / (MidGray - MinGray);
  if MaxGray <> MidGray then
    GrayK2 := (MaxGray2 - MidGray2) / (MaxGray - MidGray);
  // Second pass
  Pxl := Sprite.pMem;
  for j := 0 to Height - 1 do
  begin
    Inc(Pxl, 4);
    Len := PInteger(Pxl)^;
    Inc(Pxl, 4);
    for k := 0 to Len - 1 do
    begin
      if (Pxl^ >= 10) and (Pxl^ <= 245) then
      begin
        Gray := Pxl^ - 10;
        if Gray < MidGray then
          Gray := Trunc(MidGray2 - (MidGray - Gray) * GrayK1)
        else
          Gray := Trunc(MidGray2 + (Gray - MidGray) * GrayK2);
        Pxl^ := Gray + 10;
      end;
      Inc(Pxl);
    end;
  end;
end;

end.

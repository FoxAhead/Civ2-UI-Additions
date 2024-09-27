unit Civ2UIA_Proc;

interface

uses
  Windows,
  Graphics;

procedure SendMessageToLoader(WParam: Integer; LParam: Integer); stdcall;
procedure WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer = nil; Abs: Boolean = False);
function FastSwap(Value: Cardinal): Cardinal; register;
function Clamp(Value, MinV, MaxV: Integer): Integer;
procedure TextOutWithShadows(var Canvas: TCanvas; var TextOut: string; Left, Top: Integer; const MainColor, ShadowColor: TColor; Shadows: Cardinal);
function ScaleByZoom(Value, Zoom: Integer): Integer;
function RectWidth(const R: TRect): Integer;
function RectHeight(const R: TRect): Integer;
procedure OffsetPoint(var Point: TPoint; DX, DY: Integer);
function CopyFont(SourceFont: HFONT): HFONT;
//function ColorFromIndex(DC: HDC; Index: Integer): TColor;
function GetLabelString(StringIndex: Integer): string;
function GetProduction(): Integer;
function GetTurnsToComplete(RealCost, Done: Integer): Integer;
function GetTurnsToCompleteInCity(CityIndex: Integer): Integer;
function GetTradeConnectionLevel(aCity, i: Integer): Integer;

implementation

uses
  Math,
  Messages,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_Types;

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

procedure TextOutWithShadows(var Canvas: TCanvas; var TextOut: string; Left, Top: Integer; const MainColor, ShadowColor: TColor; Shadows: Cardinal);
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
end;

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

function CopyFont(SourceFont: HFONT): HFONT;
var
  LFont: LOGFONT;
begin
  ZeroMemory(@LFont, SizeOf(LFont));
  GetObject(SourceFont, SizeOf(LFont), @LFont);
  Result := CreateFontIndirect(LFont);
end;

{function ColorFromIndex(DC: HDC; Index: Integer): TColor;
var
  RGBQuad: Cardinal;
begin
  GetDIBColorTable(DC, Index, 1, RGBQuad);
  Result := TColor(FastSwap(RGBQuad) shr 8);
end;}

function GetLabelString(StringIndex: Integer): string;
begin
  Result := string(Civ2.GetStringInList(PIntegerArray(Pointer($00628420)^)[StringIndex]));
end;

function GetProduction(): Integer;
begin
  Result := Min(Max(0, Civ2.CityGlobals.TotalRes[1] - Civ2.CityGlobals.Support), 1000);
end;

function GetTurnsToComplete(RealCost, Done: Integer): Integer;
var
  LeftToDo, Production: Integer;
begin
  // Code from Q_StrcatBuildingCost_sub_509AC0
  LeftToDo := RealCost - 1 - Done;
  Production := Max(1, GetProduction());
  Result := Min(Max(1, LeftToDo div Production + 1), 999)
    {  Production := GetProduction();
      if Production > 0 then
        Result := Min(Max(1, LeftToDo div Production + 1), 999)
      else if LeftToDo <= 0 then
        Result := 1
      else
        Result := -1;}
end;

function GetTurnsToCompleteInCity(CityIndex: Integer): Integer;
var
  City: PCity;
  Cost, RealCost: Integer;
begin
  City := @Civ2.Cities[CityIndex];
  if City.Building < 0 then
    Cost := Civ2.Improvements[-City.Building].Cost
  else
    Cost := Civ2.UnitTypes[City.Building].Cost;
  RealCost := Cost * Civ2.Cosmic.RowsInShieldBox;
  Result := GetTurnsToComplete(RealCost, City.BuildProgress);
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
  Result := Civ2.PFFindConnection(
    Civ2.Cities[aCity].Owner,
    Civ2.Cities[aCity].X,
    Civ2.Cities[aCity].Y,
    Civ2.Cities[vPartner].X,
    Civ2.Cities[vPartner].Y);
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

end.

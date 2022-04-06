unit Civ2Proc;

interface

uses
  Windows,
  Civ2Types;

type
  TCiv2 = class
  private
  protected
  public
    ChText: PChar;
    Cities: ^TCities;
    CityWindow: PCityWindow;
    Civs: ^TCivs;
    CurrCivIndex: PInteger;
    CurrPopupInfo: PPCurrPopupInfo;
    GameParameters: PGameParameters;
    GameTurn: PWord;
    HumanCivIndex: PInteger;
    Improvements: ^TImprovements;
    Leaders: ^TLeaders;
    MainMenu: ^HMENU;
    MainWindowInfo: PWindowInfo;
    MapGraphicsInfo: PGraphicsInfo;
    MapGraphicsInfos: ^TGraphicsInfos;
    ScienceAdvisorClientRect: PRect;
    ScienceAdvisorGraphicsInfo: PGraphicsInfo;
    ShieldFontInfo: ^TFontInfo;
    ShieldLeft: ^TShieldLeft;
    ShieldTop: ^TShieldTop;
    SideBarClientRect: PRect;
    SideBarFontInfo: ^TFontInfo;
    SideBarGraphicsInfo: PGraphicsInfo;
    TimesBigFontInfo: ^TFontInfo;
    TimesFontInfo: ^TFontInfo;
    Units: ^TUnits;
    UnitTypes: ^TUnitTypes;
    constructor Create();
    destructor Destroy; override;
    procedure ClearPopupActive;
    function CreateScrollbar(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll;
    procedure DestroyScrollBar(ControlInfoScroll: PControlInfoScroll; Flag: LongBool);
    function DrawCityWindowSupport(CityWindow: PCityWindow; Flag: LongBool): PCityWindow;
    function DrawInfoCreate(A1: PRect): PDrawInfo;
    procedure DrawString(ChText: PChar; Left, Top: Integer);
    procedure DrawStringRight(ChText: PChar; Right, Top, Shift: Integer);
    function GetCityIndexAtXY(X, Y: Integer): Integer;
    function GetInfoOfClickedCitySprite(CitySpritesInfo: PCitySpritesInfo; X, Y: Integer; var SIndex, SType: Integer): Integer;
    function GetStringInList(StringIndex: Integer): PChar;
    procedure InitControlScrollRange(ControlInfoScroll: PControlInfoScroll; MinPos, MaxPos: Integer);
    procedure MapToWindow(var WindowX, WindowY: Integer; MapX, MapY: Integer);
    procedure Palette_SetRandomID(Palette: Pointer);
    procedure PopupSimpleMessage(A1, A2, A3: Integer);
    procedure RedrawMap();
    function ScreenToMap(var MapX, MapY: Integer; ScreenX, ScreenY: Integer): LongBool;
    procedure SetDIBColorTableFromPalette(DrawInfo: PDrawInfo; Palette: Pointer);
    procedure SetScrollPageSize(ControlInfoScroll: PControlInfoScroll; PageSize: Integer);
    procedure SetScrollPosition(ControlInfoScroll: PControlInfoScroll; Position: Integer);
    procedure SetTextFromLabel(A1: Integer);
    procedure SetTextIntToStr(A1: Integer);
    procedure UpdateDIBColorTableFromPalette(ThisGraphicsInfo: PGraphicsInfo; Palette: Pointer);
    procedure CenterView(X, Y: Integer);
    function GetFontHeightWithExLeading(thisFont: Pointer): Integer;
    procedure SetFocusAndBringToTop(WindowInfo: PWindowInfo);
  published
  end;

var
  Civ2: TCiv2;

implementation

uses
  SysUtils;

{ TCiv2 }

constructor TCiv2.Create;
begin
  inherited;
  // For inline ASM all TCiv2 fileds can be referenced directly only inside TCiv2 class, and as Self.FieldName
  // Important: by default EAX register contains Self reference
  ChText := Pointer($00679640);
  Cities := Pointer($0064F340);
  CityWindow := Pointer($006A91B8);
  Civs := Pointer($0064C6A0);
  CurrCivIndex := Pointer($0063EF6C);
  CurrPopupInfo := Pointer($006CEC84);
  GameParameters := Pointer($00655AE8);
  GameTurn := Pointer($00655AF8);
  HumanCivIndex := Pointer($006D1DA0);
  Improvements := Pointer($0064C488);
  Leaders := Pointer($006554F8);
  MainMenu := Pointer($006A64F8);
  MainWindowInfo := Pointer($006553D8);
  MapGraphicsInfo := Pointer($0066C7A8);
  MapGraphicsInfos := Pointer($0066C7A8);
  ScienceAdvisorClientRect := Pointer($0063EC34);
  ScienceAdvisorGraphicsInfo := Pointer($0063EB10);
  ShieldFontInfo := Pointer($006AC090);
  ShieldLeft := Pointer($642C48);
  ShieldTop := Pointer($642B48);
  SideBarClientRect := Pointer($006ABC28);
  SideBarFontInfo := Pointer($006ABF98);
  SideBarGraphicsInfo := Pointer($006ABC68);
  TimesBigFontInfo := Pointer($0063EAC0);
  TimesFontInfo := Pointer($0063EAB8);
  if ANewUnitsAreaAddress <> nil then
    Units := ANewUnitsAreaAddress
  else
    Units := Pointer(AUnits);
  UnitTypes := Pointer($0064B1B8);

  // Check structure sizes
  if SizeOf(TCityWindow) <> $16E0 then
    raise Exception.Create('Wrong size of TCityWindow');
  if SizeOf(TGraphicsInfo) <> $3F0 then
    raise Exception.Create('Wrong size of TGraphicsInfo');
  if SizeOf(TCity) <> $58 then
    raise Exception.Create('Wrong size of TCity');
  if SizeOf(TCiv) <> $594 then
    raise Exception.Create('Wrong size of TCiv');
end;

destructor TCiv2.Destroy;
begin

  inherited;
end;

procedure TCiv2.ClearPopupActive;
asm
    mov   eax, $005A3C58
    call  eax
end;

function TCiv2.CreateScrollbar(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll;
asm
    push  Flag
    push  Rect
    push  Code
    push  WindowInfo
    mov   ecx, ControlInfoScroll
    mov   eax, $0040FC50
    call  eax
    mov   @Result, eax
end;

procedure TCiv2.DestroyScrollBar(ControlInfoScroll: PControlInfoScroll; Flag: LongBool);
asm
    push  Flag
    mov   ecx, ControlInfoScroll
    mov   eax, $004BB4F0
    call  eax
end;

function TCiv2.DrawCityWindowSupport(CityWindow: PCityWindow; Flag: LongBool): PCityWindow;
asm
    push  Flag
    mov   ecx, CityWindow
    mov   eax, $004011A9
    call  eax
    mov   @Result, eax
end;

function TCiv2.GetInfoOfClickedCitySprite(CitySpritesInfo: PCitySpritesInfo; X, Y: Integer; var SIndex, SType: Integer): Integer;
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

procedure TCiv2.InitControlScrollRange(ControlInfoScroll: PControlInfoScroll; MinPos, MaxPos: Integer);
asm
    push  MaxPos
    push  MinPos
    mov   ecx, ControlInfoScroll
    mov   eax, $00402121
    call  eax
end;

procedure TCiv2.SetScrollPageSize(ControlInfoScroll: PControlInfoScroll; PageSize: Integer);
asm
    push  PageSize
    mov   ecx, ControlInfoScroll
    mov   eax, $005DB0D0
    call  eax
end;

procedure TCiv2.SetScrollPosition(ControlInfoScroll: PControlInfoScroll; Position: Integer);
asm
    push  Position
    mov   ecx, ControlInfoScroll
    mov   eax, $004027BB
    call  eax
end;

procedure TCiv2.DrawString(ChText: PChar; Left, Top: Integer);
asm
    push  Top
    push  Left
    push  ChText
    mov   eax, $00401E0B
    call  eax
    add   esp, $0C
end;

procedure TCiv2.DrawStringRight(ChText: PChar; Right, Top, Shift: Integer);
asm
    push  Shift
    push  Top
    push  Right
    push  ChText
    mov   eax, $00403607
    call  eax
    add   esp, $10
end;

procedure TCiv2.RedrawMap();
asm
    push  1
    mov   ecx, Self.HumanCivIndex
    push  [ecx]
    mov   ecx, Self.MapGraphicsInfo
    mov   eax, $00401F32
    call  eax
end;

procedure TCiv2.UpdateDIBColorTableFromPalette(ThisGraphicsInfo: PGraphicsInfo; Palette: Pointer);
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

procedure TCiv2.SetDIBColorTableFromPalette(DrawInfo: PDrawInfo; Palette: Pointer);
asm
    push  Palette
    push  DrawInfo
    mov   eax, $005E3BDC
    call  eax
    add   esp, 8
end;

procedure TCiv2.Palette_SetRandomID(Palette: Pointer);
asm
    mov   ecx, Palette
    mov   eax, $005C6A42
    call  eax
end;

procedure TCiv2.SetTextIntToStr(A1: Integer);
asm
    push  A1
    mov   eax, $00401ED8
    call  eax
    add   esp, 4
end;

procedure TCiv2.SetTextFromLabel(A1: Integer);
asm
// A1 + 0x11 = Line # in Labels.txt
    push  A1
    mov   eax, $0040BC10
    call  eax
    add   esp, 4
end;

function TCiv2.DrawInfoCreate(A1: PRect): PDrawInfo;
asm
    push  A1
    mov   eax, $005E35B0
    call  eax
    add   esp, 4
end;

procedure TCiv2.PopupSimpleMessage(A1, A2, A3: Integer);
asm
    push  A3
    push  A2
    push  A1
    mov   eax, $00410030
    call  eax
    add   esp, $0C
end;

function TCiv2.ScreenToMap(var MapX, MapY: Integer; ScreenX, ScreenY: Integer): LongBool;
asm
    push  ScreenY
    push  ScreenX
    push  MapY
    push  MapX
    mov   ecx, Self.MapGraphicsInfo
    mov   eax, $00402B2B
    call  eax
    mov   @Result, eax
end;

function TCiv2.GetCityIndexAtXY(X, Y: Integer): Integer;
asm
    push  Y
    push  X
    mov   eax, $0043CF76
    call  eax
    add   esp, 8
    mov   @Result, eax
end;

procedure TCiv2.MapToWindow(var WindowX, WindowY: Integer; MapX, MapY: Integer);
asm
    push  MapY
    push  MapX
    push  WindowY
    push  WindowX
    mov   ecx, Self.MapGraphicsInfo
    mov   eax, $0047A6B0
    call  eax
end;

function TCiv2.GetStringInList(StringIndex: Integer): PChar;
asm
    push  StringIndex
    mov   eax, $00403387
    call  eax
    add   esp, 4
end;

procedure TCiv2.CenterView(X, Y: Integer);
asm
    push  Y
    push  X
    mov   ecx, Self.MapGraphicsInfo
    mov   eax, $00403404
    call  eax
end;

function TCiv2.GetFontHeightWithExLeading(thisFont: Pointer): Integer;
asm
    mov   ecx, thisFont
    mov   eax, $00403819
    call  eax
end;

procedure TCiv2.SetFocusAndBringToTop(WindowInfo: PWindowInfo);
asm
    mov   ecx, WindowInfo
    mov   eax, $0040325B
    call  eax
end;

end.

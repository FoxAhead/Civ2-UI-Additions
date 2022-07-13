unit Civ2Proc;

interface

uses
  SysUtils,
  Windows,
  Civ2Types;

type
  PShortIntArray = ^TShortIntArray;

  TShortIntArray = array[0..32767] of ShortInt;

  TCiv2 = class
  private
  protected
  public
    AdvisorWindow: PAdvisorWindow;
    ChText: PChar;
    Cities: ^TCities;
    CityGlobals: PCityGlobals;
    CityWindow: PCityWindow;
    Civs: ^TCivs;
    Commodities: PIntegerArray;
    Cosmic: PCosmic;
    CurrCivIndex: PInteger;
    CurrPopupInfo: PPDialogWindow;
    CursorX: PSmallInt;
    CursorY: PSmallInt;
    GameParameters: PGameParameters;
    HumanCivIndex: PInteger;
    Improvements: ^TImprovements;
    Leaders: ^TLeaders;
    LoadedTxtSectionName: PChar;
    MenuBar: PMenuBar;
    MainWindowInfo: PWindowInfo;
    MapCivData: PMapCivData;
    MapData: ^PMapSquares;
    MapHeader: PMapHeader;
    MapWindow: PMapWindow;
    MapWindows: PMapWindows;
    PFDX: PShortIntArray;
    PFDY: PShortIntArray;
    PFStopX: PInteger;
    PFStopY: PInteger;
    PFData: PPFData;
    PrevWindowInfo: PWindowInfo;
    ScreenRectSize: PSize;
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
    UnitSelected: ^LongBool;
    UnitTypes: ^TUnitTypes;
    WonderCity: PWordArray;
    constructor Create();
    destructor Destroy; override;
    procedure ClearPopupActive;
    function CreateScrollbar(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll;
    procedure DestroyScrollBar(ControlInfoScroll: PControlInfoScroll; Flag: LongBool);
    function DrawCityWindowSupport(CityWindow: PCityWindow; Flag: LongBool): PCityWindow;
    procedure UpdateCityWindow(CityWindow: PCityWindow; A2: Integer);
    function DrawInfoCreate(A1: PRect): PDrawInfo;
    function DrawString(ChText: PChar; Left, Top: Integer): Integer;
    procedure DrawStringRight(ChText: PChar; Right, Top, Shift: Integer);
    function GetCityIndexAtXY(X, Y: Integer): Integer;
    function GetInfoOfClickedCitySprite(CitySpritesInfo: PCitySpritesInfo; X, Y: Integer; var SIndex, SType: Integer): Integer;
    function GetSpecialist(City, SpecialistIndex: Integer): Integer;
    procedure SetSpecialist(City, SpecialistIndex, Specialist: Integer);
    procedure CityCitizenClicked(CitizenIndex: Integer);
    function GetStringInList(StringIndex: Integer): PChar;
    procedure InitControlScrollRange(ControlInfoScroll: PControlInfoScroll; MinPos, MaxPos: Integer);
    procedure MapToWindow(var WindowX, WindowY: Integer; MapX, MapY: Integer);
    procedure Palette_SetRandomID(Palette: Pointer);
    procedure PopupSimpleGameMessage(A1, A2, A3: Integer);
    procedure RedrawMap();
    function ScreenToMap(var MapX, MapY: Integer; ScreenX, ScreenY: Integer): LongBool;
    procedure SetDIBColorTableFromPalette(DrawInfo: PDrawInfo; Palette: Pointer);
    procedure SetScrollPageSize(ControlInfoScroll: PControlInfoScroll; PageSize: Integer);
    procedure SetScrollPosition(ControlInfoScroll: PControlInfoScroll; Position: Integer);
    procedure SetTextFromLabel(A1: Integer);
    procedure SetTextIntToStr(A1: Integer);
    procedure UpdateDIBColorTableFromPalette(ThisDrawPort: PDrawPort; Palette: Pointer);
    procedure CenterView(X, Y: Integer);
    function GetFontHeightWithExLeading(thisFont: Pointer): Integer;
    procedure SetFocusAndBringToTop(WindowInfo: PWindowInfo);
    function DrawPort_Reset(DrawPort: PDrawPort; Width, Height: Integer): Integer;
    function CopySprite(Sprite: PSprite; ARect: PRect; DrawPort: PDrawPort; X, Y: Integer): PRect;
    procedure RecreateBrush(WindowInfo: PWindowInfo; Color: Integer);
    procedure sub_401BC7(A1: PDialogWindow; A2: PChar; A3, A4, A5, A6: Integer);
    function GetTextExtentX(A1: PFontInfo; A2: PChar): Integer;
    function Heap_Add(Heap: PHeap; Size: Integer): Pointer;
    function Crt_OperatorNew(Size: Integer): Pointer;
    function Scroll_Ctr(ControlInfoScroll: PControlInfoScroll): PControlInfoScroll;
    procedure ShowWindowInvalidateRect(ControlInfo: PControlInfo);
    procedure GetSpriteZoom(var Numerator, Denominator: Integer);
    procedure SetSpriteZoom(AZoom: Integer);
    procedure ResetSpriteZoom();
    procedure DlgDrawTextLine(Dialog: PDialogWindow; Text: PChar; X, Y, A5: Integer);
    procedure DrawFrame(DrawPort: PDrawPort; Rect: PRect; Color: Integer);
    procedure CallRedrawAfterScroll(ControlInfoScroll: PControlInfoScroll; Pos: Integer);
    procedure CreateDialog(Dialog: PDialogWindow);
    function CreateDialogAndWait(Dialog: PDialogWindow; TimeOut: Integer): Integer;
    procedure ListItemProcLButtonUp(Code: Integer);
    procedure DrawCitySprite(DrawPort: PDrawPort; CityIndex, A3, Left, Top, Zoom: Integer);
    procedure SetFontColorWithShadow(A1, A2, A3, A4: Integer);
    function Clamp(A1, AMin, AMax: Integer): Integer;
    procedure SetCurrFont(A1: Integer);
    procedure ShowCityWindow(CityWindow: PCityWindow; CityIndex: Integer);
    procedure Citywin_CityButtonChange(A1: Integer);
    procedure CityWindowClose();
    procedure CityWindowExit();
    procedure UpdateAdvisorCityStatus();
    function TileBg(Dst, Tile: PDrawPort; A3, A4, A5, A6, A7, A8: Integer): Integer;
    procedure CopyToPort(Src, Dst: PDrawPort; A3, A4, A5, A6, A7, A8: Integer);
    procedure UpdateCopyValidateAdvisor(A1: Integer);
    procedure CopyToScreenAndValidate(GraphicsInfo: PGraphicsInfo);
    function CivHasTech(CivIndex, Tech: Integer): LongBool;
    function CityHasImprovement(CityIndex, Improvement: Integer): LongBool;
    function UnitCanMove(UnitIndex: Integer): LongBool;
    procedure ProcessOrdersGoTo(UnitIndex: Integer);
    function HumanTurn(): Integer;
    function ProcessUnit(): Integer;
    function DrawUnit(DrawPort: PDrawPort; UnitIndex, A3, Left, Top, Zoom, WithoutFortress: Integer): Integer;
    function CalcCityGlobals(CityIndex: Integer; Calc: LongBool): Integer;
    procedure ArrangeWindows();
    procedure CopySpriteToSprite(Source, Target: PSprite);
    procedure DisposeSprite(Sprite: PSprite);
    procedure ExtractSprite64x48(Sprite: PSprite; Left, Top: Integer);
    function GetCivColor1(CivIndex: Integer): Integer;
    function GetTopUnitInStack(UnitIndex: Integer): Integer;
    function GetNextUnitInStack(UnitIndex: Integer): Integer;
    procedure AfterActiveUnitChanged(A1: Integer);
    // Map
    function WrapMapX(X: Integer): Integer;
    function IsInMapBounds(X, Y: Integer): LongBool;
    function MapGetCivData(X, Y, CivIndex: Integer): PByte;
    function MapGetSquare(X, Y: Integer): PMapSquare;
    function MapSquareIsVisibleTo(X, Y, CivIndex: Integer): LongBool;
    function MapGetOwnership(X, Y: Integer): Integer;
    function MapGetSquareCityRadii(X, Y: Integer): Integer;
    // PF
    function PFMove(X, Y, A3: Integer): Integer;
    function PFFindUnitDir(UnitIndex: Integer): Integer;
    // MenuBar
    function MenuBarAddMenu(MenuBar: PMenuBar; Num: Integer; Text: PChar): PMenu;
    function MenuBarAddSubMenu(MenuBar: PMenuBar; Num, SubNum: Integer; Text: PChar; Len: Integer): PMenu;
    function MenuBarGetSubMenu(MenuBar: PMenuBar; Num: Integer): PMenu;
  published
  end;

var
  Civ2: TCiv2;

implementation

{ TCiv2 }

constructor TCiv2.Create;
begin
  inherited;
  // For inline ASM all TCiv2 fileds can be referenced directly only inside TCiv2 class, and as Self.FieldName
  // Important: by default EAX register contains Self reference
  AdvisorWindow := Pointer($0063EB10);
  ChText := Pointer($00679640);
  Cities := Pointer($0064F340);
  CityWindow := Pointer($006A91B8);
  CityGlobals := Pointer($006A6528);
  Civs := Pointer($0064C6A0);
  Commodities := Pointer($0064B168);
  Cosmic := Pointer($0064BCC8);
  CurrCivIndex := Pointer($0063EF6C);
  CurrPopupInfo := Pointer($006CEC84);
  CursorX := Pointer($0064B1B4);
  CursorY := Pointer($0064B1B0);
  GameParameters := Pointer($00655AE8);
  HumanCivIndex := Pointer($006D1DA0);
  Improvements := Pointer($0064C488);
  Leaders := Pointer($006554F8);
  LoadedTxtSectionName := Pointer($006CECB0);
  MenuBar := Pointer($006A64F8);
  MainWindowInfo := Pointer($006553D8);
  MapCivData := Pointer($006365C0);
  MapData := Pointer($00636598);
  MapHeader := Pointer($006D1160);
  MapWindow := Pointer($0066C7A8);
  MapWindows := Pointer($0066C7A8);
  PFDX := Pointer($00628350);
  PFDY := Pointer($00628360);
  PFStopX := Pointer($00673FA0);
  PFStopY := Pointer($00673FA4);
  PFData := Pointer($0062D03C);
  PrevWindowInfo := Pointer($00637EA4);
  ScreenRectSize := Pointer($006AB198);
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
  UnitSelected := Pointer($006D1DA8);
  UnitTypes := Pointer($0064B1B8);
  WonderCity := Pointer($00655BE6);

  // Check structure sizes
  if SizeOf(TWindowInfo) <> $C5 then
    raise Exception.Create('Wrong size of TWindowInfo');
  if SizeOf(TCityWindow) <> $16E0 then
    raise Exception.Create('Wrong size of TCityWindow');
  if SizeOf(TGraphicsInfo) <> $114 then
    raise Exception.Create('Wrong size of TGraphicsInfo');
  if SizeOf(TMapWindow) <> $3F0 then
    raise Exception.Create('Wrong size of TMapWindow');
  if SizeOf(TCity) <> $58 then
    raise Exception.Create('Wrong size of TCity');
  if SizeOf(TCiv) <> $594 then
    raise Exception.Create('Wrong size of TCiv');
  if SizeOf(TAdvisorWindow) <> $4A4 then
    raise Exception.Create('Wrong size of TAdvisorWindow');
  if SizeOf(TDialogWindow) <> $2F4 then
    raise Exception.Create('Wrong size of TDialogWindow');
  if SizeOf(TCityGlobals) <> $140 then
    raise Exception.Create('Wrong size of TCityGlobals');
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

procedure TCiv2.UpdateCityWindow(CityWindow: PCityWindow; A2: Integer);
asm
    push  A2
    mov   ecx, CityWindow
    mov   eax, $00402833
    call  eax
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

function TCiv2.GetSpecialist(City, SpecialistIndex: Integer): Integer;
asm
    push  SpecialistIndex
    push  City
    mov   eax, $004013C0
    call  eax
    add   esp, 8
    mov   @Result, eax
end;

procedure TCiv2.SetSpecialist(City, SpecialistIndex, Specialist: Integer);
asm
    push  Specialist
    push  SpecialistIndex
    push  City
    mov   eax, $004022C5
    call  eax
    add   esp, $0C
end;

procedure TCiv2.CityCitizenClicked(CitizenIndex: Integer);
asm
    push  CitizenIndex
    mov   eax, $0040204A
    call  eax
    add   esp, 4
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

function TCiv2.DrawString(ChText: PChar; Left, Top: Integer): Integer;
asm
    push  Top
    push  Left
    push  ChText
    mov   eax, $00401E0B
    call  eax
    add   esp, $0C
    mov   @Result, eax
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
    mov   ecx, Self.MapWindow
    mov   eax, $00401F32
    call  eax
end;

procedure TCiv2.UpdateDIBColorTableFromPalette(ThisDrawPort: PDrawPort; Palette: Pointer);
asm
//
//    if ( Q_Pallete_GetID_sub_5C56F0(a2) != this->PrevPaletteID )
//    {
//      Q_SetDIBColorTableFromPalette_sub_5E3BDC(v2->Unknown2d_DrawInfo, a2);
//      v2->PrevPaletteID = Q_Pallete_GetID_sub_5C56F0(a2);
//    }
    push  Palette
    mov   ecx, ThisDrawPort
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

procedure TCiv2.PopupSimpleGameMessage(A1, A2, A3: Integer);
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
    mov   ecx, Self.MapWindow
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
    mov   ecx, Self.MapWindow
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
    mov   ecx, Self.MapWindow
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

function TCiv2.DrawPort_Reset(DrawPort: PDrawPort; Width, Height: Integer): Integer;
asm
    push  Height
    push  Width
    mov   ecx, DrawPort
    mov   eax, $005BD65C
    call  eax
    mov   @Result, eax
end;

function TCiv2.CopySprite(Sprite: PSprite; ARect: PRect; DrawPort: PDrawPort; X, Y: Integer): PRect;
asm
    push  Y
    push  X
    push  DrawPort
    push  ARect
    mov   ecx, Sprite
    mov   eax, $005CEF31
    call  eax
    mov   @Result, eax
end;

procedure TCiv2.RecreateBrush(WindowInfo: PWindowInfo; Color: Integer);
asm
    push  Color
    mov   ecx, WindowInfo
    mov   eax, $00402045
    call  eax
end;

procedure TCiv2.sub_401BC7(A1: PDialogWindow; A2: PChar; A3, A4, A5, A6: Integer);
asm
    push  A6
    push  A5
    push  A4
    push  A3
    push  A2
    mov   ecx, A1
    mov   eax, $00401BC7
    call  eax
end;

function TCiv2.GetTextExtentX(A1: PFontInfo; A2: PChar): Integer;
asm
    push  A2
    mov   ecx, A1
    mov   eax, $00402B21
    call  eax
end;

function TCiv2.Heap_Add(Heap: PHeap; Size: Integer): Pointer;
asm
    push  Size
    push  Heap
    mov   eax, $0040389B
    call  eax
    add   esp, 8
    mov   @Result, eax
end;

function TCiv2.Crt_OperatorNew(Size: Integer): Pointer;
asm
    push  Size
    mov   eax, $005F2470
    call  eax
    add   esp, 4
    mov   @Result, eax
end;

function TCiv2.Scroll_Ctr(ControlInfoScroll: PControlInfoScroll): PControlInfoScroll;
asm
    mov   ecx, ControlInfoScroll
    mov   eax, $004031E3
    call  eax
    mov   @Result, eax
end;

procedure TCiv2.ShowWindowInvalidateRect(ControlInfo: PControlInfo);
asm
    mov   ecx, ControlInfo
    mov   eax, $0040169A
    call  eax
end;

procedure TCiv2.GetSpriteZoom(var Numerator, Denominator: Integer);
asm
    push  Denominator
    push  Numerator
    mov   eax, $005CDA06
    call  eax
    add   esp, 8
end;

procedure TCiv2.SetSpriteZoom(AZoom: Integer);
asm
    push  AZoom
    mov   eax, $00403350
    call  eax
    add   esp, 4
end;

procedure TCiv2.ResetSpriteZoom();
asm
    mov   eax, $004023D3
    call  eax
end;

procedure TCiv2.DlgDrawTextLine(Dialog: PDialogWindow; Text: PChar; X, Y, A5: Integer);
asm
    push  A5
    push  Y
    push  X
    push  Text
    mov   ecx, Dialog
    mov   eax, $00401640
    call  eax
end;

procedure TCiv2.DrawFrame(DrawPort: PDrawPort; Rect: PRect; Color: Integer);
asm
    push  Color
    push  Rect
    push  DrawPort
    mov   eax, $00401DB1
    call  eax
    add   esp, $0C
end;

procedure TCiv2.CallRedrawAfterScroll(ControlInfoScroll: PControlInfoScroll; Pos: Integer);
asm
    push  Pos
    mov   ecx, ControlInfoScroll
    mov   eax, $005CD640
    call  eax
end;

procedure TCiv2.CreateDialog(Dialog: PDialogWindow);
asm
    mov   ecx, Dialog
    mov   eax, $004026D5
    call  eax
end;

function TCiv2.CreateDialogAndWait(Dialog: PDialogWindow; TimeOut: Integer): Integer;
asm
    push  TimeOut
    mov   ecx, Dialog
    mov   eax, $00401118
    call  eax
    mov   @Result, eax
end;

procedure TCiv2.ListItemProcLButtonUp(Code: Integer);
asm
    push  Code
    mov   eax, $005A3CCA
    call  eax
    add   esp, 4
end;

procedure TCiv2.DrawCitySprite(DrawPort: PDrawPort; CityIndex, A3, Left, Top, Zoom: Integer);
asm
    push  Zoom
    push  Top
    push  Left
    push  A3
    push  CityIndex
    push  DrawPort
    mov   eax, $00402A45
    call  eax
    add   esp, $18
end;

procedure TCiv2.SetFontColorWithShadow(A1, A2, A3, A4: Integer);
asm
    push  A4
    push  A3
    push  A2
    push  A1
    mov   eax, $00403BB6
    call  eax
    add   esp, $10
end;

function TCiv2.Clamp(A1, AMin, AMax: Integer): Integer;
asm
    push  AMax
    push  AMin
    push  A1
    mov   eax, $00402D56
    call  eax
    add   esp, $0C
    mov   @Result, eax
end;

procedure TCiv2.SetCurrFont(A1: Integer);
asm
    push  A1
    mov   eax, $0040233D
    call  eax
    add   esp, $4
end;

procedure TCiv2.ShowCityWindow(CityWindow: PCityWindow; CityIndex: Integer);
asm
    push  CityIndex
    mov   ecx, CityWindow
    mov   eax, $00402E78
    call  eax
end;

procedure TCiv2.Citywin_CityButtonChange(A1: Integer);
asm
    push  A1
    mov   eax, $004021D5
    call  eax
    add   esp, $4
end;

procedure TCiv2.CityWindowClose;
asm
    mov   eax, $00401BAE
    call  eax
end;

procedure TCiv2.CityWindowExit;
asm
    mov   eax, $004034E5
    call  eax
end;

procedure TCiv2.UpdateAdvisorCityStatus();
asm
    mov   eax, $004029F5
    call  eax
end;

function TCiv2.TileBg(Dst, Tile: PDrawPort; A3, A4, A5, A6, A7, A8: Integer): Integer;
asm
    push  A8
    push  A7
    push  A6
    push  A5
    push  A4
    push  A3
    push  Tile
    push  Dst
    mov   eax, $00402C9D
    call  eax
    add   esp, $20
    mov   @Result, eax
end;

procedure TCiv2.CopyToPort(Src, Dst: PDrawPort; A3, A4, A5, A6, A7, A8: Integer);
asm
    push  A8
    push  A7
    push  A6
    push  A5
    push  A4
    push  A3
    push  Dst
    push  Src
    mov   eax, $00402081
    call  eax
    add   esp, $20
end;

procedure TCiv2.UpdateCopyValidateAdvisor(A1: Integer);
asm
    push  A1
    mov   eax, $00402A9A
    call  eax
    add   esp, $4
end;

procedure TCiv2.CopyToScreenAndValidate(GraphicsInfo: PGraphicsInfo);
asm
    mov   ecx, GraphicsInfo
    mov   eax, $004014A1
    call  eax
end;

function TCiv2.CivHasTech(CivIndex, Tech: Integer): LongBool;
asm
    push  Tech
    push  CivIndex
    mov   eax, $00402E7D
    call  eax
    add   esp, $8
    mov   @Result, eax
end;

function TCiv2.CityHasImprovement(CityIndex, Improvement: Integer): LongBool;
asm
    push  Improvement
    push  CityIndex
    mov   eax, $00402C48
    call  eax
    add   esp, $8
    mov   @Result, eax
end;

function TCiv2.UnitCanMove(UnitIndex: Integer): LongBool;
asm
    push  UnitIndex
    mov   eax, $0040273E
    call  eax
    add   esp, $4
    mov   @Result, eax
end;

procedure TCiv2.ProcessOrdersGoTo(UnitIndex: Integer);
asm
    push  UnitIndex
    mov   eax, $00401145
    call  eax
    add   esp, $4
end;

function TCiv2.HumanTurn: Integer;
asm
    mov   eax, $00402BA8
    call  eax
    mov   @Result, eax
end;

function TCiv2.ProcessUnit: Integer;
asm
    mov   eax, $00402716
    call  eax
    mov   @Result, eax
end;

function TCiv2.DrawUnit(DrawPort: PDrawPort; UnitIndex, A3, Left, Top, Zoom, WithoutFortress: Integer): Integer;
asm
    push  WithoutFortress
    push  Zoom
    push  Top
    push  Left
    push  A3
    push  UnitIndex
    push  DrawPort
    mov   eax, $0056BAFF
    call  eax
    add   esp, $1C
    mov   @Result, eax
end;

function TCiv2.CalcCityGlobals(CityIndex: Integer; Calc: LongBool): Integer;
asm
    push  Calc
    push  CityIndex
    mov   eax, $00402603
    call  eax
    add   esp, $08
    mov   @Result, eax
end;

procedure TCiv2.ArrangeWindows;
asm
    mov   eax, $004039F4
    call  eax
end;

procedure TCiv2.CopySpriteToSprite(Source, Target: PSprite);
asm
    push  Target
    mov   ecx, Source
    mov   eax, $005CF23F
    call  eax
end;

procedure TCiv2.DisposeSprite(Sprite: PSprite);
asm
    mov   ecx, Sprite
    mov   eax, $005CDF50
    call  eax
end;

procedure TCiv2.ExtractSprite64x48(Sprite: PSprite; Left, Top: Integer);
asm
    push  Top
    push  Left
    push  Sprite
    mov   ecx, Sprite
    mov   eax, $0044AC07
    call  eax
    add   esp, $0C
end;

function TCiv2.GetCivColor1(CivIndex: Integer): Integer;
asm
    push  CivIndex
    mov   eax, $00401F8C
    call  eax
    add   esp, $04
    mov   @Result, eax
end;

function TCiv2.GetTopUnitInStack(UnitIndex: Integer): Integer;
asm
    push  UnitIndex
    mov   eax, $00403391
    call  eax
    add   esp, $04
    mov   @Result, eax
end;

function TCiv2.GetNextUnitInStack(UnitIndex: Integer): Integer;
asm
    push  UnitIndex
    mov   eax, $00402E23
    call  eax
    add   esp, $04
    mov   @Result, eax
end;

procedure TCiv2.AfterActiveUnitChanged(A1: Integer);
asm
    push  A1
    mov   eax, $004016EF
    call  eax
    add   esp, $04
end;

//
// Map
//

function TCiv2.WrapMapX(X: Integer): Integer;
asm
    push  X
    mov   eax, $004022ED
    call  eax
    add   esp, $04
    mov   @Result, eax
end;

function TCiv2.IsInMapBounds(X, Y: Integer): LongBool;
asm
    push  Y
    push  X
    mov   eax, $004012D0
    call  eax
    add   esp, $08
    mov   @Result, eax
end;

function TCiv2.MapSquareIsVisibleTo(X, Y, CivIndex: Integer): LongBool;
asm
    push  CivIndex
    push  Y
    push  X
    mov   eax, $00403C24
    call  eax
    add   esp, $0C
    mov   @Result, eax
end;

function TCiv2.MapGetOwnership(X, Y: Integer): Integer;
asm
    push  Y
    push  X
    mov   eax, $004029BE
    call  eax
    add   esp, $08
    mov   @Result, eax
end;

//
// PF
//

function TCiv2.PFMove(X, Y, A3: Integer): Integer;
asm
    push  A3
    push  Y
    push  X
    mov   eax, $004028B0
    call  eax
    add   esp, $0C
    mov   @Result, eax
end;

function TCiv2.PFFindUnitDir(UnitIndex: Integer): Integer;
asm
    push  UnitIndex
    mov   eax, $00402FA9
    call  eax
    add   esp, $04
    mov   @Result, eax
end;

function TCiv2.MapGetCivData(X, Y, CivIndex: Integer): PByte;
asm
    push  CivIndex
    push  Y
    push  X
    mov   eax, $00403823
    call  eax
    add   esp, $0C
    mov   @Result, eax
end;

function TCiv2.MapGetSquare(X, Y: Integer): PMapSquare;
asm
    push  Y
    push  X
    mov   eax, $00401BB3
    call  eax
    add   esp, $08
    mov   @Result, eax
end;

function TCiv2.MapGetSquareCityRadii(X, Y: Integer): Integer;
asm
    push  Y
    push  X
    mov   eax, $00403A67
    call  eax
    add   esp, $08
    mov   @Result, eax
end;

//
// MenuBar
//

function TCiv2.MenuBarAddMenu(MenuBar: PMenuBar; Num: Integer; Text: PChar): PMenu;
asm
    push  Text
    push  Num
    mov   ecx, MenuBar
    mov   eax, $0040117C
    call  eax
    mov   @Result, eax
end;

function TCiv2.MenuBarAddSubMenu(MenuBar: PMenuBar; Num, SubNum: Integer; Text: PChar; Len: Integer): PMenu;
asm
    push  Len
    push  Text
    push  SubNum
    push  Num
    mov   ecx, MenuBar
    mov   eax, $00402D10
    call  eax
    mov   @Result, eax
end;

function TCiv2.MenuBarGetSubMenu(MenuBar: PMenuBar; Num: Integer): PMenu;
asm
    push  Num
    mov   ecx, MenuBar
    mov   eax, $004039EF
    call  eax
    mov   @Result, eax
end;


end.

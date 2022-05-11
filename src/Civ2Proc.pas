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
    AdvisorWindow: PAdvisorWindow;
    ChText: PChar;
    Cities: ^TCities;
    CityGlobals: PCityGlobals;
    CityWindow: PCityWindow;
    Civs: ^TCivs;
    CurrCivIndex: PInteger;
    CurrPopupInfo: PPDialogWindow;
    GameParameters: PGameParameters;
    GameTurn: PWord;
    HumanCivIndex: PInteger;
    Improvements: ^TImprovements;
    Leaders: ^TLeaders;
    LoadedTxtSectionName: PChar;
    MainMenu: ^HMENU;
    MainWindowInfo: PWindowInfo;
    MapWindow: PMapWindow;
    MapWindows: PMapWindows;
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
    UnitTypes: ^TUnitTypes;
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
    procedure UpdateAdvisorCityStatus();
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
  AdvisorWindow := Pointer($0063EB10);
  ChText := Pointer($00679640);
  Cities := Pointer($0064F340);
  CityWindow := Pointer($006A91B8);
  CityGlobals := Pointer($006A6528);
  Civs := Pointer($0064C6A0);
  CurrCivIndex := Pointer($0063EF6C);
  CurrPopupInfo := Pointer($006CEC84);
  GameParameters := Pointer($00655AE8);
  GameTurn := Pointer($00655AF8);
  HumanCivIndex := Pointer($006D1DA0);
  Improvements := Pointer($0064C488);
  Leaders := Pointer($006554F8);
  LoadedTxtSectionName := Pointer($006CECB0);
  MainMenu := Pointer($006A64F8);
  MainWindowInfo := Pointer($006553D8);
  MapWindow := Pointer($0066C7A8);
  MapWindows := Pointer($0066C7A8);
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
  UnitTypes := Pointer($0064B1B8);

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

procedure TCiv2.UpdateAdvisorCityStatus();
asm
    mov   eax, $004029F5
    call  eax
end;

end.

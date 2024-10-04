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
    CDRoot: PChar;
    ChText: PChar;
    Cities: ^TCities;
    CityGlobals: PCityGlobals;
    CitySpiralDX: PShortIntArray;
    CitySpiralDY: PShortIntArray;
    CityDX: PShortIntArray;
    CityDY: PShortIntArray;
    CityWindow: PCityWindow;
    Civs: ^TCivs;
    Commodities: PIntegerArray;
    Cosmic: PCosmic;
    CurrPopupInfo: PPDialogWindow;
    CursorX: PSmallInt;
    CursorY: PSmallInt;
    FontTimes14b: ^TFontInfo;
    FontTimes16: ^TFontInfo;
    FontTimes18: ^TFontInfo;
    GameParameters: PGameParameters;
    HumanCivIndex: PInteger;
    Improvements: ^TImprovements;
    Leaders: ^TLeaders;
    LoadedTxtSectionName: PChar;
    MenuBar: PMenuBar;
    MainWindowInfo: PWindowInfo1;
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
    RulesCivilizes: ^TRulesCivilizes;
    ScreenRectSize: PSize;
    ShieldFontInfo: ^TFontInfo;
    ShieldLeft: ^TShieldLeft;
    ShieldTop: ^TShieldTop;
    SideBar: PSideBarWindow;
    SideBarClientRect: PRect;
    SprEco: PSprites;
    SprRes: PSprites;
    SprResS: PSprites;
    Units: ^TUnits;
    UnitSelected: ^LongBool;
    UnitTypes: ^TUnitTypes;

    // Functions
    // (All THISCALLs are described as STDCALLs, then assigned with PThisCall())
    AfterActiveUnitChanged: procedure(A1: Integer); cdecl;
    ArrangeWindows: procedure; cdecl;
    CalcCityGlobals: function(CityIndex: Integer; Calc: LongBool): Integer; cdecl;
    CallRedrawAfterScroll: procedure(ControlInfoScroll: PControlInfoScroll; Pos: Integer); stdcall;
    CenterView: procedure(MapWindow: PMapWindow; X, Y: Integer); stdcall;
    CityCitizenClicked: procedure(CitizenIndex: Integer); cdecl;
    CityHasImprovement: function(CityIndex, Improvement: Integer): LongBool; cdecl;
    Citywin_CityButtonChange: procedure(A1: Integer); cdecl;
    CityWindowClose: procedure; cdecl;
    CityWindowExit: procedure; cdecl;
    CivHasTech: function(CivIndex, Tech: Integer): LongBool; cdecl;
    Clamp: function(A1, AMin, AMax: Integer): Integer; cdecl;
    ClearPopupActive: procedure; cdecl;
    CopySprite: function(Sprite: PSprite; ARect: PRect; DrawPort: PDrawPort; X, Y: Integer): PRect; stdcall;
    CopySpriteToSprite: procedure(Source, Target: PSprite); stdcall;
    CopyToPort: procedure(Src, Dst: PDrawPort; A3, A4, A5, A6, A7, A8: Integer); cdecl;
    CopyToScreenAndValidate: procedure(GraphicsInfo: PGraphicsInfo); stdcall;
    CreateDialog: procedure(Dialog: PDialogWindow); stdcall;
    CreateDialogAndWait: function(Dialog: PDialogWindow; TimeOut: Integer): Integer; stdcall;
    CreateScrollbar: function(ControlInfoScroll: PControlInfoScroll; WindowInfo: PWindowInfo; Code: Integer; Rect: PRect; Flag: Integer): PControlInfoScroll; stdcall;
    Crt_OperatorNew: function(Size: Integer): Pointer; cdecl;
    DestroyScrollBar: procedure(ControlInfoScroll: PControlInfoScroll; Flag: LongBool); stdcall;
    DisposeSprite: procedure(Sprite: PSprite); stdcall;
    Distance: function(X1, Y1, X2, Y2: Integer): Integer; cdecl;
    DlgDrawTextLine: procedure(Dialog: PDialogWindow; Text: PChar; X, Y, A5: Integer); stdcall;
    DlgParams_SetNumber: procedure(NumberIndex, Value: Integer); cdecl;
    DrawCitySprite: procedure(DrawPort: PDrawPort; CityIndex, A3, Left, Top, Zoom: Integer); cdecl;
    DrawCityWindowBuilding: procedure(CityWindow: PCityWindow; A2: Integer); stdcall;
    DrawCityWindowResources: procedure(CityWindow: PCityWindow; A2: Integer); stdcall;
    DrawCityWindowSupport: function(CityWindow: PCityWindow; Flag: LongBool): PCityWindow; stdcall;
    DrawFrame: procedure(DrawPort: PDrawPort; Rect: PRect; Color: Integer); cdecl;
    DrawInfoCreate: function(A1: PRect): PDrawInfo; cdecl;
    DrawPort_Reset: function(DrawPort: PDrawPort; Width, Height: Integer): Integer; stdcall;
    DrawString: function(ChText: PChar; Left, Top: Integer): Integer; cdecl;
    DrawStringRight: procedure(ChText: PChar; Right, Top, Shift: Integer); cdecl;
    DrawUnit: function(DrawPort: PDrawPort; UnitIndex, A3, Left, Top, Zoom, WithoutFortress: Integer): Integer; cdecl;
    ExtractSprite64x48: procedure(Sprite: PSprite; Left, Top: Integer); cdecl;
    FontPrepare: procedure(Zoom: Integer); cdecl;
    FontRecreate: procedure(FontInfo: PFontInfo; FontFaceNum, Height: Integer; Style: Byte); stdcall;
    GetAdvanceCost: function(CivIndex: Integer): Integer; cdecl;
    GetCityIndexAtXY: function(X, Y: Integer): Integer; cdecl;
    GetCivColor1: function(CivIndex: Integer): Integer; cdecl;
    GetFontHeightWithExLeading: function(thisFont: Pointer): Integer; stdcall;
    GetInfoOfClickedCitySprite: function(CitySpritesInfo: PCitySpritesInfo; X, Y: Integer; var SIndex, SType: Integer): Integer; stdcall;
    GetNextUnitInStack: function(UnitIndex: Integer): Integer; cdecl;
    GetSpecialist: function(City, SpecialistIndex: Integer): Integer; cdecl;
    GetSpriteZoom: procedure(var Numerator, Denominator: Integer); cdecl;
    GetStringInList: function(StringIndex: Integer): PChar; cdecl;
    GetTextExtentX: function(A1: PFontInfo; A2: PChar): Integer; stdcall;
    GetTopUnitInStack: function(UnitIndex: Integer): Integer; cdecl;
    GetUpkeep: function(CivIndex, Improvement: Integer): Integer; cdecl;
    Heap_Add: function(Heap: PHeap; Size: Integer): Pointer; cdecl;
    HumanTurn: function: Integer; cdecl;
    InitControlScrollRange: procedure(ControlInfoScroll: PControlInfoScroll; MinPos, MaxPos: Integer); stdcall;
    InitNewGameParameters: procedure(); cdecl;
    IsInMapBounds: function(X, Y: Integer): LongBool; cdecl;
    ListItemProcLButtonUp: procedure(Code: Integer); cdecl;
    LoadMainIcon: procedure(WindowInfo1: PWindowInfo1; IconName: Integer); stdcall;
    MapGetCivData: function(X, Y, CivIndex: Integer): PByte; cdecl;
    MapGetOwnership: function(X, Y: Integer): Integer; cdecl;
    MapGetSquare: function(X, Y: Integer): PMapSquare; cdecl;
    MapGetSquareCityRadii: function(X, Y: Integer): Integer; cdecl;
    MapSquareIsVisibleTo: function(X, Y, CivIndex: Integer): LongBool; cdecl;
    MapToWindow: procedure(MapWindow: PMapWindow; var WindowX, WindowY: Integer; MapX, MapY: Integer); stdcall;
    MenuBarAddMenu: function(MenuBar: PMenuBar; Num: Integer; Text: PChar): PMenu; stdcall;
    MenuBarAddSubMenu: function(MenuBar: PMenuBar; Num, SubNum: Integer; Text: PChar; Len: Integer): PMenu; stdcall;
    MenuBarGetSubMenu: function(MenuBar: PMenuBar; Num: Integer): PMenu; stdcall;
    Palette_SetRandomID: procedure(Palette: Pointer); stdcall;
    PFFindConnection: function(CivIndex, X1, Y1, X2, Y2: Integer): Integer; cdecl;
    PFFindUnitDir: function(UnitIndex: Integer): Integer; cdecl;
    PFMove: function(X, Y, A3: Integer): Integer; cdecl;
    PopupSimpleGameMessage: procedure(A1, A2, A3: Integer); cdecl;
    ProcessOrdersGoTo: procedure(UnitIndex: Integer); cdecl;
    ProcessUnit: function: Integer; cdecl;
    RecreateBrush: procedure(WindowInfo1: PWindowInfo1; Color: Integer); stdcall;
    RedrawMap: procedure(MapWindow: PMapWindow; CivIndex: Integer; CopyToScreen: LongBool); stdcall;
    ResetSpriteZoom: procedure(); cdecl;
    ScaleByZoom: function(Value, Zoom: Integer): Integer; cdecl;
    ScreenToMap: function(MapWindow: PMapWindow; var MapX, MapY: Integer; ScreenX, ScreenY: Integer): LongBool; stdcall;
    Scroll_Ctr: function(ControlInfoScroll: PControlInfoScroll): PControlInfoScroll; stdcall;
    SetCurrFont: procedure(A1: PFontInfo); cdecl;
    SetDIBColorTableFromPalette: procedure(DrawInfo: PDrawInfo; Palette: Pointer); cdecl;
    SetFocusAndBringToTop: procedure(WindowInfo: PWindowInfo); stdcall;
    SetFontColorWithShadow: procedure(A1, A2, A3, A4: Integer); cdecl;
    SetScrollPageSize: procedure(ControlInfoScroll: PControlInfoScroll; PageSize: Integer); stdcall;
    SetScrollPosition: procedure(ControlInfoScroll: PControlInfoScroll; Position: Integer); stdcall;
    SetSpecialist: procedure(City, SpecialistIndex, Specialist: Integer); cdecl;
    SetSpriteZoom: procedure(AZoom: Integer); cdecl;
    SetTextFromLabel: procedure(A1: Integer); cdecl; // A1 + 0x11 = Line # in Labels.txt
    SetTextIntToStr: procedure(A1: Integer); cdecl;
    ShowCityWindow: procedure(CityWindow: PCityWindow; CityIndex: Integer); stdcall;
    ShowWindowInvalidateRect: procedure(ControlInfo: PControlInfo); stdcall;
    sub_401BC7: procedure(A1: PDialogWindow; A2: PChar; A3, A4, A5, A6: Integer); stdcall;
    TileBg: function(Dst, Tile: PDrawPort; A3, A4, A5, A6, A7, A8: Integer): Integer; cdecl;
    UnitCanMove: function(UnitIndex: Integer): LongBool; cdecl;
    UpdateAdvisorCityStatus: procedure(); cdecl;
    UpdateCityWindow: procedure(CityWindow: PCityWindow; A2: Integer); stdcall;
    UpdateCopyValidateAdvisor: procedure(A1: Integer); cdecl;
    UpdateDIBColorTableFromPalette: procedure(ThisDrawPort: PDrawPort; Palette: Pointer); stdcall;
    WrapMapX: function(X: Integer): Integer; cdecl;

    constructor Create();
    destructor Destroy; override;
  published
  end;

var
  Civ2: TCiv2;

implementation

type
  TThisCallStubs = packed record
    Part1: Byte;
    Part2: Cardinal;
    Address: Cardinal;
    Part3: Byte;
  end;

var
  ThisCallStubs: array[0..255] of TThisCallStubs;
  ThisCallStubsIndex: Integer = 0;

function PThisCall(Address: Cardinal): Pointer;
begin
  ThisCallStubs[ThisCallStubsIndex].Part1 := $59; // pop     ecx
  ThisCallStubs[ThisCallStubsIndex].Part2 := $68240C87; // xchg    ecx, [esp]
  ThisCallStubs[ThisCallStubsIndex].Address := Address; // push    Address
  ThisCallStubs[ThisCallStubsIndex].Part3 := $C3; // ret
  Result := @ThisCallStubs[ThisCallStubsIndex];
  Inc(ThisCallStubsIndex);
end;

{ TCiv2 }

constructor TCiv2.Create;
begin
  inherited;
  // For inline ASM all TCiv2 fileds can be referenced directly only inside TCiv2 class, and as Self.FieldName
  // Important: by default EAX register contains Self reference
{(*}

  // Variables
  AdvisorWindow              := Pointer($0063EB10);
  CDRoot                     := Pointer($006AB680);
  ChText                     := Pointer($00679640);
  Cities                     := Pointer($0064F340);
  CityWindow                 := Pointer($006A91B8);
  CityGlobals                := Pointer($006A6528);
  CitySpiralDX               := Pointer($00628370);
  CitySpiralDY               := Pointer($006283A0);
  CityDX                     := Pointer($00630D38);
  CityDY                     := Pointer($00630D50);
  Civs                       := Pointer($0064C6A0);
  Commodities                := Pointer($0064B168);
  Cosmic                     := Pointer($0064BCC8);
  CurrPopupInfo              := Pointer($006CEC84);
  CursorX                    := Pointer($0064B1B4);
  CursorY                    := Pointer($0064B1B0);
  FontTimes14b               := Pointer($0063EAB8);
  FontTimes16                := Pointer($006AB1A0);
  FontTimes18                := Pointer($0063EAC0);
  GameParameters             := Pointer($00655AE8);
  HumanCivIndex              := Pointer($006D1DA0);
  Improvements               := Pointer($0064C488);
  Leaders                    := Pointer($006554F8);
  LoadedTxtSectionName       := Pointer($006CECB0);
  MenuBar                    := Pointer($006A64F8);
  MainWindowInfo             := Pointer($006553D8);
  MapCivData                 := Pointer($006365C0);
  MapData                    := Pointer($00636598);
  MapHeader                  := Pointer($006D1160);
  MapWindow                  := Pointer($0066C7A8);
  MapWindows                 := Pointer($0066C7A8);
  PFDX                       := Pointer($00628350);
  PFDY                       := Pointer($00628360);
  PFStopX                    := Pointer($00673FA0);
  PFStopY                    := Pointer($00673FA4);
  PFData                     := Pointer($0062D03C);
  PrevWindowInfo             := Pointer($00637EA4);
  RulesCivilizes             := Pointer($00627680);
  ScreenRectSize             := Pointer($006AB198);
  ShieldFontInfo             := Pointer($006AC090);
  ShieldLeft                 := Pointer($00642C48);
  ShieldTop                  := Pointer($00642B48);
  SideBar                    := Pointer($006ABC68);
  SideBarClientRect          := Pointer($006ABC28);
  SprEco                     := Pointer($00648860);
  SprRes                     := Pointer($00644F00);
  SprResS                    := Pointer($00645068);
  if ANewUnitsAreaAddress <> nil then
    Units                    := ANewUnitsAreaAddress
  else
    Units                    := Pointer(AUnits);
  UnitSelected               := Pointer($006D1DA8);
  UnitTypes                  := Pointer($0064B1B8);

  // Functions
  @AfterActiveUnitChanged         := Pointer($004016EF);
  @ArrangeWindows                 := Pointer($004039F4);
  @CalcCityGlobals                := Pointer($00402603);
  @CallRedrawAfterScroll          := PThisCall($005CD640);
  @CenterView                     := PThisCall($00403404);
  @CityCitizenClicked             := Pointer($0040204A);
  @CityHasImprovement             := Pointer($00402C48);
  @Citywin_CityButtonChange       := Pointer($004021D5);
  @CityWindowClose                := Pointer($00401BAE);
  @CityWindowExit                 := Pointer($004034E5);
  @CivHasTech                     := Pointer($00402E7D);
  @Clamp                          := Pointer($00402D56);
  @ClearPopupActive               := Pointer($005A3C58);
  @CopySprite                     := PThisCall($005CEF31);
  @CopySpriteToSprite             := PThisCall($005CF23F);
  @CopyToPort                     := Pointer($00402081);
  @CopyToScreenAndValidate        := PThisCall($004014A1);
  @CreateDialog                   := PThisCall($004026D5);
  @CreateDialogAndWait            := PThisCall($00401118);
  @CreateScrollbar                := PThisCall($0040FC50);
  @Crt_OperatorNew                := Pointer($005F2470);
  @DestroyScrollBar               := PThisCall($004BB4F0);
  @DisposeSprite                  := PThisCall($005CDF50);
  @Distance                       := Pointer($0040377E);
  @DlgDrawTextLine                := PThisCall($00401640);
  @DlgParams_SetNumber            := Pointer($00402FE5);
  @DrawCitySprite                 := Pointer($00402A45);
  @DrawCityWindowBuilding         := PThisCall($00403CB5);
  @DrawCityWindowResources        := PThisCall($004028C9);
  @DrawCityWindowSupport          := PThisCall($004011A9);
  @DrawFrame                      := Pointer($00401DB1);
  @DrawInfoCreate                 := Pointer($005E35B0);
  @DrawPort_Reset                 := PThisCall($005BD65C);
  @DrawString                     := Pointer($00401E0B);
  @DrawStringRight                := Pointer($00403607);
  @DrawUnit                       := Pointer($0056BAFF);
  @ExtractSprite64x48             := Pointer($0044AC07);
  @FontPrepare                    := Pointer($00401C12);
  @FontRecreate                   := PThisCall($004027B1);
  @GetAdvanceCost                 := Pointer($004030E9);
  @GetCityIndexAtXY               := Pointer($0043CF76);
  @GetCivColor1                   := Pointer($00401F8C);
  @GetFontHeightWithExLeading     := PThisCall($00403819);
  @GetInfoOfClickedCitySprite     := PThisCall($00403D00);
  @GetNextUnitInStack             := Pointer($00402E23);
  @GetSpecialist                  := Pointer($004013C0);
  @GetSpriteZoom                  := Pointer($005CDA06);
  @GetStringInList                := Pointer($00403387);
  @GetTextExtentX                 := PThisCall($00402B21);
  @GetTopUnitInStack              := Pointer($00403391);
  @GetUpkeep                      := Pointer($004014DD);
  @Heap_Add                       := Pointer($0040389B);
  @HumanTurn                      := Pointer($00402BA8);
  @InitControlScrollRange         := PThisCall($00402121);
  @InitNewGameParameters          := Pointer($0040284C);   
  @IsInMapBounds                  := Pointer($004012D0);
  @ListItemProcLButtonUp          := Pointer($005A3CCA);
  @LoadMainIcon                   := PThisCall($00402662);
  @MapGetCivData                  := Pointer($00403823);
  @MapGetOwnership                := Pointer($004029BE);
  @MapGetSquare                   := Pointer($00401BB3);
  @MapGetSquareCityRadii          := Pointer($00403A67);
  @MapSquareIsVisibleTo           := Pointer($00403C24);
  @MapToWindow                    := PThisCall($0047A6B0);
  @MenuBarAddMenu                 := PThisCall($0040117C);
  @MenuBarAddSubMenu              := PThisCall($00402D10);
  @MenuBarGetSubMenu              := PThisCall($004039EF);
  @Palette_SetRandomID            := PThisCall($005C6A42);
  @PFFindConnection               := Pointer($00403481);
  @PFFindUnitDir                  := Pointer($00402FA9);
  @PFMove                         := Pointer($004028B0);
  @PopupSimpleGameMessage         := Pointer($00410030);
  @ProcessOrdersGoTo              := Pointer($00401145);
  @ProcessUnit                    := Pointer($00402716);
  @RecreateBrush                  := PThisCall($00402045);
  @RedrawMap                      := PThisCall($00401F32);
  @ResetSpriteZoom                := Pointer($004023D3);
  @ScaleByZoom                    := Pointer($00401E83);
  @ScreenToMap                    := PThisCall($00402B2B);
  @Scroll_Ctr                     := PThisCall($004031E3);
  @SetCurrFont                    := Pointer($0040233D);
  @SetDIBColorTableFromPalette    := Pointer($005E3BDC);
  @SetFocusAndBringToTop          := PThisCall($0040325B);
  @SetFontColorWithShadow         := Pointer($00403BB6);
  @SetScrollPageSize              := PThisCall($005DB0D0);
  @SetScrollPosition              := PThisCall($004027BB);
  @SetSpecialist                  := Pointer($004022C5);
  @SetSpriteZoom                  := Pointer($00403350);
  @SetTextFromLabel               := Pointer($0040BC10);
  @SetTextIntToStr                := Pointer($00401ED8);
  @ShowCityWindow                 := PThisCall($00402E78);
  @ShowWindowInvalidateRect       := PThisCall($0040169A);
  @sub_401BC7                     := PThisCall($00401BC7);
  @TileBg                         := Pointer($00402C9D);
  @UnitCanMove                    := Pointer($0040273E);
  @UpdateAdvisorCityStatus        := Pointer($004029F5);
  @UpdateCityWindow               := PThisCall($00402833);
  @UpdateCopyValidateAdvisor      := Pointer($00402A9A);
  @UpdateDIBColorTableFromPalette := PThisCall($005C0D12);
  @WrapMapX                       := Pointer($004022ED);
{*)}

  // Check structure sizes
  if SizeOf(TMSWindow) <> $2D8 then
    raise Exception.Create('Wrong size of TMSWindow');
  if SizeOf(TWindowInfo) <> $C5 then
    raise Exception.Create('Wrong size of TWindowInfo');
  if SizeOf(TCityWindow) <> $16E0 then
    raise Exception.Create('Wrong size of TCityWindow');
  if SizeOf(TGraphicsInfo) <> $114 then
    raise Exception.Create('Wrong size of TGraphicsInfo');
  if SizeOf(TMapWindow) <> $3F0 then
    raise Exception.Create('Wrong size of TMapWindow');
  if SizeOf(TUnit) <> $20 then
    raise Exception.Create('Wrong size of TUnit');
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

end.

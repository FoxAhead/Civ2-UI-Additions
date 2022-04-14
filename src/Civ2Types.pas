unit Civ2Types;

interface

uses
  Windows;

type
  PCityWindow = ^TCityWindow;

  PCitySpritesInfo = ^TCitySpritesInfo;

  PWindowInfo = ^TWindowInfo;

  PControlBlock = ^TControlBlock;

  PControlInfo = ^TControlInfo;

  PControlInfoButton = ^TControlInfoButton;

  PControlInfoScroll = ^TControlInfoScroll;

  PDrawPort = ^TDrawPort;

  PGraphicsInfo = ^TGraphicsInfo;

  PGraphicsInfoMap = ^TGraphicsInfoMap;

  PWindowStructure = ^TWindowStructure;

  PCurrPopupInfo = ^TCurrPopupInfo;

  PPCurrPopupInfo = ^PCurrPopupInfo;

  PDrawInfo = ^TDrawInfo;

  PAdvisorWindow = ^TAdvisorWindow;

  PGameParameters = ^TGameParameters;

  PSprite = ^TSprite;

  PSprites = ^TSprites;

  PUnit = ^TUnit;

  TWindowProcs = packed record            // Size 0x68  GetWindowLongA(hWnd, 4) + 0x10
    MouseFirst: Pointer;
    LButtonDown: Pointer;                 // + 0x04
    LButtonUpEnd: Pointer;                // + 0x08
    LButtonUp: Pointer;                   // + 0x0C
    RButtonDown: Pointer;                 // + 0x10
    RButtonUpEnd: Pointer;                // + 0x14
    RButtonUp: Pointer;                   // + 0x18
    LButtonDblClk: Pointer;               // + 0x1C
    KeyDown1: Pointer;                    // + 0x20
    KeyUp: Pointer;                       // + 0x24
    KeyDown2: Pointer;                    // + 0x28
    WM_CHAR: Pointer;                     // + 0x2C
    _Unknown1: Pointer;                   // + 0x30
    _Unknown2: Pointer;                   // + 0x34
    _Unknown3: Pointer;                   // + 0x38
    WM_SETFOCUS: Pointer;                 // + 0x3C
    WM_SIZE: Pointer;                     // + 0x40
    WM_MOVE: Pointer;                     // + 0x44
    WM_COMMNOTIFY: Pointer;               // + 0x48
    _Unknown8: Pointer;                   // + 0x4C
    Proc21: Pointer;                      // + 0x50
    Proc22: Pointer;                      // + 0x54
    Proc23: Pointer;                      // + 0x58
    Proc24: Pointer;                      // + 0x5C
    Proc25: Pointer;                      // + 0x60
    Proc26: Pointer;                      // + 0x64
  end;

  TWindowInfo = packed record             // GetWindowLongA(hWnd, 4),  GetWindowLongA(hWnd, 8)
    Style: Integer;                       // = 0x00000C02 ...
    Palette: Pointer;                     // + 0x04
    WindowStructure: PWindowStructure;    // + 0x08
    Unknown_0C: Integer;                  // + 0x0C
    WindowProcs: TWindowProcs;            // + 0x10
    Unknown_78: Integer;                  // + 0x78
    MinTrackSize: TPoint;                 // + 0x7C
    MaxTrackSize: TPoint;                 // + 0x84
    PopupActive: Cardinal;                // + 0x8C
    Unknown_90: array[$90..$B7] of Byte;  // + 0x90
    ControlInfo: PControlInfo;            // + 0x94
    ButtonInfoOK: PControlInfoButton;     // + 0xBC
    ButtonInfoCANCEL: PControlInfoButton; // + 0xC0
    Unknown_C4: Byte;                     // + 0xC4
  end;

  TCitySprite = packed record
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
    SType: Integer;
    // 1 = Resource Map
    // 2 = Citizens
    // 3 = Units Present
    // 4 = City Improvements
    // 5 = Construction
    // 6 = Units Supported
    SIndex: Integer;
  end;

  TCitySprites = array[0..199] of TCitySprite;

  TCitySpritesInfo = packed record        // 6A9490
    CitySprites: TCitySprites;            //
    CitySpritesItems: Integer;            // + 12C0 = 6AA750
  end;

  TCityWindow = packed record             // 6A91B8 (~TGraphicsInfo) Size = $16E0
    Unknown1: array[0..$13] of Byte;
    ClientRectangle: TRect;
    WindowRectangle: TRect;
    SpriteArea: Pointer;
    Unknown1a: Integer;
    PrevPaletteID: Integer;
    DrawInfo: PDrawInfo;
    Unknown1b: Integer;
    WindowInfo: TWindowInfo;
    Unknown1c: array[$48 + SizeOf(TWindowInfo)..$2D7] of Byte;
    CitySpritesInfo: TCitySpritesInfo;    // + 2D8 = 6A9490
    CityIndex: Integer;                   // + 159C
    Unknown2: Integer;
    Unknown3: Integer;
    Unknown4: Integer;
    Unknown5: Integer;
    Unknown6: Integer;
    ImproveListStart: Integer;
    ImproveCount: Integer;
    Unknown7: array[$15BC..$15D3] of Byte; // + 15B8
    WindowSize: Integer;                  // + 15D4 = 6AA78C  // 1, 2, 3
    Unknown8: Integer;                    //
    RectCitizens: TRect;                  //
    Rect1: TRect;                         // + 15EC
    RectFoodStorage: TRect;               //
    Rect3: TRect;                         //
    Rect4: TRect;                         //
    RectSupportOut: TRect;                //
    RectImproveOut: TRect;                //
    RectInfoOut: TRect;                   //
    RectResourceMap: TRect;               //
    RectImproveIn: TRect;                 // + 166C
    RectSupportIn: TRect;                 //
    RectInfoIn: TRect;                    //
    RectImproveScroll: TRect;             //
    Unknown10: array[$16AE..$16B5] of Byte; //
    ControlInfo: array[1..10] of Pointer; //
    ControlInfoScroll: PControlInfoScroll; //
  end;

  TControlBlock = packed record           // Size = 0x30  GetWindowLongA(hWnd, 0)  (sub_5C9499)
    hMem: HGLOBAL;
    ControlInfo: PControlInfo;
    Unknown_08: Integer;
    Unknown_0C: Integer;
    Unknown_10: Integer;
    Unknown_14: Integer;
    Unknown_18: Integer;
    Unknown_1C: Integer;
    Unknown_20: Integer;
    Unknown_24: Integer;
    Unknown_28: Integer;
    Unknown_2C: Integer;
  end;

  TControlInfo = packed record            // Size = $2C
    ControlType: Integer;                 //  8-Scrollbar, 7-ListBox, 6-Button, 4-EditBox, 3-RadioButton(Group), 2-CheckBox, 1-ListItem
    Code: Integer;                        // + 0x04
    // Button: 0x64 - OK, 0x65 - Cancel
    // ListItem: 0x3E8 + Index, 0x12C + Index
    // Scroll: 0xC8, 0xB, 0xC, 0x65
    WindowInfo: PWindowInfo;              // + 0x08
    Rect: TRect;                          // + 0x0C (Left, Top, Right, Bottom)
    HWindow: HWND;                        // + 0x1C
    ControlInfo: PControlInfo;            // + 0x20
    Unknown_24: Byte;                     // + 0x24
    Unknown_25: Byte;                     // + 0x25
    Unknown_26: Byte;                     // + 0x26
    Unknown_27: Byte;                     // + 0x27
    Unknown_28: Integer;                  // + 0x28
  end;

  TControlInfoButton = packed record      // Size = $3C
    ControlInfo: TControlInfo;
    Active: Integer;                      // + 0x2C
    Proc: Pointer;                        // + 0x30
    Unknown_34: Integer;                  // + 0x34
    Unknown_38: Integer;                  // + 0x38
  end;

  TControlInfoScroll = packed record      // Size = $40  GetWindowLongA(hWnd, GetClassLongA(hWnd, GCL_CBWNDEXTRA) - 8)
    ControlInfo: TControlInfo;
    ProcRedraw: Pointer;                  // + 0x2C
    ProcTrack: Pointer;                   // + 0x30
    PageSize: Integer;                    // + 0x34
    Unknown_38: Integer;                  // + 0x38
    CurrentPosition: Integer;             // + 0x3C
  end;

  TCurrPopupInfo = packed record
    GraphicsInfo: PGraphicsInfo;
    Unknown1: array[$04..$27] of Byte;    // + 0x04
    NumberOfLines: Integer;               // + 0x28 [A]
    NumberOfItems: Integer;               // + 0x2C [B]
    NumberOfButtons: Integer;             // + 0x30 [C]
    NumberOfButtons2: Integer;            // + 0x34 [D]
    ScrollPageSize: Integer;              // + 0x38 [E]
    Flags: Integer;                       // + 0x3C : 0x400-ClearPopup, 0x2000-Choose
    Width: Integer;                       // + 0x40
    Height: Integer;                      // + 0x44
    Unknown4: array[$48..$D7] of Byte;    // + 0x48
    SelectedItem: Cardinal;               // + 0xD8 : 0xFFFFFFFF - None

    Unknown2: Integer;                    // + 0xC8 [0x32]
    Unknown3: Integer;                    // + 0xCC [0x33]

    Left: Integer;                        // + 0xE8
    Top: Integer;                         // + 0xEC

    DialogItemList: Pointer;              // + 0x234 [8D]

    ProcReturn1: Pointer;                 // + 0x240 (Is DblClk => OK?)

    ListItems: array of TControlInfo;     // + 0x280
  end;

  TDrawPort = packed record               // Part of TGraphicsInfo; TODO: Move to TGraphicsInfo
    _Proc: Pointer;
    RectWidth: Integer;
    RectHeight: Integer;
    BmWidth4: Integer;
    BmWidth4u: Integer;
    ClientRectangle: TRect;
    WindowRectangle: TRect;
    pBmp: Pointer;
    RowsAddr: Pointer;
    PrevPaletteID: Integer;
    DrawInfo: PDrawInfo;
    ColorDepth: Integer;
  end;

  TGraphicsInfo = packed record           // GetWindowLongA(hWnd, 0x0C), Size = 0x114 (sub_5DEE28)
    DrawPort: TDrawPort;
    WindowInfo: TWindowInfo;              // + 0x48
    Unknown_10D: Byte;
    Unknown_10E: Byte;
    Unknown_10F: Byte;
    UpdateProc: Pointer;                  // + 0x110
  end;

  TGraphicsInfoMap = packed record        // Size = 0x3F0
    GraphicsInfo: TGraphicsInfo;          //
    Unknown_114: Integer;                 // + 0x114
    _CaptionHeight: Integer;              // + 0x118
    Unknown_11C: Integer;                 // + 0x11C
    _ResizeBorderWidth: Integer;          // + 0x120
    ClientTopLeft: TPoint;                // + 0x124
    ClientSize: TSize;
    Unknown6: array[$134..$2DF] of Byte;
    MapCenter: TSmallPoint;               // + 0x2E0
    MapZoom: Smallint;                    // + 0x2E4
    Unknown7: Smallint;                   // + 0x2E6
    MapRect: TRect;                       // + 0x2E8
    MapHalf: TSize;                       // + 0x2F8
    Unknown8: array[$300..$307] of Byte;
    MapCellSize: TSize;                   // + 0x308
    MapCellSize2: TSize;                  // + 0x310  1/2
    MapCellSize4: TSize;                  // + 0x318  1/4
    Unknown10: array[1..32] of Integer;
    DrawInfo2: PDrawInfo;
    Unknown11: array[1..19] of Integer;
  end;

  TMapGraphicsInfos = array[0..7] of TGraphicsInfoMap;

  // T_GraphicsInfoEx Size = 0xA28 (sub_4D5B21)

  TDrawInfo = packed record               //  Size = $28
    Unknown0: Integer;
    DeviceContext: HDC;                   // + 0x04
    Unknown1: HGDIOBJ;
    Unknown2: HGDIOBJ;
    Unknown3: HGDIOBJ;
    Unknown4: Integer;
    Width: Integer;
    Height: Integer;
    Unknown7: Integer;
    Unknown8: Integer;
  end;

  TDialogItem = packed record
    Code: Integer;
    Unknown1: Integer;                    // + 0x04
    Text: Pointer;                        // + 0x08
    Rect: Pointer;                        // + 0x0C
    NextItem: Pointer;                    // + 0x10
    ItemText: array of Char;
  end;

  TWindowStructure = packed record        // Size = $4C ?
    Unknown1: Integer;
    HWindow: HWND;                        // + 0x04
    DeviceContext: HDC;
    Unknown2: array[$0C..$1F] of Byte;
    Icon: HICON;                          // + 0x20
    Unknown_24: Integer;
    Unknown_28: Integer;
    Unknown_2C: Integer;
    _Moveable: Integer;
    _Sizeable: Integer;
    _CaptionHeight: Integer;
    _ResizeBorderWidth: Integer;
    Unknown_40: Integer;
    Unknown_44: Integer;
    Unknown_48: Integer;
  end;

  PHFONT = ^HFONT;

  PPHFONT = ^PHFONT;

  TFontInfo = packed record
    Handle: PPHFONT;
    Height: Longint;
  end;

  TSprite = packed record
    Rectangle1: TRect;
    Rectangle2: TRect;
    Rectangle3: TRect;
    Unknown1: Integer;
    hMem: HGLOBAL;
    pMem: Pointer;
  end;

  TSprites = array[0..5] of TSprite;

  TMSWindow = packed record               // Size = 0x2D8
    GraphicsInfo: TGraphicsInfo;
    Unknown_114: Integer;
    _CaptionHeight: Integer;
    Unknown_11C: Integer;
    _ResizeBorderWidth: Integer;
    ClientTopLeft: TPoint;
    ClientSize: TSize;
    Unknown1b: array[1..105] of Integer;
  end;

  TAdvisorWindow = packed record          // Size = 0x4A4
    MSWindow: TMSWindow;
    BgDrawPort: TDrawPort;
    ControlInfoButton: array[1..3] of TControlInfoButton;
    Unknown_3D4: array[1..15] of Integer;
    ControlInfoScroll: TControlInfoScroll;
    AdvisorType: Integer;
    //  1 - F1  City Status
    //  2 - F2  Defence Minister
    //  3 - F3  Intelligence Report
    //  4 - F4  Attitude Advisor
    //  5 - F5  Trade Advisor
    //  6 - F6  Science Advisor
    //  7 - F7  Wonders of the World
    //  8 - F8  Top 5 Cities, About Civilization II
    //  9 - F11 Demographics
    // 10 - F9  Civilization Score
    // 12 - Ctrl-D Casaulty Timeline
    Unknown2: array[1..2] of Integer;
    CurrCivIndex: Integer;
    aPosition: Integer;
    aPageSize: Integer;
    Unknown2a: array[1..3] of Integer;
    Height: Integer;
    Unknown3: array[1..5] of Integer;
    Width: Integer;
    Unknown_490: Integer;
    ScrollBarWidth: Integer;
    Unknown_498: Integer;
    Unknown_49C: Integer;
    Popup: Integer;
  end;

  TTaxWindow = packed record              // Size = 0x4D0
    MSWindow: TMSWindow;
    CivIndex: Integer;                    // + 0x2D8
    MaxRate: Integer;                     // + 0x2DC
    TaxRateF: Integer;                    // + 0x2E0
    LuxuryRateF: Integer;                 // + 0x2E4
    ScienceRateF: Integer;                // + 0x2E8
    TaxRate: Integer;                     // + 0x2EC
    LuxuryRate: Integer;                  // + 0x2F0
    ScienceRate: Integer;                 // + 0x2F4
    ClientWidth: Integer;                 // + 0x2F8
    ClientHeight: Integer;                // + 0x2FC
    Unknown_300: Integer;
    Unknown_304: Integer;
    Unknown_308: Integer;
    Unknown_30C: Integer;
    Unknown_310: Integer;
    Unknown_314: Integer;
    Unknown_318: Integer;
    Unknown_31C: Integer;
    ScrollBarHeight: Integer;
    Unknown_324: array[1..107] of Integer;
  end;

  TGameParameters = packed record
    word_655AE8: Word;
    dword_655AEA: Integer;
    word_655AEE: Word;
    MapFlags: Word;
    word_655AF2: Word;
    word_655AF4: Word;
    word_655AF6: Word;
    Turn: Word;
    Year: Word;
    word_655AFC: Word;
    ActiveUnitIndex: Word;                // Current unit index
    word_655B00: Word;
    PlayerTribeNumber: Byte;              // not PlayerTribeNumber?
    byte_655B03: Byte;                    // PlayerTribeNumber?
    byte_655B04: Byte;
    SomeCivIndex: Byte;                   // Active Unit Civ index?
    byte_655B06: Byte;
    byte_655B07: Byte;
    DifficultyLevel: Byte;
    BarbarianActivity: Byte;
    TribesLeftInPlay: Byte;
    HumanPlayers: Byte;
    byte_655B0C: Byte;
    byte_655B0D: Byte;
    byte_655B0E: Byte;
    byte_655B0F: Byte;
    word_655B10: Word;
    word_655B12: Word;
    word_655B14: Word;
    TotalUnits: Word;
    TotalCities: Word;
    word_655B1A: Word;
    word_655B1C: Word;
    byte_655B1E: array[1..34] of Byte;
    byte_655B40: Byte;
    byte_655B41: array[1..3] of Byte;
    byte_655B44: Byte;
  end;

  TImprovement = packed record            // Size = 0x08
    StringIndex: Cardinal;
    Cost: Byte;
    Upkeep: Byte;
    Unknown2: Byte;
    Unknown3: Byte;
  end;

  TImprovements = array[0..66] of TImprovement; // 64C488

  TUnitType = packed record               // Size = 0x14
    StringIndex: Cardinal;
    dword_64B1BC: Cardinal;
    byte_64B1C0: Byte;
    Domain: Byte;
    // 0 = Ground
    // 1 = Air
    // 2 = Sea
    byte_64B1C2: Byte;
    byte_64B1C3: Byte;
    Att: Byte;
    Def: Byte;
    byte_64B1C6: Byte;
    byte_64B1C7: Byte;
    Cost: Byte;
    byte_64B1C9: Byte;
    Role: Byte;                           // 0x64B1CA
    // 0 = Attack
    // 1 = Defend
    // 2 = Naval Superiority
    // 3 = Air Superiority
    // 4 = Sea Transport
    // 5 = Settle
    // 6 = Diplomacy
    // 7 = Trade
    byte_64B1CB: Byte;
  end;

  TUnitTypes = array[0..$3D] of TUnitType; // 64B1B8

  TUnit = packed record                   // Size = 0x20
    X: Word;                              // X
    Y: Word;                              // Y
    Attributes: Word;
    // 0010 0000 0000 0000 - 0x2000 Veteran
    // 0100 0000 0000 0000 - 0x4000 Unit issued with the 'wait' order
    UnitType: Byte;                       // 0x6560F6
    CivIndex: Byte;                       // 0x6560F7
    MovePoints: Byte;                     // 0x6560F8 (Move * Road movement multiplier)
    byte_6560F9: Byte;
    byte_6560FA: Byte;
    MoveDirection: Byte;                  // 0x6560FB
    byte_6560FC: Byte;
    Counter: Byte;                        // 0x6560FD Settlers work / Caravan commodity / Air turn
    MoveIteration: Byte;
    Orders: Byte;                         // 0x6560FF
    // 0x01 Fortify
    // 0x02 Fortified
    // 0x03 Sleep
    // 0x04 Build fortress
    // 0x05 Build road/railroad
    // 0x06 Build irrigation
    // 0x07 Build mine
    // 0x08 Transform terrain
    // 0x09 Clean up pollution
    // 0x0A Build airbase
    // 0x0B, 0x1B Go to
    // 0xFF No orders
    HomeCity: Byte;                       // 0x656100
    byte_656101: Byte;
    GotoX: Word;                          // 0x656102
    GotoY: Word;                          // 0x656104
    PrevInStack: Word;                    // 0x656106
    NextInStack: Word;                    // 0x656108
    ID: Integer;
    word_65610E: Word;
  end;

  TUnits = array[0..$7FF] of TUnit;       // 6560F0

  TCity = packed record                   // Size = 0x58
    X: Smallint;                          //
    Y: Smallint;                          // + 0x02
    Attributes: Cardinal;                 // + 0x04
    // 0000 0000 0000 0001 - Disorder
    // 0000 0000 0000 0010 - We Love the King Day
    Owner: Byte;                          // + 0x08
    Size: Byte;                           // + 0x09
    Founder: Byte;                        // + 0x0A
    TurnsCaptured: Byte;                  // + 0x0B
    byte_64F34C: Byte;
    RevealedSize: array[1..9] of Byte;
    Specialists: Cardinal;
    // 00 - No specialist
    // 01 - Entertainer
    // 10 - Taxman
    // 11 - Scientist
    FoodStorage: Smallint;
    BuildProgress: Smallint;
    BaseTrade: Smallint;
    Name: array[0..15] of Char;
    dword_64F370: Integer;
    Improvements: array[1..5] of Byte;
    Building: Shortint;
    byte_64F37A: Byte;
    byte_64F37B: Byte;
    byte_64F37C: array[1..2] of Byte;
    byte_64F37E: Byte;
    byte_64F37F: array[1..2] of Byte;
    byte_64F381: Byte;
    byte_64F382: array[1..2] of Byte;
    word_64F384: Smallint;
    word_64F386: array[1..2] of Smallint;
    Science: Smallint;
    Tax: Smallint;
    Trade: Smallint;
    TotalFood: Byte;
    TotalShield: Byte;
    HappyCitizens: Byte;
    UnHappyCitizens: Byte;
    ID: Integer;
  end;

  TCities = array[0..$FF] of TCity;       // 64F340

  TCiv = packed record                    // Size = 0x594
    Unknown1: Word;                       //          64C6A0
    Gold: Integer;                        // + 0x02 = 64C6A2
    Leader: Word;                         // + 0x06 = 64C6A6
    Beakers: Word;                        // + 0x08 = 64C6A8
    Unknown3: array[$A..$14] of Byte;
    Government: Byte;
    Unknown4: array[$16..$1F] of Byte;
    Treaties: array[0..7] of Integer;
    // 0x00000001 Contact
    // 0x00000002 Cease Fire
    // 0x00000004 Peace
    // 0x00000008 Alliance
    // 0x00000010 Vendetta
    // 0x00000080 Embassy
    // 0x00002000 War
    Unknown9: array[$40..$153] of Byte;
    DefMinUnitBuilding: array[0..61] of Byte;
    Unknown10: array[$192..$593] of Byte;
  end;

  TCivs = array[1..8] of TCiv;            // 64C6A0

  TShieldLeft = array[0..$3E] of Integer; // 642C48

  TShieldTop = array[0..$3E] of Integer;  // 642B48

  TLeader = packed record                 // Size = 0x30
    Attack: Byte;
    Expand: Byte;
    Civilize: Byte;
    Female: Byte;
    byte_6554FC: Byte;
    CitiesBuilt: Byte;
    Color: Word;
    Style: Word;
    word_655502: Word;
    word_655504: Word;
    word_655506: Word;
    word_655508: Word;
    word_65550A: Word;
    word_65550C: array[1..14] of Word;
  end;

  TLeaders = array[1..21] of TLeader;     // 6554F8

const
  //AThisCitySprites = $006A9490;
  AUnits = $6560F0;
  //A_j_Q_GetInfoOfClickedCitySprite_sub_46AD85 = $00403D00;
  //A_j_Q_ScreenToMap_sub_47A540 = $00402B2B;
  //A_j_Q_RedrawMap_sub_47CD51 = $00401F32;
  //A_Q_GetFontHeightWithExLeading_sub_403819 = $00403819;
  //A_Q_On_WM_TIMER_sub_5D47D0 = $005D47D0;
  A_Q_LoadMainIcon_sub_408050 = $00408050;
  A_j_Q_GetNumberOfUnitsInStack_sub_5B50AD = $004029E1;
  A_Q_PopupListOfUnits_sub_5B6AEA = $005B6AEA;
  //A_Q_CreateScrollbar_sub_40FC50 = $0040FC50;
  A_Q_InitNewGameParameters_sub_4AA9C0 = $004AA9C0;
  CST_RESOURCES: Integer = 1;
  CST_CITIZENS: Integer = 2;
  CST_UNITS_PRESENT: Integer = 3;
  CST_IMPROVEMENTS: Integer = 4;
  CST_BUILD: Integer = 5;
  CST_SUPPORTED_UNITS: Integer = 6;

var
  ANewUnitsAreaAddress: Pointer = nil;    // For Units Limit patch

implementation

end.

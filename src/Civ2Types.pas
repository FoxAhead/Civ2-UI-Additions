unit Civ2Types;

interface

uses
  SysUtils,
  Windows;

type
  PCityWindow = ^TCityWindow;

  PCityGlobals = ^TCityGlobals;

  PCitySpritesInfo = ^TCitySpritesInfo;

  PHeap = ^THeap;

  PMenu = ^TMenu;

  PMenuBar = ^TMenuBar;

  PMenuInfo = ^TMenuInfo;

  PWindowInfo = ^TWindowInfo;

  PFontInfo = ^TFontInfo;

  PControlBlock = ^TControlBlock;

  PControlInfo = ^TControlInfo;

  PControlInfoListItem = ^TControlInfoListItem;

  PControlInfoListItems = ^TControlInfoListItems;

  PControlInfoRadio = ^TControlInfoRadio;

  PControlInfoRadios = ^TControlInfoRadios;

  PControlInfoRadioGroup = ^TControlInfoRadioGroup;

  PControlInfoButton = ^TControlInfoButton;

  PControlInfoButtons = ^TControlInfoButtons;

  PControlInfoScroll = ^TControlInfoScroll;

  PListItem = ^TListItem;

  PDlgTextLine = ^TDlgTextLine;

  PDrawPort = ^TDrawPort;

  PGraphicsInfo = ^TGraphicsInfo;

  PMapWindow = ^TMapWindow;

  PMapWindows = ^TMapWindows;

  PWindowStructure = ^TWindowStructure;

  PDialogWindow = ^TDialogWindow;

  PDialogExtra = ^TDialogExtra;

  PPDialogWindow = ^PDialogWindow;

  PDrawInfo = ^TDrawInfo;

  PAdvisorWindow = ^TAdvisorWindow;

  PCosmic = ^TCosmic;

  PGameParameters = ^TGameParameters;

  PMapHeader = ^TMapHeader;

  PMapCivData = ^TMapCivData;

  PMapSquare = ^TMapSquare;

  PMapSquares = ^TMapSquares;

  PPFData = ^TPFData;

  PSprite = ^TSprite;

  PSprites = ^TSprites;

  PMSWindow = ^TMSWindow;

  PUnit = ^TUnit;

  PCity = ^TCity;

  TWindowProcs = packed record            // Size = 0x68
    ProcMouseMove: Pointer;
    ProcLButtonDown: Pointer;             // + 0x04
    ProcLButtonUpEnd: Pointer;            // + 0x08
    ProcLButtonUp: Pointer;               // + 0x0C
    ProcRButtonDown: Pointer;             // + 0x10
    ProcRButtonUpEnd: Pointer;            // + 0x14
    ProcRButtonUp: Pointer;               // + 0x18
    ProcLButtonDblClk: Pointer;           // + 0x1C
    ProcKeyDown1: Pointer;                // + 0x20
    ProcKeyUp: Pointer;                   // + 0x24
    ProcKeyDown2: Pointer;                // + 0x28
    ProcChar: Pointer;                    // + 0x2C
    ProcClose: Pointer;                   // + 0x30
    ProcSysCommandMinimize: Pointer;      // + 0x34
    ProcSysCommandRestore: Pointer;       // + 0x38
    ProcSetFocus: Pointer;                // + 0x3C
    ProcSize: Pointer;                    // + 0x40
    ProcMove: Pointer;                    // + 0x44
    ProcCommNotify: Pointer;              // + 0x48
    ProcHScroll: Pointer;                 // + 0x4C
    ProcHScrollThumbTrack: Pointer;       // + 0x50
    ProcVScroll: Pointer;                 // + 0x54
    ProcVScrollThumbTrack: Pointer;       // + 0x58
    Proc24: Pointer;                      // + 0x5C
    ProcEnterSizeMove: Pointer;           // + 0x60
    ProcExitSizeMove: Pointer;            // + 0x64
  end;

  THeap = packed record                   // Size = $12
    Unknown_00: Byte;
    Unknown_01: Byte;
    Unknown_02: Byte;
    Unknown_03: Byte;
    hMem: HGLOBAL;
    pMem: Pointer;
    Size: Word;
    AllocSize: Word;
    FreeSize: Word;
  end;

  TMenu = packed record
    Text: PChar;
    Num: Integer;
    Flags: Cardinal;
    SubCount: Integer;
    Next: PMenu;
    Prev: PMenu;
    FirstSubMenuOrParent: PMenu;
  end;

  TMenuBar = packed record
    hMenu: HMENU;
    Heap: THeap;
    Unknown_16: Word;
    Flags: Cardinal;
    FirstMenu: PMenu;
  end;

  TMenuInfo = packed record
    WindowInfo: PWindowInfo;
    MenuBar: PMenuBar;
    Proc: Pointer;
  end;

  // WindowProc1        - GetWindowLongA(hWnd, 8)
  // WindowProcCommon   - GetWindowLongA(hWnd, 4)
  // WindowProcMSWindow - GetWindowLongA(hWnd, 0)
  TWindowInfo = packed record             // Size = 0xC5
    Style: Integer;                       //
    Palette: Pointer;                     // + 0x04
    WindowStructure: PWindowStructure;    // + 0x08
    Unknown_0C: Integer;                  // + 0x0C
    WindowProcs: TWindowProcs;            // + 0x10
    Unknown_78: Integer;                  // + 0x78
    MinTrackSize: TPoint;                 // + 0x7C
    MaxTrackSize: TPoint;                 // + 0x84
    PopupActive: Cardinal;                // + 0x8C
    Unknown_90: Integer;                  // + 0x90
    Unknown_94: Integer;                  // + 0x94
    Unknown_98: Integer;                  // + 0x98
    Unknown_9C: Integer;                  // + 0x9C
    Unknown_A0: Integer;                  // + 0xA0
    Unknown_A4: Integer;                  // + 0xA4
    LButtonDown: Integer;                 // + 0xA8
    RButtonDown: Integer;                 // + 0xAC
    HScrollPos: Integer;                  // + 0xB0
    VScrollPos: Integer;                  // + 0xB4
    ControlInfo: PControlInfo;            // + 0xB8
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
    // Scroll: 0xC8, 0xB (Vert), 0xC(Horz), 0x65
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

  // ControlType = 1
  TControlInfoListItem = packed record    // Size = $40
    ControlInfo: TControlInfo;
    Unknown_2C: Integer;
    ProcMouseMove: Pointer;
    ProcLButtonUp: Pointer;
    ProcLButtonDown: Pointer;
    ProcLButtonDblClk: Pointer;
  end;

  TControlInfoListItems = array[0..0] of TControlInfoListItem;

  TControlInfoRadio = packed record       // Size = $A4
    HWindow: HWND;
    Rect: TRect;
    Index: Integer;
    Enabled: Integer;
    Text: array[0..127] of Char;
    HotKey: array[0..3] of Char;
    HotKeyPos: Integer;
  end;

  TControlInfoRadios = array[0..0] of TControlInfoRadio;

  // ControlType = 3
  TControlInfoRadioGroup = packed record  // Size = $50
    ControlInfo: TControlInfo;
    ProcLButtonDown: Pointer;
    Proc2: Pointer;
    ProcRButtonDown: Pointer;
    NRadios: Integer;
    Columns: Integer;
    Selected: Integer;
    hRadios: HGLOBAL;
    pRadios: PControlInfoRadios;
    FontInfo: PFontInfo;
  end;

  // ControlType = 6
  TControlInfoButton = packed record      // Size = $3C
    ControlInfo: TControlInfo;
    Active: Integer;                      // + 0x2C
    Proc: Pointer;                        // + 0x30
    ButtonColor: Integer;                 // + 0x34
    FontInfo: PFontInfo;                  // + 0x38
  end;

  TControlInfoButtons = array[0..0] of TControlInfoButton;

  // ControlType = 8
  TControlInfoScroll = packed record      // Size = $40  GetWindowLongA(hWnd, GetClassLongA(hWnd, GCL_CBWNDEXTRA) - 8)
    ControlInfo: TControlInfo;
    ProcRedraw: Pointer;                  // + 0x2C
    ProcTrack: Pointer;                   // + 0x30
    PageSize: Integer;                    // + 0x34
    Unknown_38: Integer;                  // + 0x38
    CurrentPosition: Integer;             // + 0x3C
  end;

  PListboxItem = Pointer;

  TListItem = packed record
    UnitIndex: Integer;
    Unknown_04: Integer;
    Text: PChar;
    Sprite: PSprite;
    Next: PListItem;
  end;

  TDlgTextLine = packed record
    Index: Integer;
    Flags: Integer;
    Text: PChar;
    Size: Integer;
    Unknown_10: Integer;
    Unknown_14: Integer;
    Unknown_18: Integer;
    Next: PDlgTextLine;
  end;

  PEdit = Pointer;

  PControlInfoCheckbox = Pointer;

  PControlInfoEdit = Pointer;

  TButton = packed record
    StdType: Integer;
    Left: Integer;
  end;

  TDlgProc3SpriteDraw = procedure(Sprite: PSprite; GraphicsInfo: PGraphicsInfo; A3, A4, A5, A6: Integer); cdecl;

  TDialogWindow = packed record           // Size = $2F4 ?
    GraphicsInfo: PGraphicsInfo;
    DrawPort: PDrawPort;
    FontInfo1: PFontInfo;
    FontInfo2: PFontInfo;
    FontInfo3: PFontInfo;
    Unknown_14: Integer;
    Unknown_18: Integer;
    _Height: Integer;
    NumTextLines: Integer;
    NumEdits: Integer;
    NumLines: Integer;
    NumListItems: Integer;
    NumButtonsStd: Integer;
    NumButtons: Integer;
    Columns: Integer;
    Flags: Integer;
    // 0x00000001 - Has Cancel button (StdType = 2)
    // 0x00000004 - Checkboxes
    // 0x00000008 - Don't show
    // 0x00000020 - Created
    // 0x00000040 - Has Help button (StdType = 1)
    // 0x00000200 - Created parts
    // 0x00000400 - ClearPopup
    // 0x00001000 - Has ListBox
    // 0x00002000 - Choose
    // 0x00004000 - Without background
    // 0x00010000 - System popup
    // 0x00040000 - System listbox
    // 0x01000000 - Force scrollbar for listbox
    // 0x02000000 - Without Ok button (StdType = 0)
    ClientSize: TSize;
    ScrollOrientation: Integer;
    ListboxWidth: array[0..1] of Integer;
    ListboxHeight: array[0..1] of Integer;
    ListboxPageSize: array[0..1] of Integer;
    Color1: Integer;
    Color2: Integer;
    Color3: Integer;
    Color4: Integer;
    Color5: Integer;
    Color6: Integer;
    Color7: Integer;
    RatioNumerator: Integer;
    RatioDenominator: Integer;
    Unknown_88: Integer;
    Unknown_8C: Integer;
    Color8: Integer;
    Unknown_94: Integer;
    Unknown_98: Integer;
    Color9: Integer;
    Unknown_A0: Integer;
    Unknown_A4: Integer;
    Unknown_A8: Integer;
    Unknown_AC: Integer;
    Unknown_B0: Integer;
    Unknown_B4: Integer;
    VertPadding: Integer;
    HorzMargin: Integer;
    LineSpacing: Integer;
    TextIndent: Integer;
    Bevel: Integer;
    LRFrame: Integer;
    CaptionHeight: Integer;
    Unknown_D4: Integer;
    SelectedItem: Cardinal;
    PressedButton: Integer;
    Position: TPoint;
    ClientTopLeft: TPoint;
    Unknown_F0: Integer;
    Unknown_F4: Integer;
    Unknown_F8: Integer;
    Unknown_FC: Integer;
    ListTopLeft: TPoint;
    Unknown_108: Integer;
    Unknown_10C: Integer;
    _EditsLeft: Integer;
    ButtonsTop: Integer;
    _MaxWidth1: Integer;
    _Width: Integer;
    _MaxWidth2: Integer;
    Unknown_124: Integer;
    Unknown_128: Integer;
    ButtonsWidth: Integer;
    Zoom: Integer;
    Title: PChar;
    Rects1: array[0..1] of TRect;
    Rects2: array[0..1] of TRect;
    Rects3: array[0..1] of TRect;
    Rects4: array[0..1] of TRect;
    Unknown_1B8: array[0..1] of Integer;
    VScrollWidth1: Integer;
    VScrollWidth2: Integer;
    HScrollHeight1: Integer;
    HScrollHeight2: Integer;
    Unknown_1D0: array[0..1] of Integer;
    Unknown_1D8: array[0..1] of Integer;
    Unknown_1E0: array[0..1] of Integer;
    ListboxInnerWidth: array[0..1] of Integer;
    Unknown_1F0: array[0..1] of Integer;
    Unknown_1F8: Integer;
    Unknown_1FC: Integer;
    Unknown_200: Integer;
    Unknown_204: Integer;
    ListboxSpriteAreaWidth: array[0..1] of Integer;
    PageStartListboxItem: array[0..1] of PListboxItem;
    Unknown_218: Integer;
    _Extra: PDialogExtra;                 // ! Storing data in unused structure members
    SelectedListboxItem: PListboxItem;
    SelectedListItem: PListItem;
    FirstListboxItem: PListboxItem;
    LastListboxItem: PListboxItem;
    FirstTextLine: PDlgTextLine;
    FirstListItem: PListItem;
    Edit: PEdit;
    Proc1: Pointer;
    Proc2: Pointer;
    Proc3SpriteDraw: TDlgProc3SpriteDraw;
    Proc4SpriteDraw: Pointer;
    Proc5: Pointer;
    Proc6: Pointer;
    Heap: THeap;
    Unknown_266: Word;
    Unknown_268: Integer;
    CheckboxControls: PControlInfoCheckbox;
    EditControls: PControlInfoEdit;
    ButtonControls: PControlInfoButtons;
    Unknown_278: array[0..1] of Integer;
    ListItemControls: PControlInfoListItems;
    ScrollControls1: array[0..1] of PControlInfoScroll;
    ScrollControls2: array[0..1] of PControlInfoScroll;
    ButtonTexts: array[0..5] of PChar;
    Buttons: array[0..5] of TButton;
    Unknown_2DC: Integer;
    Unknown_2E0: Integer;
    Unknown_2E4: Integer;
    Unknown_2E8: Integer;
    Unknown_2EC: Integer;
    Unknown_2F0: Integer;
  end;
  {
  TDialogWindow = packed record           // Size = $2F4 ?
    GraphicsInfo: PGraphicsInfo;
    Unknown1: array[$04..$27] of Byte;    // + 0x04
    NumLines: Integer;                    // + 0x28 [A]
    NumListItems: Integer;                // + 0x2C [B]
    NumberOfButtonsStd: Integer;          // + 0x30 [C]
    NumberOfButtons: Integer;             // + 0x34 [D]
    ScrollPageSize: Integer;              // + 0x38 [E]
    Flags: Integer;                       // + 0x3C :
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
}

  TDialogExtra = packed record
    DialogIndex: Integer;
    OriginalListboxHeight: Integer;
    OriginalListHeight: Integer;
    NonListHeight: Integer;
    ListPageStart: Integer;
    ListPageSize: Integer;
    ListItemMaxHeight: Integer;
  end;

  TDrawPort = packed record               // Part of TGraphicsInfo;
    _Proc: Pointer;
    Width: Integer;
    Height: Integer;
    BmWidth4: Integer;
    BmWidth4u: Integer;
    ClientRectangle: TRect;
    WindowRectangle: TRect;
    pBmp: PByte;
    RowsAddr: Pointer;
    PrevPaletteID: Integer;
    DrawInfo: PDrawInfo;
    ColorDepth: Integer;
  end;

  // WindowProc2 - GetWindowLongA(hWnd, 0xC)
  TGraphicsInfo = packed record           // Size = 0x114 (sub_5DEE28)
    DrawPort: TDrawPort;
    WindowInfo: TWindowInfo;              // + 0x48
    Unknown_10D: Byte;
    Unknown_10E: Byte;
    Unknown_10F: Byte;
    UpdateProc: Pointer;                  // + 0x110
  end;

  // T_GraphicsInfoEx Size = 0xA28 (sub_4D5B21)

  TDrawInfo = packed record               //  Size = $28
    Unknown0: Integer;
    DeviceContext: HDC;                   // + 0x04
    Unknown1: HGDIOBJ;
    HBmp: HBITMAP;
    ReplacedObject: HGDIOBJ;
    IsTopDownDIB: Integer;
    Width: Integer;
    Height: Integer;
    BmWidth4: Integer;
    PBmp: PByteArray;
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
    HMem: HGLOBAL;
    HWindow: HWND;                        // + 0x04
    DeviceContext: HDC;                   // + 0x08
    Unknown_0C: Integer;
    Unknown_10: Integer;
    Brush: HBRUSH;                        // + 0x14
    Palette: HPALETTE;                    // + 0x18
    Cursor: HCURSOR;                      // + 0x1C
    Icon: HICON;                          // + 0x20
    Unknown_24: Integer;
    Unknown_28: Integer;
    DrawPort: PDrawPort;
    Moveable: Integer;
    Sizeable: Integer;
    CaptionHeight: Integer;
    ResizeBorderWidth: Integer;
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

  TSprites = array[0..255] of TSprite;

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

  TMapWindow = packed record              // Size = 0x3F0
    MSWindow: TMSWindow;
    Unknown_2D8: Word;                    // + 0x2D8
    Unknown_2DA: Word;                    // + 0x2DA
    Unknown_2DC: Word;                    // + 0x2DC
    Unknown_2DE: Word;                    // + 0x2DE
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

  TMapWindows = array[0..7] of TMapWindow; // 66C7A8

  TCityWindow = packed record             // 6A91B8  Size = $16E0
    MSWindow: TMSWindow;
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
    Zoom: Integer;                        //
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
    FontInfo: TFontInfo;                  //
    ControlInfo: array[1..10] of Pointer; //
    ControlInfoScroll: PControlInfoScroll; //
  end;

  TCityGlobals = packed record
    BuildProgress: Integer;
    field_4: array[1..4] of char;
    field_8: array[1..28] of char;
    field_24: Integer;
    HappyCitizens: Integer;
    Tax: Integer;
    field_30: Integer;
    AttUnitsInCity: Integer;
    RowsInFoodBox: Integer;
    field_3C: Integer;
    Support: Integer;
    field_44: Integer;
    field_48: Integer;
    field_4C: Integer;
    field_50: Integer;
    ShieldsInRow: Integer;
    TradeCorruption: Integer;
    field_5C: Integer;
    DistanceToCapital: Integer;
    field_64: array[1..4] of char;
    TradeRevenue: array[0..2] of Integer;
    field_74: Integer;
    field_78: Integer;
    BuildingType: Integer;
    UnhappyCitizens: Integer;
    field_84: Integer;
    field_88: Integer;
    field_8C: array[1..4] of char;
    field_90: Integer;
    field_94: Integer;
    field_98: Integer;
    field_9C: Integer;
    TotalRes: array[0..2] of Integer;
    field_AC: Integer;
    Settlers: Integer;
    field_B4: Integer;
    field_B8: Integer;
    AttUnitsOfDiscontent: Integer;
    field_C0: Integer;
    field_C4: array[1..4] of char;
    field_C8: char;
    field_C9: char;
    gapCA: BYTE;
    field_CB: char;
    field_CC: char;
    field_CD: array[1..3] of char;
    field_D0: Integer;
    Lux: Integer;
    Capital: Integer;
    FreeCitizens: Integer;
    SettlersEat: Integer;
    PaidUnits: Integer;
    field_E8: Integer;
    field_EC: array[1..4] of char;
    field_F0: Integer;
    PrevFoodDelta: Integer;
    field_F8: char;
    field_F9: char;
    gapFA: BYTE;
    field_FB: char;
    field_FC: char;
    field_FD: array[1..3] of char;
    field_100: array[1..64] of char;
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
    Unknown_454: Integer;
    Unknown_458: Integer;
    CurrCivIndex: Integer;
    ScrollPosition: Integer;
    ScrollPageSize: Integer;

    ListTop: Integer;
    ListHeight: Integer;
    LineHeight: Integer;

    Height: Integer;
    Unknown3: array[1..5] of Integer;
    Width: Integer;
    Unknown_490: Integer;
    ScrollBarWidth: Integer;
    ControlsInitialized: Integer;
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

  TCosmic = packed record                 // Size = 0x16
    RoadMovementMultiplier: Byte;
    ChanceTriremeLost: Byte;
    CitizenEats: Byte;
    RowsInFoodBox: Byte;
    RowsInShieldBox: Byte;
    SettlersEatUpToMonarchy: Byte;
    SettlersEatFromCommunism: Byte;
    CitySizeFirstUnhappinessChieftain: Byte;
    RiotFactor: Byte;
    AqueductSize: Byte;
    SewerSystemSize: Byte;
    TechParadigm: Byte;
    BaseTransformTime: Byte;
    FreeSupportMonarchy: Byte;
    FreeSupportCommunism: Byte;
    FreeSupportFundamentalism: Byte;
    CommunismPalaceDistance: Byte;
    FundamentalismLosesScience: Byte;
    ShieldPenalty: Byte;
    ParadropRange: Byte;
    MassThrustParadigm: Byte;
    FundamentalismMaxScience: Byte;
  end;

  TGameParameters = packed record
    word_655AE8: Word;
    GraphicAndGameOptions: Integer;
    // 0x0020 - Show Map Grid
    // 0x0100 - Tutorial help.
    // 0x1000 - Show enemy moves.
    // 0x4000 - Always wait at end of turn.
    word_655AEE: Word;
    MapFlags: Word;
    // 0x0002 - ?Finished
    // 0x0004 - Map SizeX*SizeY >= 6000
    // 0x0008 - Map SizeX*SizeY <  3000
    // 0x0040 - ?Scenario
    // 0x0080 - ?Scenario started
    word_655AF2: Word;
    word_655AF4: Word;
    word_655AF6: Word;
    Turn: Word;
    Year: Word;
    word_655AFC: Word;
    ActiveUnitIndex: SmallInt;            // Current unit index
    word_655B00: Word;
    MultiType: Byte;                      // Multiplayer Game Type
    // 0 - Singleplayer
    // 1 - Hot Seat
    // 3 - Network Game
    // 4 - Internet
    byte_655B03: Byte;                    // PlayerTribeNumber?
    byte_655B04: Byte;
    SomeCivIndex: Shortint;               // Active Unit Civ index?
    byte_655B06: Byte;
    RevealMap: Boolean;
    DifficultyLevel: Byte;
    // 0 - Chieftain (easiest)
    // 1 - Warlord
    // 2 - Prince
    // 3 - King
    // 4 - Emperor
    // 5 - Deity (toughest)
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

  TMapHeader = packed record
    SizeX: SmallInt;
    SizeY: SmallInt;
    Area: SmallInt;
    Flat: SmallInt;
    Seed: SmallInt;
    ArrayW: SmallInt;
    ArrayH: SmallInt;
  end;

  TMapCivData = array[0..7] of PByteArray;

  TMapSquare = packed record
    TerrainType: Byte;
    // 0000 0000 - 0x00 Desert
    // 0000 0001 - 0x01 Plains
    // 0000 0010 - 0x02 Grassland
    // 0000 0011 - 0x03 Forest
    // 0000 0100 - 0x04 Hills
    // 0000 0101 - 0x05 Mountains
    // 0000 0110 - 0x06 Tundra
    // 0000 0111 - 0x07 Glacier
    // 0000 1000 - 0x08 Swamp
    // 0000 1001 - 0x09 Jungle
    // 0000 1010 - 0x0A Ocean
    // 0010 0000 - 0x20 Only used for resource tiles. Indicates that the tile was being animated when the game was saved - no apparent effect.
    // 0100 0000 - 0x40 No resource
    // 1000 0000 - 0x80 River
    Improvements: Byte;
    // 0000 0000 - 0x00 Nothing
    // 0000 0001 - 0x01 Unit Present
    // 0000 0010 - 0x02 City Present
    // 0000 0100 - 0x04 Irrigation
    // 0000 1000 - 0x08 Mining
    // 0000 1100 - 0x0C Farmland
    // 0001 0000 - 0x10 Road
    // 0011 0000 - 0x30 Railroad (+ Road)
    // 0100 0000 - 0x40 Fortress
    // 0100 0010 - 0x42 Airbase
    // 1000 0000 - 0x80 Pollution
    CityRadii: Byte;
    MassIndex: Byte;
    Visibility: Byte;
    OwnershipAndFertility: Byte;
  end;
  TMapSquares = array[0..32000] of TMapSquare;

  TPFData = packed record
    UnitType: Integer;
    field_4: Integer;
    CivIndex: Integer;
    field_C: Integer;
    Debug: Integer;
    NeedDebug: Integer;
  end;

  TImprovement = packed record            // Size = 0x08
    StringIndex: Cardinal;
    Cost: Byte;
    Upkeep: Byte;
    Preq: ShortInt;
    Unknown3: Byte;
  end;

  TImprovements = array[0..66] of TImprovement; // 64C488

  TUnitType = packed record               // Size = 0x14
    StringIndex: Cardinal;
    Flags: Cardinal;
    // 0000 0000 0000 0001 - 0x0001 Two space visibility
    // 0000 0000 0000 0010 - 0x0002 Ignore zones of control
    // 0000 0000 0000 0100 - 0x0004 Can make amphibious assaults
    // 0000 0000 0000 1000 - 0x0008 Submarine advantages/disadvantages
    // 0000 0000 0001 0000 - 0x0010 Can attack air units (fighter)
    // 0000 0000 0010 0000 - 0x0020 Ship must stay near land (trireme)
    // 0000 0000 0100 0000 - 0x0040 Negates city walls (howitzer)
    // 0000 0000 1000 0000 - 0x0080 Can carry air units (carrier)
    // 0000 0001 0000 0000 - 0x0100 Can make paradrops
    // 0000 0010 0000 0000 - 0x0200 Alpine (treats all squares as road)
    // 0000 0100 0000 0000 - 0x0400 x2 on defense versus horse (pikemen)
    // 0000 1000 0000 0000 - 0x0800 Free support for fundamentalism (fanatics)
    // 0001 0000 0000 0000 - 0x1000 Destroyed after attacking (missiles)
    // 0010 0000 0000 0000 - 0x2000 x2 on defense versus air (AEGIS)
    // 0100 0000 0000 0000 - 0x4000 Unit can spot submarines
    Until_: Byte;
    Domain: Byte;
    // 0 = Ground
    // 1 = Air
    // 2 = Sea
    Move: Byte;
    Range: Byte;
    Att: Byte;
    Def: Byte;
    HitPoints: Byte;
    FirePower: Byte;
    Cost: Byte;
    Hold: Byte;
    Role: Byte;                           // 0x64B1CA
    // 0 = Attack
    // 1 = Defend
    // 2 = Naval Superiority
    // 3 = Air Superiority
    // 4 = Sea Transport
    // 5 = Settle
    // 6 = Diplomacy
    // 7 = Trade
    Preq: Byte;
  end;

  TUnitTypes = array[0..$3D] of TUnitType; // 64B1B8

  TUnit = packed record                   // Size = 0x20
    X: Word;                              // X
    Y: Word;                              // Y
    Attributes: Word;
    // 0000 0000 0000 0010 - 0x0002 ?Flag checked in UnitCanMove
    // 0000 0000 0001 0000 - 0x0010 Paradropped
    // 0000 0100 0000 0000 - 0x0400 Unit causes discontent
    // 0000 1000 0000 0000 - 0x0800 Unit is supported
    // 0010 0000 0000 0000 - 0x2000 Veteran
    // 0100 0000 0000 0000 - 0x4000 Unit issued with the 'wait' order
    UnitType: Byte;                       // 0x6560F6
    CivIndex: Shortint;                   // 0x6560F7
    MovePoints: Shortint;                 // 0x6560F8 (Move * Road movement multiplier)
    Visibility: Byte;
    HPLost: Byte;                         // + 0x0A
    MoveDirection: Byte;                  // 0x6560FB
    byte_6560FC: Byte;
    Counter: Byte;                        // 0x6560FD Settlers work / Caravan commodity / Air turn
    MoveIteration: Byte;
    Orders: Shortint;                     // 0x6560FF
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
    // 0000 0000 0000 0000 0000 0000 0000 0001 - 0x00000001 Disorder
    // 0000 0000 0000 0000 0000 0000 0000 0010 - 0x00000002 We Love the King Day
    // 0000 0000 0000 0000 0000 0000 0000 0100 - 0x00000004 Improvement sold
    // 0000 0000 0000 0001 0000 0000 0000 0000 - 0x00010000 Airlifted
    // 0000 0000 0100 0000 0000 0000 0000 0000 - 0x00400000 Investigated by spy
    // 0000 0100 0000 0000 0000 0000 0000 0000 - 0x04000000 x1 Objective
    // 0001 0000 0000 0000 0000 0000 0000 0000 - 0x10000000 x3 Major Objective
    Owner: Byte;                          // + 0x08
    Size: Byte;                           // + 0x09
    Founder: Byte;                        // + 0x0A
    TurnsCaptured: Byte;                  // + 0x0B
    KnownTo: Byte;
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
    Workers: Integer;
    Improvements: array[1..5] of Byte;
    Building: Shortint;
    TradeRoutes: Shortint;
    SuppliedTradeItem: array[0..2] of Shortint;
    DemandedTradeItem: array[0..2] of Shortint;
    CommodityTraded: array[0..2] of Shortint;
    TradePartner: array[0..2] of Smallint;
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
    Flags: Word;                          //          64C6A0
    // 0x0001 - Skip next Oedo year (eg, used when falling into anarchy)
    // 0x0002 - Tribe is at war with another tribe? Used for peace turns calculation
    // 0x0004 - Related to anarchy? On at the start of games
    // 0x0008 - Tribe has just recovered from revolution (allows government change)
    // 0x0020 - Free advance available from receiving Philosophy (cleared when received)
    // 0x0200 - Female
    Gold: Integer;                        // + 0x02 = 64C6A2
    Leader: Word;                         // + 0x06 = 64C6A6
    Beakers: Word;                        // + 0x08 = 64C6A8
    Unknown3: array[$A..$14] of Byte;
    Government: Byte;
    // 0 - Anarchy
    // 1 - Despotism
    // 2 - Monarchy
    // 3 - Communism
    // 4 - Fundamentalism
    // 5 - Republic
    // 6 - Democracy
    Unknown4: array[$16..$1F] of Byte;
    Treaties: array[0..7] of Integer;
    // 0x00000001 Contact
    // 0x00000002 Cease Fire
    // 0x00000004 Peace
    // 0x00000008 Alliance
    // 0x00000010 Vendetta
    // 0x00000080 Embassy
    // 0x00002000 War
    // 0x00040000 Accepted tribute
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

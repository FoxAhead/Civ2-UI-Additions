unit Civ2Types;

interface

uses
  MMSystem,
  SysUtils,
  Windows;

type
  PWindowProcs = ^TWindowProcs;

  PCityWindow = ^TCityWindow;

  PCityGlobals = ^TCityGlobals;

  PCitySprites = ^TCitySprites;

  PHeap = ^THeap;

  PMenu = ^TMenu;

  PMenuBar = ^TMenuBar;

  PMenuInfo = ^TMenuInfo;

  PWindowInfo1 = ^TWindowInfo1;

  PWindowInfo = ^TWindowInfo;

  PFontData = ^TFontData;

  PFontInfo = ^TFontInfo;

  PPalette = ^TPalette;

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

  PSideBarWindow = ^TSideBarWindow;

  PTaxWindow = ^TTaxWindow;

  PCosmic = ^TCosmic;

  PGame = ^TGame;

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

  PCiv = ^TCiv;

  PMciInfo = ^TMciInfo;

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
    // 0x00000001 - Hidden
    // 0x00000002 -
    // 0x00000004 - Checked
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
    // 0x00008000 -
    FirstMenu: PMenu;
  end;

  TMenuInfo = packed record
    WindowInfo1: PWindowInfo1;
    MenuBar: PMenuBar;
    Proc: Pointer;
  end;

  // WindowProc1        - GetWindowLongA(hWnd, 8)
  // WindowProcCommon   - GetWindowLongA(hWnd, 4)
  // WindowProcMSWindow - GetWindowLongA(hWnd, 0)
  TWindowInfo1 = packed record            // Size = 0xB8
    Style: Integer;                       //
    Palette: PPalette;                    // + 0x04
    WindowStructure: PWindowStructure;    // + 0x08
    Unknown_0C: Integer;                  // + 0x0C
    WindowProcs: TWindowProcs;            // + 0x10
    MenuBar: PMenuBar;                    // + 0x78
    MinTrackSize: TPoint;                 // + 0x7C
    MaxTrackSize: TPoint;                 // + 0x84
    PopupActive: Cardinal;                // + 0x8C
    Unknown_90: Integer;                  // + 0x90
    Unknown_94: Integer;                  // + 0x94
    ProcMenuExec: Pointer;                // + 0x98
    Unknown_9C: Integer;                  // + 0x9C
    Unknown_A0: Integer;                  // + 0xA0
    Unknown_A4: Integer;                  // + 0xA4
    LButtonDown: Integer;                 // + 0xA8
    RButtonDown: Integer;                 // + 0xAC
    HScrollPos: Integer;                  // + 0xB0
    VScrollPos: Integer;                  // + 0xB4
  end;

  // TODO: Rename
  // TWindowInfo1 -> TWindowInfo
  // TWindowInfo -> TWindowInfoCtrl (possibliy Control window info)
  TWindowInfo = packed record             // Size = 0xC5
    WindowInfo1: TWindowInfo1;
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

  TCitySpritesArray = array[0..199] of TCitySprite;

  TCitySprites = packed record            // 6A9490
    Sprites: TCitySpritesArray;           //
    Count: Integer;                       // + 12C0 = 6AA750
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

  // ControlType = 2
  TControlInfoCheckbox = packed record
    ControlInfo: TControlInfo;
    Proc: Pointer;
    Checked: Integer;
    Enabled: Integer;
    FontInfo: PFontInfo;
  end;

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
    Index: Integer;
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
    // 0x00000008 - Don't wait result
    // 0x00000010 - Don't destroy GraphicsInfo
    // 0x00000020 - Created
    // 0x00000040 - Has Help button (StdType = 1)
    // 0x00000200 - Created parts
    // 0x00000400 - ClearPopup
    // 0x00001000 - Has ListBox
    // 0x00002000 - Choose
    // 0x00004000 - Without background
    // 0x00008000 - ?Append dialog data to existing one (example ADVICE.TXT)
    // 0x00010000 - System popup
    // 0x00040000 - System listbox
    // 0x00800000 - Sorted listbox
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
    _Extra: PDialogExtra;                 // ! Storing data in possibly unused structure members
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
    RowsOffset: Pointer;
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
    Style: Integer;
    // 0x00000008 - Style |= WS_MINIMIZEBOX
    // 0x00000010 - Style |= WS_MAXIMIZEBOX
    // 0x00000020 - Style |= WS_SYSMENU
    // 0x00000040 - Style |= WS_CAPTION
    // 0x00000080 - Style |= WS_VSCROLL
    // 0x00000100 - Style |= WS_HSCROLL
    // 0x00000200 - If aParent: Style |= WS_CHILD | WS_CLIPSIBLINGS, ExStyle = WS_EX_NOPARENTNOTIFY
    // 0x00000800 - Style |= WS_POPUP
  end;

  TFontData = packed record
    FontHandle: HFONT;
    Unknown_4: Integer;
  end;

  TFontInfo = packed record
    FontDataHandle: HGLOBAL;
    Height: Longint;
  end;

  TPalette = packed record
    PalVersion: Word;
    PalNumEntries: Word;
    Colors: array[0..255] of PALETTEENTRY;
    HPal: HPALETTE;
    ID: Integer;
    Unknown_040C: Integer;
    Unknown_0410: Integer;
    Unknown_0414: Integer;
    Unknown_0418: Integer;
    Unknown_041C: Integer;
    Unknown_0420: Integer;
    Unknown_0424: Byte;
    Unknown_0425: Byte;
    Unknown_0426: Byte;
    Unknown_0427: Byte;
    HGlobal_0428: HGLOBAL;
    HGlobal_042C: HGLOBAL;
    HGlobal_0430: HGLOBAL;
  end;

  TSprite = packed record                 // Size = 0x3C
    Rectangle1: TRect;
    Rectangle2: TRect;
    Rectangle3: TRect;
    Color: Byte;
    Unknown_31: Byte;
    Unknown_32: Byte;
    Unknown_33: Byte;
    hMem: HGLOBAL;
    pMem: Pointer;
  end;

  TSprites = array[0..255] of TSprite;

  TWinButton = packed record
    Code: Integer;
    Unknown_04: Integer;
    Unknown_08: Integer;
    Width: Integer;
    Height: Integer;
    Sprite: PSprite;
    ListItem: PControlInfoListItem;
  end;

  TMSWindow = packed record               // Size = 0x2D8
    GraphicsInfo: TGraphicsInfo;
    Unknown_114: Integer;
    _CaptionHeight: Integer;
    Border: Integer;
    _ResizeBorderWidth: Integer;
    ClientTopLeft: TPoint;
    ClientSize: TSize;
    Unknown_134: array[1..50] of Integer;
    WinButtonCount: Integer;
    WinButtons: array[0..5] of TWinButton;
    WinButtonProc: Pointer;
    RectDrawPort: TRect;
    RectClient: TRect;
    FontInfo1: PFontInfo;
    FontInfo2: PFontInfo;
    FontInfo3: PFontInfo;
  end;

  TMapWindow = packed record              // Size = 0x3F0
    MSWindow: TMSWindow;
    Unknown_2D8: Word;                    // 02D8
    Unknown_2DA: Word;                    // 02DA
    Unknown_2DC: Word;                    // 02DC
    Unknown_2DE: Word;                    // 02DE
    MapCenter: TSmallPoint;               // 02E0
    MapZoom: Smallint;                    // 02E4
    Unknown7: Smallint;                   // 02E6
    MapRect: TRect;                       // 02E8
    MapHalf: TSize;                       // 02F8
    Unknown8: array[$300..$307] of Byte;
    MapCellSize: TSize;                   // 0308
    MapCellSize2: TSize;                  // 0310  1/2
    MapCellSize4: TSize;                  // 0318  1/4
    Unknown_320: TSize;                   // 0320
    ClientSize: TSize;                    // 0328
    Unknown_330: TSize;                   // 0330
    //Unknown10: array[1..26] of Integer;
    //DrawInfo2: PDrawInfo;
    //Unknown11: array[1..19] of Integer;
    FontInfo1: TFontInfo;                 // 0338
    FontInfo2: TFontInfo;                 // 0340
    PrevFont1Height: Integer;             // 0348
    PrevFont2Height: Integer;             // 034C
    Unknown_350: Integer;                 // 0350
    Unknown_354: Integer;                 // 0354
    Cursor: Integer;                      // 0358
    PrevMapZoom: Integer;                 // 035C
    DrawPortMouse: TDrawPort;             // 0360
    DrawPortMouse2: TDrawPort;            // 03A8
  end;

  TMapWindows = array[0..7] of TMapWindow; // 66C7A8

  TCityWindow = packed record             // 6A91B8  Size = $16E0
    MSWindow: TMSWindow;                  // 0000
    CitySprites: TCitySprites;            // 02D8
    CityIndex: Integer;                   // 159C
    Minimized: BOOL;                      // 15A0
    Hidden: BOOL;                         // 15A4
    NoUpdate: BOOL;                       // 15A8
    CityModalMode: Integer;               // 15AC - 0, 1, 2 (Warning GAME.TXT @CITYMODAL)
    CentralInfo: Integer;
    ImproveListStart: Integer;
    ImproveCount: Integer;
    Unknown_15BC: Integer;
    Unknown_15C0: Integer;
    Unknown_15C4: Integer;
    Unknown_15C8: Integer;
    Unknown_15CC: Integer;
    Unknown_15D0: Integer;
    WindowSize: Integer;                  // + 15D4 = 6AA78C  // 1, 2, 3
    Zoom: Integer;                        //
    RectCitizens: TRect;                  //
    RectResources: TRect;                 // + 15EC
    RectFoodStorage: TRect;               //
    RectBuilding: TRect;                  //
    RectButtons: TRect;                   //
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

  TCityGlobals = packed record            // Size = 0x140
    BuildProgress: Integer;
    field_4: array[1..4] of Char;
    field_8: array[1..28] of Char;
    // 0000 0001 - 0x01 Not valid
    // 0000 0100 - 0x04 Foreign offensive unit
    // 0000 1000 - 0x08 City
    // 0010 0000 - 0x20 Foreign offensive unit (human)
    CitizensNotWorking: Integer;
    HappyCitizens: Integer;
    Tax: Integer;
    field_30: Integer;
    AttUnitsInCity: Integer;
    RowsInFoodBox: Integer;
    field_3C: Integer;
    Support: Integer;
    ProdCorruption: Integer;
    field_48: Integer;
    LinkToCapital: Integer;
    field_50: Integer;
    ShieldsInRow: Integer;
    TradeCorruption: Integer;
    Pollution: Integer;
    DistanceToCapital: Integer;
    field_64: array[1..4] of Char;
    TradeRevenue: array[0..2] of Integer;
    AngryCitizens: Integer;
    field_78: Integer;
    BuildingType: Integer;
    UnhappyCitizens: Integer;
    field_84: Integer;
    field_88: Integer;
    field_8C: array[1..4] of Char;
    TileRes: array[0..2] of Integer;
    TechPollution: Integer;
    TotalRes: array[0..2] of Integer;     // 0 - Food, 1 - Production, 2 - Trade
    field_AC: Integer;
    Settlers: Integer;
    field_B4: Integer;
    field_B8: Integer;
    AttUnitsOfDiscontent: Integer;
    field_C0: Integer;
    field_C4: array[1..4] of Char;
    UnhappyArray: array[0..4] of Byte;
    field_CD: array[1..3] of Char;
    EnvLevel: Integer;
    Lux: Integer;
    Capital: Integer;
    FreeCitizens: Integer;
    SettlersEat: Integer;
    PaidUnits: Integer;
    field_E8: Integer;
    field_EC: array[1..4] of Char;
    field_F0: Integer;
    PrevFoodDelta: Integer;
    HappyArray: array[0..4] of Byte;
    field_FD: array[1..3] of Char;
    AngryArray: array[0..4] of Byte;
    field_100: array[1..59] of Char;
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
    //  8 - F8  Top 5 Cities, About Civilization II, Hall of Fame
    //  9 - F11 Demographics
    // 10 - F9  Civilization Score, Civilization Rating
    // 12 - Ctrl-D Casaulty Timeline
    Unknown_454: Integer;
    _Range: Integer;
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

  TSideBarWindow = packed record          // Size = 0x350
    MSWindow: TMSWindow;
    Unknown_2D8: Byte;
    Unknown_2D9: ShortInt;
    Unknown_2DA: ShortInt;
    Unknown_2DB: ShortInt;
    Unknown_2DC: Integer;
    Unknown_2E0: Integer;
    Unknown_2E4: Integer;
    Unknown_2E8: Integer;
    Unknown_2EC: Integer;
    Unknown_2F0: Integer;
    Unknown_2F4: Integer;
    Unknown_2F8: Integer;
    Unknown_2FC: Integer;
    Unknown_300: Integer;
    Unknown_304: Integer;
    Unknown_308: Integer;
    Unknown_30C: Integer;
    Unknown_310: Integer;
    Unknown_314: Integer;
    Unknown_318: Integer;
    Unknown_31C: Integer;
    Unknown_320: Integer;
    Unknown_324: Integer;
    Unknown_328: Integer;
    Unknown_32C: Integer;
    FontInfo: TFontInfo;
    Unknown_338: Integer;
    Unknown_33C: Integer;
    Rect: TRect;
  end;

  TTaxWindow = packed record              // Size = 0x508
    MSWindow: TMSWindow;
    CivIndex: Integer;
    MaxRate: Integer;
    TaxRateF: Integer;
    LuxuryRateF: Integer;
    ScienceRateF: Integer;
    TaxRate: Integer;
    LuxuryRate: Integer;
    ScienceRate: Integer;
    ClientWidth: Integer;
    ClientHeight: Integer;
    x0: Integer;
    y0: Integer;
    TotalIncome: Integer;
    TotalScience: Integer;
    TotalCost: Integer;
    PadX: Integer;
    PadY: Integer;
    ScrollW: Integer;
    ScrollBarHeight: Integer;
    ButtonW: Integer;
    ButtonH: Integer;
    FontHeight: Integer;
    yT: Integer;
    yL: Integer;
    yS: Integer;
    yGov: Integer;
    yTot: Integer;
    yDis: Integer;
    RateExceeded: Integer;
    Locks: array[0..2] of Integer;
    ScrollTax: TControlInfoScroll;
    ScrollLuxury: TControlInfoScroll;
    ScrollScience: TControlInfoScroll;
    Checkbox: array[0..2] of TControlInfoCheckbox;
    Button: TControlInfoButton;
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

  TGame = packed record                   // 0x655AE8
    CustomFeatures: Word;                 // Custom Rules
    // 0x0010 - Simplified Combat
    // 0x8000 - Flat World
    // 0x0080 - Bloodlust (No spaceships allowed)
    // 0x0100 - Don't Restart Eliminated Players
    GraphicAndGameOptions: Integer;
    // Game Options
    // 0x00000008 - Music
    // 0x00000010 - Sound Effects
    // 0x00000020 - Show Map Grid
    // 0x00000040 - ENTER key closes City Screen.
    // 0x00000080 - Move units w/ mouse (cursor arrows).
    // 0x00000100 - Tutorial help.
    // 0x00000200 - Instant advice.
    // 0x00000400 - Fast piece slide.
    // 0x00000800 - No pause after enemy moves.
    // 0x00001000 - Show enemy moves.
    // 0x00002000 - Autosave each turn.
    // 0x00004000 - Always wait at end of turn.
    // 0x00008000 - Cheat mode
    // Graphic Options
    // 0x00010000 - Wonder Movies
    // 0x00020000 - Throne Room
    // 0x00040000 - Diplomacy Screen
    // 0x00080000 - Civilopedia for Advances
    // 0x00100000 - High Council
    // 0x00200000 - Animated Heralds (Requires 16 megabytes RAM)
    word_655AEE: Word;
    MapFlags: Word;
    // 0x0002 - ?Finished
    // 0x0004 - Map SizeX*SizeY >= 6000
    // 0x0008 - Map SizeX*SizeY <  3000
    // 0x0040 - ?Scenario
    // 0x0080 - ?Scenario started
    word_655AF2: Word;
    TutorialsShown: Word;
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
    HumanCivIndex: Byte;                  // PlayerTribeNumber?
    byte_655B04: Byte;
    SomeCivIndex: ShortInt;               // Active Unit Civ index?
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
    Enemies: Byte;
    byte_655B0E: Byte;
    byte_655B0F: Byte;
    word_655B10: Word;
    word_655B12: Word;
    PeaceTurns: Word;
    TotalUnits: Word;
    TotalCities: Word;
    word_655B1A: Word;
    word_655B1C: Word;
    TechsDiscoveredFirst: array[0..99] of Byte;
    // 0x00 - None
    // 0x01 - 0x07 - Number of the tribe which first discovered the technology
    // 0x08 - More than one tribe, eg, starting technologies.
    TechsDiscovered: array[0..99] of Byte;
    // 0000 0001 - Tribe 0 (Barbarians)
    // 0000 0010 - Tribe 1
    // ...
    // 1000 0000 - Trube 7
    WonderCities: array[0..27] of SmallInt;
    // 0xXXXX - City Index
    // 0xFFFE - Lost
    // 0xFFFF - Not built yet
    field_136: SmallInt;
    field_138: Byte;
    field_139: Char;
    CivsRating: array[0..7] of Byte;
    field_142: array[0..7] of Byte;
  end;

  TMapHeader = packed record
    SizeX: SmallInt;
    SizeY: SmallInt;
    Area: SmallInt;
    Flat: SmallInt;                       // (0=round, 1=flat). Really determined by byte 13 at the start of the savegame, instead of here.
    Seed: SmallInt;                       // seed (can be anything, but there are only 64 patterns)
    ArrayW: SmallInt;
    ArrayH: SmallInt;
  end;

  TMapCivData = array[0..7] of PByteArray; // Known tile TerrainFeatures for the civilization in question

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
    TerrainFeatures: Byte;
    // 0000 0000 - 0x00 Nothing
    // 0000 0001 - 0x01 Unit Present
    // 0000 0010 - 0x02 City Present
    // 0000 0100 - 0x04 Irrigation
    // 0000 1000 - 0x08 Mining
    // 0000 1100 - 0x0C Farmland (Irrigation + Mining)
    // 0001 0000 - 0x10 Road
    // 0011 0000 - 0x30 Railroad (+ Road)
    // 0100 0000 - 0x40 Fortress
    // 0100 0010 - 0x42 Airbase (Fortress + City)
    // 1000 0000 - 0x80 Pollution
    CityRadii: Byte;
    // 0000 0000 - None or Barbarians
    // 0010 0000 - Tribe 1
    // 0100 0000 - Tribe 2
    // 0110 0000 - Tribe 3
    // 1000 0000 - Tribe 4
    // 1010 0000 - Tribe 5
    // 1100 0000 - Tribe 6
    // 1110 0000 - Tribe 7
    MassIndex: Byte;
    // This simply gives every different body of land and every body of water a separate number.
    // Counting starts at the top-left corner and procedes from left to right and from top to bottom.
    // Water bodies of less than 9 squares always have number 63, but do count towards the total.
    // Both the land and water counters start counting at one. (c) HEX-EDITING SAVED GAMES (hexedit.rtf)
    Visibility: Byte;
    // 0000 0000 - Unexplored by all
    // 0000 0001 - Visible to tribe 0
    // ...
    // 1000 0000 - Visible to tribe 7
    OwnershipAndFertility: Byte;
    // .... XXXX - Fertility 0x0 - 0xF
    // 0000 .... - Owned by tribe 0 (barbarians)
    // 0001 .... - Owned by tribe 1
    // ...
    // 0111 .... - Owned by tribe 7
    // 1111 .... - No ownership - Can have goody hut (based on seed)
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

  TRulesCivilize = packed record          // Size = 0x10
    Name: array[0..3] of Char;
    TextIndex: Integer;
    Unknown_08: ShortInt;
    PreqNotNO: ShortInt;
    AiValue: ShortInt;
    Modifier: ShortInt;
    Category: ShortInt;
    Epoch: ShortInt;
    Preq: array[0..1] of ShortInt;
  end;

  TRulesCivilizes = array[0..99] of TRulesCivilize; // 0x00627680

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
    Abilities: Cardinal;
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
    X: Word;                              // 0000
    Y: Word;                              // 0002
    Attributes: Word;                     // 0004
    // 0000 0000 0000 0010 - 0x0002 ?Flag checked in UnitCanMove
    // 0000 0000 0000 0100 - 0x0004 This unit is violating foreign territory
    // 0000 0000 0001 0000 - 0x0010 Paradropped
    // 0000 0000 0100 0000 - 0x0040 ?this bit appear to be set on the first time you move an unit - and remains this way
    // 0000 0100 0000 0000 - 0x0400 Unit causes discontent
    // 0000 1000 0000 0000 - 0x0800 Unit is supported
    // 0010 0000 0000 0000 - 0x2000 Veteran
    // 0100 0000 0000 0000 - 0x4000 Unit issued with the 'wait' order (the 'W' was pressed on this unit)
    // 1000 0000 0000 0000 - 0x8000 ?automate (not just settlers!)
    UnitType: Byte;                       // 0006
    CivIndex: ShortInt;                   // 0007
    MovePoints: ShortInt;                 // 0008 (Move * Road movement multiplier)
    Visibility: Byte;                     // 0009
    HPLost: Byte;                         // 000A
    MoveDirection: Byte;                  // 000B
    DebugSymbol: Char;                    // 000C
    Counter: ShortInt;                    // 000D Settlers work / Caravan commodity / Air turn
    MoveIteration: Byte;                  // 000E
    Orders: ShortInt;                     // 000F
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
    HomeCity: Byte;                       // 0010
    byte_656101: Byte;                    // 0011
    GotoX: Word;                          // 0012
    GotoY: Word;                          // 0014
    PrevInStack: Word;                    // 0016
    NextInStack: Word;                    // 0018
    ID: Integer;                          // 001A
    word_65610E: Word;                    // 001E
  end;

  TUnits = array[0..$7FF] of TUnit;       // 6560F0

  TCity = packed record                   // Size = 0x58
    X: SmallInt;                          // 0000
    Y: SmallInt;                          // 0002
    Attributes: Cardinal;                 // 0004
    // 0000 0000 0000 0000 0000 0000 0000 0001 - 0x00000001 Disorder
    // 0000 0000 0000 0000 0000 0000 0000 0010 - 0x00000002 We Love the King Day
    // 0000 0000 0000 0000 0000 0000 0000 0100 - 0x00000004 Improvement sold
    // 0000 0000 0000 0000 0000 0000 0000 1000 - 0x00000008 Technology stolen
    // 0000 0000 0000 0000 0000 0000 1000 0000 - 0x00000080 Coastal
    // 0000 0000 0000 0001 0000 0000 0000 0000 - 0x00010000 Airlifted
    // 0000 0000 0100 0000 0000 0000 0000 0000 - 0x00400000 Investigated by spy
    // 0000 0100 0000 0000 0000 0000 0000 0000 - 0x04000000 x1 Objective
    // 0001 0000 0000 0000 0000 0000 0000 0000 - 0x10000000 x3 Major Objective
    Owner: Byte;                          // 0008
    Size: ShortInt;                       // 0009
    Founder: Byte;                        // 000A
    TurnsCaptured: Byte;                  // 000B
    KnownTo: Byte;                        // 000C
    RevealedSize: array[0..7] of ShortInt; // 000D
    Unknown_15: Byte;                     // 0015
    Specialists: Cardinal;                // 0016
    // 00 - No specialist
    // 01 - Entertainer
    // 10 - Taxman
    // 11 - Scientist
    FoodStorage: Smallint;                // 001A
    BuildProgress: Smallint;              // 001C
    BaseTrade: Smallint;                  // 001E
    Name: array[0..15] of Char;           // 0020
    Workers: Integer;                     // 0030
    // 0000 0000 000X XXXX XXXX XXXX XXXX XXXX - Bit number equals index in CitySpiral (20 - center tile)
    // XXXX XX00 0000 0000 0000 0000 0000 0000 - Number of non-working citizens
    Improvements: array[1..5] of Byte;    // 0034
    Building: ShortInt;                   // 0039  < 0 - -Improvement; >= 0 - UnitType
    TradeRoutes: ShortInt;                // 003A
    SuppliedTradeItem: array[0..2] of ShortInt; // 003B
    DemandedTradeItem: array[0..2] of ShortInt; // 003E
    CommodityTraded: array[0..2] of ShortInt; // 0041
    TradePartner: array[0..2] of SmallInt; // 0044
    Science: SmallInt;                    // 004A
    Tax: SmallInt;                        // 004C
    Trade: SmallInt;                      // 004E
    TotalFood: Byte;                      // 0050
    TotalShield: Byte;                    // 0051
    HappyCitizens: Byte;                  // 0052
    UnHappyCitizens: Byte;                // 0053
    ID: Integer;                          // 0054
  end;

  TCities = array[0..$FF] of TCity;       // 64F340

  TCivSub1 = packed record
    X: SmallInt;
    Y: SmallInt;
    Unknown_4: Byte;
    Unknown_5: Byte;
  end;

  TCiv = packed record                    // Size = 0x594
    Flags: Word;                          //          64C6A0
    // 0x0001 - Skip next Oedo year (eg, used when falling into anarchy)
    // 0x0002 - Tribe is at war with another tribe? Used for peace turns calculation
    // 0x0004 - Toggled every turn with 1/3 chance. When this flag is not set, Republic Senate confirmes your action.
    // 0x0008 - Tribe has just recovered from revolution (allows government change)
    // 0x0020 - Free advance available from receiving Philosophy (cleared when received)
    // 0x0200 - Female
    Gold: Integer;                        // + 0x02 = 64C6A2
    Leader: Word;                         // + 0x06 = 64C6A6
    Beakers: Word;                        // + 0x08 = 64C6A8
    ResearchingTech: SmallInt;            // 000A
    CapitalX: SmallInt;                   // 000C - Used to center the CityWindow overview minimap by capital
    TurnOfCityBuild: SmallInt;
    Techs: Byte;
    FutureTechs: Byte;
    Unknown_12: ShortInt;
    ScienceRate: Byte;
    TaxRate: Byte;
    Government: Byte;
    // 0 - Anarchy
    // 1 - Despotism
    // 2 - Monarchy
    // 3 - Communism
    // 4 - Fundamentalism
    // 5 - Republic
    // 6 - Democracy
    SenateChances: ShortInt;
    Unknown_17: array[$17..$1A] of Byte;  // 0017
    Unknown_1B: Byte;                     // 001B
    Unknown_1C: Word;                     // 001C
    Reputation: Byte;                     // 001E
    // 0 - Spotless
    // 1 - Excellent
    // ..
    // 7 - Atrocious
    Unknown_1F: Byte;                     // 001F
    Treaties: array[0..7] of Integer;     // 0020
    // 0x00000001 - Contact
    // 0x00000002 - Cease Fire
    // 0x00000004 - Peace
    // 0x00000008 - Alliance
    // 0x00000010 - Vendetta
    // 0x00000020 - ?Hatred or ?Their space ship will arrive sooner
    // 0x00000080 - Embassy
    // 0x00000100 - They talked about nukes with us
    // 0x00002000 - War
    // 0x00004000 - Recently signed Peace treaty / Cease fire
    // 0x00020000 - We nuked them
    // 0x00040000 - Accepted tribute
    Attitude: array[0..7] of Byte;        // 0040
    //   0 - Worshipful
    // ...
    // 100 - Enraged
    Unknown9: array[$48..$153] of Byte;
    DefMinUnitBuilding: array[0..61] of Byte; // 0154
    //    Unknown10: array[$192..$593] of Byte;
    Unknown_192: array[0..63] of Word;
    Unknown_212: array[0..63] of Word;
    Unknown_292: array[0..63] of Byte;
    Unknown_2D2: array[0..63] of ShortInt;
    Unknown_312: array[0..63] of ShortInt;
    Unknown_352: array[0..63] of ShortInt;
    Unknown_392: array[0..63] of ShortInt;
    Unknown_3D2: SmallInt;
    Unknown_3D4: array[0..6] of SmallInt;
    Unknown_3E2: array[0..7] of SmallInt;
    Unknown_3F2: ShortInt;
    Unknown_3F3: array[0..9] of ShortInt;
    Unknown_3FD: ShortInt;
    Unknown_3FE: SmallInt;
    SpaceFlags: Byte;
    // 0000 0001 - 0x01 Started construction
    // 0000 0010 - 0x02 Launched
    // 0000 1000 - 0x08 Fusion powered
    Unknown_401: array[0..18] of ShortInt;
    Unknown_414: array[0..47] of TCivSub1;
    Unknown_534: array[0..15] of TCivSub1;
  end;

  TCivs = array[0..7] of TCiv;            // 64C6A0

  TShieldLeft = array[0..$3E] of Integer; // 642C48

  TShieldTop = array[0..$3E] of Integer;  // 642B48

  TLeader = packed record                 // Size = 0x30
    Attack: Byte;
    Expand: Byte;
    Civilize: Byte;
    Unknown1: Byte;
    Gender: Byte;
    CitiesBuilt: Byte;
    Color: Word;
    Style: Word;
    NameIndex: Word;
    NationPlural: Word;
    NationAdjective: Word;
    NameIndexes: array[0..1] of Word;
    GovernorName: array[0..6, 0..1] of Word;
  end;

  TLeaders = array[1..21] of TLeader;     // 6554F8

  TMciInfo = packed record                // 6389D4
    SequencerId: MCIDEVICEID;
    CdAudioId: MCIDEVICEID;
    CdAudioId2: MCIDEVICEID;              // Unused. Will use this for file DeviceID
    NumberOfTracks: Integer;
  end;

const
  CST_RESOURCES                           = 1;
  CST_CITIZENS                            = 2;
  CST_UNITS_PRESENT                       = 3;
  CST_IMPROVEMENTS                        = 4;
  CST_BUILD                               = 5;
  CST_SUPPORTED_UNITS                     = 6;
  CIV2_DLG_HAS_CANCEL_BUTTON              = $00000001;
  CIV2_DLG_CHECKBOXES                     = $00000004;
  CIV2_DLG_CREATED                        = $00000020;
  CIV2_DLG_HAS_HELP_BUTTON                = $00000040;
  CIV2_DLG_CREATED_PARTS                  = $00000200;
  CIV2_DLG_CLEAR_POPUP                    = $00000400;
  CIV2_DLG_LISTBOX                        = $00001000;
  CIV2_DLG_CHOOSE                         = $00002000;
  CIV2_DLG_SYSTEMPOPUP                    = $00010000;
  CIV2_DLG_SYSTEMLISTBOX                  = $00040000;
  CIV2_DLG_SORTEDLISTBOX                  = $00800000;
  CIV2_DLG_FORCE_SCROLLBAR_FOR_LISTBOX    = $01000000;

implementation

end.

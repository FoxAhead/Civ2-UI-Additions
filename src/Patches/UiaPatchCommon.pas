unit UiaPatchCommon;

interface

uses
  UiaPatch;

type
  TUiaPatchCommon = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Graphics,
  SysUtils,
  Windows,
  Civ2Proc,
  Civ2UIA_Ex,
  Civ2UIA_CanvasEx;

// Draw version info in top right corner
procedure PatchWindowProcMSWindowWmPaintAfter(AHWnd: HWND; const APaint: TPaintStruct); stdcall;
var
  Canvas: TCanvasEx;
  R: TRect;
  TextOut: string;
begin
  if AHWnd = Civ2.MainWindowInfo.WindowStructure.HWindow then
  begin
    TextOut := ExtractFileName(Ex.ModuleNameString) + ' v' + Ex.VersionString;
    GetClientRect(AHWnd, R);
    Canvas := TCanvasEx.Create(APaint.hdc);
    Canvas.Font.Name := 'MS Sans Serif';
    Canvas.Font.Size := 8;
    Canvas.Brush.Style := bsClear;
    //Canvas.SetTextColors(10, 31); Doesn't work because drawing directly to screen DC
    Canvas.MoveTo(R.Right - 10, 10);
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_RIGHT);
    Canvas.Free();
  end;
  EndPaint(AHWnd, APaint);
end;

function PatchFindAndLoadResourceEx(ResType: PChar; ResNum: Integer; var Module: HMODULE; var ResInfo: HRSRC): HGLOBAL; stdcall;
var
  MyResInfo: HRSRC;
  Gifs: array[0..4] of char;
begin
  Gifs := 'GIFS';
  if StrLComp(ResType, Gifs, 4) = 0 then
  begin
    if Ex.DllGifNeedFixing(ResNum) then
    begin
      MyResInfo := FindResource(HInstance, MakeIntResource(ResNum), Gifs);
      if MyResInfo <> 0 then
      begin
        Module := HInstance;
        ResInfo := MyResInfo;
      end;
    end;
  end;
  Result := LoadResource(Module, ResInfo);
end;

procedure PatchFindAndLoadResource(); register;
asm
    lea   eax, [ebp - $0C] // HRSRC hResInfo
    push  eax
    lea   eax, [ebp - $18] // HMODULE hModule
    push  eax
    push  [ebp + $0C]      // char *aResName
    push  [ebp + $08]      // char *aResType
    call  PatchFindAndLoadResourceEx
    push  $005DB2F3
    ret
end;

{ TUiaPatchCommon }

procedure TUiaPatchCommon.Attach(HProcess: Cardinal);
begin
  // Version info
  WriteMemory(HProcess, $005DC520, [OP_NOP, OP_CALL], @PatchWindowProcMSWindowWmPaintAfter);

  // Fix mk.dll (229.gif, 250.gif) and pv.dll (105.gif)
  WriteMemory(HProcess, $005DB2D4, [OP_JMP], @PatchFindAndLoadResource);

  // Fix dye-copper demand bug: initialize variable int vRoads [ebp-128h] with 0
  WriteMemory(HProcess, $0043D61D + 3, [$FF, $FF, $FF, $FF]);

  // Default new game map zoom 1:1
  WriteMemory(HProcess, $00413770 + 7, [$00]);
  
end;

initialization
  TUiaPatchCommon.RegisterMe();

end.

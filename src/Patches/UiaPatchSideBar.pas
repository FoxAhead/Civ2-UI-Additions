unit UiaPatchSideBar;

interface

uses
  UiaPatch;

type
  TUiaPatchSideBar = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  SysUtils,
  Civ2Proc,
  Civ2UIA_Proc;

procedure PatchDrawSideBarTopEx; stdcall;
var
  TextOut: string;
  Top: Integer;
begin
  TextOut := Format('%s %d', [GetLabelString($2D), Civ2.Game.Turn]); // 'Turn'
  StrCopy(Civ2.ChText, PChar(TextOut));
  Top := Civ2.SideBarClientRect^.Top + (Civ2.SideBar.FontInfo.Height - 1) * 2;
  Civ2.TxtPortDrawStringRight(Civ2.ChText, Civ2.SideBarClientRect^.Right, Top, 0);
end;

procedure PatchDrawSideBarTop; register;
asm
    mov   eax, $00401E0B //j_Q_DrawStringCurrDrawPort2_sub_43C8D0
    call  eax
    add   esp, $0C
    call  PatchDrawSideBarTopEx
    push  $00569552
    ret
end;

procedure PatchDrawLocationTextEx(X, Y: Integer); stdcall;
var
  MassIndex: Integer;
begin
  if Civ2.Game.RevealMap then
  begin
    MassIndex := Civ2.MapGetMassIndex(X, Y);
    Civ2.txtStrcatSpace;
    Civ2.txtStrcatInt(MassIndex);
  end;
end;

procedure PatchDrawLocationText(); register;
asm
    push  [ebp + $C]
    push  [ebp + $8]
    call  PatchDrawLocationTextEx
    push  $0056917C
    ret
end;

{ TUiaPatchSideBar }

procedure TUiaPatchSideBar.Attach(HProcess: Cardinal);
begin
  // Show turn number
  WriteMemory(HProcess, $0056954A, [OP_JMP], @PatchDrawSideBarTop);
  // Show mass index only in Reveal Entire Map cheat mode
  WriteMemory(HProcess, $0056915E, [OP_JMP], @PatchDrawLocationText);
end;

initialization
  TUiaPatchSideBar.RegisterMe();

end.


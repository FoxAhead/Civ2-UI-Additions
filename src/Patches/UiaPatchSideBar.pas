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
  Civ2.DrawStringRightCurrDrawPort2(Civ2.ChText, Civ2.SideBarClientRect^.Right, Top, 0);
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

{ TUiaPatchSideBar }

procedure TUiaPatchSideBar.Attach(HProcess: Cardinal);
begin

  WriteMemory(HProcess, $0056954A, [OP_JMP], @PatchDrawSideBarTop);

end;

initialization
  TUiaPatchSideBar.RegisterMe();

end.


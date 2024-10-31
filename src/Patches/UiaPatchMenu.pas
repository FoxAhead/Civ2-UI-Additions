unit UiaPatchMenu;

interface

uses
  UiaPatch;

type
  TUiaPatchMenu = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  SysUtils,
  Windows,
  Civ2Types,
  Civ2Proc,
  UiaPatchArrangeWindows,
  Civ2UIA_FormAbout,
  Civ2UIA_FormSettings,
  Civ2UIA_FormConsole;

const
  IDM_SETTINGS = $A01;
  IDM_ABOUT = $A02;
  IDM_TEST = $A03;
  IDM_TEST2 = $A04;
  IDA_ARRANGE_S = $329;
  IDA_ARRANGE_L = $32A;

procedure MoveMenu(Menu, Menu1: PMenu; Before: Boolean = False); stdcall;
var
  MenuCopy, Menu1Copy: TMenu;
begin
  MenuCopy := Menu^;
  Menu1Copy := Menu1^;
  if Before then
  begin
    if (Menu1.Prev = Menu) or (Menu.Next = Menu1) then
      Exit;
    if Menu1.Prev <> nil then
      Menu1.Prev.Next := Menu;
    Menu.Prev := Menu1Copy.Prev;
    Menu.Next := Menu1;
    Menu1.Prev := Menu;
    if MenuCopy.Prev <> nil then
      MenuCopy.Prev.Next := MenuCopy.Next;
    if MenuCopy.Next <> nil then
      MenuCopy.Next.Prev := MenuCopy.Prev;
  end
  else
  begin
    if (Menu1.Next = Menu) or (Menu.Prev = Menu1) then
      Exit;
    if Menu1.Next <> nil then
      Menu1.Next.Prev := Menu;
    Menu.Prev := Menu1;
    Menu.Next := Menu1Copy.Next;
    Menu1.Next := Menu;
    if MenuCopy.Prev <> nil then
      MenuCopy.Prev.Next := MenuCopy.Next;
    if MenuCopy.Next <> nil then
      MenuCopy.Next.Prev := MenuCopy.Prev;
  end;
end;

procedure PatchBuildMenuBarEx(); stdcall;
var
  MenuArrange: PMenu;
  MenuArrangeS: PMenu;
  MenuArrangeL: PMenu;
  Text: array[0..255] of Char;
  P: PChar;
begin
  Civ2.MenuBar_AddMenu(Civ2.MenuBar, $A, '&UI Additions');
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_SETTINGS, '&Settings...', 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, 0, nil, 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_ABOUT, '&About...', 0);
  //Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_TEST, '&Test...', 0);
  //Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_TEST2, '&Test2...', 0);

  MenuArrange := Civ2.MenuBar_GetSubMenu(Civ2.MenuBar, $328);
  if MenuArrange <> nil then
  begin
    StrCopy(Text, MenuArrange.Text);
    StrCat(Text, ' S');
    P := StrEnd(Text) - 1;
    Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, 0, nil, 0);
    MenuArrangeS := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, IDA_ARRANGE_S, Text, 0);
    MoveMenu(MenuArrange, MenuArrangeS, False);
    P^ := 'L';
    MenuArrangeL := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, IDA_ARRANGE_L, Text, 0);
  end;
end;

procedure PatchBuildMenuBar(); register;
asm
    mov   eax, $0040194C // j_Q_FClose_sub_4A2020();
    call  eax
    call  PatchBuildMenuBarEx
    push  $004E4C3D
    ret
end;

procedure PatchMenuExecDefaultCaseEx(SubNum: Integer); stdcall;
begin
  case SubNum of
    IDM_SETTINGS:
      ShowFormSettings();
    IDM_ABOUT:
      if GetAsyncKeyState(VK_SHIFT) and $8000 = 0 then
        ShowFormAbout()
      else
        TFormConsole.Open();
    //IDM_TEST:
      //ShowFormTest();
    //IDM_TEST2:
      //Test2();
    IDA_ARRANGE_S:
      begin
        ArrangeWindowMiniMapWidth := 185;
        Civ2.ArrangeWindows();
        ArrangeWindowMiniMapWidth := -1;
      end;
    IDA_ARRANGE_L:
      begin
        ArrangeWindowMiniMapWidth := 350;
        Civ2.ArrangeWindows();
        ArrangeWindowMiniMapWidth := -1;
      end;
  end;
end;

procedure PatchMenuExecDefaultCase(); register;
asm
    push  [ebp + $0C] // int aSubNum
    call  PatchMenuExecDefaultCaseEx
    push  $004E3A81
    ret
end;

{ TUiaPatchMenu }

procedure TUiaPatchMenu.Attach(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $004E4C38, [OP_JMP], @PatchBuildMenuBar);
  WriteMemory(HProcess, $004E3A72, [OP_CALL], @PatchMenuExecDefaultCase);
end;

initialization
  TUiaPatchMenu.RegisterMe();

end.

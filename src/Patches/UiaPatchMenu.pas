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
  UiaMain,
  UiaPatchArrangeWindows,
  Civ2UIA_FormAbout,
  Civ2UIA_FormSettings,
  Civ2UIA_FormConsole,
  Civ2UIA_Proc,
  Tests;

const
  IDM_CARAVAN_REVENUE                     = $211;
  IDM_ARRANGE_S                           = $329;
  IDM_ARRANGE_L                           = $32A;
  IDM_SETTINGS                            = $A01;
  IDM_ABOUT                               = $A02;
  IDM_SWITCH_SNOWFALL                     = $A03;
  IDM_TEST                                = $A04;
  IDM_TEST2                               = $A05;

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

procedure StrCopyTitleFromDialog(Text, SectionName: PChar);
var
  Dlg: TDialogWindow;
begin
  Civ2.Dlg_InitWithHeap(@Dlg, $2000);
  Civ2.Dlg_LoadGAMESimpleL0F0(@Dlg, SectionName);
  StrCopy(Text, Dlg.Title);
  Civ2.Dlg_CleanupHeap(@Dlg);
end;

procedure PatchBuildMenuBarEx(); stdcall;
var
  MenuArrange: PMenu;
  MenuArrangeS: PMenu;
  MenuArrangeL: PMenu;
  Text: array[0..79] of Char;
  P: PChar;
  MenuFindCity: PMenu;
  MenuCaravanRevenue: PMenu;
begin
  Civ2.MenuBar_AddMenu(Civ2.MenuBar, $A, '&UI Additions');
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_SETTINGS, '&Settings...', 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, 0, nil, 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_ABOUT, '&About...', 0);
  if Uia.SnowFlakes.IsItTime() then
    Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_SWITCH_SNOWFALL, '&Switch snowfall', 0);
  //Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_TEST, '&Test...', 0);
  //Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_TEST2, '&Test2...', 0);
  //
  MenuArrange := Civ2.MenuBar_GetSubMenu(Civ2.MenuBar, $328);
  if MenuArrange <> nil then
  begin
    StrCopy(Text, MenuArrange.Text);
    StrCat(Text, ' S');
    P := StrEnd(Text) - 1;
    Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, 0, nil, 0);
    MenuArrangeS := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, IDM_ARRANGE_S, Text, 0);
    MoveMenu(MenuArrange, MenuArrangeS, False);
    P^ := 'L';
    MenuArrangeL := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, IDM_ARRANGE_L, Text, 0);
  end;
  //
  MenuFindCity := Civ2.MenuBar_GetSubMenu(Civ2.MenuBar, $210);
  if MenuFindCity <> nil then
  begin
    Civ2.DlgParams_SetStringText(0, '...');
    StrCopyTitleFromDialog(Text, 'SUPPLYSHOW');
    StrCat(Text, '|Shift+G');
    MenuCaravanRevenue := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 2, IDM_CARAVAN_REVENUE, Text, 0);
    MoveMenu(MenuCaravanRevenue, MenuFindCity);
  end;

end;

procedure PatchBuildMenuBar(); register;
asm
    mov   eax, $0040194C // Restored j_Q_FClose_sub_4A2020();
    call  eax
    call  PatchBuildMenuBarEx
    push  $004E4C3D
    ret
end;

procedure PatchUpdateMenuBarEx(); stdcall;
var
  CaravanRevenueActive: Boolean;
  Commodity: Integer;
  Unit1: PUnit;
  Text: array[0..79] of Char;
begin
  CaravanRevenueActive := False;
  with Civ2 do
  begin
    DlgParams_SetStringText(0, '...');
    if (UnitSelected^) and (Game.ActiveUnitIndex >= 0) then
    begin
      Unit1 := @Units[Game.ActiveUnitIndex];
      Commodity := Unit1.Counter;
      if (Unit1.ID <> 0) and (Unit1.HomeCity <> $FF) and (Unit1.CivIndex = HumanCivIndex^) and (Unit1.Orders = -1) and (UnitTypes[Unit1.UnitType].Role = 7) and (Commodity >= 0) then
      begin
        CaravanRevenueActive := True;
        DlgParams_SetString(0, Commodities[Commodity]);
      end;
    end;
    StrCopyTitleFromDialog(Text, 'SUPPLYSHOW');
    StrCat(Text, '|Shift+G');
    MenuBar_ModifyMenuText(MenuBar, IDM_CARAVAN_REVENUE, Text);
    MenuBar_EnableSubMenu(MenuBar, IDM_CARAVAN_REVENUE, CaravanRevenueActive);
    MenuBar_EnableSubMenu(MenuBar, IDM_CARAVAN_REVENUE, not CaravanRevenueActive);

    MenuBar_CreateMenu(MenuBar, nil);     // Restored
  end;
end;

procedure PatchUpdateMenuBar(); register;
asm
    call  PatchUpdateMenuBarEx
    push  $004E5B92
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
    IDM_SWITCH_SNOWFALL:
      Uia.SnowFlakes.Switch();
    //IDM_TEST:
      //ShowFormTest();
    //IDM_TEST2:
      //Test2();
    IDM_ARRANGE_S:
      begin
        ArrangeWindowMiniMapWidth := 185;
        Civ2.ArrangeWindows();
        ArrangeWindowMiniMapWidth := -1;
      end;
    IDM_ARRANGE_L:
      begin
        ArrangeWindowMiniMapWidth := 350;
        Civ2.ArrangeWindows();
        ArrangeWindowMiniMapWidth := -1;
      end;
    IDM_CARAVAN_REVENUE:
      begin
        PopupCaravanDeliveryRevenues(Civ2.HumanCivIndex^);
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
  WriteMemory(HProcess, $004E5B8D, [OP_CALL], @PatchUpdateMenuBar);
  WriteMemory(HProcess, $004E3A72, [OP_CALL], @PatchMenuExecDefaultCase);
end;

initialization
  TUiaPatchMenu.RegisterMe();

end.

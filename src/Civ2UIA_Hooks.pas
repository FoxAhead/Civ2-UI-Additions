unit Civ2UIA_Hooks;

interface

procedure HookImportedFunctions(HProcess: THandle);

implementation

uses
  Civ2UIA_Types,
  Civ2UIA_Proc,
  Civ2UIA_FormConsole,
  SysUtils,
  Classes,
  Windows;

type
  PHookInfo = ^THookInfo;

  THookInfo = packed record
    CallerChain: PCallerChain;
    Addr: Pointer;
    AddrOriginal: Pointer;
    AddrPatched: Pointer;
    ParamsCount: Integer;
  end;

var
  OriginalAddresses: array[1..10] of Integer;
  HookListAddr: TList;
  HookListAddrOriginal: TList;
  HookListAddrPatched: TList;
  HookListParamsCount: TList;

function HookGetCallerChain(): PCallerChain; register;
asm
    mov   eax, ebp
end;

procedure HookPushParams(ParamsCount: Integer); register;
asm
    mov   ecx, ParamsCount
    pop   eax

@@LABEL1:
    push  [ebp + 4 + 4 * ecx]
    loop  @@LABEL1
    push  eax
end;

function HookCall(Address: Pointer): Integer; register;
asm
    call  Address
end;

function PatchSetFocus(HWindow: HWND): Integer; stdcall;
var
  CallerChain: PCallerChain;
  CallerAddress: Integer;
  OriginalAddress: Integer;
  Text: string;
begin
  CallerChain := HookGetCallerChain();
  CallerAddress := Integer(CallerChain.Caller);
  //  SendMessageToLoader(1, 0);
  //  SendMessageToLoader(CallerAddress, HWindow);
  Text := '';
  repeat
    Text := Format('%.6x %s', [Integer(CallerChain.Caller), Text]);
    CallerChain := CallerChain.Prev;
  until Cardinal(CallerChain.Caller) > $1000000;
  TFormConsole.Log(Format('SetFocus(%.8x): %s', [HWindow, Text]));
  OriginalAddress := OriginalAddresses[1];
  asm
    push  HWindow
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end
end;

function PatchDestroyWindow(HWindow: HWND): Integer; stdcall;
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  SendMessageToLoader(2, 0);
  SendMessageToLoader(CallerAddress, HWindow);
  OriginalAddress := OriginalAddresses[2];
  TFormConsole.Log(Format('%.6x DestroyWindow(%.8x)', [CallerAddress, HWindow]));
  asm
    push  HWindow
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end
end;

function PatchShowWindow(HWindow: HWND; nCmdShow: Integer; HookInfo: PHookInfo): Integer; stdcall;
var
  CallerChain: PCallerChain;
  OriginalAddress: Pointer;
  CurrGetFocusBefore: HWND;
  CurrGetFocusAfter: HWND;
begin
  {  CallerChain := HookGetCallerChain();
    //CurrGetFocusBefore := GetFocus();
    //SendMessageToLoader(3, nCmdShow);
    //SendMessageToLoader(HWindow, nCmdShow);
    if nCmdShow = 5 then
    begin
      SendMessageToLoader(HWindow, Integer(CallerChain.Caller));
      SendMessageToLoader(HWindow, Integer(CallerChain.Prev.Caller));
    end;}
  //  OriginalAddress := OriginalAddresses[3];
  HookPushParams(HookInfo.ParamsCount);
  asm
    mov   eax, HookInfo
    mov   eax, THookInfo(eax).AddrOriginal
    call  eax
    mov   @Result, eax
  end;
  //CurrGetFocusAfter := GetFocus();
  //MapMessagesList.Add(TMapMessage.Create(Format('%.8x => %.6x ShowWindow(%.8x, %.d) => %.8x', [CurrGetFocusBefore,CallerAddress, HWindow, nCmdShow,CurrGetFocusAfter])));
//  if nCmdShow = 5 then
//    SetFocus(HWindow);
end;

function PatchHookSetWindowPos(A1, A2, A3, A4, A5: Integer): Integer; stdcall;
//HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  OriginalAddress := OriginalAddresses[4];
  SendMessageToLoader(CallerAddress, 0);
  asm
    push  A5
    push  A4
    push  A3
    push  A2
    push  A1
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
end;

function PatchHookSetWindowLongA(HWindow: HWND; A2, A3: Integer): Integer; stdcall;
//HWND hWnd, int nIndex, LONG dwNewLong
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  OriginalAddress := OriginalAddresses[5];
  if A2 = -4 then
  begin
    SendMessageToLoader(CallerAddress, HWindow);
    SendMessageToLoader(A2, A3);
  end;
  asm
    push  A3
    push  A2
    push  HWindow
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
end;

function PatchHookSetCursor(A1: Integer): Integer; stdcall;
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  OriginalAddress := OriginalAddresses[6];
  SendMessageToLoader(CallerAddress, A1);
  asm
    push  A1
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
end;

function PatchHookCreateWindowEx(dwExStyle: DWORD; lpClassName: PChar; lpWindowName: PChar; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer; hWndParent: HWND; hMenu: hMenu; hInstance: HINST; lpParam: Pointer): HWND; stdcall;
//DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam
var
  CallerAddress1: Integer;
  CallerAddress2: Integer;
  CallerAddress3: Integer;
  CallerAddress4: Integer;
  CallerAddress5: Integer;
  CallerAddress6: Integer;
  CallerAddress7: Integer;
  OriginalAddress: Integer;
begin
  asm
    mov   ebx, ebp
    mov   eax, [ebx + 4]
    mov   CallerAddress1, eax
    mov   ebx, [ebx]
    mov   eax, [ebx + 4]
    mov   CallerAddress2, eax
    mov   ebx, [ebx]
    mov   eax, [ebx + 4]
    mov   CallerAddress3, eax
    mov   ebx, [ebx]
    mov   eax, [ebx + 4]
    mov   CallerAddress4, eax
    mov   ebx, [ebx]
    mov   eax, [ebx + 4]
    mov   CallerAddress5, eax
    mov   ebx, [ebx]
    mov   eax, [ebx + 4]
    mov   CallerAddress6, eax
    mov   ebx, [ebx]
    mov   eax, [ebx + 4]
    mov   CallerAddress7, eax
  end;
  OriginalAddress := OriginalAddresses[7];
  asm
    push  lpParam
    push  hInstance
    push  hMenu
    push  hWndParent
    push  nHeight
    push  nWidth
    push  Y
    push  X
    push  dwStyle
    push  lpWindowName
    push  lpClassName
    push  dwExStyle
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
  SendMessageToLoader(Result, CallerAddress1);
  SendMessageToLoader(CallerAddress2, CallerAddress3);
  SendMessageToLoader(CallerAddress4, CallerAddress5);
  SendMessageToLoader(CallerAddress6, CallerAddress7);
end;

function PatchHookAppendMenu(A1, A2, A3, A4: Integer): Integer; stdcall;
//(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCSTR lpNewItem)
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
  MenuText: string;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  OriginalAddress := OriginalAddresses[8];
  //MenuText := string(A4);
  SendMessageToLoader(A3, A4);
  asm
    push  A4
    push  A3
    push  A2
    push  A1
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
end;

function PatchHookSetScrollPos(A1, A2, A3, A4: Integer): Integer; stdcall;
// int __stdcall SetScrollPos(HWND hWnd, int nBar, int nPos, BOOL bRedraw)
var
  CallerChain: PCallerChain;
  OriginalAddress: Integer;
begin
  asm
    mov   CallerChain, ebp
  end;
  SendMessageToLoader(A1, Integer(CallerChain.Caller));
  SendMessageToLoader(A3, Integer(CallerChain.Prev.Caller));
  OriginalAddress := OriginalAddresses[9];
  asm
    push  A4
    push  A3
    push  A2
    push  A1
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
end;

function PatchHookSetScrollRange(A1, A2, A3, A4, A5: Integer): Integer; stdcall;
// BOOL __stdcall SetScrollRange(HWND hWnd, int nBar, int nMinPos, int nMaxPos, BOOL bRedraw)
var
  CallerChain: PCallerChain;
  OriginalAddress: Integer;
begin
  CallerChain := HookGetCallerChain();
  SendMessageToLoader(A1, Integer(CallerChain.Caller));
  SendMessageToLoader(A4, Integer(CallerChain.Prev.Caller));
  OriginalAddress := OriginalAddresses[10];
  asm
    push  A5
    push  A4
    push  A3
    push  A2
    push  A1
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
end;

{$O-}

procedure HookBase(); stdcall;
var
  HookInfo: THookInfo;
  i: Integer;
  ReturnAddress: Pointer;
begin
  asm
    mov   HookInfo.CallerChain, ebp
    mov   eax, [ebp + 4]
    mov   eax, [eax - 4]
    mov   HookInfo.Addr, eax
  end;
  i := HookListAddr.IndexOf(HookInfo.Addr);
  HookInfo.AddrOriginal := HookListAddrOriginal[i];
  HookInfo.AddrPatched := HookListAddrPatched[i];
  HookInfo.ParamsCount := Integer(HookListParamsCount[i]);
  //SendMessageToLoader(Integer(HookInfo.Addr), Integer(HookInfo.ParamsCount));
  //SendMessageToLoader(Integer(HookInfo.AddrOriginal), Integer(HookInfo.AddrPatched));
  asm
    lea   eax, HookInfo
    push  eax
  end;
  HookPushParams(HookInfo.ParamsCount);
  asm
    mov   eax, HookInfo.AddrPatched
    call  eax
    mov   ecx, HookInfo.ParamsCount
    shl   ecx, 2
    leave
    pop   edx
    add   esp, ecx
    push  edx
    ret
  end;
end;

{$O+}

procedure HookFunction(Index: Integer; HProcess: THandle; Address: Integer; ProcAddress: Pointer; ParamsCount: Integer);
var
  BytesRead: Cardinal;
  OriginalAddress: Pointer;
begin
  ReadProcessMemory(HProcess, Pointer(Address), @OriginalAddress, 4, BytesRead);
  OriginalAddresses[Index] := Integer(OriginalAddress);
  HookListAddr.Add(Pointer(Address));
  HookListAddrOriginal.Add(OriginalAddress);
  HookListAddrPatched.Add(ProcAddress);
  HookListParamsCount.Add(Pointer(ParamsCount));
  //  WriteMemory(HProcess, Address, [], ProcAddress, True);
  WriteMemory(HProcess, Address, [], @HookBase, True);
end;

procedure HookImportedFunctions(HProcess: THandle);
begin
  HookListAddr := TList.Create();
  HookListAddrOriginal := TList.Create();
  HookListAddrPatched := TList.Create();
  HookListParamsCount := TList.Create();
  HookFunction(1, HProcess, $006E7D94, @PatchSetFocus, 1);
  //HookFunction(2, HProcess, $006E7E1C, @PatchDestroyWindow);
  //HookFunction(3, HProcess, $006E7E24, @PatchShowWindow, 2);
  //HookFunction(4, HProcess, $006E7DB8, @PatchHookSetWindowPos); - Never Used!
  //HookFunction(5, HProcess, $006E7DB0, @PatchHookSetWindowLongA);
  //HookFunction(6, HProcess, $006E7E64, @PatchHookSetCursor);
  //HookFunction(7, HProcess, $006E7D50, @PatchHookCreateWindowEx);
  //HookFunction(8, HProcess, $006E7ED0, @PatchHookAppendMenu);
  //HookFunction(9, HProcess, $006E7EA8, @PatchHookSetScrollPos);
  //HookFunction(10, HProcess, $006E7EAC, @PatchHookSetScrollRange);
  //SendMessageToLoader(3, OriginalAddresses[2]);
end;

end.

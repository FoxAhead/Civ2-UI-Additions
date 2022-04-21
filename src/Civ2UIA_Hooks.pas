unit Civ2UIA_Hooks;

interface

procedure HookImportedFunctions(HProcess: THandle);

implementation

uses
  Civ2UIA_Global,
  Civ2UIA_Proc,
  Civ2UIA_MapMessage,
  Civ2UIA_Ex,
  SysUtils,
  Windows;

var
  OriginalAddresses: array[1..10] of Integer;

function PatchSetFocus(HWindow: HWND): Integer; stdcall;
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  SendMessageToLoader(1, 0);
  SendMessageToLoader(CallerAddress, HWindow);
  OriginalAddress := OriginalAddresses[1];
  MapMessagesList.Add(TMapMessage.Create(Format('%.6x SetFocus(%.8x)', [CallerAddress, HWindow])));
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
  MapMessagesList.Add(TMapMessage.Create(Format('%.6x DestroyWindow(%.8x)', [CallerAddress, HWindow])));
  asm
    push  HWindow
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end
end;

function PatchShowWindow(HWindow: HWND; nCmdShow: Integer): Integer; stdcall;
var
  CallerAddress: Integer;
  OriginalAddress: Integer;
  CurrGetFocusBefore: HWND;
  CurrGetFocusAfter: HWND;
begin
  asm
    mov   eax, [ebp + 4]
    mov   CallerAddress, eax
  end;
  CurrGetFocusBefore := GetFocus();
  //SendMessageToLoader(3, nCmdShow);
  //SendMessageToLoader(CallerAddress, HWindow);
  OriginalAddress := OriginalAddresses[3];
  asm
    push  nCmdShow
    push  HWindow
    mov   eax, OriginalAddress
    call  eax
    mov   @Result, eax
  end;
  CurrGetFocusAfter := GetFocus();
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

procedure HookFunction(Index: Integer; HProcess: THandle; Address: Integer; ProcAddress: Pointer);
var
  BytesRead: Cardinal;
  PatchedAddress: LongRec;
begin
  ReadProcessMemory(HProcess, Pointer(Address), @OriginalAddresses[Index], 4, BytesRead);
  PatchedAddress := LongRec(ProcAddress);
  WriteMemory(HProcess, Address, [PatchedAddress.Bytes[0], PatchedAddress.Bytes[1], PatchedAddress.Bytes[2], PatchedAddress.Bytes[3]]);
end;

procedure HookImportedFunctions(HProcess: THandle);
begin
  //HookFunction(1, HProcess, $006E7D94, @PatchSetFocus);
  //HookFunction(2, HProcess, $006E7E1C, @PatchDestroyWindow);
  //HookFunction(3, HProcess, $006E7E24, @PatchShowWindow);
  //HookFunction(4, HProcess, $006E7DB8, @PatchHookSetWindowPos); - Never Used!
  //HookFunction(5, HProcess, $006E7DB0, @PatchHookSetWindowLongA);
  //HookFunction(6, HProcess, $006E7E64, @PatchHookSetCursor);
  //HookFunction(7, HProcess, $006E7D50, @PatchHookCreateWindowEx);
  //HookFunction(8, HProcess, $006E7ED0, @PatchHookAppendMenu);
  //SendMessageToLoader(3, OriginalAddresses[2]);
end;

end.

unit UiaPatchDllGif;

interface

uses
  UiaPatch;

type
  TUiaPatchDllGif = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  SysUtils,
  Windows;

type
  TDllGifsToBeFixed = packed record
    ResNum: Integer;
    WrongSize: Cardinal;
  end;

{(*}
const
  DllGifsToBeFixed: array[1..3] of TDllGifsToBeFixed = (
    ( ResNum: 105; WrongSize: 74478 ),
    ( ResNum: 229; WrongSize: 29923 ),
    ( ResNum: 250; WrongSize: 27741 )
  );
{*)}

var
  ResNumsDoFixCache: array[105..250] of Shortint; // 1 - Yes, 0 - Undefined, -1 - No

function DllGifNeedFixing(ResNum: Integer): Boolean;
type
  TModules = array[0..34] of HMODULE;
var
  i, j, k, l: Integer;
  ResInfo: HRSRC;
  ModulesCount: Integer;
  HModules: ^TModules;
  ResSize: Cardinal;
begin
  Result := False;
  if ResNum in [Low(ResNumsDoFixCache)..High(ResNumsDoFixCache)] then
  begin
    ModulesCount := PInteger($006387CC)^;
    HModules := Pointer($006E4F60);
    if ResNumsDoFixCache[ResNum] = 0 then // Undefined
    begin
      ResNumsDoFixCache[ResNum] := -1;
      for i := Low(DllGifsToBeFixed) to High(DllGifsToBeFixed) do
      begin
        if DllGifsToBeFixed[i].ResNum = ResNum then
        begin
          for j := 0 to ModulesCount - 1 do
          begin
            ResInfo := FindResource(HModules^[j], MakeIntResource(ResNum), 'GIFS');
            if ResInfo <> 0 then
            begin
              Inc(l);
              ResSize := SizeofResource(HModules^[j], ResInfo);
              if ResSize = DllGifsToBeFixed[i].WrongSize then
                ResNumsDoFixCache[ResNum] := 1;
              Break;
            end;
          end;
          Break;
        end;
      end;
      //SendMessageToLoader(ResNum, ResNumsDoFixCache[ResNum]);
    end;
    Result := (ResNumsDoFixCache[ResNum] = 1);
  end;
end;

function PatchFindAndLoadResourceEx(ResType: PChar; ResNum: Integer; var Module: HMODULE; var ResInfo: HRSRC): HGLOBAL; stdcall;
var
  MyResInfo: HRSRC;
  Gifs: array[0..4] of char;
begin
  Gifs := 'GIFS';
  if StrLComp(ResType, Gifs, 4) = 0 then
  begin
    if DllGifNeedFixing(ResNum) then
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

{ TUiaPatchDllGif }

procedure TUiaPatchDllGif.Attach(HProcess: Cardinal);
begin
  // Fix mk.dll (229.gif, 250.gif) and pv.dll (105.gif)
  WriteMemory(HProcess, $005DB2D4, [OP_JMP], @PatchFindAndLoadResource);
end;

initialization
  TUiaPatchDllGif.RegisterMe();

end.


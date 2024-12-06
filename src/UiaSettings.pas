unit UiaSettings;

interface

uses
  Classes;

type
  TUiaDat = packed record
    Version: Integer;
    Size: Integer;
    ColorExposure: Double;
    ColorGamma: Double;
    AdvisorHeights: array[1..12] of Word;
    DialogLines: array[1..16] of Byte;
    Flags: array[0..31] of Byte;          // 256 flags
    AdvisorSorts: array[1..12] of ShortInt; // 0 - no sort, 1 - sort by first column ascending, -1 - sort by first column descending, etc...
  end;

  TUiaSettings = class
  private
  protected
  public
    Dat: TUiaDat;
    SuppressPopupList: TStringList;
    constructor Create;
    destructor Destroy; override;
    function DatFlagSet(i: Integer): Boolean;
    procedure Load();
    procedure LoadDatFile();
    procedure LoadDefaultDat();
    procedure Save();
    procedure SaveDatFile();
    procedure SetDatFlag(i: Integer; v: Boolean);
  published
  end;

implementation

uses
  SysUtils,
  Windows,
  Civ2UIA_Proc,
  Civ2UIA_FormConsole;

const
  FILENAME_CIV2UIA_DAT                    = 'CIV2UIA.DAT';
  FILENAME_CIV2UIASP_TXT                  = 'Civ2UIASuppressPopup.txt';

  { TUiaSettings }

constructor TUiaSettings.Create;
begin
  SuppressPopupList := TStringList.Create();
  Load();
end;

function TUiaSettings.DatFlagSet(i: Integer): Boolean;
var
  j, k: Integer;
begin
  j := i shr 3;
  k := 1 shl (i and 7);
  Result := (Dat.Flags[j] and k) <> 0;
end;

destructor TUiaSettings.Destroy;
begin
  SuppressPopupList.Free();
  inherited;
end;

procedure TUiaSettings.Load;
begin
  SuppressPopupList.Clear();
  try
    SuppressPopupList.LoadFromFile(FILENAME_CIV2UIASP_TXT);
  except
  end;
  LoadDatFile();
end;

procedure TUiaSettings.LoadDatFile;
var
  FileHandle, BytesRead, SizeOfDat: Integer;
begin
  SizeOfDat := SizeOf(Dat);
  ZeroMemory(@Dat, SizeOfDat);
  FileHandle := FileOpen(FILENAME_CIV2UIA_DAT, fmOpenRead);
  if FileHandle > 0 then
  begin
    BytesRead := FileRead(FileHandle, Dat, SizeOfDat);
    FileClose(FileHandle);
    if (BytesRead <= SizeOfDat) and (Dat.Version = 1) and (Dat.Size <= SizeOfDat) then
      Exit;
  end;
  LoadDefaultDat();
end;

procedure TUiaSettings.LoadDefaultDat;
begin
  Dat.Version := 1;
  Dat.Size := SizeOf(Dat);
  Dat.ColorExposure := 0.0;
  Dat.ColorGamma := 1.0;
  FillChar(Dat.Flags, SizeOf(Dat.Flags), $FF);
end;

procedure TUiaSettings.Save;
begin
  try
    SuppressPopupList.SaveToFile(FILENAME_CIV2UIASP_TXT);
    SaveDatFile();
  except
    on E: Exception do
    begin
      TFormConsole.Log('TUiaSettings.Save() Error %s', [E.Message]);
    end;
  end;
end;

procedure TUiaSettings.SaveDatFile;
var
  FileHandle, BytesWritten: Integer;
begin
  FileHandle := FileCreate(FILENAME_CIV2UIA_DAT);
  if FileHandle > 0 then
  begin
    BytesWritten := FileWrite(FileHandle, Dat, SizeOf(Dat));
    FileClose(FileHandle);
    if BytesWritten <> SizeOf(Dat) then
      DeleteFile(FILENAME_CIV2UIA_DAT);
  end;
end;

procedure TUiaSettings.SetDatFlag(i: Integer; v: Boolean);
var
  j, k: Integer;
begin
  j := i shr 3;
  k := 1 shl (i and 7);
  if v then
    Dat.Flags[j] := Dat.Flags[j] or k
  else
    Dat.Flags[j] := Dat.Flags[j] and not k;
end;

end.

unit UiaPatchCDAudio;

interface

uses
  UiaPatch;

type
  TUiaPatchCDAudio = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Graphics,
  MMSystem,
  SysUtils,
  Types,
  Windows,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx;

var
  MCICDCheckThrottle: Integer;
  MCIPlayId: MCIDEVICEID;
  MCIPlayTrack: Cardinal;
  MCIPlayLength: Cardinal;
  MCITextSizeX: Integer;

function CDGetTrackLength(ID: MCIDEVICEID; TrackN: Cardinal): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_LENGTH;
  StatusParms.dwTrack := TrackN;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM + MCI_TRACK, Longint(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn shl 8);
end;

function CDGetPosition(ID: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_POSITION;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM, Longint(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn);
end;

function CDGetMode(ID: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_MODE;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM, Longint(@StatusParms)) = 0 then
    Result := StatusParms.dwReturn;
end;

function CDPosition_To_String(TMSF: Cardinal): string;
begin
  Result := Format('Track %.2d - %.2d:%.2d', [HiByte(HiWord(TMSF)), LOBYTE(HiWord(TMSF)), HiByte(LOWORD(TMSF))]);
end;

function CDLength_To_String(MSF: Cardinal): string;
begin
  Result := Format('%.2d:%.2d', [LOBYTE(HiWord(MSF)), HiByte(LOWORD(MSF))]);
end;

function CDTime_To_Frames(TMSF: Cardinal): Integer;
begin
  Result := LOBYTE(HiWord(TMSF)) * 60 * 75 + HiByte(LOWORD(TMSF)) * 75 + LOBYTE(LOWORD(TMSF));
end;

procedure DrawCDPositon(Position: Cardinal);
var
  //DC: HDC;
  Canvas: TCanvasEx;
  //SavedDC: Integer;
  TextOut: string;
  R: TRect;
  R2: TRect;
  TextSize: TSize;
begin
  TextOut := CDPosition_To_String(Position) + ' / ' + CDLength_To_String(MCIPlayLength);
  //DC := Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo^.DeviceContext;
  Canvas := TCanvasEx.Create(@Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort);
  //SavedDC := SaveDC(DC);
  //Canvas := TCanvas.Create();
  //Canvas.Handle := DC;
  Canvas.Font.Style := [];
  Canvas.Font.Size := 10;
  Canvas.Font.Name := 'Arial';
  TextSize := Canvas.TextExtent(TextOut);
  if TextSize.cx > MCITextSizeX then
    MCITextSizeX := TextSize.cx;
  R := Rect(0, 0, MCITextSizeX, TextSize.cy);
  OffsetRect(R, Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.ClientRectangle.Right - MCITextSizeX, 9);
  InflateRect(R, 2, 0);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  Canvas.Pen.Color := clBlack;
  Canvas.Rectangle(R);
  R2 := R;
  InflateRect(R2, -1, -1);
  R2.Right := R2.Left + (R2.Right - R2.Left) * CDTime_To_Frames(Position) div CDTime_To_Frames(MCIPlayLength);
  Canvas.Brush.Color := clSkyBlue;
  Canvas.Pen.Color := clSkyBlue;
  Canvas.Rectangle(R2);
  Canvas.Brush.Style := bsClear;
  Canvas.MoveTo(R.Left + 2, R.Top + 0);
  Canvas.Font.Color := clBlack;
  Canvas.FontShadowColor := clWhite;
  Canvas.FontShadows := SHADOW_NONE;
  Canvas.TextOutWithShadows(TextOut);
  //Canvas.Handle := 0;
  Canvas.Free();
  //RestoreDC(DC, SavedDC);
  InvalidateRect(Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure^.HWindow, @R, True);
end;

function PatchMciPlay(MCIId: MCIDEVICEID; uMessage: UINT; dwParam1, dwParam2: DWORD): MCIERROR; stdcall;
var
  PlayParms: TMCI_Play_Parms;
begin
  MCIPlayId := 0;
  MCIPlayTrack := 0;
  Result := mciSendCommand(MCIId, uMessage, dwParam1, dwParam2);
  if Result = 0 then
  begin
    PlayParms := PMCI_Play_Parms(dwParam2)^;
    MCIPlayId := MCIId;
    MCIPlayTrack := PlayParms.dwFrom;
    MCIPlayLength := CDGetTrackLength(MCIPlayId, MCIPlayTrack);
  end;
end;

procedure PatchCheckCDStatus(); stdcall;
var
  Position: Cardinal;
  ID: Cardinal;
begin
  Inc(MCICDCheckThrottle);
  if MCICDCheckThrottle > 5 then
  begin
    MCICDCheckThrottle := 0;
    if MCIPlayId > 0 then
    begin
      if CDGetMode(MCIPlayId) = MCI_MODE_PLAY then
      begin
        Position := CDGetPosition(MCIPlayId);
        DrawCDPositon(Position);
        if ((Position and $00FFFFFF) >= MCIPlayLength) or ((Position shr 24) <> MCIPlayTrack) then
        begin
          ID := MCIPlayId;
          MCIPlayId := 0;
          mciSendCommand(ID, MCI_STOP, 0, 0);
          mciSendCommand(ID, MCI_CLOSE, 0, 0);
          PostMessage(PCardinal($006E4FF8)^, MM_MCINOTIFY, MCI_NOTIFY_SUCCESSFUL, ID);
        end;
      end;
    end;
  end;
end;

function PatchWindowProcMsMrTimerAfter(): Integer; stdcall;
begin
  Result := 0;
  PatchCheckCDStatus();
end;

{ TUiaPatchCDAudio }

procedure TUiaPatchCDAudio.Attach(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchWindowProcMsMrTimerAfter);
  WriteMemory(HProcess, $005DDCD3, [OP_NOP, OP_CALL], @PatchMciPlay);
end;

initialization
  TUiaPatchCDAudio.RegisterMe();

end.


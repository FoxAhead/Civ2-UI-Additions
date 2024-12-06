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
  Classes,
  Graphics,
  MMSystem,
  SysUtils,
  Windows,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_FormConsole;

const
  MAGIC_DEVICE_ID                         = $12345678;

var
  MCICDCheckThrottle: Integer;
  MCIPlayTrack: Cardinal;
  MCIPlayLength: Cardinal;
  MCITextSizeX: Integer;
  MCICallbackHWND: HWND;
  MusicPlaylist: TStringList;

function ConvertMsToTMSF(Track: Cardinal; Ms: Cardinal): Cardinal;
var
  t, m, s, f: Byte;
begin
  t := Track;
  m := Ms div 60000;
  s := Ms mod 60000 div 1000;
  f := Ms mod 1000 * 75 div 1000;
  Result := mci_Make_TMSF(t, m, s, f);
end;

function GetCurrentDeviceId(): MCIDEVICEID;
begin
  if Civ2.MciInfo.CdAudioId = MAGIC_DEVICE_ID then
    Result := Civ2.MciInfo.CdAudioId2
  else if Civ2.MciInfo.CdAudioId <> 0 then
    Result := Civ2.MciInfo.CdAudioId
  else
    Result := 0;
end;

function GetCurrentTrackLengthFSM(): Cardinal;
var
  StatusParms: MCI_STATUS_PARMS;
  MciResult: MCIERROR;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_LENGTH;
  if Civ2.MciInfo.CdAudioId = MAGIC_DEVICE_ID then
  begin
    if mciSendCommand(Civ2.MciInfo.CdAudioId2, MCI_STATUS, MCI_STATUS_ITEM, DWORD(@StatusParms)) = 0 then
      Result := FastSwap(ConvertMsToTMSF(0, StatusParms.dwReturn));
  end
  else if Civ2.MciInfo.CdAudioId <> 0 then
  begin
    StatusParms.dwTrack := MCIPlayTrack;
    if mciSendCommand(Civ2.MciInfo.CdAudioId, MCI_STATUS, MCI_STATUS_ITEM + MCI_TRACK, DWORD(@StatusParms)) = 0 then
      Result := FastSwap(StatusParms.dwReturn shl 8);
  end;
end;

function GetCurrentPositionFSMT(): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_POSITION;
  if mciSendCommand(GetCurrentDeviceId(), MCI_STATUS, MCI_STATUS_ITEM, DWORD(@StatusParms)) = 0 then
  begin
    if Civ2.MciInfo.CdAudioId = MAGIC_DEVICE_ID then
      Result := FastSwap(ConvertMsToTMSF(MCIPlayTrack, StatusParms.dwReturn))
    else
      Result := FastSwap(StatusParms.dwReturn);
  end;
end;

function GetCurrentMode(): Cardinal;
var
  StatusParms: MCI_STATUS_PARMS;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_MODE;
  if mciSendCommand(GetCurrentDeviceId(), MCI_STATUS, MCI_STATUS_ITEM, DWORD(@StatusParms)) = 0 then
    Result := StatusParms.dwReturn;
end;

function FSMT_To_String(FSMT: Cardinal): string;
begin
  Result := Format('Track %.2d - %.2d:%.2d', [HiByte(HiWord(FSMT)), LOBYTE(HiWord(FSMT)), HiByte(LOWORD(FSMT))]);
end;

function FSM_To_String(FSM: Cardinal): string;
begin
  Result := Format('%.2d:%.2d', [LOBYTE(HiWord(FSM)), HiByte(LOWORD(FSM))]);
end;

function FSMT_To_Frames(FSMT: Cardinal): Integer;
begin
  Result := LOBYTE(HiWord(FSMT)) * 60 * 75 + HiByte(LOWORD(FSMT)) * 75 + LOBYTE(LOWORD(FSMT));
end;

procedure DrawCDPositon(Position: Cardinal);
var
  Canvas: TCanvasEx;
  TextOut: string;
  R: TRect;
  R2: TRect;
  TextSize: TSize;
begin
  if Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo = nil then
    Exit;
  TextOut := FSMT_To_String(Position) + ' / ' + FSM_To_String(MCIPlayLength);
  Canvas := TCanvasEx.Create(@Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort);
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
  R2.Right := R2.Left + (R2.Right - R2.Left) * FSMT_To_Frames(Position) div FSMT_To_Frames(MCIPlayLength);
  Canvas.Brush.Color := clSkyBlue;
  Canvas.Pen.Color := clSkyBlue;
  Canvas.Rectangle(R2);
  Canvas.Brush.Style := bsClear;
  Canvas.MoveTo(R.Left + 2, R.Top + 0);
  Canvas.Font.Color := clBlack;
  Canvas.FontShadowColor := clWhite;
  Canvas.FontShadows := SHADOW_NONE;
  Canvas.TextOutWithShadows(TextOut);
  Canvas.Free();
  InvalidateRect(Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure^.HWindow, @R, True);
end;

// Draw CD Positon and Fix for MCI not notifying on track end since Vista
procedure PatchCheckCDStatus(); stdcall;
var
  Position: Cardinal;
  ID: Cardinal;
begin
  if Civ2.MciInfo.CdAudioId <> 0 then
  begin
    MCICDCheckThrottle := (MCICDCheckThrottle + 1) mod 5;
    if MCICDCheckThrottle = 0 then
    begin
      if GetCurrentMode() = MCI_MODE_PLAY then
      begin
        Position := GetCurrentPositionFSMT();
        DrawCDPositon(Position);
        //TFormConsole.Log('PatchCheckCDStatus %.08x %.08x %.08x', [Position, MCIPlayLength, MCIPlayTrack]);
        if (Civ2.MciInfo.CdAudioId <> MAGIC_DEVICE_ID) and (((Position and $00FFFFFF) >= MCIPlayLength) or ((Position shr 24) <> MCIPlayTrack)) then
        begin
          TFormConsole.Log('PatchCheckCDStatus %.08x %.08x %.08x', [Position, MCIPlayLength, MCIPlayTrack]);
          ID := Civ2.MciInfo.CdAudioId;
          //Civ2.MciInfo.CdAudioId := 0;
          //MciSendCommand(ID, MCI_STOP, 0, 0);
          //MciSendCommand(ID, MCI_CLOSE, 0, 0);
          PostMessage(MCICallbackHWND, MM_MCINOTIFY, MCI_NOTIFY_SUCCESSFUL, ID);
        end;
      end;
    end;
  end;
end;

function GetCDRoot(): PChar;
begin
  if Civ2.CDRoot[0] = #0 then
    Civ2.CDRootFind('Civ2\Civ2.exe');
  Result := Civ2.CDRoot;
end;

function PatchWindowProcMsMrTimerAfter(): Integer; stdcall;
begin
  PatchCheckCDStatus();
  Result := 0;
end;

function TryMciOpenCdAudio(ElementName: PChar; dwParam1: DWORD; var dwParam2: MCI_OPEN_PARMS; out MciResult: MCIERROR): Boolean; stdcall;
var
  SavedOpenParms: MCI_OPEN_PARMS;
  Text: array[0..255] of Char;
begin
  Result := False;
  SavedOpenParms := dwParam2;
  if ElementName = nil then
    dwParam2.lpstrElementName := nil
  else if ElementName[1] = ':' then
    dwParam2.lpstrElementName := ElementName
  else
    Exit;
  MciResult := mciSendCommand(0, MCI_OPEN, dwParam1, DWORD(@dwParam2));
  Result := (MciResult = 0);
  if not Result then
  begin
    dwParam2 := SavedOpenParms;
    mciGetErrorString(MciResult, Text, SizeOf(Text));
    TFormConsole.Log(IntToStr(MciResult) + Text);
  end;
end;

// Specify CDRoot as ElementName for MCI_OPEN command to correctly identify Civ2 CD in case of several CD-ROMs present
function PatchMciOpenCDAudio(mciId: MCIDEVICEID; uMessage: UINT; dwParam1: DWORD; dwParam2: PMCI_Open_Parms): MCIERROR; stdcall;
begin
  // Try add CDRoot as ElementName for more specific CD-ROM search, not just first one in system
  if not TryMciOpenCdAudio(GetCDRoot(), dwParam1 or MCI_OPEN_ELEMENT, dwParam2^, Result) then
    // Fallback to default logic
    TryMciOpenCdAudio(nil, dwParam1, dwParam2^, Result);
end;

function GetMusicPath(): string;
begin
  if Civ2.PathWorking[0] <> #0 then
  begin
    Result := Civ2.PathWorking + '\Music\';
    if DirectoryExists(Result) then
      Exit;
  end;
  if Civ2.PathCivilizationDirectory[0] = #0 then
    Civ2.CheckPaths('Civ2\Civ2.exe');
  Result := Civ2.PathCivilizationDirectory + 'Music\';
  if DirectoryExists(Result) then
    Exit;
  Result := '';
end;

function InitMusicPlaylist(): MCIERROR;
const
  SoundFileMask                           : string = '.mp3;.wav;.aiff;.flac;.ogg;.aac;.wma;.ape';
var
  MusicPath: string;
  SR: TSearchRec;
begin
  MusicPlaylist.Clear();
  TFormConsole.Log(Format('PathCivilizationDirectory: %s', [Civ2.PathCivilizationDirectory]));
  TFormConsole.Log(Format('PathWorking: %s', [Civ2.PathWorking]));
  MusicPath := GetMusicPath();
  TFormConsole.Log(Format('MusicPath: %s', [MusicPath]));
  if MusicPath <> '' then
  begin
    Result := 0;
    if SysUtils.FindFirst(MusicPath + '*', faArchive, SR) = 0 then
    begin
      repeat
        if Pos(LowerCase(ExtractFileExt(SR.Name)), SoundFileMask) > 0 then
        begin
          MusicPlaylist.Add(MusicPath + SR.Name);
          TFormConsole.Log(Format('Name: %s Size: %d Attr: %x', [SR.Name, SR.Size, SR.Attr]));
        end;
      until SysUtils.FindNext(SR) <> 0;
      SysUtils.FindClose(SR);
    end;
  end
  else
    Result := MCIERR_FILE_NOT_FOUND;
end;

function WrapMciSendCommand(mciId: MCIDEVICEID; uMessage: UINT; dwParam1: DWORD; dwParam2: DWORD): MCIERROR; stdcall;
var
  OpenParmsP: ^MCI_OPEN_PARMS absolute dwParam2;
  StatusParmsP: ^MCI_STATUS_PARMS absolute dwParam2;
  SeekParmsP: ^MCI_SEEK_PARMS absolute dwParam2;
  PlayParmsP: ^MCI_PLAY_PARMS absolute dwParam2;
  OpenParms: MCI_OPEN_PARMS;
  FileIdx: Integer;
  dwFlags: DWORD;
begin
  Result := 0;
  if uMessage = MCI_OPEN then
    if (GetCDRoot() = '.\') and (OpenParmsP.lpstrDeviceType = 'cdaudio') then
    begin
      Result := InitMusicPlaylist();
      if Result = 0 then
        OpenParmsP.wDeviceID := MAGIC_DEVICE_ID;
    end
    else
      Result := PatchMciOpenCDAudio(mciId, uMessage, dwParam1, PMCI_Open_Parms(dwParam2))
  else if mciId = MAGIC_DEVICE_ID then
  begin
    case uMessage of
      MCI_CLOSE:
        begin
          MusicPlaylist.Clear();
        end;
      MCI_SET:
        begin
        end;
      MCI_SEEK:
        begin
          FileIdx := Integer(SeekParmsP.dwTo) - 2;
          if (dwParam1 = MCI_TO) and (FileIdx < 0) and (FileIdx >= MusicPlaylist.Count) then
            Result := MMIOERR_CANNOTSEEK;
          //TFormConsole.Log(Format('MCI_SEEK %d, Result %d', [TrackNo, Result]));
        end;
      MCI_STATUS:
        begin
          if (dwParam1 = MCI_STATUS_ITEM) and (StatusParmsP.dwItem = MCI_STATUS_NUMBER_OF_TRACKS) then
            StatusParmsP.dwReturn := MusicPlaylist.Count + 1;
        end;
      MCI_PLAY:
        begin
          FileIdx := Integer(PlayParmsP.dwFrom) - 2;
          if (FileIdx < 0) and (FileIdx >= MusicPlaylist.Count) then
            Result := MMIOERR_CANNOTSEEK
          else
          begin
            dwFlags := MCI_OPEN_ELEMENT;
            OpenParms.lpstrElementName := PChar(MusicPlaylist[FileIdx]);
            //TFormConsole.Log(Format('lpstrElementName %s', [OpenParms.lpstrElementName]));
            Result := mciSendCommand(0, MCI_OPEN, dwFlags, DWORD(@OpenParms));
            if Result <> 0 then
            begin
              dwFlags := dwFlags or MCI_OPEN_TYPE;
              OpenParms.lpstrDeviceType := 'mpegvideo';
              Result := mciSendCommand(0, MCI_OPEN, dwFlags, DWORD(@OpenParms));
            end;
            if Result = 0 then
            begin
              Civ2.MciInfo.CdAudioId2 := OpenParms.wDeviceID;
              Result := mciSendCommand(Civ2.MciInfo.CdAudioId2, MCI_PLAY, MCI_NOTIFY, DWORD(PlayParmsP));
              if Result <> 0 then
              begin
                mciSendCommand(Civ2.MciInfo.CdAudioId2, MCI_CLOSE, 0, 0);
                Civ2.MciInfo.CdAudioId2 := 0;
              end;
            end;
          end;
        end;
      MCI_STOP:
        begin
          mciSendCommand(Civ2.MciInfo.CdAudioId2, MCI_STOP, 0, 0);
          mciSendCommand(Civ2.MciInfo.CdAudioId2, MCI_CLOSE, 0, 0);
          Civ2.MciInfo.CdAudioId2 := 0;
        end;
    end;
  end
  else
    Result := mciSendCommand(mciId, uMessage, dwParam1, dwParam2);

  if uMessage = MCI_PLAY then
  begin
    TFormConsole.Log(Format('MCI_PLAY TrackN %d, Result %d', [PlayParmsP.dwFrom, Result]));
    MCIPlayTrack := 0;
    if Result = 0 then
    begin
      MCICallbackHWND := PlayParmsP.dwCallback;
      MCIPlayTrack := PlayParmsP.dwFrom;
      MCIPlayLength := GetCurrentTrackLengthFSM();
    end;
  end;
end;

function PatchWindowProcMCINotify(hWnd: hWnd; Msg: UINT; wParam: wParam; lParam: lParam): LRESULT; stdcall;
begin
  if Msg <> MM_MCINOTIFY then
  begin
    Result := DefWindowProcA(hWnd, Msg, wParam, lParam);
    Exit;
  end;
  if wParam = MCI_NOTIFY_SUCCESSFUL then
  begin
    TFormConsole.Log('MCI_NOTIFY MCI_NOTIFY_SUCCESSFUL %.08x', [lParam]);
    if Word(lParam) = Civ2.MciInfo.SequencerId then
      Civ2.MciNotifySequencer()
        // Also trigger when we are in file mode
    else if (Word(lParam) = Civ2.MciInfo.CdAudioId) or (Civ2.MciInfo.CdAudioId = MAGIC_DEVICE_ID) and (Word(lParam) = Civ2.MciInfo.CdAudioId2) then
      Civ2.MciNotifyCdAudio();
  end
  else
    TFormConsole.Log('MCI_NOTIFY %.08x %.08x', [wParam, lParam]);
  Result := 0;
end;

function PatchMciPrepareCdAudio(): Integer; cdecl;
begin
  if GetCDRoot() = '.\' then
    InitMusicPlaylist();
  Result := Civ2.MciGetNumberOfTracks();  // Restore
end;

{ TUiaPatchCDAudio }

procedure TUiaPatchCDAudio.Attach(HProcess: Cardinal);
begin
  // On MsMrTimer event check CD status to draw current position and send MCI_NOTIFY_SUCCESSFUL at the end of each track
  WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchWindowProcMsMrTimerAfter);
  // Wrap mciSendCommandA function to intercept all MCI commands
  WriteMemory(HProcess, $006E7FAC, [], @WrapMciSendCommand, True);
  // CreateWindowMMWindow: replace whole WndClass.lpfnWndProc function
  WriteMemory(HProcess, $005DD8B0 + 3, [], @PatchWindowProcMCINotify, True);
  // Update music file list in case WorkingDirectory was changed
  WriteMemory(HProcess, $0046E4BF, [OP_CALL], @PatchMciPrepareCdAudio);
end;

initialization
  MusicPlaylist := TStringList.Create();
  MusicPlaylist.Sorted := True;
  TUiaPatchCDAudio.RegisterMe();

finalization
  MusicPlaylist.Free();

end.

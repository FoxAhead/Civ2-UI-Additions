unit UiaPatchSuppressPopup;

interface

uses
  UiaPatch;

type
  TUiaPatchSuppressPopup = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  SysUtils,
  UiaMain,
  Civ2Types;

function SimplePopupSuppressed(SectionName: PChar): Boolean;
begin
  Result := False;
  if (SectionName <> nil) and Uia.Settings.DatFlagSet(0) then
  begin
    Result := (Uia.Settings.SuppressPopupList.IndexOf(string(SectionName)) > -1);
  end;
end;

procedure PatchLoadPopupDialogAfterEx(Dialog: PDialogWindow; FileName, SectionName: PChar); stdcall;
var
  TextLine: PDlgTextLine;
  Text: string;
begin
  if (FileName <> nil) and (StrComp(FileName, 'GAME') = 0) then
  begin
    if SimplePopupSuppressed(SectionName) then
    begin
      if Dialog.Title <> nil then
        Text := string(Dialog.Title) + ': ';
      TextLine := Dialog.FirstTextLine;
      while TextLine <> nil do
      begin
        Text := Text + ' ' + string(TextLine.Text);
        TextLine := TextLine.Next;
      end;
      Uia.MapMessages.Add(Text);
      Dialog.PressedButton := $12345678;
    end
  end;
end;

procedure PatchLoadPopupDialogAfter(); register;
asm
    push  eax
    push  [ebp + $0C]  // char *aSectionName
    push  [ebp + $08]  // char *aFileName
    push  [ebp - $180] // P_DialogWindow this
    call  PatchLoadPopupDialogAfterEx
    pop   eax
    push  $005A6C1C
    ret
end;

procedure PatchCreateDialogAndWaitBefore(); register;
asm
    mov   [ebp - $114], ecx
    cmp   [ecx + $DC], $12345678 // Dialog.PressedButton
    je    @LABEL_NODIAOLOG
    push  $005A5F46
    ret

@LABEL_NODIAOLOG:
    mov   [ecx + $DC], 0
    XOR   eax, eax
    push  $005A6323
    ret
end;

{ TUiaPatchSuppressPopup }

procedure TUiaPatchSuppressPopup.Attach(HProcess: Cardinal);
begin
  // (0) Suppress specific simple popup message
  WriteMemory(HProcess, $005A6C12, [OP_JMP], @PatchLoadPopupDialogAfter);
  WriteMemory(HProcess, $005A5F40, [OP_JMP], @PatchCreateDialogAndWaitBefore);

end;

initialization
  TUiaPatchSuppressPopup.RegisterMe();

end.

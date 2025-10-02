unit UiaPatchDlg;

interface

uses
  UiaPatch;

type
  TUiaPatchDlg = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Classes,
  Civ2Types,
  Civ2Proc;

var
  // Global variable to store list of dialog section names that should be sortable
  SortableDialogSectionNames: TStringList;

function PatchLoadGAMESimpleL0(DummyEAX, DummyEDX: Integer; This: PDialogWindow; Flags: Integer; SectionName: PChar): Integer; register;
begin
  // Check if the requested section name is in our sortable list
  if SortableDialogSectionNames.IndexOf(SectionName) >= 0 then
    // If it is sortable, set the sort flag
    Flags := Flags or CIV2_DLG_SORTEDLISTBOX;
  // Call the original dialog loading function with modified flags
  Result := Civ2.Dlg_LoadSimple(This, 'GAME', SectionName, 0, Flags);
end;

{ TUiaPatchDlg }

procedure TUiaPatchDlg.Attach(HProcess: Cardinal);
begin
  // Initialize the list of sortable dialog section names
  SortableDialogSectionNames := TStringList.Create();
  SortableDialogSectionNames.Sorted := True; // for efficient lookups
  SortableDialogSectionNames.Add('AIRLIFTSELECT');
  // Intercept creating simple dialogs
  WriteMemory(HProcess, $004037CE, [OP_JMP], @PatchLoadGAMESimpleL0);
end;

initialization
  TUiaPatchDlg.RegisterMe();

end.


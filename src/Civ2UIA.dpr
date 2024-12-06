library Civ2UIA;

{$R 'Civ2UIA_GIFS.res' 'Civ2UIA_GIFS.rc'}
{%File 'Civ2ProcDeclF.inc'}
{%File 'Civ2ProcImplF.inc'}

uses
  Windows,
  Civ2Types in 'Civ2Types.pas',
  Civ2Proc in 'Civ2Proc.pas',
  Civ2UIA_CanvasEx in 'Civ2UIA_CanvasEx.pas',
  Civ2UIA_FormAbout in 'Civ2UIA_FormAbout.pas' {FormAbout},
  Civ2UIA_FormConsole in 'Civ2UIA_FormConsole.pas' {FormConsole},
  Civ2UIA_FormSettings in 'Civ2UIA_FormSettings.pas' {FormSettings},
  Civ2UIA_FormStrings in 'Civ2UIA_FormStrings.pas' {FormStrings},
  Civ2UIA_FormTest in 'Civ2UIA_FormTest.pas' {FormTest},
  Civ2UIA_Hooks in 'Civ2UIA_Hooks.pas',
  Civ2UIA_MapMessage in 'Civ2UIA_MapMessage.pas',
  Civ2UIA_MapMessages in 'Civ2UIA_MapMessages.pas',
  Civ2UIA_MapOverlay in 'Civ2UIA_MapOverlay.pas',
  Civ2UIA_MapOverlayModule in 'Civ2UIA_MapOverlayModule.pas',
  Civ2UIA_Options in 'Civ2UIA_Options.pas',
  Civ2UIA_PathLine in 'Civ2UIA_PathLine.pas',
  Civ2UIA_Proc in 'Civ2UIA_Proc.pas',
  Civ2UIA_QuickInfo in 'Civ2UIA_QuickInfo.pas',
  Civ2UIA_SortedAbstractList in 'Civ2UIA_SortedAbstractList.pas',
  Civ2UIA_SortedCitiesList in 'Civ2UIA_SortedCitiesList.pas',
  Civ2UIA_SortedUnitsList in 'Civ2UIA_SortedUnitsList.pas',
  Civ2UIA_Types in 'Civ2UIA_Types.pas',
  UiaMain in 'UiaMain.pas',
  UiaPatch in 'Patches\UiaPatch.pas',
  UiaPatch64Bit in 'Patches\UiaPatch64Bit.pas',
  UiaPatchAI in 'Patches\UiaPatchAI.pas',
  UiaPatchArrangeWindows in 'Patches\UiaPatchArrangeWindows.pas',
  UiaPatchAttitudeAdvisor in 'Patches\UiaPatchAttitudeAdvisor.pas',
  UiaPatchCDAudio in 'Patches\UiaPatchCDAudio.pas',
  UiaPatchCDCheck in 'Patches\UiaPatchCDCheck.pas',
  UiaPatchCityStatusAdvisor in 'Patches\UiaPatchCityStatusAdvisor.pas',
  UiaPatchCityView in 'Patches\UiaPatchCityView.pas',
  UiaPatchCityWindow in 'Patches\UiaPatchCityWindow.pas',
  UiaPatchColorCorrection in 'Patches\UiaPatchColorCorrection.pas',
  UiaPatchCommon in 'Patches\UiaPatchCommon.pas',
  UiaPatchCPUUsage in 'Patches\UiaPatchCPUUsage.pas',
  UiaPatchDllGif in 'Patches\UiaPatchDllGif.pas',
  UiaPatchDrawUnit in 'Patches\UiaPatchDrawUnit.pas',
  UiaPatchLimits in 'Patches\UiaPatchLimits.pas',
  UiaPatchMapWindow in 'Patches\UiaPatchMapWindow.pas',
  UiaPatchMenu in 'Patches\UiaPatchMenu.pas',
  UiaPatchMultiplayer in 'Patches\UiaPatchMultiplayer.pas',
  UiaPatchResizableWindows in 'Patches\UiaPatchResizableWindows.pas',
  UiaPatchScienceAdvisor in 'Patches\UiaPatchScienceAdvisor.pas',
  UiaPatchSideBar in 'Patches\UiaPatchSideBar.pas',
  UiaPatchSuppressPopup in 'Patches\UiaPatchSuppressPopup.pas',
  UiaPatchTaxWindow in 'Patches\UiaPatchTaxWindow.pas',
  UiaPatchTests in 'Patches\UiaPatchTests.pas',
  UiaPatchTimers in 'Patches\UiaPatchTimers.pas',
  UiaPatchTradeAdvisor in 'Patches\UiaPatchTradeAdvisor.pas',
  UiaPatchUnits in 'Patches\UiaPatchUnits.pas',
  UiaPatchUnitsLimit in 'Patches\UiaPatchUnitsLimit.pas',
  UiaPatchUnitsListPopup in 'Patches\UiaPatchUnitsListPopup.pas',
  UiaSettings in 'UiaSettings.pas',
  Tests in 'Tests.pas',
  Civ2UIA_SnowFlakes in 'Civ2UIA_SnowFlakes.pas';

{$R *.res}

procedure DllMain(Reason: Integer);
var
  HProcess: Cardinal;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        HProcess := OpenProcess(PROCESS_ALL_ACCESS, False, GetCurrentProcessId());
        Uia.AttachPatches(HProcess);
        CloseHandle(HProcess);
        SendMessageToLoader(0, 0);
      end;
    DLL_PROCESS_DETACH:
      ;
  end;
end;

begin
  DllProc := @DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.

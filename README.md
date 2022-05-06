# Civilization II User Interface Additions

## Description
This launcher will add some enhancements to Sid Meier's Civilization II: Multiplayer Gold Edition without modifying game executable.

## Features added
1. Mouse wheel and middle button support:
   - Scroll lists, change city specialists, change taxes
   - Ctrl + wheel - zoom map, Ctrl + middle button - normal zoom level
   - Middle button click on map - center map on that spot
   - Middle button drag map - panning

2. Scrollbar was added to Activate Unit popup dialog with more than 9 units in stack. Now you can choose any unit in stack beyond limit of 9.  
![Screenshot](Screenshots/UnitsPopupListWithScrollbar.png?raw=true "Screenshot")

3. For Settlers and Engineers internal work counter is shown over the unit sprite. This means that you can see how much work is exactly accumulated in unit. This and previous feature are very useful for rush terraforming.  
![Screenshot](Screenshots/EngineersCounter.png?raw=true "Screenshot")  
For more information about how this counter works see links:  
https://forums.civfanatics.com/threads/90129/  
https://apolyton.net/forum/civiliza...ilization-ii/31110-info-settlers-engineers-gl

4. Click-bounds of specialists sprites corrected in city screen. In the original game, if you click as it seems almost to the center of the sprite, then the adjacent one on the right changes. This is especially noticeable in large cities.

5.  Game turn added to the status sidebar.  
![Screenshot](Screenshots/GameTurn.png?raw=true "Screenshot")  
This is useful for making a decision about the beginning of the revolution according to the rules of the Oedo years. Revolution starts when the number of the turn is a multiple of four.

6. Current research numbers are displayed in the Science Advisor for precise research control.  
![Screenshot](Screenshots/ScienceAdvisor.png?raw=true "Screenshot")

7. Correct CD audio tracks looping and displaying play progress.  
![Screenshot](Screenshots/CDAudioTrackProgress.png?raw=true "Screenshot")

7. Game icon fix (visible in Alt+Tab popup).

8. Resetting city name prompts, when restarting a new game without closing program.

9. Show buildings even with zero maintenance cost in Trade Advisor.  
![Screenshot](Screenshots/TradeAdvisorZeroCost.png?raw=true "Screenshot")

10. Scrollbar for supported units in the city window. And a number of total supported units.  
![Screenshot](Screenshots/CityWindowSupport.png?raw=true "Screenshot")

11. 64-bit patch included. Exactly the same version as here:  
https://github.com/FoxAhead/Civilization-II-64-bit-Editbox-Patcher  
This means correct work of all input fields.

12. No-CD patch included (note that this disables intro/wonders movies and High Council movies)

13. Enable multiplayer for Windows 8, 10 (should also work on older OS).

14. Option for enabling Simultaneous moves in multiplayer. This is the same as writing 'Simultaneous=1' string to the CIV.INI file. With this option enabled, the multiplayer feature 'Humans Move Units at the Same Time' should be available when setting up a new multiplayer game.

15. Sort supported units list.  
![Screenshot](Screenshots/SortSupportedUnitsList.png?raw=true "Screenshot")  
Sotring order is: role 5 (Settlers, Engineers) is first, then attacking units ordered by domain (ground, air sea), descending by defense, descending by attack and then the rest by ID.

16. Reset Engineer's order after passing its work to coworker. If there is already a worker in the tile, then when adding a new one, he takes the work counter for himself, and the order of the previous one is additionally reset. Thus, there should be only one worker with an order in a cell. This simplifies rush terraforming, as it eliminates the need to wake up the unit each time. Refer to point 3 for more information.

17. Don't break unit movement on ZOC (zone of control). If unit has 'Go To' order, it doesn't stop when entering ZoC. Of course, the ZOC rule still applies. Originally, this behavior was applied only for role 7 units (Caravan, Freight). Be careful with this option, the unit will only stop when it breaks the ZOC rule or runs out of movement points. That is, for example, a unit directed at an enemy city will continuously try to enter it, attacking the defenders. Or attack an enemy unit suddenly emerging from the fog of war.

18. Reset units Wait flag after activating. Originally, units ordered with 'Wait' command recieves special Wait flag; when switching to the next unit, it is searched for as the closest one without a Wait flag; if nothing is found, then all these flags are cleared and searched again. With this option, all Wait flags are immediately cleared when a unit is manually activated, which should build a more convenient sequence for switching to nearby units.

19. Reset MoveIteration before start moving to prevent wrong warning. This fixes the incorrect 'Long Unit Move' warning that was caused by a non-resetting movement counter.

20. Set focus to city window when opened from Advisor and back to Advisor when closed. Originally, the focus stayed on the adviser window, so none of the city hotkeys worked, and pressing Esc closed the advisor instead of the city window.

Some experimental features that could change some original game rules or limitations without a guarantee of stability:
 - Change total units limit from default 2048. Don't use numbers greater than 32767. Saves with number of units greater than default should be loaded only with this patch.

Also some enhancements from [civ2patch project](https://github.com/vinceho/civ2patch) included:
 - reducing CPU usage when the application is idle

and patches that affect some game rules and limitations:
 - AI hostility
 - Retirement year
 - Population limit
 - Gold limit
 - Map size limit

All features can be switched in 'Options...' dialog.

## Requirements
Game version Multiplayer Gold Edition 5.4.0f (Patch 3) is supported only.

## Using
 1. Unzip files `Civ2UIALauncher.exe` and `Civ2UIA.dll` to game's folder
 2. Run `Civ2UIALauncher.exe`
 3. Click 'Play'

The launcher will search for `CIV2.EXE` and `Civ2UIA.dll` in its current folder and try to set all paths 
automatically.
You can create shortcut to start game immediately. All selected paths are saved in shortcut.

[Download](https://github.com/FoxAhead/Civ2-UI-Additions/releases)

[CivFanatics topic](https://forums.civfanatics.com/threads/623515/)

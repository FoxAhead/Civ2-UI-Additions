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

8. Game icon fix (visible in Alt+Tab popup).

9. Resetting city name prompts, when restarting a new game without closing program.

10. Show buildings even with zero maintenance cost in Trade Advisor.  
![Screenshot](Screenshots/TradeAdvisorZeroCost.png?raw=true "Screenshot")

11. Scrollbar for supported units in the city window. And a number of total supported units.  
![Screenshot](Screenshots/CityWindowSupport.png?raw=true "Screenshot")

12. 64-bit patch included. Exactly the same version as here:  
https://github.com/FoxAhead/Civilization-II-64-bit-Editbox-Patcher  
This means correct work of all input fields.

13. No-CD patch included (note that this disables intro/wonders movies and High Council movies)

14. Enable multiplayer for Windows 8, 10 (should also work on older OS).

15. Option for enabling Simultaneous moves in multiplayer. This is the same as writing 'Simultaneous=1' string to the CIV.INI file. With this option enabled, the multiplayer feature 'Humans Move Units at the Same Time' should be available when setting up a new multiplayer game.

16. Sort supported units list.  
![Screenshot](Screenshots/SortSupportedUnitsList.png?raw=true "Screenshot")  
Sorting order is: role 5 (Settlers, Engineers) is first, then attacking units ordered by domain (ground, air sea), descending by defense, descending by attack and then the rest by ID.

17. Reset Engineer's order after passing its work to coworker. If there is already a worker in the tile, then when adding a new one, he takes the work counter for himself, and the order of the previous one is additionally reset. Thus, there should be only one worker with an order in a cell. This simplifies rush terraforming, as it eliminates the need to wake up the unit each time. Refer to point 3 for more information.

18. Don't break unit movement on ZOC (zone of control). If unit has 'Go To' order, it doesn't stop when entering ZOC. Of course, the ZOC rule still applies. Originally, this behavior was applied only for role 7 units (Caravan, Freight). Be careful with this option, the unit will only stop when it breaks the ZOC rule or runs out of movement points. That is, for example, a unit directed at an enemy city will continuously try to enter it, attacking the defenders. Or attack an enemy unit suddenly emerging from the fog of war.

19. Tweak units rotation algorithm. Originally, units ordered with 'Wait' command receives special Wait flag; when switching to the next unit, it is searched for as the closest one without a Wait flag; if nothing is found, then all these flags are cleared and searched again. With this option, when manually activating an unit it clears the flag for all units of this stack, and vice versa sets it for all the rest. Also store activation position for later switching to nearby units. All this should build alternative convenient sequence for units rotation.

20. Reset MoveIteration before start moving to prevent wrong warning. This fixes the incorrect 'Long Unit Move' warning that was caused by a non-resetting movement counter.

21. Set focus to City window when opened from Advisor and back to Advisor when closed. Originally, the focus stayed on the Advisor window, so none of the City hotkeys worked, and pressing Esc closed the Advisor instead of the City window.

22. Celebrating city in yellow color instead of white in Attitude Advisor (F4). So it's more noticeable now. And food surplus/shortage icon if city has it  
![Screenshot](Screenshots/AttitudeAdvisorCelebratingYellow.png?raw=true "Screenshot")

23. Indicating attitude in the city window. Texts below citizen sprites are colored as in Attitude Advisor. This helps to immediately see the effect of the used specialists.  
![Screenshot](Screenshots/CityWindowColorAttitude.png?raw=true "Screenshot")

24. Radio buttons hotkeys. Can speed up the selection of options using the keyboard.  
![Screenshot](Screenshots/RadioButtonsHotkeys.png?raw=true "Screenshot")

25. Quickinfo tooltips. Hover mouse over the city or units and hold Ctrl key.  
![Screenshot](Screenshots/QuickinfoTooltip.png?raw=true "Screenshot")

26. Made most advisors and lists vertically resizable.  
![Screenshot](Screenshots/ResizableLists.png?raw=true "Screenshot")

27. Advisors caption area increased to make it easier to move windows around.

28. Better scrolling in Units List Popup: no flickering, adjusting scrollbar PageSize, keys navigation.

29. Added Cancel button to city Change Production dialog - Esc is now Cancel.

30. Added shields cost and maintenance in the city Change Production list.  
![Screenshot](Screenshots/CityChangeProductionShieldsAndCancel.png?raw=true "Screenshot")

31. Enhanced City Status advisor. Added total cities number and more icons. Cities can be sorted by size, name, food, shields, trade or production type. Clicking on production item directly will bring up the change production dialog.  
![Screenshot](Screenshots/CityStatusAdvisorSortingAndTotal.png?raw=true "Screenshot")

32. Mass change specialists in City window. Hover mouse over specialist, hold Shift key and scroll mouse wheel - this changes all specialists at once. Shift-clicking on specialist change others to the same one.

33. Suppress simple GAME.TXT popups. The list of popup names could be set in the UIA Settings (`Menu` - `UI Additions` - `Settings...` - `List...`). These popups will be shown in the map overlay instead, eliminating the annoying need to click 'OK' button.  
![Screenshot](Screenshots/SuppressSimplePopups.png?raw=true "Screenshot")

34. Include fix for `mk.dll` (`229.gif`, `250.gif`) and `pv.dll` (`105.gif`). As here:  
https://forums.civfanatics.com/resources/corrected-dlls-for-mge.24259/
    > restoring original Louis XIV and Joan of Arc leader portraits that were accidentally overwritten with Alexander and Hippolyta, and the furthest Throne Room wall that was overwritten with the second level.

    This fix is applied automatically based on GIF size comparisons. If `mk.dll` and `pv.dll` are modded, the fix will not be applied.

35. Color correction. If the game seems too dull or too bright for you, then this can be corrected without editing the GIF palettes. This and some other options can be set in `Menu` - `UI Additions` - `Settings...`.  
![Screenshot](Screenshots/UIASettings.png?raw=true "Screenshot")

36. Mass move units of the same type with Shift+RightClick. With unit activated hold Shift and Right-Click on the destination square. All units of the same type capable of moving (with move points, not fortified, not on sentry etc.) will be ordered to move.

37. Added gold coins to the Foreign Minister.

38. Two new View-menu items: `Arrange Windows S` and `Arrange Windows L`. They differ in slightly smaller and larger dimensions of the side panel compared to the standard option `Arrange Windows`.

39. PathLines for city trade routes and unit movement.  
![Screenshot](Screenshots/PathLineCity.png?raw=true "PathLineCity")
![Screenshot](Screenshots/PathLineUnit.png?raw=true "PathLineUnit")  
With city selected (right-click on it to place blinking white cursor) and Shift pressed moving mouse around will draw the path along which qualified road or railroad should be built to get permanent trade bonus. Moving mouse over this same city will draw all (up to three) existing trade routes. More details about qualified roads here:  
https://apolyton.net/forum/miscellaneous/archives/civ2-strategy-archive-aa/104062-trade-roads-%C2%96-determination-of-the-bonus-road-and-railroad-connection  
With the active unit selected and Shift pressed, moving the mouse will draw a predictable path based on your knowledge of the world map (existing units and terrain improvements). That is, when drawing a path, hidden foreign units, cities or roads are not taken into account.

40. Fix dye-copper demand bug. Due to uninitialized variable of number of roads there was very high demand quotients for dye and copper. More info on How Supply and Demand Lists Are Determine:  
https://apolyton.net/forum/civilization-series/civilization-i-and-civilization-ii/79947-how-supply-and-demand-lists-are-determined

41. Better grayed sprites for units on sentry. Instead of a simple gray silhouette, the unit is displayed in gray halftones, which helps to better recognize the type of unit.

42. Key `U` now also loads (sets on Sentry) all ground units in stack. Pressing `U` when there are no units on guard on the stack puts all ground units on that stack back on guard.

43. New game default map zoom 1:1. Now, when starting a new game, the map zoom is set to 1:1 (level 0), regardless of the screen width (previously, if the screen width was more than 1000 pixels, the zoom was set to level 2).

44. Finally fixed AI attitude calculation. Due to the uninitialized variable, every turn the attitude of the AI changed to the minimum, which made the AI very aggressive towards the player. This bug turned out to be so obvious that it was decided to completely remove the option to enable it. This bug is fixed by default without any options.
Unlike the previous version of the patch, which originated somewhere in the deep history of this forum, and which completely cut off the change in the attitude, now the calculation of the attitude should be performed as it was intended by the algorithm.

Some experimental features that could change some original game rules or limitations without a guarantee of stability:
 - Change total units limit from default 2048. Don't use numbers greater than 32767. Saves with number of units greater than default should be loaded only with this patch.

Also some enhancements from [civ2patch project](https://github.com/vinceho/civ2patch) included:
 - reducing CPU usage when the application is idle

and patches that affect some game rules and limitations:
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

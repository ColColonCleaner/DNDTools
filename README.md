# DND Tools for Tabletop Simulator
### Tools I've created/modified to make playing 5e DND (Fifth Edition Dungeons & Dragons) better for my group.

+ Mini injection with health bars, initiative tracking, 5e status effects, automatic resizing, and movement measured with DND rules.
+ Wall spawner with adjustable color, transparency, and height. Can also spawn floors and blocks to cover table areas.
+ Tabletop grid management with calibration to maps and saving to OneWorld.
+ Automatically resizing AOE markers and flight platforms.
+ Dice roller with save slots and modifiers, roll at advantage/disadvantage.

### Full table with all these tools available [HERE](https://steamcommunity.com/sharedfiles/filedetails/?id=2455649013) 
<img src="https://i.imgur.com/NQHSpI0.jpg" width="200">

# DND Mini Injector
<img src="https://i.imgur.com/83uMYlZ.jpg" width="500">

### Latest Version: 4.7.6
+ **Injection.** 
  + Place a mini on the top of this panel to inject it, flip the panel over and place an injected mini on it to remove injection.
  + Removing injection does not remove saved settings for that mini.
  + The asset bundle from [Conditions & Ruler for D&D 5e](https://steamcommunity.com/sharedfiles/filedetails/?id=2051577172) can also be injected. Access to the status effects is available by clicking the left side of UI Bars. Note, this asset bundle can take a second or two to process when it's injected, so it can make loading save games feel laggy for a few seconds. I'll work on improving this if possible.
+ **Options.**
  + Click the center of a mini's UI to show/hide the settings panel. Currently you can only interact with the front of UI ; there is a feature I'm trying to have added so the UI can be double-sided, please upvote this if you want that to happen: [Backface culling for XML UI](https://tabletopsimulator.nolt.io/11)
  + Menu options shown in red are enabled, white are disabled.
  + Settings set for the minis are synced between states if the mini has multiple.
  + Injected UI has 3 bars for information in red/blue/yellow. Red is used for health, the other two can be used for whatever suits you. Click the **right** side of the bars to show/hide bar adjustment buttons. Bars for PC minis are visible to everyone, and global visibility for NPC minis is optional.
  + Injected UI can be rotated and moved up/down to match your mini. There are 'UI Height UP', 'UI Height DOWN', and 'UI Rotate 90' shortcuts in the right-click menu for quick adjustment, with fine adjustment available in the settings panel.
  + Minis can be stabilized so that they don't fall over when set down.
  + PC minis are always visible through fog of war.
  + NPC minis can be hidden from players via the right click menu.
  + If OneWorld is available on the table it will be automatically initialized shortly after the mini injector loads. This can be disabled in the right-click menu by turning off 'Auto-OneWorld'.
+ **Movement.**
  + When an injected mini is picked up a token 1 square wide will spawn underneath facing the player. That token shows distance with DND rules in 5 foot increments.
  + All distances in these tools are with reference to the TTS grid. Modifying that grid will affect the calculated distances.
  + Alternate diagonal measurement (1.5x) is available and can be toggled either on the injector or on the minis themselves.
  + Metric mode can be toggled on the injector or on the minis themselves.
  + Hex grids are supported by the mini injector.
+ **Automatic Resizing.**
  + Minis can be calibrated to grid size with the right-click menu. Size the mini to match the grid, then calibrate.
  + Whenever the measurement tool calibrates the grid, the mini spawns, or the mini exits a bag, it will be automatically resized to match the grid.
  + After manually modifying the size of the mini or the grid you can use the 'Reset Scale' option in the mini's right-click menu to make the mini match the grid again.
  + For automatic resizing to work in all scenarios the injector must be present on the table at all times.
+ **Colors/Highlighting.**
  + Highlights can be selected in mini's settings panel, one is available for every player color.
  + For PCs in the initiative list their highlight takes precedance, then mini coloring.
  + For NPCs they are always white regardless of highlight/coloring.
+ **Initiative.**
  + Minis can either roll initiative automatically with 'Initiative Mod' or enter it manually in 'Initiative Value' if rolling is disabled. 'Initiative Value' resets to 100 each time initiative ends.
  + By default initiative minis must be in the center of the table, over the map zone. The OneWorld map zone bounds are used for this. If OneWorld is not available the default 'Custom Rectangle' table map bounds are used. This feature can be toggled with 'Init Table Only' in the right-click menu.
  + Initiative Mod is used to break ties, followed by mini name. This isn't *fully* accurate to 5e but it's close enough to the actual rule.
  + PCs are displayed on the injector's UI with a red bar, NPCs with a grey one.
  + Current initiative position is tracked with an arrow in the notes and a light grey highlight on the UI.
  + Move forward/backward in the initiative using the center arrow buttons, or with hotkeys available under Options->Game Keys.
  + Minis are pinged when their turn starts; this can be toggled in the right-click menu on the injector.
  + Health of minis are tracked and can be changed on the main UI.
  + The 'Enter' text field on each line will adjust health of the minis; a positive number will increase health, a negative number will decrease health. NPCs are automatically removed from initiative and their highlights disabled when they drop to 0 health.
  + Health status of untouched / healthy / feeling it / bloody / spicy / deaths door / dead, are tracked for each mini. This is only visible to the DM.
+ **Automatic Updates.**
  + Injected minis are automatically updated when they spawn, exit bags, or change states.
+ **Prefabs.**
  + The following workshop has all of the models already injected and calibrated to grid.
  + DO NOT OPEN THE WORKSHOP IN TTS, it will use about 12GB of your ram and take a very long time to load. Just use the 'Search' menu option to grab the models you need.
  + [DND 5e Miniatures w/Auto-Sizing and Measurement](https://steamcommunity.com/sharedfiles/filedetails/?id=2359564131)

# Floating Status Effects
<img src="https://i.imgur.com/e3S1Rnp.jpg" width="500">

+ These status effect tokens can be placed on top of injected minis.
+ They will disappear and spawn a floating button above the mini showing the status.
+ Clicking the floating status button removes the status.

# DND Measurement Tool
<img src="https://i.imgur.com/ncy9Hfm.jpg" width="500">

### Latest Version: 2.7.0

+ Pick up an object then pick up the measurement tool to display distance.
+ Measurement uses DND rules in 5 foot increments with either normal or alternate diagonal style.
+ It can calibrate the table's grid. Enable calibration in the right-click menu then set up a measurement. Enter how many feet the distance should be in that field and click away from it. Vertex mode will enable calibration between grid line intersections rather than grid square centers.
+ The tool will always face the player using it while it's active.
+ Color of the line is the color of the tool.
+ While the tool is active it will stay in place when dropped, even if off the table.
+ With alternate diagonal style enabled the calibration field only displays with fully vertical or horizontal measurements.
+ **Remember you can toggle displaying TTS grid lines in the options menu, or in the measurement tool's right-click menu.**

# Wall Spawner
<img src="https://i.imgur.com/jF3X3ek.jpg" width="500">

### Latest Version: 1.7

+ **[SHOWCASE VIDEO](https://www.youtube.com/watch?v=9xxFUDGJmbE)** 
+ **OFF:** Spawner is disabled.
+ **NORMAL:** Use the ping tool (Tab or F4) to place walls. Each wall needs a start and end ping.
+ **CHAIN:** In this mode it will continually place walls between pings.
+ **SQUARE:** In this mode it will spawn floors/ceilings over the TTS grid.
+ **BLOCK:** Give 3 pings, 2 for a side and 1 for width, and it will spawn a block covering that area.
+ Walls take color/transparency of the spawner.
+ Change wall height and offset with the input fields.

# Automatically Resizing AOE Markers
<img src="https://i.imgur.com/hh916S9.png" width="500">

+ Uses **[Saught's Spell AoE Hit Markers](https://steamcommunity.com/sharedfiles/filedetails/?id=2099498874)**
+ Includes: Cones, Circles, Cylinders, Domes, Cubes, and Flight Platforms.
+ The markers automatically resize to match the table's grid.
+ The markers are stabilized on drop, so they can be placed on slanted surfaces without tilting as a result.
+ Flight platforms must be locked in place for the hitboxes to work. 

# Click Roller Strip
<img src="https://i.imgur.com/EPYE26S.jpg" width="500">

### Latest Version: 3.0.2

+ Click buttons to spawn dice. Can spawn 4 rows of dice. Dice automatically resize as more are added.
+ Right-click buttons to remove types of dice in spawned order.
+ Roll at advantage/disadvantage. Rolling this way will take the highest/lowest result of all dice added to the tower.
+ Roll results are displayed in order added to the tower.
+ Dice and rolls are always visible, even inside hidden zones.

# Auto-Scale Injector
### Latest Version: 1.0.0

+ Place an object on the injector to lock its scale with reference to the TTS grid.
+ Flip the injector over and place an injected object onto it to remove the injection.
+ Injected objects are automatically stabilized so they don't fall over.

# OneWorld Fog-Of-War Spawner
### Latest Version: 2.2.0

+ Click the button on top and it will spawn a fog-of-war zone and animate it into place.
+ The zone tracks the currently deployed OneWorld map and will perfectly cover it.
+ If OneWorld is not available/deployed it will use the default 'Custom Rectangle' table bounds.
+ Use 'Hide OW Minimaps' to hide the map objects that float above the table in the corner from your players.
+ Use 'Hide OW Hub' to hide the OneWorld hub from your players.

# One World GridSaver Tokens
<img src="https://i.imgur.com/7sVcizo.jpg" width="500">

### Latest Version: 2.1.0

+ These GridSaver tokens allow you to save TTS grid settings with your OneWorld maps.
+ When you 'BUILD' the OneWorld map with a GridSaver in it, the grid state that was saved with the token will come back.
+ Injected miniatures will be automatically resized to match the new grid.
+ Use 'Enable Grid Proj.' to enable grid projection on the OneWorld table map.
+ All variables for the grid are saved/reloaded. Enabled, color, transparancy, size, offset, etc.

# OneWorld LineSaver Tokens
### Latest Version: 2.0.0

+ These LineSaver tokens allow you to save lines/drawings with your OneWorld maps.
+ It will save all global drawn lines in the main map zone of the table. The area covered by the current OneWorld map, or the default 'Custom Rectangle' zone if OneWorld is not available.
+ Instructions are provided on the tokens themselves.

# 5e Fallout Armor Calculator
<img src="https://i.imgur.com/QHRVoBZ.jpg" width="500">

+ [Wiki for 5e Fallout](http://5efallout.wikidot.com/)
+ Running a campain in the world of New Vegas at the moment.
+ The conversion 5e Fallout uses a custom armor system. This calculator automates that.
+ [Wiki for 5e Fallout](http://5efallout.wikidot.com/)
+ Power armor is not included yet.

 **Code credit to the following workshops; their work has been built on for these tools:** 
[Centimeter Ruler](https://steamcommunity.com/sharedfiles/filedetails/?id=2063724696) /
[Self Measuring Movement Scripted Bases](https://steamcommunity.com/sharedfiles/filedetails/?id=2069900392) /
[HP Bar Writer](https://steamcommunity.com/sharedfiles/filedetails/?id=1403813124) /
[Condition (and spell) Tokens DnD 5e](https://steamcommunity.com/sharedfiles/filedetails/?id=2227786087) /
[Object Stabilizers](https://steamcommunity.com/sharedfiles/filedetails/?id=2359564131) /
[Miniature HUD Utility](https://steamcommunity.com/sharedfiles/filedetails/?id=1694376433) /
[Improved Dice Roller](https://steamcommunity.com/sharedfiles/filedetails/?id=2134616469) /
[Click Roller Strip](https://steamcommunity.com/sharedfiles/filedetails/?id=1092390834) /
[Saught's Spell AoE Hit Markers](https://steamcommunity.com/sharedfiles/filedetails/?id=2099498874)

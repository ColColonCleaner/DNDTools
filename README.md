# DND Tools for Tabletop Simulator
### Tools I've created/modified to make playing 5e DND (Fifth Edition Dungeons & Dragons) better for my group.

+ Mini injection with health bars, initiative tracking, 5e status effects, automatic resizing, and movement measured with DND rules.
+ Wall spawner with adjustable color, transparency, and height.
+ Tabletop grid management with calibration to maps and saving to OneWorld.
+ Dice roller with save slots and modifiers, roll at advantage/disadvantage.

 **Code credit to the following workshops; their work has been built on for these tools:** 
[Centimeter Ruler](https://steamcommunity.com/sharedfiles/filedetails/?id=2063724696) /
[Self Measuring Movement Scripted Bases](https://steamcommunity.com/sharedfiles/filedetails/?id=2069900392) /
[HP Bar Writer](https://steamcommunity.com/sharedfiles/filedetails/?id=1403813124) /
[Condition (and spell) Tokens DnD 5e](https://steamcommunity.com/sharedfiles/filedetails/?id=2227786087) /
[Object Stabilizers](https://steamcommunity.com/sharedfiles/filedetails/?id=2359564131) /
[Miniature HUD Utility](https://steamcommunity.com/sharedfiles/filedetails/?id=1694376433) /
[Improved Dice Roller](https://steamcommunity.com/sharedfiles/filedetails/?id=2134616469) /
[Click Roller Strip](https://steamcommunity.com/sharedfiles/filedetails/?id=1092390834)

The code for these tools is available [on Github.](https://github.com/ColColonCleaner/DNDTools)

![DND Mini Injector Image](https://i.imgur.com/83uMYlZ.jpg "DND Mini Injector")
# DND Mini Injector
### Latest Version: 4.5.11
+ **Injection.** 
  + Place a mini on the top of this panel to inject it, flip the panel over and place an injected mini on it to remove injection.
  + Removing injection does not remove saved settings for that mini.
+ **Options.**
  + Click the center of a mini's UI to show/hide the settings panel.
  + Menu options shown in red are enabled, white are disabled.
  + Settings set for the minis are synced between states if the mini has multiple.
  + Injected UI has 3 bars for information in red/blue/yellow. Red is used for health, the other two can be used for whatever suits you. Click the **right** side of the bars to show/hide bar adjustment buttons. Bars for PC minis are visible to everyone, and global visibility for NPC minis is optional.
  + Injected UI can be rotated and moved up/down to match your mini. There are 'UI Height UP' and 'UI Rotate 90' shortcuts in the right-click menu for quick adjustment, with fine adjustment available in the settings panel.
  + Minis can be stabilized so that they don't fall over when set down.
  + PC minis are always visible through fog of war.
+ **Movement.**
  + When an injected mini is picked up a token 1 square wide will spawn underneath facing the player. That token shows distance with DND rules in 5 foot increments.
  + All distances in these tools are with reference to the TTS square grid. Modifying that grid will affect the calculated distances.
  + Alternate diagonal measurement (1.5x) is available and can be toggled either on the injector or on the minis themselves.
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

![Floating Status Effects Image](https://i.imgur.com/e3S1Rnp.jpg "Floating Status Effects")
# Floating Status Effects

+ These status effect tokens can be placed on top of injected minis.
+ They will disappear and spawn a floating button above the mini showing the status.
+ Clicking the floating status button removes the status.

![DND Measurement Tool Image](https://i.imgur.com/ncy9Hfm.jpg "DND Measurement Tool")
# DND Measurement Tool
### Latest Version: 2.30

+ Measurement uses DND rules in 5 foot increments.
+ Diagonals on grids are the same distance as straight. Alternate diagonal movement coming soon.
+ It can calibrate the grid of the table with the current distance measured. To calibrate, **REPLACE the description with a calibration code.** Type a distance prefixed with 'c' into the description. i.e. c50 calibrates the current distance as 50 feet. The tool and the object it's connected to should be placed in the center of their respective squares.
+ The tool will always face the player using it while it's active.
+ Color of the line is the color of the tool.
+ While the tool is active it will stay in place when dropped, even if off the table.
+ **Remember you can toggle displaying TTS grid lines in the options menu.**

![Wall Spawner Image](https://i.imgur.com/9OEZSWC.jpg "Wall Spawner")
# Wall Spawner
### Latest Version: 1.7

+ **[SHOWCASE VIDEO](https://www.youtube.com/watch?v=9xxFUDGJmbE)** 
+ **OFF:** Spawner is disabled.
+ **NORMAL:** Use the ping tool (Tab or F4) to place walls. Each wall needs a start and end ping.
+ **CHAIN:** In this mode it will continually place walls between pings.
+ **SQUARE:** In this mode it will spawn floors/ceilings over the TTS grid.
+ **BLOCK:** Give 3 pings, 2 for a side and 1 for width, and it will spawn a block covering that area.
+ Walls take color/transparency of the spawner.
+ Change wall height and offset with the input fields.

![Click Roller Strip Image](https://i.imgur.com/EPYE26S.jpg "Click Roller Strip")
# Click Roller Strip
### Latest Version: 3.0.2

+ Click buttons to spawn dice. Can spawn 4 rows of dice. Dice automatically resize as more are added.
+ Right-click buttons to remove types of dice in spawned order.
+ Roll at advantage/disadvantage. Rolling this way will take the highest/lowest result of all dice added to the tower.
+ Roll results are displayed in order added to the tower.
+ Dice and rolls are always visible, even inside hidden zones.

![One World GridSaver Tokens Image](https://i.imgur.com/7sVcizo.jpg "One World GridSaver Tokens")
# One World GridSaver Tokens

+ These GridSaver tokens allow you to save TTS grid size/offset with your OneWorld maps.
+ When you 'BUILD' the OneWorld map with a GridSaver in it, the grid state that was saved with the token will come back.
+ Injected miniatures will be automatically resized to match the new grid.

![5e Fallout Armor Calculator Image](https://i.imgur.com/QHRVoBZ.jpg "5e Fallout Armor Calculator")
# 5e Fallout Armor Calculator

+ [Wiki for 5e Fallout](http://5efallout.wikidot.com/)
+ Running a campain in the world of New Vegas at the moment.
+ The conversion 5e Fallout uses a custom armor system. This calculator automates that.
+ Power armor is not included yet.

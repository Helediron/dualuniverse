# dualuniverse

2024: Added MyDU Linux installation and MyDU-Autostart systemd service scripts to autostart MyDU.


Old:

This is collection of scripts from DU Alpha. These were last time tested in Alpha 3.1, and some even earlier.

These scripts are not actively maintained, but a historic collection from dark times we don't (cannot) speak about.

Beta note: Right click a used programming board and select "remove dynamic properties" before reusing it.

## AntiGravityController

Manage antigravity generator with a "touchscreen". Poke the screen with your mouse, *not* with F.

- Control the antigravity generator through on-screen buttons.
- Enable/disable the generator. Show/hide antigravity HUD widget at the same time.
- Disabling requires three consequent clicks for safety.
- Lock to prevent misclicks. Autolocks after few minutes.
- Set base altitude with up/down buttons. At lower altitudes it adjusts at 100m steps. At higher altitude steps grow bigger.
- Pressing long time up/down increases adjustment rate progressively.
- Separate button to lower base altitude down ten meters for landing on mountains with AG.
- Shows few essential values important for AG: altitude, vertical speed and gravity.
- Has on-screen help and error messages.
- Checks that core, AG and screen are correctly linked

Installation instructions:

- Install ship elements, programming board and screen.
- Copy the whole JSON file content to clipboard, then right-click programming board, "Advanced, Paste Lua configuration from clipboard".
- Link programming board to screen, core and antigravity generator. The core and generator show a warning that event will be wiped. That is okay and answer "YES".
- Turn on screen and programming board

## FollowerPet

"The Moose". A simple follower pet which either follows you or wanders randomly in a small area spreading disorder. Press antigravity to switch mode. Extremely stupid being. It will try to hump your ship. Tweak with Lua parameters.


- The new version wants two telemeters/vboosters, one pointing forward (telefws) and one down (teledown).
- The pet has only one key input: Alt+G toggles between follow and wandering mode.

2020-10-27 new:

- Alt+J toggles the HUD visibility. There is also a Lua parameter for initial visibility.
- NQ changed antigravity key from Ctrl+G to Alt+G. Updated HUD accordingly.
- NQ added distance function to hover engines, so hover engines can be used to measure distances too.


Features:

- The pet keeps looking towards you. If it was moving, it stops and turns.
- When closer than 5 meters it freezes itself. Asimov's robot rule 1.
- When closer than 10 meters it idles. After awhile it sits down.
- When further than 10 meters away it moves towards the owner.
- When seeing an obstacle in front of itself it tries randomly to move around.
- The pet shows a small info widget about its state.

This is not a smart pet. It's the bare-bones minimum implemetation. Limitations:

- This WILL do stupid things and will continue until shut down or runs out of fuel
- The pet ignores vertical dimension.
- Having only one telemeter to see is very limiting.
- Collision avoidance is simplest possible. It randomly moves left/right/backwards/up.
- It shuts down if pitch or roll gets too big.

The "ship" requires:

- Hover engine, fuel tank, brakes, adjustors
- Four horizontal engines (forward, back, left, right). It might work even with just one pushing forward, but then it has absolutely no capability to go around obstacles.
- Remote controller
- Two telemeters or vboosters (don't need space fuel tank if used just as detectors)
Right-clicking/advanced/Edit Lua parameters has following options:

- showDebug prints debug lines to Lua chat tab
- gvDefaultFloatDistance is default height the pet floats from ground
- gvExtraLiftWhenMoving is an additional distance to ground on top of default when moving.
- gvWonderingArea is the approximate width of an area the pet wanders around randomly.
- gvWonderingTime is time spent reaching new spot before next random location.
- gvTooClose is distance to obstacle. When forward sensor tells something is closer, the pet starts an avoidance mode trying to get around it.
- gvRandomMode set to true if you want pet to start in wandering

## FuelDisplay

Shows fuel tank status on screen and/or HUD. Tweak with Lua parameters.

Features:

- The script gets fuel percentage and time left from tank, which gets adjusted according to player skills.
- Displayed names can be one of three: tanktype+size, element's name or link's name.
- Tanks can be sorted by size.
- When there is fuel left for only few minutes in a tank, the time left is shown orange/red.
- The script can show fuel display on one or two screens, one for pilot and second for engineer.
- The script can show the display on HUD for the player who activated it.

Parameters:

The script has configurable parameters. Change them by right-clicking the programming board, Actions for this element, Edit Lua parameters. Be careful with values. Incorrect values may break the script. Use only true or false .

- showDebug: should be kept false. If true, it writes some debug info to chat/notifications.
- useSlotName: If true then the name on display is the link's name. You need to edit the Lua script to be able to change them.
- useElementName: If true then the name on display is the one set by right-clicking a tank in build mode, Actions for this element, Rename element.
- Note: if both useSlotName and useElementName are false, then the name on display is <tank type>-<tank size>, e.g. "space-S". This is the default.
- sortBySize: if true, tanks are sorted by size. If false, display order is uncertain.
- displayHUD: if true, the tank display is also visible on game display for the player who started the programming board. The HUD display is only visible initially and then when fuel is actually consumed.

Instructions:

- Install in build mode a programming board and a screen.
- Link the screen to programming board. Link second display if needed.
- Link each fuel tank to programming board.
- Copy file content from attachment FuelDisplay-yyyymmdd.json content to clipboard.
- Right-click the programming board, Actions for this element, Paste Lua configuration from clipboard.
- Start the programming board!

If all goes well, the screen shows few seconds "Initializing", and the list of tanks. If HUD display is enabled then same list comes visible at the left edge of game display. The HUD display turns off after a while. It comes back when something actually starts consuming fuel.

## TiltScreen

A very old script using four telemeters to show how level the ground below is.

## DisplayTweak

Goddam ancient script which improved visibility of minimap on HUD. It's a sample of a simplest possible HUD UI. **This does not work any more because NQ isolated game UI from script UI**.

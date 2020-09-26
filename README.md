# dualuniverse

This is collection of scripts from DU Alpha. These were last time tested in Alpha 3.1, and some even earlier.

These scripts are not actively maintained, but a historic collection from dark times we don't (cannot) speak about.

## AntiGravityController

Manage antigravity generator with a "touchscreen". Poke the screen with your mouse, *not* with F.

Installation instructions:

- Install ship elements, programming board and screen.
- Copy the whole file content to clipboard, then right-click programming board, "Advanced, Paste Lua configuration from clipboard".
- Link programming board to screen, core and antigravity generator. The core and generator show a warning that event will be wiped. That is okay and answer "YES".
- Turn on screen and programming board

## FollowerPet

"The Moose". A simple follower pet which either follows you or wanders randomly in a small area spreading disorder. Press antigravity to switch mode. Extremely stupid being. It will try to hump your ship. Tweak with Lua parameters.

## FuelDisplay

Shows fuel tank status on screen and/or HUD. Tweak with Lua parameters.

## TiltScreen

A very old script using four telemeters to show how level the ground below is.

## DisplayTweak

Goddam ancient script which improved visibility of minimap on HUD. It's a sample of a simplest possible HUD UI. **This does not work any more because NQ isolated game UI from script UI**.

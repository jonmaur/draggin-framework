draggin-framework
=================
A framework for use with the [MOAI SDK](http://moaiforge.com/).

#Overview
The Draggin Framework is a collection of scripts to help with common game tasks. It is 
released under the MIT license. Draggin is only tested with MOAI 1.7 sdk release on
MoaiForge for Windows. It should work on other platforms but it hasn't been tested yet.
Draggin should work with most versions and hosts of MOAI.

##Display
This module helps you setup a display with a "virtual res" stretched across the screen
with black bars to help keep the original aspect ratio

##Debug Server
Simple server which accepts up to 4 telnet connections. Can send strings to the clients.
Executes lua code sent by the client.

##Font Manager
Just a simple font loader which helps with things like not loading the same font twice.

##Save System
Simple wrapper for the MOAI serialization saving functions. It adds support for a
default table.

##Signal Slots
Simple signal slot system.

##Finite State Machine
An FSM based off of [Jesse Warden's Corona Port](https://github.com/JesterXL/Lua-Corona-SDK-State-Machine) of [Cassio Souza’s ActionScript FSM.](https://github.com/cassiozen/AS3-State-Machine)

##Gamestate Manager
A setup for pushing, popping, and swapping gamestates in a gamestate stack.

##Sound Manager
Untz based sound wrapper. Adds signals for sound events. Adds the concept of sound "groups."
If Untz isn't available, everything still works, you just won't hear sound.

##Table Extention
Adds helpful functions you wish were in the standard table library but aren't. Like
deepcopy(), empty(), and print()

##TextBox
Adds dynamic shadows to text and other helpers like blink()

##TileMap
Helper for loading and rendering of TileMaps. Supports "no cracks" rendering using the
bleed technique. Also supports paralax scrolling.

##Physics
Helper for maintaining a Box2D physics world. Can add Draggin Sprites to the physics world.
Includes a [RUBE Editor](https://www.iforce2d.net/rube/) json loader, supporting almost all RUBE features.

#Tools
Draggin comes with tools to compile assets for use with Draggin. Tools are available for
compiling Sprites, TileMaps, and a simple almost useless Box2D compiler. The tools
are all written in Python 2.7 and are cross-platform.

##Sprite Compiler
Compiles a folder with animation sequences of png's into a Sprite complete with an
optimized Sprite Texture sheet. Frames are placed a few pixels apart and alpha edges are
bled out to prevent any of the transparent colour bleeding back into the frame when
rendering with filtering on.

##TileMap Compiler
Takes a big png of an entire map and chops it up into non-duplicated tiles and creates a
map. Also bleeds the edges of the tiles in the texture sheet so there won't be any cracks 
showing up later when rendering, even when scaled.

##Box2D Compiler
A rather super simple compiler which takes an svg file with a path and outputs that as
a path for use in MOAI's Box2D implementation. (Deprecated)

##Asset Processing Scripts
Draggin comes packaged with some ready to use scons scripts which gather Sprites, Tilemaps,
Audio Files, Font Files, Box2D svg's, and RUBE json files. The scons scripts then output the compiled
versions of the assets which are ready to be loaded by Draggin. The scripts only reprocess assets
if they have changed since the last time.

#Getting Started

##Base Requirements
* [MOAI SDK](http://moaiforge.com/) It doesn't have to be this version, you can probably use any MOAI.

##Tool Requirements
* [Python 2.7](https://www.python.org/)
* [Python Image Library](http://www.pythonware.com/products/pil/) or [Pillow](https://pypi.python.org/pypi/Pillow)

##Asset Processing Requirements
* All tool requirements
* [Scons 2.x.x](http://www.scons.org/)

##Samples Requirements
* All other requirements above
* Set the following OS environment variables:

	* MOAI_BIN=(path_to_moai_executable)
	* DRAGGIN_FRAMEWORK=(path_to_draggin-framework)

##Running Samples
* Navigate to a DRAGGIN_FRAMEWORK/samples/(sample)/ directory
* run the "processassets(.bat or .sh)" script
* run the "run(.bat or .sh)" script

##Recommended Editors
* [RUBE](https://www.iforce2d.net/rube/) Not free, but truely a really useful box2d editor! It's great for editing levels with a lot of physics.

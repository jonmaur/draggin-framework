Draggin Framework for MOAI

Overview
The Draggin Framework is a collection of scripts to help with common game tasks. It is
released under the MIT license. Officially Draggin is only tested with MOAI 1.5 stable branch
and the Windows, Linux, and Android Hosts. I see no reason why it wouldn't work with any
host, or even most versions of MOAI.

Display
This module helps you setup a display with a "virtual res" stretched across the screen
with black bars to help keep the original aspect ratio

Debug Server
Simple server which accepts telnet connections. Sends print outs to the client.
Executes lua code sent by the client.

Font Manager
Just a simple font loader which helps with things like not loading the same font twice.

Save System
Simple wrapper for the MOAI serialization saving functions. It adds support for a
default table.

Signal Slots
Simple signals.

Finite State Machine
An FSM based off of <name's> port of <name's> ActionScript FSM.

Gamestate Manager
A setup for pushing, popping, and swapping gamestates in a gamestate stack.

Sound Manager
Untz based sound wrapper. Adds signals for sound events. Adds the concept of sound "groups."
If Untz isn't available, everything still works, you just won't hear sound.

Table Extention
Adds helpful functions you wish were in the standard table library but aren't. Like
deepcopy(), empty(), and print()

TextBox
Adds dynamic shadows to text and other helpers like blink()

TileMap
Helper for loading and rendering of TileMaps. Supports "no cracks" rendering using the
bleed technique. Also supports paralax scrolling.



Tools
Draggin comes with tools to compile assets for use with Draggin. Tools are available for
compiling Sprites, TileMaps, and a simple almost useless Box2D compiler. The tools
are all written in Python 2.7 and are cross-platform.

Sprite Compiler
Compiles a folder with animation sequences of png's into a Sprite complete with an
optimized Sprite Texture sheet.

TileMap Compiler
Takes a big png of an entire map and chops it up into non-duplicated tiles and the
map. Also bleeds the edges of the tiles so there won't be any cracks showing up later
when rendering.

Box2D Compiler
A rather super simple compiler which takes an svg file with a path and outputs that as
a path for use in MOAI's Box2D implementation.



Asset Build Scripts
Draggin comes packaged with some ready to use scons scripts which gather Sprites, Tilemaps,
Audio Files, Font Files, and Box2D svg's. The scons scripts then output the compiled versions of the
assets which can be loaded by Draggin.



Getting Started

Base Requirements
- MOAI

Tool Requirements
- Python 2.7
- Python Image Library
- Scons (optional)


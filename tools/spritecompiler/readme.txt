How To use spriteCompiler.py

What you need:
- Python 2.7
- Python Image Library

Setup a sprite:
- Put all the .png's in a single folder, the folder name becomes the sprite's name
- The .png's should be named as such <animation name>_<frame number>.png
- The .png's work best if they are 32bit as they will be cropped when placed on the texture sheet
- The last frame is optionally the "reference point" if there is a single non-transparent pixel
  where the ref point should be
- All frames of an animation should be the same size, or the ref point won't work
- 32bit .png's are preferred

Compile the sprite:
- Drag the sprite folder on to the spriteCompiler.py
- 2 files are generated, <sprite>.lua and <sprite>.png in the parent folder of the sprite folder

Create a sprite (prop) in MOAI
- Make sure you're using the "Draggin Framework"

lua code:

-- load the sprite module
Sprite = require "draggin/sprite"

-- create a sprite
local player = Sprite.new("sprite name")

-- play an animation
player:playAnimation("animation name")

-- create a layer and put the sprite in it
local layer = MOAILayer2D.new()
layer:insertProp(player)

-- finally, make sure your layer is in the current MOAI render table


Notes:
- The sprite created is also a MOAIProp
- Feel free to add more table entries to the created Sprite

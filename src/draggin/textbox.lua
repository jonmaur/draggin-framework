--[[
Copyright (c) 2014 Jon Maur

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

----------------------------------------------------------------
-- TextBox

local FontManager = require "draggin/fontmanager"

local Display = require "draggin/display"
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight



local TextBox = {}

--- Create a TextBox instance.
-- A TextBox is an object which wraps up 2 MOAITextBox objects such that 1 is
-- normal text and the other is it's shadow. Basically if you don't want to
-- bake in a shadow, or you want a dynamic shadow, you can use this.
-- @param _strFont optional, the name of the font to use
-- @param _fontSize optional, the size of the font to use. More useful for ttf fonts.
-- @param _bShadow optional, should there be a shadow? Default yes.
-- @return the new TextBox instance
function TextBox.new(_strFont, _fontSize, _bShadow)

	if _bShadow == nil then
		_bShadow = true
	end

	local shadow = _bShadow
	local layer
	local partition
	local txt = {}

	local shadowColor = {0, 0, 0, 0.75}
	local styleShadow = MOAITextStyle.new()
	styleShadow:setColor(unpack(shadowColor))

	local normalColor = {1, 1, 1, 1}
	local styleNormal = MOAITextStyle.new()
	styleNormal:setColor(unpack(normalColor))


	local txtShadow = MOAITextBox.new()
	txtShadow:setStyle(styleShadow)

	local txtNormal = MOAITextBox.new()
	txtNormal:setStyle(styleNormal)

	local shadowOffsetX = 2
	local shadowOffsetY = 2

	local blinktimer

	--- Set the parent entity.
	-- Same as MOAITextBox:setParent()
	-- @param _parent any MOAI entity which can be a parent.
	function txt:setParent(_parent)
		txtShadow:setParent(_parent)
		txtNormal:setParent(_parent)
	end

	--- Sets the font.
	-- @param _font optional, the name of the font to use
	-- @param _size optional, the size of the font to use
	function txt:setFont(_font, _size)

		local font = FontManager.getFont(_font, _size)

		styleShadow:setFont(font)
		styleNormal:setFont(font)
	end

	--- Set the location of this instance.
	-- Same as MOAITextBox:setLoc()
	-- @param x the x position
	-- @param y the y position
	function txt:setLoc(x, y)

		txtShadow:setLoc(x + shadowOffsetX, y + shadowOffsetY)
		txtNormal:setLoc(x, y)
	end

	--- Seek to this location.
	-- Same as MOAITextBox:setLoc()
	-- @param x the x position
	-- @param y the y position
	-- @param _secs the number of seconds to take
	-- @param _ease the MOAIEaseType to use
	function txt:seekLoc(x, y, _secs, _ease)

		_ease = _ease or MOAIEaseType.SMOOTH

		txtShadow:seekLoc(x + shadowOffsetX, y + shadowOffsetY, _secs, _ease)
		return txtNormal:seekLoc(x, y, _secs, _ease)
	end

	--- Set the rectangle area to render text in.
	-- Same as MOAITextBox:setRect()
	-- @param x1 the x1 top left x position
	-- @param y1 the y1 top left y position
	-- @param x2 the x2 bottom right x position
	-- @param y2 the y2 bottom right y position
	function txt:setRect(x1, y1, x2, y2)

		txtShadow:setRect(x1, y1, x2, y2)
		txtNormal:setRect(x1, y1, x2, y2)
		txt:setLoc(txtNormal:getLoc())
	end

	--- Helper for setting up the position, area, and anchor point.
	-- Anchor point is normalized 0 to 1 such that 0 is anchored on the left of the rect
	-- and 1 is the right. This affects the rect's positioning.
	-- @param x the x position
	-- @param y the y position
	-- @param w the width of the rect
	-- @param h the height of the rect
	-- @param _anchorx a nomalized x anchor point
	function txt:setDimensions(x, y, w, h, _anchorx, _anchory)

		local x1 = -(w * _anchorx)
		local y1 = -(h * _anchory)

		local x2 = x1 + w
		local y2 = y1 + h

		txtShadow:setRect(x1, y1, x2, y2)
		txtNormal:setRect(x1, y1, x2, y2)
		txt:setLoc(x, y)
	end

	--- Set the alignment of this instance.
	-- Same as MOAITextBox:setAlignment()
	-- @param _halign the new horizontal alignment
	-- @param _valign optional, the new vertical alignment
	function txt:setAlignment(_halign, _valign)

		txtShadow:setAlignment(_halign, _valign)
		txtNormal:setAlignment(_halign, _valign)
	end

	--- Set the text of this instance.
	-- Same as MOAITextBox:setString()
	-- @param _str the text to display
	function txt:setString(_str)

		txtShadow:setString(_str)
		txtNormal:setString(_str)

		-- loop back for partition picking
		txtNormal.str = _str
	end

	--- Removes this TextBox from the layer.
	-- Also removes it from the partition.
	function txt:removeFromLayer()
		if layer ~= nil then
			-- remove text from the previous layer
			layer:removeProp(txtShadow)
		end
		if partition ~= nil then
			partition:removeProp(txtNormal)
		end

		layer = nil
		partition = nil
	end

	--- Insert this TextBox into a MOAILayer and/or MOAIPartition.
	-- Removes it from the current layer and partition
	-- @param _layer optional, the layer to insert this TextBox into
	-- @param _partition optional, the partition to insert this TextBox into
	function txt:insertIntoLayer(_layer, _partition)

		txt:removeFromLayer()

		layer = _layer

		partition = _partition or _layer

		if layer == nil then
			return
		end

		if shadow then
			layer:insertProp(txtShadow)
		end
		partition:insertProp(txtNormal)
	end

	--- Enable or disable the TextBox's shadow.
	-- @param _bEnable optional, true to enable the shadow, defaults to true
	function txt:enableShadow(_bEnable)
		if _bEnable == nil then
			_bEnable = true
		end

		shadow = _bEnable

		-- insert or remove the shadow text as needed
		if layer ~= nil then
			if shadow then
				layer:insertProp(txtShadow)
			else
				layer:removeProp(txtShadow)
			end
		end
	end

	--- Set the shadow's render offset.
	-- @param x the x shadow offset
	-- @param y the y shadow offset
	function txt:setShadowOffset(x, y)

		shadowOffsetX = x
		shadowOffsetY = y

		self:setLoc(txtNormal:getLoc())
	end

	--- Sets the text color.
	-- Not the shadow color
	-- @param r the red, or a table array with 4 numbers for red, green, blue, alpha
	-- @param g the green
	-- @param b the blue
	-- @param a the alpha
	function txt:setColor(r, g, b, a)

		if type(r) == "number" then
			styleNormal:setColor(r, g, b, a)
			normalColor = {r, g, b, a}
		elseif type(r) == "table" then
			styleNormal:setColor(unpack(r))
			normalColor = {unpack(r)}
		end
	end

	--- Sets the shadow color.
	-- Not the text color
	-- @param r the red,  or a table array with 4 numbers for red, green, blue, alpha
	-- @param g the green
	-- @param b the blue
	-- @param a the alpha
	function txt:setShadowColor(r, g, b, a)

		if type(r) == "number" then
			styleShadow:setColor(r, g, b, a)
			shadowColor = {r, g, b, a}
		elseif type(r) == "table" then
			styleShadow:setColor(unpack(r))
			shadowColor = {unpack(r)}
		end
	end

	--- Set the scale.
	-- Same as MOAITextBox:setScl()
	-- @param x the x scale
	-- @param y the y scale
	function txt:setScl(x, y)
		txtShadow:setScl(x, y)
		txtNormal:setScl(x, y)
	end

	--- Seek to this scale.
	-- Same as MOAITextBox:seekScl()
	-- @param x the target x scale
	-- @param y the target y scale
	-- @param _secs the number of seconds to reach the target scale
	-- @param _ease optional, the ease type to use, defaults to MOAIEaseType.SMOOTH
	-- @return the MOAIAction object of the normal text
	function txt:seekScl(x, y, _secs, _ease)

		_ease = _ease or MOAIEaseType.SMOOTH

		txtShadow:seekScl(x, y, _secs, _ease)
		return txtNormal:seekScl(x, y, _secs, _ease)
	end

	--- Set the text reveal speed.
	-- Same as MOAITextBox:setSpeed(), does it's thing when you call spool.
	-- @param _speed the speed
	function txt:setSpeed(_speed)
		txtShadow:setSpeed(_speed)
		txtNormal:setSpeed(_speed)
	end

	--- Set the text reveal ammount.
	-- Same as MOAITextBox:setReveal(), does it's thing when you call spool.
	-- @param _numchars the number of chars to reveal at a time
	function txt:setReveal(_numchars)
		txtShadow:setReveal(_numchars)
		txtNormal:setReveal(_numchars)
	end

	--- Check to see if a MOAIProp is equal to the text or it's shadow.
	-- Usefull when checking if this TextBox was touched/clicked
	-- @param _prop the MOAIProp to check against the text and shadow
	-- @return true if the _prop is the same as the text or it's shadow
	function txt:isProp(_prop)
		return _prop == txtNormal or _prop == txtShadow
	end

	--- Spool the text.
	-- Same as MOAITextBox:spool()
	-- TODO: make the shadow spool action a child of the normal... I guess
	-- @return the MOAIAction object for the text's spool action
	function txt:spool()
		txtShadow:spool()
		return txtNormal:spool()
	end

	--- Stop blinking.
	function txt:stopBlink()
		if blinktimer then
			blinktimer:stop()
			blinktimer = nil
		end
	end

	--- Start Blinking.
	-- TODO: Blink action?
	-- @param _secs the blink interval in seconds
	function txt:blink(_secs)
		_secs = _secs or 1
		_secs = _secs / 2

		txt:stopBlink()
		blinktimer = MOAITimer.new()
		local flip = true
		blinktimer:setSpan(_secs)
		blinktimer:setMode(MOAITimer.LOOP)
		blinktimer:setListener(MOAITimer.EVENT_TIMER_LOOP, function()
			if flip then
				txtNormal:seekColor(normalColor[1], normalColor[2], normalColor[3], 0, _secs)
				txtShadow:seekColor(shadowColor[1], shadowColor[2], shadowColor[3], 0, _secs)
			else
				txtNormal:seekColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4], _secs)
				txtShadow:seekColor(shadowColor[1], shadowColor[2], shadowColor[3], shadowColor[4], _secs)
			end
			flip = not flip
		end)
		blinktimer:start()
	end

	--- Fade out the text.
	-- @param _secs the number of seconds to take to fade out
	function txt:fadeOut(_secs)
		_secs = _secs or 1

		txtNormal:seekColor(normalColor[1], normalColor[2], normalColor[3], 0, _secs)
		txtShadow:seekColor(shadowColor[1], shadowColor[2], shadowColor[3], 0, _secs)
	end

	--- Fade in the text.
	-- @param _secs the number of seconds to take to fade in
	function txt:fadeIn(_secs)
		_secs = _secs or 1

		txtNormal:seekColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4], _secs)
		txtShadow:seekColor(shadowColor[1], shadowColor[2], shadowColor[3], shadowColor[4], _secs)
	end

	--- Destroy this TextBox instance.
	-- Stops and clears the blinking. Removes from layer and partition.
	function txt:destroy()
		if blinktimer then
			blinktimer:stop()
			blinktimer = nil
		end
		txt:removeFromLayer()
	end

	txt:setFont(_strFont, _fontSize)

	-- This just makes sure the shadow shows up even if no one sets the location later
	txt:setLoc(0, 0)

	return txt
end

return TextBox

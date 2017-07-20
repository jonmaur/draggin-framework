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

-- local Draggin = require "draggin/draggin"
-- local signal = require "draggin/signal"

local Display = {}

-- resolution stuff
Display.screenWidth = -1
Display.screenHeight = -1

Display.windowWidth = -1
Display.windowHeight = -1

Display.virtualWidth = 320
Display.virtualHeight = 480

Display.viewport = MOAIViewport.new()
Display.guiViewport = MOAIViewport.new()

Display.modes = nil	-- on a PC Sledge host this will be a table of all the supported Display modes


--- Resets the viewports.
-- Used after the display mode changes.
local function resetViewports()

	local deviceWidth = MOAIEnvironment.horizontalResolution or Display.screenWidth
	local deviceHeight = MOAIEnvironment.verticalResolution or Display.screenHeight

	if not Display.fullscreen then
		deviceWidth = Display.screenWidth
		deviceHeight = Display.screenHeight
	end

	print("Device res", deviceWidth, deviceHeight)

	Display.screenOffsetX = 0
	Display.screenOffsetY = 0

	local gameAspect = Display.virtualHeight / Display.virtualWidth
	local realAspect = deviceHeight / deviceWidth

	if realAspect > gameAspect then
		Display.screenWidth = deviceWidth
		Display.screenHeight = deviceWidth * gameAspect
	else
		Display.screenWidth = deviceHeight / gameAspect
		Display.screenHeight = deviceHeight
	end

	if Display.screenWidth < deviceWidth then
		Display.screenOffsetX = ( deviceWidth - Display.screenWidth ) * 0.5
	end

	if Display.screenHeight < deviceHeight then
		Display.screenOffsetY = ( deviceHeight - Display.screenHeight ) * 0.5
	end

	print("resize Display offset", Display.screenOffsetX, Display.screenOffsetY)
	-- the "game" viewport
	Display.viewport:setSize(Display.screenOffsetX, Display.screenOffsetY, Display.screenOffsetX + Display.screenWidth, Display.screenOffsetY + Display.screenHeight)
	Display.viewport:setScale(Display.virtualWidth, Display.virtualHeight)
	Display.viewport:setOffset(-1, -1)

	-- the gui or "screen" viewport
	Display.guiViewport:setSize(Display.screenOffsetX, Display.screenOffsetY, Display.screenOffsetX + Display.screenWidth, Display.screenOffsetY + Display.screenHeight)
	Display.guiViewport:setScale(Display.virtualWidth, Display.virtualHeight)
	Display.guiViewport:setOffset(-1, -1)
end

--- Initialize the SDL host display.
-- The SDL host has support for fullscreen modes, set that up here.
local function initDisplaySDL()
	print("initDisplaySDL", Display.windowWidth, Display.windowHeight)
	-- we're on a PC
	-- if you don't open a window you'll get garbage!
	MOAISim.openWindow(Display.appTitle, Display.windowWidth/2, Display.windowHeight/2)

	-- gather all the Display info
	local cmode, dmode, allmodes = MOAIDisplaySDL.getCurrentMode()

	-- tables look like this:
	-- w
	-- h
	-- bpp
	-- refresh
	-- format

	local modes = {}

	print("Current Display Mode:")
	for k, v in pairs(cmode) do
		print(k, v)
	end
	print("Desktop Display Mode:")
	for k, v in pairs(dmode) do
		print(k, v)
	end

	-- grab some supported modes
	-- 16:9, 24bit, 60hz
	local aspect = 16/9
	print("modes:")
	for k, v in pairs(allmodes) do
		--print("mode", k, v)
		if type(v) == "table" then
			if (v.bpp == 24 and v.refresh == 60) or (v.bpp == dmode.bpp and v.refresh == dmode.refresh) then
				for kk, vv in pairs(v) do
					print(kk, vv)
				end
				local newmode = {}
				newmode.w = v.w
				newmode.h = v.h
				newmode.bpp = v.bpp
				newmode.refresh = v.refresh
				modes[#modes+1] = newmode
			end
		end
	end

	Display.modes = modes

	Display.screenWidth = dmode.w
	Display.screenHeight = dmode.h

	Display.dmode = dmode

	-- make up some window modes
	local windowmodes = {}
	local i = 1
	local scale = 1

	if (Display.virtualWidth <= Display.screenWidth) and (Display.virtualHeight <= Display.screenHeight) then
		-- virtual is smaller than window, scale up
		while (Display.virtualWidth * scale <= Display.screenWidth) and Display.virtualHeight * scale <= Display.screenHeight do
			windowmodes[i] = {w = Display.virtualWidth * scale, h = Display.virtualHeight * scale, bpp = dmode.bpp, refresh = dmode.refresh}
			i = i + 1
			scale = scale + 0.5
		end
	else
		-- virtual is bigger than window, scale down
		while scale > 0 do
			windowmodes[i] = {w = Display.virtualWidth * scale, h = Display.virtualHeight * scale, bpp = dmode.bpp, refresh = dmode.refresh}
			i = i + 1
			scale = scale - 0.25
		end
	end

	Display.windowmodes = windowmodes

	-- Forcing a windowed display mode first, otherwise switching to a windowed mode later is missing the window titlebar
	MOAIDisplaySDL.setMode(Display.windowWidth/2, Display.windowHeight/2, dmode.refresh, dmode.bpp, 0)
	-- MOAIDisplaySDL.setMode(modes[2].w, modes[2].h, modes[2].refresh, modes[2].bpp, 1)
	Display.screenWidth = Display.windowWidth
	Display.screenHeight = Display.windowHeight
end

--- Initialize the Display.
-- Properly sets up the display no matter what kind of device it's running on.
-- @param _appTitle The text that appears on the Window's title bar
-- @param _virtualWidth The desired game resolution width
-- @param _virtualHeight The desired game resolution height
-- @param _screenWidth The desired Window or Fullscreen resolution width (only makes sense on a PC host)
-- @param _screenHeight The desired Window or Fullscreen resolution height (only makes sense on a PC host)
-- @param _bFullscreen boolean true if you want fullscreen (only makes sense on a Sledge host)
function Display:init(_appTitle, _virtualWidth, _virtualHeight, _screenWidth, _screenHeight, _bFullscreen)

	print("Display:init()")
	Display.appTitle = _appTitle
	Display.virtualWidth = _virtualWidth or Display.virtualWidth
	Display.virtualHeight = _virtualHeight or Display.virtualHeight

	Display.screenWidth = _screenWidth or Display.virtualWidth
	Display.screenHeight = _screenHeight or Display.virtualHeight

	Display.windowWidth = Display.screenWidth
	Display.windowHeight = Display.screenHeight

	if _bFullscreen == nil then
		_bFullscreen = false
	end
	Display.fullscreen = _bFullscreen

	Display.screenOffsetX = 0
	Display.screenOffsetY = 0

	print("Virtual res", Display.virtualWidth, Display.virtualHeight)
	print("Requested screen res", Display.screenWidth, Display.screenHeight, Display.fullscreen)
	
	if MOAIDisplaySDL then
		initDisplaySDL()
		local dmode = Display:findDisplayMode(_screenWidth, _screenHeight, _bFullscreen)
		Display:setDisplayMode(dmode, _bFullscreen)
	end

	MOAISim.setStep(1 / 60) -- run sim at 60hz
	MOAISim.clearLoopFlags()
	MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED) -- one update per timer event; no sim throttling

	resetViewports()

	if SledgeInputWrapper then
		-- don't hide the mouse cursor
		SledgeInputWrapper.hideCursorInsideWindow(false)
	end

	print("Display initialized")
end

-- TODO: finish this, add fallbacks and support for closest match
function Display:findDisplayMode(_width, _height, _fullscreen)
	if _fullscreen then
		for index, mode in ipairs(Display.modes) do
			if _width == mode.w and _height == mode.h then
				-- found
				return mode
			end
		end
		-- fallback to default display mode
		return Display.dmode
	else
		for index, mode in ipairs(Display.windowmodes) do
			if _width == mode.w and _height == mode.h then
				-- found
				return mode
			end
		end
		-- fallback to the first window mode
		return Display.windowmodes[1]
	end
end

--- Toggle fullscreen mode.
-- Currently only does something if running in a SDL host
function Display:toggleFullscreen()

	-- this should really only be called on a SDL host
	if MOAIDisplaySDL == nil then
		print("Trying to toggle fullscreen mode but not running on a SDL host.")
		return
	end

	local dmode = Display.dmode
	if Display.fullscreen then
		MOAIDisplaySDL.setMode(Display.windowWidth, Display.windowHeight, dmode.refresh, dmode.bpp, 0)
		Display.screenWidth = Display.windowWidth
		Display.screenHeight = Display.windowHeight
	else
		MOAIDisplaySDL.setMode(dmode.w, dmode.h, dmode.refresh, dmode.bpp, 1)
		Display.screenWidth = dmode.w
		Display.screenHeight = dmode.h
	end

	Display.fullscreen = not Display.fullscreen
	--settings.fullscreen = Display.fullscreen

	resetViewports()
end

--- Set the display mode.
-- Currently only does anything on an SDL host
-- @param _dmode A reference to an entry in the Display.modes table or this whole function will blow up!
-- @param _bFullscreen boolean true if the mode should be fullscreen
function Display:setDisplayMode(_dmode, _bFullscreen)
	-- hopefully _dmode is a table reference to an entry in Display.modes or this isn't going to work...
	if MOAIDisplaySDL == nil then
		print("Trying to set a display mode but not running on a SDL host.")
		return
	end

	if _dmode.w == nil or _dmode.h == nil or _dmode.bpp == nil or _dmode.refresh == nil then
		print("Invalid _dmode in call to Display:setDisplayMode()!")
		return
	end

	if _bFullscreen == nil then
		_bFullscreen = Display.fullscreen
	end

	if _bFullscreen then
		MOAIDisplaySDL.setMode(_dmode.w, _dmode.h, _dmode.refresh, _dmode.bpp, 1)
		Display.screenWidth = _dmode.w
		Display.screenHeight = _dmode.h
	else
		MOAIDisplaySDL.setMode(_dmode.w, _dmode.h, _dmode.refresh, _dmode.bpp, 0)
		Display.screenWidth = _dmode.w
		Display.screenHeight = _dmode.h
		Display.windowWidth = _dmode.w
		Display.windowHeight = _dmode.h
	end

	resetViewports()
end

--- Save a screenshot.
-- TODO: This whole function
-- @param _filename the name of the file for the screen shot
function Display:saveScreenShot(_filename)
	-- TODO: this
	print("Display:saveScreenShot() not implemented yet.")
end


return Display

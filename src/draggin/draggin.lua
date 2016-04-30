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


local Display = require "draggin/display"
local Signal = require "draggin/signal"

local keyboard = MOAIInputMgr.device.keyboard

-- "Draggin" is the name of all these helper/wrapper systems for MOAI
local Draggin = {}

-- Default app title
Draggin.appTitle = "Draggin"


--- A simple linear lerp.
-- Linearly interpolate from one value to another based on a 0 to 1 scale.
-- @param _from the start value
-- @param _to the end value
-- @param _by scale of 0 to 1
-- @return the value from _from to _to based on the scale by _by
function Draggin.lerp(_from, _to, _by)
	return ((_to - _from) * _by) + _from
end

--- A simple isnan.
-- Check for nan
-- @param _num the number to check
-- @return true if _num is nan
function Draggin.isnan(_num)
	return _num ~= _num
end

--- Clean number
-- If the param _num is nan or inf, return 0
-- Otherwise return _num
-- @param _num the number to clean
-- @return a clean version of _num
function Draggin.cleanNumber(_num)
	if _num ~= _num or _num == math.huge then
		return 0
	end
	return _num
end

local debugDrawOn = false
--- Set debug draws.
-- Sets debug draws for MOAITextBox objects.
-- @param _enable if true or false, enable or disable the draws. If nil, toggle the draws.
function Draggin:debugDraw(_enable)

	if _enable == nil then
		-- toggle
		debugDrawOn = not debugDrawOn
	else
		debugDrawOn = _enable
	end

	local alpha = 0
	if debugDrawOn then
		alpha = 1
	end

	MOAIDebugLines.setStyle(MOAIDebugLines.TEXT_BOX, 1, 1, 1, 1, alpha)
	MOAIDebugLines.setStyle(MOAIDebugLines.TEXT_BOX_LAYOUT, 1, 0, 0, 1, alpha)
	MOAIDebugLines.setStyle(MOAIDebugLines.TEXT_BOX_BASELINES, 1, 1, 0, 0, alpha)
end

--- Print out a bunch of MOAIEnvironment vars.
-- Most of them are nil.
function Draggin:printEnvironment()
	print ("--------- Environment --------")
	print ("               Display Name : ", MOAIEnvironment.appDisplayName)
	print ("                     App ID : ", MOAIEnvironment.appID)
	print ("                App Version : ", MOAIEnvironment.appVersion)
	print ("            Cache Directory : ", MOAIEnvironment.cacheDirectory)
	print ("   Carrier ISO Country Code : ", MOAIEnvironment.carrierISOCountryCode)
	print ("Carrier Mobile Country Code : ", MOAIEnvironment.carrierMobileCountryCode)
	print ("Carrier Mobile Network Code : ", MOAIEnvironment.carrierMobileNetworkCode)
	print ("               Carrier Name : ", MOAIEnvironment.carrierName)
	print ("            Connection Type : ", MOAIEnvironment.connectionType)
	print ("               Country Code : ", MOAIEnvironment.countryCode)
	print ("                    CPU ABI : ", MOAIEnvironment.cpuabi)
	print ("               Device Brand : ", MOAIEnvironment.devBrand)
	print ("                Device Name : ", MOAIEnvironment.devName)
	print ("        Device Manufacturer : ", MOAIEnvironment.devManufacturer)
	print ("                Device Mode : ", MOAIEnvironment.devModel)
	print ("            Device Platform : ", MOAIEnvironment.devPlatform)
	print ("             Device Product : ", MOAIEnvironment.devProduct)
	print ("         Document Directory : ", MOAIEnvironment.documentDirectory)
	print ("         iOS Retina Display : ", MOAIEnvironment.iosRetinaDisplay)
	print ("              Language Code : ", MOAIEnvironment.languageCode)
	print ("                   OS Brand : ", MOAIEnvironment.osBrand)
	print ("                 OS Version : ", MOAIEnvironment.osVersion)
	print ("         Resource Directory : ", MOAIEnvironment.resourceDirectory)
	print ("                 Screen DPI : ", MOAIEnvironment.screenDpi)
	print ("              Screen Height : ", MOAIEnvironment.screenHeight)
	print ("               Screen Width : ", MOAIEnvironment.screenWidth)
	print ("                deviceWidth : ", MOAIEnvironment.horizontalResolution)
	print ("               deviceHeight : ", MOAIEnvironment.verticalResolution)
	print ("                       UDID : ", MOAIEnvironment.udid)
	print ("----------- Input ------------")
	print ("                   Keyboard : ", MOAIInputMgr.device.keyboard ~= nil)
	print ("                      Mouse : ", MOAIInputMgr.device.pointer ~= nil)
	print ("                      Touch : ", MOAIInputMgr.device.touch ~= nil)
	print ("                       Pad0 : ", MOAIInputMgr.pad0)
	print ("                       Pad1 : ", MOAIInputMgr.pad1)
	print ("                       Pad2 : ", MOAIInputMgr.pad2)
	print ("                       Pad3 : ", MOAIInputMgr.pad3)
	print ("----------- Sound ------------")
	print ("                       Untz : ", MOAIUntzSystem ~= nil)
	print ("------------ End -------------")
end


--- Spin wait a MOAIThread.
-- CAN ONLY BE CALLED FROM A THREAD! Asserts if it's not. Other coroutines continue.
-- @param _secs the number of seconds to wait.
function Draggin:wait(_secs)
	assert(MOAIThread.currentThread() ~= nil, "Trying to wait without running in a coroutine!\n")

	local prevElapsedTime = MOAISim.getElapsedTime()
	local elapsedTime = 0

	while (true) do

		elapsedTime = MOAISim.getElapsedTime() - prevElapsedTime

		--print(elapsedTime)
		if elapsedTime >= _secs then
			return
		end
		coroutine.yield()
	end
end

--- Spawns a new thread to wait for seconds and then calls the callback.
-- TODO: a better way to do this? There has to be a better way...
-- @param _secs the number of seconds to wait
-- @param _funct optional function to call when the wait is over
-- @return the MOAIThread which was created so you can cancle the callback
function Draggin:waitThenCallback(_secs, _funct)

	local function mainFunc()
		Draggin:wait(_secs)
		_funct()
	end

	local thread = MOAIThread.new()
	thread:run(mainFunc)

	return thread
end

--- Create a fullscreen textured prop.
-- The texture will appear to be stretched if it isn't already the size of the virtual res
-- @param _filename the texture file to load for the prop
-- @param _layer optionally send a layer to insert the prop into
-- @return the created prop
function Draggin:createFullscreenProp(_filename, _layer)
	local deck = MOAIGfxQuad2D.new ()
	deck:setTexture(_filename)
	deck:setRect(0, 0, Display.virtualWidth, Display.virtualHeight)
	deck:setUVRect(0, 0, 1, 1)

	local prop = MOAIProp2D.new()
	prop:setDeck(deck)
	prop.name = _filename

	if _layer then
		_layer:insertProp(prop)
	end

	return prop
end

local sig_keyboard = Signal.new()

--- Register for keyboard events.
-- Typically you'd be using the ActionMap system, but this is also available.
-- callback signature: _func(_key, _down)
-- @param _func callback function which receives the key and state
-- @return true if there's a keyboard device
-- @see Draggin:removeKeyboardCallback
function Draggin:registerKeyboardCallback(_func)
	sig_keyboard:register(_func)

	-- let whoever called this know if we even have a keyboard
	return keyboard ~= nil
end

--- Remove a keyboard callback
-- Removes a callback added with Draggin:registerKeyboardCallback
-- @param _func the same function you registered (it'll do nothing if it wasn't the same)
-- @see Draggin:registerKeyboardCallback
function Draggin:removeKeyboardCallback(_func)
	sig_keyboard:remove(_func)
end

-- keep track of each key
local keystate = {}
local function onKeyboardEvent(_key, _down)

	--print("onKeyboardEvent", _key, _down)
	if keystate[_key] == nil then
		keystate[_key] = "up"
	end

	if _down then
		if keystate[_key] == "down" then
			keystate[_key] = "held"
			sig_keyboard:emit(_key, "held")
			--print ("held")
		elseif keystate[_key] == "up" then
			keystate[_key] = "down"
			sig_keyboard:emit(_key, "down")
		end
		-- if _down and keystate[_key] == "held" don't do anything
	else
		if keystate[_key] ~= "up" then
			keystate[_key] = "up"
			sig_keyboard:emit(_key, "up")
		end
	end
end

--- Inject a keyboard event as if the user actually used the keyboard
-- Only fakes it for the callbacks that were registered, it's not low level
-- MOAI stuff.
-- @param _key the key to inject
-- @param _down boolean, is the key down?
function Draggin:injectKeyboardEvent(_key, _down)
	onKeyboardEvent(_key, _down)
end

-- if there's a keyboard, setup the Draggin callback
if keyboard then
	keyboard:setCallback(onKeyboardEvent)
end

-- Joystick support, this is pretty much what SDL2 considers a joystick
-- Mostly something like an xbox 360 controller
local joysticks = { MOAIInputMgr.joy0, MOAIInputMgr.joy1, MOAIInputMgr.joy2, MOAIInputMgr.joy3 }
Draggin.joysticks = joysticks
local sig_joysticks = { Signal.new(), Signal.new(), Signal.new(), Signal.new() }


--- Register a callback for joystick events.
-- You'll have to be running a MOAI host which supports joysticks
-- Callback signature: _func(_padnumber, button, state)
-- @param _padnumber the joystick number 1-4
-- @param _func the callback
function Draggin:registerJoystickCallback(_padnumber, _func)
	--print("Draggin:registerJoystickCallback(", _padnumber, _func, ")")
	sig_joysticks[_padnumber]:register(_func)

	-- let whoever called this know if we even have a joystick
	return joysticks[_padnumber] ~= nil
end

--- Remove a joystick callback
-- Removes a callback added with Draggin:registerJoystickCallback
-- @param _func the same function you registered (it'll do nothing if it wasn't the same)
-- @see Draggin:registerJoystickCallback
function Draggin:removeJoystickCallback(_padnumber, _func)
	sig_joysticks[_padnumber]:remove(_func)
end

--local buttonstates = {[0] = {}, [1] = {}, [2] = {}, [3] = {}}
for i = 1, #joysticks do
	local buttonstate = {}
	local function onJoystickButtonEvent(_key, _down)

		--local buttonstate = buttonstates[i]

		--print("onJoystickEvent", i, _key, _down)
		if buttonstate[_key] == nil then
			buttonstate[_key] = "up"
			--print(i, _key, "nil")
		end

		if _down then
			if buttonstate[_key] == "down" then
				buttonstate[_key] = "held"
				sig_joysticks[i]:emit(i, _key, "held")
				--print(i, _key, "held")
			elseif buttonstate[_key] == "up" then
				buttonstate[_key] = "down"
				sig_joysticks[i]:emit(i, _key, "down")
				--print(i, _key, "down")
			end
			-- if _down and buttonstate[_key] == "held" don't do anything
		else
			if buttonstate[_key] ~= "up" then
				buttonstate[_key] = "up"
				sig_joysticks[i]:emit(i, _key, "up")
				--print(i, _key, "up")
			end
		end
	end


	if joysticks[i] then
		--print("joystick setCallback", i)
		joysticks[i].buttons:setCallback(onJoystickButtonEvent)
	end
end

-- TODO: is there even a point to this?
-- function Draggin:injectJoystickEvent(_padnumber, _key, _down)
-- 	onKeyboardEvent(_key, _down)
-- end


-- input = {[1] = {x, y, tapCount, state}}
-- down, up, held (when you stay still for x secs), dragging
-- do we need a hold timer??
-- these are the 16 max "touches"
local inputPointers = {
	[1] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[2] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[3] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[4] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[5] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[6] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[7] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[8] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[9] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[10] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[11] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[12] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[13] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[14] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[15] = {x = -100, y = -100, tapCount = 0, state = "off"},
	[16] = {x = -100, y = -100, tapCount = 0, state = "off"},
}


local sig_pointer = Signal.new()

--- Registers a pointer callback
-- Pointer can mean a mouse or a touch, depending on the host/device.
-- Callback signature: _func(_index, x, y, state, tapCount)
-- @param _func
-- @see Draggin:removePointerCallback
function Draggin:registerPointerCallback(_func)
	sig_pointer:register(_func)
end

--- Remove a pointer callback
-- Removes a callback added with Draggin:registerPointerCallback
-- @param _func the same function you registered (it'll do nothing if it wasn't the same)
-- @see Draggin:registerPointerCallback
function Draggin:removePointerCallback(_func)
	sig_pointer:remove(_func)
end


-- mouse is always index 1
-- _index	touch index
-- _x, _y	position
-- _down	touches are always down here, mouse is considered down if left button is pressed
local function onPointerCallback(_index, _x, _y, _state, _tapCount)
	local ptr = inputPointers[_index]

	-- if we didn't get a new one, use the old one
	ptr.x = _x or ptr.x
	ptr.y = _y or ptr.y
	ptr.tapCount = _tapCount or 0	-- i dunno, mice don't have tap counts...
	ptr.state = _state	-- there should always be a state


	-- debug prints
	--print("input:", _index, ptr.x, ptr.y, ptr.tapCount, ptr.state)

	sig_pointer:emit(_index, ptr.x, ptr.y, ptr.state, ptr.tapCount)
end

--- Inject a pointer event as if the user actually used a pointer
-- Only fakes it for the callbacks that were registered, it's not low level
-- MOAI stuff.
-- @param _index the index of the pointer
-- @param _x the x position of the pointer
-- @param _y the y position of the pointer
-- @param _state the down state of the pointer
-- @param _tapCount the tap count of the pointer
-- @param _down boolean, is the key down?
function Draggin:injectPointerEvent(_index, _x, _y, _state, _tapCount)
	onPointerCallback(_index, _x, _y, _state, _tapCount)
end

if MOAIInputMgr.device.pointer then

	-- mouse input
	MOAIInputMgr.device.pointer:setCallback(
		function (_x, _y)
			local state = MOAIInputMgr.device.mouseLeft:isDown()
			if state then
				if inputPointers[1].state == "down" or inputPointers[1].state == "held" then
					state = "held"
				else
					state = "down"
				end
			else
				if inputPointers[1].state == "up" or inputPointers[1].state == "off" then
					state = "off"
				else
					state = "up"
				end
			end

			--print("MOAIInputMgr.device.pointer:setCallback", _x, _y)

			onPointerCallback(1, _x, _y, state)
		end
	)

	MOAIInputMgr.device.mouseLeft:setCallback(
		function (_down)

			local x, y = MOAIInputMgr.device.pointer:getLoc()
			local state
			if _down then
				if inputPointers[1].state == "down" then
					state = "held"
				else
					state = "down"
				end
			else
				if inputPointers[1].state == "up" then
					state = "off"
				else
					state = "up"
				end
			end

			onPointerCallback(1, x, y, state)
		end
	)

	MOAIInputMgr.device.mouseRight:setCallback(
		function (_down)

			local x, y = MOAIInputMgr.device.pointer:getLoc()
			local state
			if _down then
				if inputPointers[2].state == "down" then
					state = "held"
				else
					state = "down"
				end
			else
				if inputPointers[2].state == "up" then
					state = "off"
				else
					state = "up"
				end
			end

			onPointerCallback(2, x, y, state)
		end
	)
elseif MOAIInputMgr.device.touch then
	-- touch input
	MOAIInputMgr.device.touch:setCallback(

		function (eventType, _index, _x, _y, _tapCount)

			local state
			if eventType == MOAITouchSensor.TOUCH_DOWN then
				state = "down"
			elseif eventType == MOAITouchSensor.TOUCH_UP then
				state = "up"
			elseif eventType == MOAITouchSensor.TOUCH_MOVE then
				state = "held"
			else
				state = "off"
			end

			-- touch indices start at 0, but Draggin's start at 1
			onPointerCallback(_index+1, _x, _y, state, _tapCount)
		end
	)
else
	print("WHAT??? There's no mouse or touch input? Must be a new host?")
end

--- Make a coroutine wait for any input from any source.
-- Supports pointers, keyboards, and joysticks
function Draggin:waitForAnyInput()

	local input

	local function pointerInputFunc(_index, _x, _y, _state, _tapCount)
		--print("waitForAnyInput", _state)
		if _state == "up" then
			input = true
			--print("waitForAnyInput", _state)
		end
	end

	local function keyboardInputFunc(_index, _state)
		--print("waitForAnyInput", _state)
		if _state == "up" then
			input = true
			--print("waitForAnyInput", _state)
			up = false
		end
	end

	local function joystickInputFunc(_padnumber, _index, _state)
		--print("waitForAnyInput", _state)
		if _state == "up" then
			input = true
			--print("waitForAnyInput", _state)
		end
	end

	-- might not actually have a keyboard but that's ok
	Draggin:registerKeyboardCallback(keyboardInputFunc)
	Draggin:registerPointerCallback(pointerInputFunc)

	-- and do all the joysticks
	Draggin:registerJoystickCallback(1, joystickInputFunc)
	Draggin:registerJoystickCallback(2, joystickInputFunc)
	Draggin:registerJoystickCallback(3, joystickInputFunc)
	Draggin:registerJoystickCallback(4, joystickInputFunc)

	while input == nil do
		coroutine.yield()
	end

	Draggin:removeKeyboardCallback(keyboardInputFunc)
	Draggin:removePointerCallback(pointerInputFunc)

	Draggin:removeJoystickCallback(1, joystickInputFunc)
	Draggin:removeJoystickCallback(2, joystickInputFunc)
	Draggin:removeJoystickCallback(3, joystickInputFunc)
	Draggin:removeJoystickCallback(4, joystickInputFunc)
end

--- Callback after any input buttons or touch events
-- Supports pointers, keyboards, and joysticks
-- @param _callback	callback function.
-- @return the MOAIThread that was created, so you can cancle it.
function Draggin:callbackOnAnyInput(_callback)
	local thread = MOAIThread.new()
	thread:run(function ()
		Draggin:waitForAnyInput()
		_callback()
	end)

	return thread
end

return Draggin

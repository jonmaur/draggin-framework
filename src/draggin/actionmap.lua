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
-- ActionMap

-- An ActionMap is a mapping of inputs to "actions"
-- For example you can map the spacebar to the "jump" action
-- Inputs can be any keyboard key, pointer/touch, or joystick button
-- analog stick inputs are currently unsupported

local Draggin = require "draggin/draggin"

-- this line locally overrides the normal print with one that checks settings.debug first
local print = require "draggin/debugprint"


local ActionMap = {}

-- TODO: support sending a table with all the action info and exporting the same table
-- this would make it easy to save and load action maps

--- Creates a new ActionMap instance.
-- ActionMaps are mappings of inputs to actions. It's a way to setup the controls
-- of your game without hardcoding the actual key press everywhere. An action can
-- be triggered by any number of inputs from any number of input devices. ActionMaps
-- also provide a way to inject actions which can be used to easily add something
-- like an on screen touch gamepad.
-- Don't forget to call ActionMap:update() at the end of your game loop!
-- @returns the created ActionMap instance
function ActionMap.new()

	local map = {}
	local actionMap = {}
	local enabled = true

	--- Add a new action.
	-- @param _action string, the action name
	-- @param _key optional, the keyboard key which will trigger the action
	-- @param _index optional, the touch/pointer index
	-- @param _joystick optional, the joystick number
	-- @param _button optional, the joystick button, means nothing if _joystick is not set
	function map:addAction(_action, _key, _index, _joystick, _button)

		print("creating new action:", _action, _key, _index, _joystick, _button)
		actionMap[_action] = actionMap[_action] or {}
		actionMap[_action].state = "up"
		actionMap[_action].prevstate = "up"
		if not actionMap[_action].keyboardCallbacks then
			actionMap[_action].keyboardCallbacks = {}
		end

		local keyboardCallbacks = actionMap[_action].keyboardCallbacks

		-- if there's a key then it's for the keyboard
		if _key ~= nil then

			if type(_key) == "string" then
				_key = string.byte(_key)
			end

			local callback = function (_keycode, _state)
				--print("action key", _keycode, _state)
				if enabled and (_keycode == _key) then
					--print("action", _keycode, _state, _key)
					actionMap[_action].state = _state
				end
			end
			-- hold on to the keyboardCallbacks so they can be removed later
			keyboardCallbacks[#keyboardCallbacks+1] = callback
			Draggin:registerKeyboardCallback(callback)
		end


		-- touch and pointer events
		if not actionMap[_action].pointerCallbacks then
			actionMap[_action].pointerCallbacks = {}
		end

		local pointerCallbacks = actionMap[_action].pointerCallbacks

		-- if there's an index it's a touch event, but could also be a keyboard event
		if _index ~= nil then
			local callback = function (_pointer, _state)
				--print("action", _keycode, _state)
				if enabled and (_pointer == _index) then
					actionMap[_action].state = _state
				end
			end
			-- hold on to the pointerCallbacks so they can be removed later
			pointerCallbacks[#pointerCallbacks+1] = callback
			Draggin:registerPointerCallback(callback)
		end


		-- joypad button events
		if not actionMap[_action].buttonCallbacks then
			actionMap[_action].buttonCallbacks = {}
		end

		local buttonCallbacks = actionMap[_action].buttonCallbacks

		-- if there's a button it's a joypad event, but could also be another event
		if _joystick ~= nil then
			local callback = function (_joy, _butt, _state)
				--print("action", _joy, _butt, _state)
				if enabled and (_joy == _joystick) and (_butt == _button) then
					actionMap[_action].state = _state
				end
			end
			-- hold on to the buttonCallbacks so they can be removed later
			buttonCallbacks[#buttonCallbacks+1] = callback
			Draggin:registerJoystickCallback(_joystick, callback)
		end
	end

	--- Completely removes an action.
	-- Removes an action no matter how many inputs it had
	-- @param _action string, the action to remove
	function map:removeAction(_action)

		local act = actionMap[_action]

		if act == nil then
			return
		end

		for _, v in pairs(act.pointerCallbacks) do
			Draggin:removePointerCallback(v)
		end

		for _, v in pairs(act.keyboardCallbacks) do
			Draggin:removeKeyboardCallback(v)
		end

		for _, v in pairs(act.buttonCallbacks) do
			Draggin:removeJoystickCallback(1, v)
			Draggin:removeJoystickCallback(2, v)
			Draggin:removeJoystickCallback(3, v)
			Draggin:removeJoystickCallback(4, v)
		end

		actionMap[_action] = nil
	end

	--- Inject an action.
	-- Call this function if you need to manually inject actions
	-- unmapped actions are logged but ignored.
	-- this is how a virtual gamepad might work.
	-- @param _action string, the action to inject
	-- @param _state optional, the state to give it, defaults to "down"
	function map:injectAction(_action, _state)
		if not enabled then
			return
		end

		_state = _state or "down"

		local act = actionMap[_action]
		if act then
			act.state = _state
		else
			print("unmapped action", _action)
		end
	end

	--- Get the current state of an action.
	-- This is what you use to check the state of an action, almost as you
	-- would check the state of a button press.
	-- @param _action string, the action to check
	-- @return the state of the action: "down", "held", or "up"
	function map:stateOf(_action)
		assert(actionMap[_action], tostring(_action).." does not exist in this action map!")
		return actionMap[_action].state
	end

	--- Get the previous state of an action.
	-- This is what you use to check the previous state of an action, almost as you
	-- would check the state of a button press.
	-- @param _action string, the action to check
	-- @return the previous state of the action: "down", "held", or "up"
	function map:prevStateOf(_action)
		assert(actionMap[_action], tostring(_action).." does not exist in this action map!")
		return actionMap[_action].prevstate
	end

	--- Update the action map.
	-- You need to call this AFTER you check all the states, so at the end of
	-- your game loop. This function turns "down" events into "held"
	function map:update()
		if not enabled then
			return
		end

		-- check other stuff here
		for _, action in pairs(actionMap) do
			action.prevstate = action.state
			if action.state == "down" then
				action.state = "held"
			end
		end
	end

	--- Prints out all the active actions.
	function map:print()

		print("Action Map:")
		for k, v in pairs(actionMap) do
			print(k, v.state)
		end
	end

	--- Clear this action map
	-- Sets all actions to "up"
	function map:clear()
		for _, action in pairs(actionMap) do
			action.state = "up"
			action.prevstate = "up"
		end
	end

	--- Enable this action map.
	function map:enable()
		map:clear()
		enabled = true
	end

	--- Disable this action map.
	function map:disable()
		map:clear()
		enabled = false
	end

	return map
end

return ActionMap

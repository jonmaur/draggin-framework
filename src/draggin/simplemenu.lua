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
-- SimpleMenu
-- A simple text base game menu.

local Draggin = require "draggin/draggin"
local TextBox = require "draggin/textbox"
local Sound = require "draggin/sound"
local Display = require "draggin/display"

-- this line locally overrides the normal print with one that checks settings.debug first
--local print = require "draggin/debugprint"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local cleanNumber = Draggin.cleanNumber


local SimpleMenu = {}

--- Add default menu joystick actions.
-- Quick default action setup using standard joystick menu keys.
-- @param _actions an action map table
-- @param _padnumber the joystick number, nil for all joysticks
-- @return true on success, nil on fail
function SimpleMenu.addJoystickActions(_actions, _padnumber)

	if not (_actions and _actions.addAction) then
		return false
	end

	local function add_action_to_joy(i)
		_actions:addAction("ok", nil, nil, i, 7) -- start
		_actions:addAction("ok", nil, nil, i, 1) -- A
		_actions:addAction("cancle", nil, nil, i, 2) -- B
		_actions:addAction("cancle", nil, nil, i, 5) -- select
		_actions:addAction("up", nil, nil, i, 12) -- dpad up
		_actions:addAction("down", nil, nil, i, 13) -- dpad down
		_actions:addAction("left", nil, nil, i, 14) -- dpad left
		_actions:addAction("right", nil, nil, i, 15) -- dpad right
	end

	if _padnumber then
		add_action_to_joy(_padnumber)
	else
		for i = 1, #Draggin.joysticks do
			add_action_to_joy(i)
		end
	end

	return true
end

--- Add default menu keyboad actions.
-- Quick default action setup using standard PC keyboard menu keys.
-- @param _actions an action map table
-- @return true on success, nil on fail
function SimpleMenu.addKeyboardActions(_actions)

	if _actions and _actions.addAction then
		_actions:addAction("cancle", 283, nil) -- esc
		_actions:addAction("cancle", 264, nil) -- backspace
		_actions:addAction("ok", 269, nil) -- enter
		_actions:addAction("ok", ' ', nil)
		_actions:addAction("left", 'a', nil)
		_actions:addAction("right", 'd', nil)
		_actions:addAction("up", 'w', nil)
		_actions:addAction("down", 's', nil)

		-- arrow keys
		_actions:addAction("left", 293, nil) -- left arrow
		_actions:addAction("right", 295, nil) -- right arrow
		_actions:addAction("up", 294, nil) -- up arrow
		_actions:addAction("down", 296, nil) -- down arrow

		return true
	end
end

--- Remove the default menu keyboad actions.
-- Quick way to remove the actions added with addKeyboardActions().
-- But be super careful! This removes ALL buttons and keys assigned to the default actions for menus,
-- not just the keys from addKeyboardActions().
-- @param _actions an action map table
-- @return true on success, nil on fail
function SimpleMenu.removeKeyboardActions(_actions)
	if _actions and _actions.addAction then
		_actions:removeAction("cancle")
		_actions:removeAction("ok")
		_actions:removeAction("left")
		_actions:removeAction("right")
		_actions:removeAction("up")
		_actions:removeAction("down")

		return true
	end
end

--- Create a SimpleMenu.
-- A SimpleMenu is a quick way to get text based menus.
-- You send a table describing the entries as such:
-- _entries = {
--	[1] = {txt = "Start", onChoose = startgame, enabled = true, options = {"Continue", "New Game"}},
--	[2] = {txt = "Sound", onChoose = setsound, enabled = true, options = {"On", "Off"}}
-- }
-- txt, string, required, the text that shows up
-- onChoose, function, optional, the callback for when the menu option is chosen
-- enabled, boolean, optional, is this entry enabled and selectable?
-- options, table, optional, a table of string entries for the "options" of this entry
--
-- The configuration table overrides default menu configs as such:
-- _config.normalColor an array of the normal text color
-- _config.normalShadowColor an array of the normal text shadow color
-- _config.selectedColor the selected text color
-- _config.selectedShadowColor the selected text shadow color
-- _config.disabledColor the disabled text color
-- _config.disabledShadowColor the disabled text shadow color
-- _config.sndnavigate a Sound object to play when navigating the menu
-- _config.sndchoose a Sound object to play when choosing an item in the menu
-- _config.fontname the name of the font to use for this menu
-- _config.fontsize the size of the font to use for this menu
-- _config.spacing the ammount of spacing between menu entries
-- _config.top the y position of the top of the menu
-- _config.left the x position of the left side of the menu
-- _config.shadowX the shadow x offset
-- _config.shadowY the shadow y offset
-- _config.entrywidth the menu entries width
--
-- @param _entries a table describing the entries of this menu
-- @param _layer the layer to add this menu too, required
-- @param _config a table describing the configuration of this menu
-- @return the new SimpleMenu instance
function SimpleMenu.new(_entries, _layer, _config)
	--print("Creating a new SimpleMenu")
	-- _entries looks like this-- _config.sndnavigate a Sound object to play when navigating the menu

	--local ent = {
	--	[1] = {txt = "Start", onChoose = startgame, enabled = true, options = {"Continue", "New Game"}},
	--	[2] = {txt = "Sound", onChoose = setsound, enabled = true, options = {"On", "Off"}}
	--}

	local config = _config or {}

	local menu = {}

	local normalColor = config.normalColor or {0.5, 0.5, 0.5, 1}
	local normalShadowColor = config.normalShadowColor or {0, 0, 0, 0.75}
	local selectedColor = config.selectedColor or {59/255, 182/255, 209/255, 1}
	local selectedShadowColor = config.selectedShadowColor or {0, 0, 0, 0.75}
	local disabledColor = config.disabledColor or {0.15, 0.15, 0.15, 0.75}
	local disabledShadowColor = config.disabledShadowColor or {0, 0, 0, 0.75}

	local sndnavigate = config.sndnavigate
	local sndchoose = config.sndchoose

	local fontname = config.fontname or "PressStart6"
	local fontsize = config.fontsize or 24
	local fontscale = config.fontscale or 1

	local spacing = config.spacing or fontsize + 2
	local shadowX = config.shadowX or 0.4
	local shadowY = config.shadowY or 0.4

	local viewportWidth = config.viewportWidth or virtualWidth
	local viewportHeight = config.viewportHeight or virtualHeight

	local entrywidth = config.entrywidth or viewportWidth/8
	local top = config.top or viewportHeight/2
	local left = config.left or 0
	local align = config.align or MOAITextBox.CENTER_JUSTIFY
	local alignoptions = config.alignoptions or MOAITextBox.CENTER_JUSTIFY

	local items = {}
	local selected

	local partition = MOAIPartition.new()
	_layer:setPartition(partition)

	--- Move the menu selection up.
	function menu:moveUp()
		--print("menu:moveUp()")

		local newSelected = selected
		local testSelected = selected - 1
		local looped = false

		while true do
			if testSelected <= 0 then
				if looped then
					-- already looped? just get out of here
					menu:setSelected(selected)
					return
				end
				testSelected = #items
				looped = true
			end

			local item = items[testSelected]
			if item.label ~= nil and item.label == true then
				-- skip
			elseif item.enabled ~= nil and item.enabled == false then
				-- skip
			else
				-- ok!
				newSelected = testSelected
				if sndnavigate then
					sndnavigate:play()
				end
				break
			end

			testSelected = testSelected - 1
		end

		menu:setSelected(newSelected)
	end

	--- Move the menu selection down.
	function menu:moveDown()
		--print("menu:moveDown()")

		local newSelected = selected
		local testSelected = selected + 1
		local looped = false

		while true do
			if testSelected > #items then
				if looped then
					-- already looped? just get out of here
					menu:setSelected(selected)
					return
				end
				testSelected = 1
				looped = true
			end

			local item = items[testSelected]
			if item.label ~= nil and item.label == true then
				-- skip
			elseif item.enabled ~= nil and item.enabled == false then
				-- skip
			else
				-- ok!
				newSelected = testSelected
				if sndnavigate then
					sndnavigate:play()
				end
				break
			end

			testSelected = testSelected + 1
		end

		menu:setSelected(newSelected)
	end

	--- Move the menu selection right.
	-- Only makes sense for entries with multiple entries
	function menu:moveRight()
		local item = items[selected]
		if item.subtxt == nil or not item.enabled then
			return
		end

		local options = item.subtxt.options
		local newOption = item.subtxt.option

		newOption = newOption + 1
		if newOption > #options then
			newOption = 1
		end
		item.subtxt.option = newOption
		item.subtxt:setString(options[newOption])

		if type(item.onChange) == "function" then
			item.onChange(item.txt, options[newOption], newOption)
		end
		if sndnavigate then
			sndnavigate:play()
		end
	end

	--- Move the menu selection left.
	-- Only makes sense for entries with multiple entries
	function menu:moveLeft()
		local item = items[selected]
		if item.subtxt == nil or not item.enabled then
			return
		end

		local options = item.subtxt.options
		local newOption = item.subtxt.option

		newOption = newOption - 1
		if newOption < 1 then
			newOption = #options
		end
		item.subtxt.option = newOption
		item.subtxt:setString(options[newOption])

		if type(item.onChange) == "function" then
			item.onChange(item.txt, options[newOption], newOption)
		end
		if sndnavigate then
			sndnavigate:play()
		end
	end

	--- Set the menu's selection.
	-- @param _item string or number representing the menu's entry to select
	-- @return true if successful, does nothing if not successful
	function menu:setSelected(_item)
		--print("menu:setSelected", _item)

		if type(_item) == "string" then
			-- find the index
			for k, v in pairs(items) do
				--print("here")
				if v.txt == _item then
					_item = k

					break
				end
			end
		end

		if type(_item) == "number" then
			if items[_item] ~= nil and items[_item].enabled and not items[_item].label then
				if items[selected] ~= nil then
					items[selected]:setColor(normalColor)
					items[selected]:setShadowColor(normalShadowColor)
					if items[selected].subtxt then
						items[selected].subtxt:setColor(normalColor)
						items[selected].subtxt:setShadowColor(normalShadowColor)
					end
				end

				selected = _item
				items[selected]:setColor(selectedColor)
				items[selected]:setShadowColor(selectedShadowColor)
				if items[selected].subtxt then
					items[selected].subtxt:setColor(selectedColor)
					items[selected].subtxt:setShadowColor(selectedShadowColor)
				end

				-- success!
				return true
			end
		end

		-- unsuccessful
		return false
	end

	--- Set the option of a menu entry
	-- @param _item string or number representing the menu's entry to set the option of
	-- @param _strOption string, the option to set
	function menu:setOption(_item, _strOption)
		--print("menu:setOption", _item, _strOption)
		if type(_item) == "string" then
			-- find the index
			for k, v in pairs(items) do
				--print("here")
				if v.txt == _item then
					_item = k

					break
				end
			end
		end

		local item = items[_item]
		local options = item.subtxt.options
		local newOption = item.subtxt.option

		-- find the index
		for k, v in pairs(options) do
			--print("there")
			if v == _strOption then
				--print("menu:setOption found it!", k, v)
				newOption = k
				item.subtxt.option = newOption
				item.subtxt:setString(v)

				if type(item.onChange) == "function" then
					item.onChange(item.txt, v, k)
				end

				break
			end
		end
	end

	--- Set the option of a menu entry
	-- @param _item string or number representing the menu's entry to set the option of
	-- @param _disabled boolean, disable this menu entry?
	function menu:setDisabled(_item, _disabled)
		print("menu:setDisabled", _item, _disabled)
		if type(_item) == "string" then
			-- find the index
			for k, v in pairs(items) do
				--print("here")
				if v.txt == _item then
					_item = k

					break
				end
			end
		end

		local item = items[_item]
		local options = item.subtxt.options

		if _disabled then
			item:setColor(disabledColor)
			item:setShadowColor(disabledShadowColor)
			item.subtxt:setColor(disabledColor)
			item.subtxt:setShadowColor(disabledShadowColor)
			item.enabled = false
		else
			item:setColor(normalColor)
			item:setShadowColor(normalShadowColor)
			item.subtxt:setColor(normalColor)
			item.subtxt:setShadowColor(normalShadowColor)
			item.enabled = true
		end
	end

	--- Choose the currently selected menu entry.
	-- if the current entry has a callback, the fist argument is the item text
	-- the option text (if any) is the 2nd argument
	function menu:chooseSelected()
		--print("chooseSelected")
		local item = items[selected]

		if type(item.onChoose) == "function" then
			if item.subtxt and item.subtxt.options and item.subtxt.option ~= nil then
				item.onChoose(item.txt, item.subtxt.options[item.subtxt.option], item.subtxt.option)
			else
				item.onChoose(item.txt)
			end
		end

		if sndchoose then
			sndchoose:play()
		end
	end


	-- initialization
	-- check for options text for positioning
	local hasoptions = false
	for k, t in ipairs(_entries) do
		if type(t.options) == "table" then
			hasoptions = true
			break
		end
	end

	--print("_entries", #_entries)
	for k, t in ipairs(_entries) do

		--print("simplemenu item", k, t)

		local txtBox = TextBox.new(fontname, fontsize)
		items[k] = txtBox
		if t.label and hasoptions then
			txtBox:setRect(-(entrywidth/2)+left, -fontsize/1.5, (entrywidth/2)+left, fontsize/1.5)
			txtBox:setAlignment(MOAITextBox.CENTER_JUSTIFY)
		else
			txtBox:setRect(-entrywidth+left, -fontsize/1.5, left, fontsize/1.5)
			txtBox:setAlignment(align)
		end
		txtBox:setLoc(viewportWidth/2, top - (spacing*(k-1)))
		txtBox:setScl(fontscale, fontscale)
		txtBox:setShadowOffset(shadowX, shadowY)
		txtBox:setString(t.txt)
		txtBox.txt = t.txt

		txtBox:insertIntoLayer(_layer, partition)


		-- "option text?"
		if type(t.options) == "table" then
			local subtxt = TextBox.new(fontname, fontsize)
			txtBox.subtxt = subtxt
			subtxt:setRect(left, -fontsize/1.5, entrywidth+left, fontsize/1.5)
			subtxt:setLoc(viewportWidth/2, top - (spacing*(k-1)))
			subtxt:setScl(fontscale, fontscale)
			subtxt:setAlignment(alignoptions)
			subtxt:setShadowOffset(shadowX, shadowY)
			subtxt:insertIntoLayer(_layer, partition)

			subtxt:setString(t.options[1])
			subtxt:setColor(normalColor)
			subtxt:setShadowColor(normalShadowColor)
			subtxt.options = t.options
			subtxt.option = 1
		end

		-- copy entries
		if t.enabled ~= nil then
			txtBox.enabled = t.enabled
		else
			txtBox.enabled = true
		end
		txtBox.label = t.label
		txtBox.onChoose = t.onChoose
		txtBox.onChange = t.onChange

		txtBox:setColor(normalColor)
		txtBox:setShadowColor(normalShadowColor)

		if t.enabled == false then
			txtBox:setColor(disabledColor)
			txtBox:setShadowColor(disabledShadowColor)
			if txtBox.subtxt ~= nil then
				txtBox.subtxt:setColor(disabledColor)
				txtBox.subtxt:setShadowColor(disabledShadowColor)
			end
		elseif selected == nil and not (type(t.label) == "boolean" and t.label == true) then
			-- this is the first enabled item, so it is selected
			menu:setSelected(k)
		end

		if type(t.color) == "table" then
			txtBox:setColor(t.color)
			if txtBox.subtxt ~= nil then
				txtBox.subtxt:setColor(t.color)
			end
		end
	end


	--- Enable touch/pointer input.
	-- Registers a pointer callback so don't forget to call disableTouch when done
	-- using this menu.
	-- @see menu:disableTouch
	function menu:enableTouch()
		-- mouse pointer and touch
		menu.onPointerCallback = function (_index, _x, _y, _state, _tapCount)

			local x, y = _layer:wndToWorld(_x, _y)
			local pick = partition:propForPoint(x, y)

			if pick and _state == "down" then
				--print("picked", pick.str)
				menu:setSelected(pick.str)
			end
			if pick and _state == "up" then
				--print("picked", pick.str)
				if menu:setSelected(pick.str) then
					menu:chooseSelected()
				end
			end
		end

		Draggin:registerPointerCallback(menu.onPointerCallback)
	end

	--- Disable touch/pointer input.
	-- Removes a pointer callback so don't forget to call this when done
	-- using this menu.
	-- @see menu:enableTouch
	function menu:disableTouch()
		-- mouse pointer and touch
		Draggin:removePointerCallback(menu.onPointerCallback)
		menu.onPointerCallback = nil
	end

	--- Destroy this menu.
	-- It's a destructor so don't forget it!
	function menu:destroy()
		menu:disableTouch()

		-- clean up the items
		for i = 1, #items do
			if items[i].subtxt then
				items[i].subtxt:destroy()
				items[i].subtxt = nil
			end

			items[i]:destroy()
			items[i] = nil
		end
	end

	--- Check for default navigation actions
	-- Just a helper function since this is usually what's checked to navigate around menus.
	-- The action map better have "up", "down", "left", and "right" or this function makes no
	-- sense.
	-- @param _actions an action map
	-- @return true if there was any navigating
	function menu:defaultNavigation(_actions)
		if _actions and _actions.stateOf then
			if _actions:stateOf("up") == "down" then
				menu:moveUp()
				return true
			elseif _actions:stateOf("down") == "down" then
				menu:moveDown()
				return true
			elseif _actions:stateOf("left") == "down" then
				menu:moveLeft()
				return true
			elseif _actions:stateOf("right") == "down" then
				menu:moveRight()
				return true
			end
		end
	end

	-- should this be hidden from the caller?
	--menu.selected = selected
	menu.items = items

	return menu
end


return SimpleMenu

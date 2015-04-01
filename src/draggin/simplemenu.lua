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


local SimpleMenu = {}

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
-- _config.selectedColor the selected text color
-- _config.disabledColor the disabled text color
-- _config.sndnavigate a Sound object to play when navigating the menu
-- _config.sndchoose a Sound object to play when choosing an item in the menu
-- _config.fontname the name of the font to use for this menu
-- _config.fontsize the size of the font to use for this menu
-- _config.spacing the ammount of spacing between menu entries
-- _config.top the y position of the top of the menu
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
	local selectedColor = config.selectedColor or {59/255, 182/255, 209/255, 1}
	local disabledColor = config.disabledColor or {0.15, 0.15, 0.15, 0.75}

	local sndnavigate = config.sndnavigate or Sound.new('laser.wav', 'fx')
	local sndchoose = config.sndchoose or Sound.new('shot.wav', 'fx')

	local fontname = config.fontname or "PressStart6"
	local fontsize = config.fontsize or 24

	local spacing = config.spacing or fontsize + 2
	local top = config.top or virtualHeight/2
	local shadowX = config.shadowX or 0.4
	local shadowY = config.shadowY or 0.4

	local entrywidth = config.entrywidth or virtualWidth/8

	local items = {}
	local selected

	local partition = MOAIPartition.new()
	_layer:setPartition(partition)

	--- Move the menu selection up.
	function menu:moveUp()
		--print("menu:moveUp()")

		local newSelected = selected
		local testSelected = selected - 1
		while testSelected > 0 do
			local item = items[testSelected]
			if item.label ~= nil and item.label == true then
				-- skip
			elseif item.enabled ~= nil and item.enabled == false then
				-- skip
			else
				-- ok!
				newSelected = testSelected
				sndnavigate:play()
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
		while testSelected <= #items do
			local item = items[testSelected]
			if item.label ~= nil and item.label == true then
				-- skip
			elseif item.enabled ~= nil and item.enabled == false then
				-- skip
			else
				-- ok!
				newSelected = testSelected
				sndnavigate:play()
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
		if item.subtxt == nil then
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
		sndnavigate:play()
	end

	--- Move the menu selection left.
	-- Only makes sense for entries with multiple entries
	function menu:moveLeft()
		local item = items[selected]
		if item.subtxt == nil then
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
		sndnavigate:play()
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
					if items[selected].subtxt then
						items[selected].subtxt:setColor(normalColor)
					end
				end

				selected = _item
				items[selected]:setColor(selectedColor)
				if items[selected].subtxt then
					items[selected].subtxt:setColor(selectedColor)
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

		sndchoose:play()
	end


	-- initialization

	--print("_entries", #_entries)
	for k, t in ipairs(_entries) do

		--print("simplemenu item", k, t)

		local txtBox = TextBox.new(fontname, fontsize)
		items[k] = txtBox
		txtBox:setRect(-entrywidth, -fontsize/1.5, entrywidth, fontsize/1.5)
		txtBox:setLoc(virtualWidth/2, top - (spacing*(k)))
		txtBox:setAlignment(MOAITextBox.CENTER_JUSTIFY)
		txtBox:setShadowOffset(shadowX, shadowY)
		txtBox:setString(t.txt)
		txtBox.txt = t.txt

		txtBox:insertIntoLayer(_layer, partition)


		-- "option text?"
		if type(t.options) == "table" then
			local subtxt = TextBox.new(fontname, fontsize)
			txtBox.subtxt = subtxt
			subtxt:setRect(entrywidth, -fontsize/1.5, entrywidth*2, fontsize/1.5)
			subtxt:setLoc(virtualWidth/2, top - (spacing*(k)))
			subtxt:setAlignment(MOAITextBox.CENTER_JUSTIFY)
			subtxt:setShadowOffset(shadowX, shadowY)
			subtxt:insertIntoLayer(_layer, partition)

			subtxt:setString(t.options[1])
			subtxt:setColor(normalColor)
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

		if t.enabled == false then
			txtBox:setColor(disabledColor)
			if txtBox.subtxt ~= nil then
				txtBox.subtxt:setColor(disabledColor)
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

	-- should this be hidden from the caller?
	--menu.selected = selected
	menu.items = items

	return menu
end


return SimpleMenu

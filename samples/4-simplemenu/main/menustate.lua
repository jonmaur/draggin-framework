local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local TextBox = require "draggin/textbox"
local ActionMap = require "draggin/actionmap"
local AudioManager = require "draggin/audiomanager"
local Sound = require "draggin/sound"
local SimpleMenu = require "draggin/simplemenu"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local menustate = {}

function menustate.new()

	--Draggin:debugDraw(true)

	local state = {}

	state.name = "MenuState"

	local layers = {}
	local mainThread
	local txt


	local hellocount = 0
	local function hello()
		local str

		hellocount = hellocount + 1

		if hellocount == 1 then
			str = "Is that you world?"
		elseif hellocount == 2 then
			str = "Are you saying hi to me?"
		elseif hellocount == 3 then
			str = "Yep, this is a callback for selecting a menu option."
		elseif hellocount == 4 then
			str = "It's still a callback."
		elseif hellocount == 5 then
			str = "WHEE!"
			hellocount = 0
		else
			str = "IMPOSSIBLE!"
			hellocount = 0
		end

		print(str)
		txt:setString(str)
		txt:spool()
	end

	local function exitgame()
		os.exit()
	end

	local function menuChanged(_item, _option)
		local str = "MENU CHANGE TEST: "..tostring(_item)..", "..tostring(_option)
		print(str)
		txt:setString(str)
		txt:spool()

		if _item == "Sound" then
			if _option == "On" then
				AudioManager:enableGroup("fx")
			else
				AudioManager:disableGroup("fx")
			end
		elseif _item == "Debug" then
			if _option == "On" then
				Draggin:debugDraw(true)
			else
				Draggin:debugDraw(false)
			end
		end
	end

	function state:init()

		-- create the main layer
		local layer = MOAILayer2D.new()
		layer:setViewport(viewport)
		layers[#layers+1] = layer

		-- create the text boxes
		local toptxt = TextBox.new("LiberationSansNarrow-Regular", 32)
		toptxt:setRect(virtualWidth/8, virtualHeight-60, virtualWidth - (virtualWidth/8), virtualHeight)
		toptxt:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.LEFT_JUSTIFY)
		toptxt:setString("WASD and SPACEBAR to navigate this menu.")
		toptxt:insertIntoLayer(layer)

		txt = TextBox.new("LiberationSansNarrow-Regular", 48)
		txt:setRect(virtualWidth/4, 0, virtualWidth - (virtualWidth/4), virtualHeight/4)
		txt:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
		txt:insertIntoLayer(layer)


		local items = {
			{txt = "MENU", label = true, color = {1,0,0,1}},
			{txt = "Hello?", onChoose = hello},
			{txt = "Sound", onChange = menuChanged, options = {"On", "Off"}},
			{txt = "Debug", onChange = menuChanged, options = {"Off", "On"}},
			{txt = "Exit", onChoose = exitgame}
		}

		local menuConfig = {
			normalColor = {0.5, 0.5, 0.5, 1},
			selectedColor = {1, 1, 0, 1},
			disabledColor = {0.15, 0.15, 0.15, 0.75},

			sndnavigate = Sound.new('choose.wav', 'fx'),
			sndchoose = Sound.new('navigate.wav', 'fx'),

			fontname = "LiberationSansNarrow-Regular",
			fontsize = 48,

			top = virtualHeight - virtualHeight/8,
			shadowX = -1,
			shadowY = -1
		}

		local layer = MOAILayer2D.new()
		layer:setViewport(viewport)
		layers[#layers+1] = layer

		menu = SimpleMenu.new(items, layer, menuConfig)

		-- action map
		actions = ActionMap.new()

		actions:addAction("cancle", 'z', nil)
		actions:addAction("ok", ' ', nil)
		actions:addAction("ok", 'enter', nil)
		actions:addAction("left", 'a', nil)
		actions:addAction("right", 'd', nil)
		actions:addAction("up", 'w', nil)
		actions:addAction("down", 's', nil)

		print(state.name.." init() done.")
	end

	function state:gotFocus()

		print(state.name.." got focus")

		local function mainFunc()

			while true do

				if actions:stateOf("up") == "down" then
					menu:moveUp()
				elseif actions:stateOf("down") == "down" then
					menu:moveDown()
				elseif actions:stateOf("left") == "down" then
					menu:moveLeft()
				elseif actions:stateOf("right") == "down" then
					menu:moveRight()
				end

				if actions:stateOf("ok") == "down" then
					menu:chooseSelected()
					menu:moveLeft() -- a bit of a hack to get the menu options to change
				elseif actions:stateOf("cancle") == "down" then
					resumegame()
				end

				-- oh snap, you have to update the actions AFTER you check them or you might miss "down" states which turn
				-- turn into "held" states inside the update function
				actions:update()
			 	coroutine.yield()
			end

		end

		mainThread = MOAIThread.new()
		mainThread:run(mainFunc)
		actions:enable()

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)
	end

	function state:lostFocus()
		print(state.name.." lost focus")

		actions:disable()

		-- TODO: clean up all the stuff in this gamestate
	end


	return state
end

return menustate

local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sprite = require "draggin/sprite"
local FontMgr = require "draggin/fontmanager"
local TextBox = require "draggin/textbox"
local Tilemap = require "draggin/tilemap"
local Sound = require "draggin/sound"
local SimpleMenu = require "draggin/simplemenu"
local ActionMap = require "draggin/actionmap"
local GameStateManager = require "draggin/gamestatemanager"

local NinjaState = require "ninjastate"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local random = math.random

local TitleState = {}


function TitleState.new()

	local ninjastate = NinjaState.new()

	local state = {}

	state.name = "TitleState"
	local textSpeed = 20

	local mainlayer
	local presentTextBox
	local continueText

	local menu
	local menulayer
	local actions


	local function exitgame()
		os.exit()
	end

	function state:init()
		-- setup the rendering for this state
		state.layers = {}

		local layers = state.layers

		bg = Tilemap.new("bg", viewport)
		layers[#layers+1] = bg.layer


		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)

		layers[#layers+1] = mainlayer

		-- the textboxes
		presentTextBox = TextBox.new()
		presentTextBox:setFont("PressStart32")
		presentTextBox:setRect(virtualWidth/8, virtualHeight/4, virtualWidth - virtualWidth/8, virtualHeight - (virtualHeight/16))
		presentTextBox:setAlignment(MOAITextBox.CENTER_JUSTIFY)
		presentTextBox:setSpeed(textSpeed)
		presentTextBox:insertIntoLayer(mainlayer)

		continueText = TextBox.new()
		continueText:setFont("PressStart16")
		continueText:setRect(virtualWidth/8, virtualHeight/16, virtualWidth - virtualWidth/8, virtualHeight/4)
		continueText:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
		continueText:insertIntoLayer(mainlayer)


		-- menu stuff
		-- create the menu layer
		menulayer = MOAILayer2D.new()
		menulayer:setViewport(viewport)


		-- action map
		actions = ActionMap.new()

		actions:addAction("cancle", string.char(27), nil)
		actions:addAction("cancle", 'z', nil)
		actions:addAction("ok", ' ', nil)
		actions:addAction("ok", string.char(13), nil)
		actions:addAction("left", 'a', nil)
		actions:addAction("right", 'd', nil)
		actions:addAction("up", 'w', nil)
		actions:addAction("down", 's', nil)

		actions:addAction("left", 'left', nil)
		actions:addAction("right", 'right', nil)
		actions:addAction("up", 'up', nil)
		actions:addAction("down", 'down', nil)
	end

	function state:gotFocus()

		print(state.name.." got focus")
		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(state.layers)

		-- scrolling bg
		local function scrollFunc()
			local action
			while true do
				bg.prop:setLoc(0, -bg.mapHeightInPixels + virtualHeight)
				action = bg.prop:seekLoc(-960, -bg.mapHeightInPixels + virtualHeight, 4, MOAIEaseType.LINEAR)
				MOAIThread.blockOnAction(action)

			end
		end

		state.scrollThread = MOAIThread.new()
		state.scrollThread:run(scrollFunc)


		local function introFunc()

			presentTextBox:setString("ZOARRITIN PRESENTS")

			local spoolAction = presentTextBox:spool()
			MOAIThread.blockOnAction(spoolAction)


			Draggin:wait(3)

			presentTextBox:setString(string.upper(Draggin.appTitle))
			spoolAction = presentTextBox:spool()
			MOAIThread.blockOnAction(spoolAction)

			Draggin:wait(3)

			continueText:setString("PRESS START!")
			continueText:blink(1)

			Draggin:waitForAnyInput()

			Draggin:wait(0.25)

			-- clear the text
			presentTextBox:setString("")
			continueText:setString("")
			continueText:stopBlink()


			-- menu stuff
			local function oneplayer()
				GameStateManager.switchState(ninjastate, 1)
			end
			local function twoplayer()
				GameStateManager.switchState(ninjastate, 2)
			end


			local items = {
				{txt = "1 PLAYER", onChoose = oneplayer},
				{txt = "2 PLAYERS", onChoose = twoplayer},
				{txt = "EXIT", onChoose = exitgame}
			}

			local menuConfig = {
				normalColor = {79/255, 25/255, 94/255, 1},
				selectedColor = {203/255, 39/255, 96/255, 1},
				disabledColor = {0.15, 0.15, 0.15, 0.75},

				sndnavigate = Sound.new('navigate.wav', 'fx'),
				sndchoose = Sound.new('choose.wav', 'fx'),

				fontname = "PressStart32",
				fontsize = 32,

				spacing = 40,
				shadowX = 2,
				shadowY = -2,

				entrywidth = virtualWidth/2,
			}
			menu = SimpleMenu.new(items, menulayer, menuConfig)
			state.layers[#state.layers+1] = menulayer

			menu:enableTouch()

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
				elseif actions:stateOf("cancle") == "down" then
					resumegame()
				end

				-- you have to update the actions AFTER you check them or you might miss "down" states which turn
				-- turn into "held" states inside the update function
				actions:update()
			 	coroutine.yield()
			 end
		end

		state.introThread = MOAIThread.new()
		state.introThread:run(introFunc)
	end

	function state:lostFocus()

		state.introThread:stop()
		state.introThread = nil

		state.scrollThread:stop()
		state.scrollThread = nil

		menu:destroy()
		menu = nil
	end


	return state
end

return TitleState

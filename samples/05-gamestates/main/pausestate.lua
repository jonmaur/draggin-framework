local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sound = require "draggin/sound"
local SimpleMenu = require "draggin/simplemenu"
local ActionMap = require "draggin/actionmap"
local GameStateManager = require "draggin/gamestatemanager"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight


local PauseState = {}

function PauseState.new()

	local state = {}

	state.name = "PauseState"

	local prevstate
	local menu
	local actions


	local function resumegame()
		if GameStateManager.getTopName() == "PauseState" then
			GameStateManager.popState()
		else
			print("Error! How is PauseState not the top state right now?")
		end
	end

	local function returntotitle()
		if GameStateManager.getTopName() == "PauseState" then
			GameStateManager.popState()
			GameStateManager.popState()
		else
			print("Error! How is PauseState not the top state right now?")
		end
	end

	local function exitgame()
		os.exit()
	end

	-- called once before entering the first time
	function state:init()
		state.layer = MOAILayer2D.new()
		state.layer:setViewport(viewport)


		local items = {
			{txt = "PAUSED", label = true, color = {1,0,0,1}},
			{txt = "Resume", onChoose = resumegame},
			{txt = "Titlescreen", onChoose = returntotitle},
			{txt = "Exit", onChoose = exitgame}
		}

		local menuConfig = {
			normalColor = {79/255, 25/255, 94/255, 1},
			selectedColor = {203/255, 39/255, 96/255, 1},
			disabledColor = {0.15, 0.15, 0.15, 0.75},

			sndnavigate = Sound.new('navigate.wav', 'fx'),
			sndchoose = Sound.new('choose.wav', 'fx'),

			fontname = "PressStart16",
			fontsize = 16,

			spacing = 20,
			shadowX = 1,
			shadowY = -1,

			entrywidth = virtualWidth/2,
		}

		menu = SimpleMenu.new(items, state.layer, menuConfig)

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

		--actions:addAction("left", 'left', nil)
		--actions:addAction("right", 'right', nil)
		--actions:addAction("up", 'up', nil)
		--actions:addAction("down", 'down', nil)

	end

	-- entering this state, effectively running it
	-- if you wish to do more stuff, you should spawn a thread here
	function state:gotFocus(_prevState)

		print("PauseState got focus", _prevState)
		prevstate = _prevState

		local function mainFunc()
			print("in mainFunc of menu")

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

				-- oh snap, you have to update the actions AFTER you check them or you might miss "down" states which turn
				-- turn into "held" states inside the update function
				actions:update()
			 	coroutine.yield()
			end

		end

		-- rendering
		table.insert(prevstate.layers, state.layer)
		MOAIRenderMgr.setRenderTable(prevstate.layers)

		state.mainThread = MOAIThread.new()
		state.mainThread:run(mainFunc)
		actions:enable()
	end

	-- leaving this state to go on to another, clean up stuff from enter()
	function state:lostFocus(_newState)
		print("PauseState lost focus")
		actions:disable()

		state.mainThread:stop()
		state.mainThread = nil

		table.remove(prevstate.layers)
	end

	-- called to completely unload this state, usually clean up the stuff from init()
	function state:destroy()
		state.layer = nil
	end

	return state
end

return PauseState

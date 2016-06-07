local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sprite = require "draggin/sprite"
local GameStateManager = require "draggin/gamestatemanager"
local ActionMap = require "draggin/actionmap"
local PauseState = require "pausestate"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local ninjastate = {}

function ninjastate.new()

	local pausestate = PauseState.new()
	local state = {}

	state.name = "NinjaState"

	local layers = {}
	state.layers = layers
	local mainlayer

	local actions
	local blueninja
	local redninja

	local numPlayers

	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		blueninja = Sprite.new("ninja")
		blueninja:setColor(0, 0, 1, 1)
		redninja = Sprite.new("ninja")
		redninja:setColor(1, 0, 0, 1)

		-- action map
		actions = ActionMap.new()
		actions:addAction("pause", string.char(27), nil)

		print(state.name.." init() done.")
	end

	function state:gotFocus(_prev, _numPlayers)

		print(state.name.." got focus", _numPlayers)

		actions:enable()

		numPlayers = _numPlayers or numPlayers

		-- the ninja sprites
		blueninja:playAnimation("runRight")
		if numPlayers == 2 then
			blueninja:setLoc(virtualWidth/3, virtualHeight/2)
			redninja:playAnimation("runRight")
			redninja:setLoc(virtualWidth-(virtualWidth/3), virtualHeight/2)
			mainlayer:insertProp(redninja)
		else
			blueninja:setLoc(virtualWidth/2, virtualHeight/2)
		end
		mainlayer:insertProp(blueninja)

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)

		local function mainFunc()
			print("in mainFunc of menu")

			while true do

				if actions:stateOf("pause") == "down" then
					GameStateManager.pushState(pausestate)
				end

				-- oh snap, you have to update the actions AFTER you check them or you might miss "down" states which turn
				-- turn into "held" states inside the update function
				actions:update()
			 	coroutine.yield()
			end

		end

		state.mainThread = MOAIThread.new()
		state.mainThread:run(mainFunc)
	end

	function state:lostFocus()
		print(state.name.." lost focus")
		mainlayer:removeProp(blueninja)
		mainlayer:removeProp(redninja)
		actions:disable()
	end


	return state
end

return ninjastate

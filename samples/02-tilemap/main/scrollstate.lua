local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Tilemap = require "draggin/tilemap"
local GameStateManager = require "draggin/gamestatemanager"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local ScrollState = {}

function ScrollState.new()

	local state = {}

	state.name = "ScrollState"

	local layers = {}
	local mainlayer

	local bg

	function state:init()

		bg = Tilemap.new("bg", viewport)
		layers[#layers+1] = bg.layer
	end

	function state:gotFocus()

		print(state.name.." got focus")
		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)

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
	end

	function state:lostFocus()
		state.scrollThread:stop()
		state.scrollThread = nil
	end


	return state
end

return ScrollState

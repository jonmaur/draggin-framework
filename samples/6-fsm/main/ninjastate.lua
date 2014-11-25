local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sprite = require "draggin/sprite"
local ActionMap = require "draggin/actionmap"
local TextBox = require "draggin/textbox"
local Ninja = require "ninja"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local ninjastate = {}

function ninjastate.new()

	local state = {}

	state.name = "NinjaState"

	local layers = {}
	local mainlayer

	local txt
	local ninja
	local ninjaThread

	local actions


	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		txt = TextBox.new("LiberationSansNarrow-Regular", 24)
		txt:setColor(1, 1, 1, 1)
		txt:setRect(virtualWidth/16, virtualHeight - virtualHeight/4, virtualWidth - virtualWidth/16, virtualHeight - virtualHeight/16)
		txt:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
		txt:setString('[space] jump, [enter] attack, [esc] quit')

		ninja = Ninja.new()


		-- action map
		actions = ActionMap.new()

		actions:addAction("quit", string.char(27))
		actions:addAction("jump", ' ', nil)
		actions:addAction("attack", 'b', nil)
		actions:addAction("attack", string.char(13), nil)

		print(state.name.." init() done.")
	end

	function state:gotFocus()

		print(state.name.." got focus")

		txt:insertIntoLayer(mainlayer)

		-- the ninja
		ninja:setLoc(virtualWidth/2, virtualHeight/2)
		mainlayer:insertProp(ninja)

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)

		local function ninjaFunc()
			while true do

				if actions:stateOf("quit") == "down" then
					os.exit()

				elseif actions:stateOf("jump") == "down" then
					ninja:tryJumpState()

				elseif actions:stateOf("attack") == "down" then
					ninja:tryAttackState()
				end

				ninja:update()
				actions:update()
				coroutine.yield()
			end
		end

		ninjaThread = MOAIThread.new()
		ninjaThread:run(ninjaFunc)
	end

	function state:lostFocus()
		print(state.name.." lost focus")
		mainlayer:removeProp(ninja)
		txt:removeFromLayer()

		ninjaThread:stop()
		ninjaThread = nil
	end


	return state
end

return ninjastate

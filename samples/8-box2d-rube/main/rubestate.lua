local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Tilemap = require "draggin/tilemap"
local GameStateManager = require "draggin/gamestatemanager"
local Physics = require "draggin/physics"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local floor = math.floor

local RubeState = {}

function RubeState.new()

	local state = {}

	state.name = "RubeState"

	local layers = {}
	local camera
	local mainlayer

	local bg
	local phys

	function state:init()

		camera = MOAICamera2D.new()

		bg = Tilemap.new("bg", viewport, camera)
		bg.prop:setLoc(-virtualWidth/8, -bg.mapHeightInPixels + (virtualHeight*1.89))
		bg.prop:setScl(0.06, 0.06)
		layers[#layers+1] = bg.layer

		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		mainlayer:setCamera(camera)
		layers[#layers+1] = mainlayer

		phys = Physics.new(nil, 1, mainlayer)
		phys:loadRubeJson("bluecar2")
	end

	function state:gotFocus()

		print(state.name.." got focus")
		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)

		local offsetX = (-virtualWidth / 2)
		local offsetY = (-virtualHeight / 2)

		local x = 0
		local y = 0
		--local z = 1/45
		local z = 1/45*4

		--z = (2 / virtualWidth) + 1


		offsetX = (-virtualWidth / 2) * z
		offsetY = (-virtualHeight / 2) * z

		-- update the player and get it's current position so we can move the camera
		-- floor these values because we don't do fractional pixels
		camera:setLoc(floor(x + offsetX), floor(y + offsetY))
		camera:setScl(z, z)

	end

	function state:lostFocus()
	end


	return state
end

return RubeState

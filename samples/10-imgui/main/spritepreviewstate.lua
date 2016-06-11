local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sprite = require "draggin/sprite"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local spritepreviewstate = {}

function spritepreviewstate.new()

	local state = {}

	state.name = "SpritePreviewState"

	local layers = {}
	local mainlayer

	local ninja
	local animThread
	local imguiThread

	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		ninja = Sprite.new("ninja")

		print(state.name.." init() done.")
	end

	function state:gotFocus()

		print(state.name.." got focus")

		-- the ninja sprite
		ninja:playAnimation("runRight")
		ninja:setLoc(virtualWidth/2, virtualHeight/2)
		mainlayer:insertProp(ninja)

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)


		-- animate the ninja
		local function animFunc()
			while true do
				ninja:playAnimation("runRight")
				Draggin:wait(3)
				ninja:playAnimation("jumpRight", 1, MOAITimer.PING_PONG)
				Draggin:wait(3)
			end
		end

		animThread = MOAIThread.new()
		animThread:run(animFunc)

		-- animate the ninja
		local function imguiFunc()
			local v = MOAIImVec2.new()
			
			while true do
				-- imgui test
				-- MOAIImGui.ShowTestWindow(true)
				MOAIImGui.Begin("Window Test", true, MOAIImGui.ImGuiWindowFlags_AlwaysHorizontalScrollbar + MOAIImGui.ImGuiWindowFlags_AlwaysVerticalScrollbar)
					v:set(200, 32)
					MOAIImGui.BeginChild(1)
						MOAIImGui.Text("Animation: "..tostring(ninja:getCurrentAnimationName()))
					MOAIImGui.EndChild()
					MOAIImGui.Text("Animation: "..tostring(ninja:getCurrentAnimationName()))
				MOAIImGui.End()

				coroutine.yield()
			end
		end

		imguiThread = MOAIThread.new()
		imguiThread:run(imguiFunc)
	end

	function state:lostFocus()
		print(state.name.." lost focus")
		mainlayer:removeProp(ninja)

		animThread:stop()
		animThread = nil

		imguiThread:stop()
		imguiThread = nil
	end


	return state
end

return spritepreviewstate

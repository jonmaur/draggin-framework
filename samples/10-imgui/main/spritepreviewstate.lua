local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sprite = require "draggin/sprite"
local ImGuiExt = require "draggin/imguiext"

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
	local imguiThread

	local ninja_animations

	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		ninja = Sprite.new("ninja")
		ninja_animations = {}

		for k, v in pairs(ninja.spriteData.curves) do
			table.insert(ninja_animations, k)
		end

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

		local function imguiFunc()

			local debug_open = true

			local animation_open = true
			local animation_item = 1
			local animation_selected = false
			local animation_speed = 1

			while true do

				-- main menu bar
				if MOAIImGui.BeginMainMenuBar() then
					if MOAIImGui.BeginMenu("File") then
						if MOAIImGui.MenuItem("Animation Preview") then
							animation_open = not animation_open
						end
						MOAIImGui.EndMenu()
					end
					if MOAIImGui.BeginMenu("Tools") then
						if MOAIImGui.MenuItem("Ninja Debug") then
							debug_open = not debug_open
						end
						MOAIImGui.EndMenu()
					end
					MOAIImGui.EndMainMenuBar()
				end

				-- debug window
				debug_open = ImGuiExt.window("ninja", ninja, debug_open)

				-- animation preview window
				if animation_open then
					_, animation_open = MOAIImGui.Begin("Animation Preview", animation_open)

						animation_selected, animation_item = MOAIImGui.Combo("animation", animation_item, ninja_animations)
						if animation_selected then
							ninja:playAnimation(ninja_animations[animation_item])
						end

						local changed = false
						changed, animation_speed = MOAIImGui.DragFloat("speed", animation_speed, 0.01, 0, 4, nil, nil)
						if changed then
							ninja.anim:setSpeed(animation_speed)
						end

					MOAIImGui.End()
				end

				coroutine.yield()
			end
		end

		imguiThread = MOAIThread.new()
		imguiThread:run(imguiFunc)
	end

	function state:lostFocus()
		print(state.name.." lost focus")
		mainlayer:removeProp(ninja)

		imguiThread:stop()
		imguiThread = nil
	end


	return state
end

return spritepreviewstate

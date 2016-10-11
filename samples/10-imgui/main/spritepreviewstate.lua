local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local SpriteManager = require "draggin/spritemanager"
local Sprite = require "draggin/sprite"
local ImGuiExt = require "draggin/imguiext"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local spritepreviewstate = {}

local col_grey = MOAIImGui.ColorConvertFloat4ToU32(0.4,0.4,0.4,1)
local col_lightgrey = MOAIImGui.ColorConvertFloat4ToU32(0.65,0.65,1,1)
local col_red = MOAIImGui.ColorConvertFloat4ToU32(0.6,0.2,0.2,1)
local col_green = MOAIImGui.ColorConvertFloat4ToU32(0.2,0.6,0.2,1)
local col_blue = MOAIImGui.ColorConvertFloat4ToU32(0.2,0.6,0.6,1)
local col_yellow = MOAIImGui.ColorConvertFloat4ToU32(0.6,0.6,0.2,1)

function spritepreviewstate.new()

	local state = {}

	state.name = "SpritePreviewState"

	local layers = {}
	local mainlayer

	local obj
	local imguiThread

	local obj_sprites = {"ninja", "players"}
	local obj_animations

	local debug_open = true
	local spritedata_open = true

	local animation_open = true
	local sprite_item = 1
	local sprite_selected = false
	local animation_item = 1
	local animation_selected = false
	local animation_speed = 1

	local show_bounds = true

	local function initSprite(name)

		if name then
			obj:setSpriteData(name)
		end

		obj_animations = {}

		animation_item = 1

		for k, v in pairs(obj.spriteData.curves) do
			table.insert(obj_animations, k)
		end
	end

	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		obj = Sprite.new("ninja")
		initSprite()

		print(state.name.." init() done.")
	end

	function state:gotFocus()

		print(state.name.." got focus")

		-- the obj sprite
		obj:playAnimation(obj_animations[1])
		obj:setLoc(virtualWidth/2, virtualHeight/2)
		mainlayer:insertProp(obj)

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)

		local function imguiFunc()

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
						if MOAIImGui.MenuItem("obj Debug") then
							debug_open = not debug_open
						end
						if MOAIImGui.MenuItem("sprite data") then
							spritedata_open = not spritedata_open
						end
						MOAIImGui.EndMenu()
					end
					MOAIImGui.EndMainMenuBar()
				end

				-- debug window
				debug_open = ImGuiExt.window("obj", obj, debug_open)

				-- sprite data window
				spritedata_open = ImGuiExt.window("spritedata", SpriteManager.getSpriteDataTable(), spritedata_open)

				-- animation preview window
				if animation_open then
					_, animation_open = MOAIImGui.Begin("Animation Preview", animation_open)

						-- local x, y = MOAIImGui.GetWindowPos()
						-- dl = MOAIImGui.GetWindowDrawList()
						-- dl:PushClipRectFullScreen()
						-- dl:AddCircle(x+100, y+200, 25)
						-- dl:AddCircle(20,200, 4)
						-- dl:AddCircle(175,100, 4)
						-- dl:AddCircle(200,320, 4)

						-- dl:AddLine(200, 200, 220, 220)
						-- dl:AddRect(310, 410, 310+20, 410+20)
						-- dl:AddRectFilled(320, 420, 320+20, 420+20)
						-- dl:AddRectFilledMultiColor(330, 430, 330+20, 430+20)

						-- dl:PathLineTo(10, 10)
						-- dl:PathBezierCurveTo(20,200, 175,100, 200,320)
						-- dl:PathLineTo(300, 10)
						-- dl:PathStroke()

						-- dl:PopClipRect()

						sprite_selected, sprite_item = MOAIImGui.Combo("sprite", sprite_item, obj_sprites)
						if sprite_selected then
							initSprite(obj_sprites[sprite_item])
						end

						animation_selected, animation_item = MOAIImGui.Combo("animation", animation_item, obj_animations)
						if animation_selected then
							obj:playAnimation(obj_animations[animation_item])
						end

						local changed = false
						changed, animation_speed = MOAIImGui.DragFloat("speed", animation_speed, 0.01, 0, 4, nil, nil)
						if changed then
							obj.anim:setSpeed(animation_speed)
						end

						_, show_bounds = MOAIImGui.Checkbox("bounds", show_bounds)
						if show_bounds then
							local x, y = obj:getLoc()
							local dl = MOAIImGui.GetWindowDrawList()
							dl:PushClipRectFullScreen()
							
							local r = obj.spriteData.bounds[obj_animations[animation_item]]
							dl:AddRect(x+r[1], y+r[2], x+r[3], y+r[4], col_red)
							
							dl:PopClipRect()
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
		mainlayer:removeProp(obj)

		imguiThread:stop()
		imguiThread = nil
	end


	return state
end

return spritepreviewstate

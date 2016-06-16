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
			local red = MOAIImVec4.new()
			red:set(1, 0, 0, 1)
			local checked = false
			local activebutton = 1
			
			while true do
				-- imgui test
				-- MOAIImGui.ShowTestWindow(true)
				MOAIImGui.Begin("Window Test", true, MOAIImGui.ImGuiWindowFlags_AlwaysHorizontalScrollbar + MOAIImGui.ImGuiWindowFlags_AlwaysVerticalScrollbar)
					v:set(200, 64)
					MOAIImGui.BeginChild(1, v)
						MOAIImGui.TextColored(red, "Animation: ")
						MOAIImGui.Text(tostring(ninja:getCurrentAnimationName()))
						MOAIImGui.TextDisabled("Disabled text. No point in using format strings here, construct the string in lua.")
					MOAIImGui.EndChild()
					MOAIImGui.TextWrapped("Wrapped text. No point in using format strings here, construct the string in lua.")
					MOAIImGui.TextUnformatted("Text with NULL (\0) characters. NULL's show up as \0, but that's ok.")
					MOAIImGui.Text("Animation: "..tostring(ninja:getCurrentAnimationName()))
					MOAIImGui.LabelText("Animation: ", tostring(ninja:getCurrentAnimationName()))
					MOAIImGui.Bullet()
					MOAIImGui.BulletText("Bullet Text")
					if MOAIImGui.Button("Press test") then
						print("button pressed")
					end
					if MOAIImGui.InvisibleButton("invisible id", v) then
						print("invisible button pressed")
					end
					if MOAIImGui.SmallButton("Small Press test") then
						print("small button pressed")
					end
					
					checked = MOAIImGui.Checkbox("Checkbox", checked)
					if checked then
						MOAIImGui.Text("Checked! ")
					end
					activebutton = MOAIImGui.RadioButton("Radio 1", activebutton, 1)
					activebutton = MOAIImGui.RadioButton("Radio 2", activebutton, 2)
					activebutton = MOAIImGui.RadioButton("Radio 3", activebutton, 3)
					activebutton = MOAIImGui.RadioButton("Radio 4", activebutton, 4)
					MOAIImGui.Text("active! "..tostring(activebutton))
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

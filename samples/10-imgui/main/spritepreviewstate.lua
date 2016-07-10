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
			local treeopen = true
			local red = MOAIImVec4.new()
			red:set(1, 0, 0, 1)
			local checked = false
			local activebutton = 1

			local comboitem = 1
			local comboitems = {"one", "two", "three", "four", "five"}

			local color = MOAIImVec4.new()
			color:set(1,1,0,1)

			local progress = 0
			local drag2 = MOAIImVec2.new()
			local drag3 = MOAIImVec4.new()
			local drag4 = MOAIImVec4.new()
			local min = 0
			local max = 100

			local idrag = 1
			local idrag2 = MOAIImVec2.new()
			local idrag3 = MOAIImVec4.new()
			local idrag4 = MOAIImVec4.new()
			local imin = 0
			local imax = 100

			local name = ""
			local namelbl = ""

			local f = 0
			local inputf2 = MOAIImVec2.new()
			local inputf3 = MOAIImVec4.new()
			local inputf4 = MOAIImVec4.new()

			local num = 0
			local inputnum2 = MOAIImVec2.new()
			local inputnum3 = MOAIImVec4.new()
			local inputnum4 = MOAIImVec4.new()

			local slide = 1
			local slide2 = MOAIImVec2.new()
			local slide3 = MOAIImVec4.new()
			local slide4 = MOAIImVec4.new()

			local slideangle = 0

			local islide = 1
			local islide2 = MOAIImVec2.new()
			local islide3 = MOAIImVec4.new()
			local islide4 = MOAIImVec4.new()
			local vslidesize = MOAIImVec2.new()
			vslidesize:set(32, 150)

			local showheader = true
			
			while true do
				-- imgui test
				-- MOAIImGui.ShowTestWindow(true)
				MOAIImGui.Begin("Window Test", true, MOAIImGui.WindowFlags_AlwaysHorizontalScrollbar + MOAIImGui.WindowFlags_AlwaysVerticalScrollbar)
					v:set(200, 64)
					MOAIImGui.BeginChild(1, v, true)
						MOAIImGui.TextColored(red, "Animation: ")
						MOAIImGui.TreePush()
						MOAIImGui.Text(tostring(ninja:getCurrentAnimationName()))
						MOAIImGui.TreePop()
						MOAIImGui.TextDisabled("Disabled text. No point in using format strings here, construct the string in lua.")
					MOAIImGui.EndChild()
					MOAIImGui.SetNextTreeNodeOpen(treeopen, MOAIImGui.SetCond_FirstUseEver)
					treeopen = MOAIImGui.TreeNode("id1", "Text")
					if treeopen then
						MOAIImGui.TextUnformatted("Text with NULL (\0) characters. NULL's show up as \0, but that's ok.")
						MOAIImGui.LabelText("Animation: ", tostring(ninja:getCurrentAnimationName()))
						MOAIImGui.Bullet()
						MOAIImGui.BulletText("Bullet Text")
						MOAIImGui.TreePop()
					end

					MOAIImGui.Separator()
					local spacing = MOAIImGui.GetTreeNodeToLabelSpacing()
					MOAIImGui.Text("GetTreeNodeToLabelSpacing, "..tostring(spacing))
					MOAIImGui.Separator()
					
					if MOAIImGui.TreeNode("id2", "Buttons") then
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

						MOAIImGui.TreePop()
					end

					if MOAIImGui.TreeNode("Drag Numbers") then
						comboitem = MOAIImGui.Combo("Numbers", comboitem, comboitems)
						MOAIImGui.Text("Combo: "..tostring(comboitem)..", "..comboitems[comboitem])

						MOAIImGui.ColorButton(color, false, true)
						MOAIImGui.ColorEdit3("Button Color 3", color)
						MOAIImGui.ColorEdit4("Button Color 4", color)

						progress = MOAIImGui.DragFloat("progress", progress, 0.01, 0, 1, nil, nil)
						MOAIImGui.ProgressBar(progress)

						MOAIImGui.DragFloat2("drag2", drag2, 0.01, 0, 1, nil, nil)
						MOAIImGui.DragFloat3("drag3", drag3, 0.01, 0, 1, nil, nil)
						MOAIImGui.DragFloat4("drag4", drag4, 0.01, 0, 1, nil, nil)
						min, max = MOAIImGui.DragFloatRange2("Range", min, max)

						idrag = MOAIImGui.DragInt("idrag", idrag, 1, 0, 100, nil, nil)
						MOAIImGui.DragInt2("idrag2", idrag2, 1, 0, 100, nil, nil)
						MOAIImGui.DragInt3("idrag3", idrag3, 1, 0, 100, nil, nil)
						MOAIImGui.DragInt4("idrag4", idrag4, 1, 0, 100, nil, nil)
						imin, imax = MOAIImGui.DragIntRange2("iRange", imin, imax)

						MOAIImGui.TreePop()
					end

					if MOAIImGui.TreeNode("Input Text") then
						local enter
						name, enter = MOAIImGui.InputText("What is your name?", name, 12)

						if enter then
							namelbl = name
						end

						MOAIImGui.Text(namelbl)

						MOAIImGui.TreePop()
					end

					if MOAIImGui.TreeNode("Slider Numbers") then
						
						MOAIImGui.Indent()
						MOAIImGui.BeginGroup()
						slide = MOAIImGui.SliderFloat("slider", slide, 0, 1, nil, nil)
						MOAIImGui.SliderFloat2("slide2", slide2, 0, 1, nil, nil)
						MOAIImGui.Indent()
						MOAIImGui.SliderFloat3("slide3", slide3, 0, 1, nil, nil)
						MOAIImGui.SliderFloat4("slide4", slide4, 0, 1, nil, nil)
						MOAIImGui.EndGroup()
						MOAIImGui.Unindent()

						MOAIImGui.Spacing()
						slideangle = MOAIImGui.SliderAngle("slider angle", slideangle, 0, 90)
						MOAIImGui.Spacing()

						islide = MOAIImGui.SliderInt("islide", islide, 0, 100, nil, nil)
						MOAIImGui.SliderInt2("islide2", islide2, 0, 100, nil, nil)
						MOAIImGui.Dummy(islide2)
						MOAIImGui.SliderInt3("islide3", islide3, 0, 100, nil, nil)
						MOAIImGui.SliderInt4("islide4", islide4, 0, 100, nil, nil)

						slide = MOAIImGui.VSliderFloat("vslider", vslidesize, slide, 0, 1, nil, nil)
						MOAIImGui.SameLine()
						MOAIImGui.NewLine()
						MOAIImGui.SameLine()
						islide = MOAIImGui.VSliderInt("vislide", vslidesize, islide, 0, 100, nil, nil)

						MOAIImGui.TreePop()
					end

					local isopen
					showheader, isopen = MOAIImGui.CollapsingHeader("Input Numbers", showheader)
					if isopen then
						f = MOAIImGui.InputFloat("InputFloat", f)
						MOAIImGui.InputFloat2("InputFloat2", inputf2)
						MOAIImGui.InputFloat3("InputFloat3", inputf3)
						MOAIImGui.InputFloat4("InputFloat4", inputf4)

						MOAIImGui.Spacing()
						num = MOAIImGui.InputInt("InputInt", num)
						MOAIImGui.InputInt2("InputInt2", inputnum2)
						MOAIImGui.InputInt3("InputInt3", inputnum3)
						MOAIImGui.InputInt4("InputInt4", inputnum4)

						local posx, posy = MOAIImGui.GetCursorPos()
						MOAIImGui.Text("cursor pos: "..tostring(posx)..", "..tostring(posy))
						posx = MOAIImGui.GetCursorPosX()
						posy = MOAIImGui.GetCursorPosY()
						MOAIImGui.Text("cursor pos: "..tostring(posx)..", "..tostring(posy))

						local cpos = MOAIImVec2.new()
						cpos:set(posx, posy)
						MOAIImGui.SetCursorPos(cpos)
						MOAIImGui.Text("XXXXX")

						MOAIImGui.SetCursorPosX(200)
						MOAIImGui.Text("XXXXX")
					end

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

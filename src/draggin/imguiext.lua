--[[
Copyright (c) 2014 Jon Maur

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local ImGuiExt = {}

local grey = MOAIImVec4.new()
grey:set(0.4,0.4,0.4,1)

local lightgrey = MOAIImVec4.new()
lightgrey:set(0.65,0.65,1,1)

local red = MOAIImVec4.new()
red:set(0.6,0.2,0.2,1)

local green = MOAIImVec4.new()
green:set(0.2,0.6,0.2,1)

local blue = MOAIImVec4.new()
blue:set(0.2,0.6,0.6,1)

local yellow = MOAIImVec4.new()
yellow:set(0.6,0.6,0.2,1)

-- take anything and make an ImGui widget for it
function ImGuiExt.tablewidgets(lable, obj, hidetypes)
	local ret

	hidetypes = hidetypes or {}

	if type(obj) == "table" and not hidetypes["table"] then
		local open = MOAIImGui.TreeNode(tostring(lable))
		MOAIImGui.SameLine()
		MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(tostring(obj)))
		MOAIImGui.TextColored(blue, tostring(obj))
		if open then
			local count = 0
			for k, v in pairs(obj) do
				count = count + 1
				ImGuiExt.tablewidgets(k, v, hidetypes)
			end
			if count == 0 then
				MOAIImGui.TextColored(red, "{empty}")
			end
			MOAIImGui.TreePop()
		end
	elseif type(obj) == "userdata" and not hidetypes["userdata"] then
		local open = MOAIImGui.TreeNode(tostring(lable))
		MOAIImGui.SameLine()
		MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(tostring(obj)))
		MOAIImGui.TextColored(green, tostring(obj))
		if open then
			if obj.getClassTable then
				local open = MOAIImGui.TreeNode(tostring(lable).." class")
				MOAIImGui.SameLine()
				MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(tostring(obj:getClassTable())))
				MOAIImGui.TextColored(blue, tostring(obj:getClassTable()))
				if open then
					local count = 0
					for k, v in pairs(obj:getClassTable()) do
						count = count + 1
						ImGuiExt.tablewidgets(k, v, hidetypes)
					end
					if count == 0 then
						MOAIImGui.TextColored(red, "{empty}")
					end
					MOAIImGui.TreePop()
				end
			end
			if obj.getMemberTable then
				local open = MOAIImGui.TreeNode(tostring(lable).." member")
				MOAIImGui.SameLine()
				MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(tostring(obj:getMemberTable())))
				MOAIImGui.TextColored(blue, tostring(obj:getMemberTable()))
				if open then
					local count = 0
					for k, v in pairs(obj:getMemberTable()) do
						count = count + 1
						ImGuiExt.tablewidgets(k, v, hidetypes)
					end
					if count == 0 then
						MOAIImGui.TextColored(red, "{empty}")
					end
					MOAIImGui.TreePop()
				end
			end
			if obj.getRefTable then
				local open = MOAIImGui.TreeNode(tostring(lable).." ref")
				MOAIImGui.SameLine()
				MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(tostring(obj:getRefTable())))
				MOAIImGui.TextColored(blue, tostring(obj:getRefTable()))
				if open then
					local count = 0
					for k, v in pairs(obj:getRefTable()) do
						count = count + 1
						ImGuiExt.tablewidgets(k, v, hidetypes)
					end
					if count == 0 then
						MOAIImGui.TextColored(red, "{empty}")
					end
					MOAIImGui.TreePop()
				end
			end

			MOAIImGui.TreePop()
		end
	elseif type(obj) == "function" and not hidetypes["function"] then
		
		local info = debug.getinfo(obj)

		MOAIImGui.PushStyleColor(MOAIImGui.Col_Text, lightgrey);
		local open = MOAIImGui.TreeNode(tostring(lable))
		if info.what == "Lua" then
			if MOAIImGui.BeginPopupContextItem(tostring(lable)) then
				if MOAIImGui.Selectable("Open script") then
					os.execute("START "..info.short_src)
				end
				MOAIImGui.EndPopup()
			end
		end
		MOAIImGui.PopStyleColor();
		MOAIImGui.SameLine()
		MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(tostring(obj)))
		MOAIImGui.TextColored(yellow, tostring(obj))
		if open then
			local count = 0
			for k, v in pairs(info) do
				count = count + 1
				ImGuiExt.tablewidgets(k, v, hidetypes)
			end
			if count == 0 then
				MOAIImGui.TextColored(red, "{empty}")
			end
			MOAIImGui.TreePop()
		end
	elseif not hidetypes[type(obj)] then
		MOAIImGui.PushStyleColor(MOAIImGui.Col_Text, lightgrey);
		if type(obj) == "string" and not hidetypes["string"] then
			MOAIImGui.BulletText(tostring(lable)..' = "'..tostring(obj)..'"')
		else
			MOAIImGui.BulletText(tostring(lable).." = "..tostring(obj))
		end
		MOAIImGui.PopStyleColor();
		MOAIImGui.SameLine()
		MOAIImGui.SetCursorPosX(MOAIImGui.GetWindowContentRegionWidth() - MOAIImGui.CalcTextSize(type(obj)))
		MOAIImGui.TextColored(blue, type(obj))
	end
end


function ImGuiExt.window(lable, obj, open, hidetypes)
	if type(open) == "nil" then
		open = true
	end

	if open then
		_, open = MOAIImGui.Begin(lable, open)
		if open then
			ImGuiExt.tablewidgets(lable, obj, hidetypes)
		end
		MOAIImGui.End()
	end

	return open
end

return ImGuiExt

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
grey:set(0.5,0.5,0.5,1)

-- take anything and make an ImGui widget for it
function ImGuiExt.tablewidgets(lable, obj)
	local ret

	if type(obj) == "table" then
		local open = MOAIImGui.TreeNode(tostring(lable))
		MOAIImGui.SameLine()
		MOAIImGui.TextColored(grey, tostring(obj))
		if open then
			local count = 0
			for k, v in pairs(obj) do
				count = count + 1
				ImGuiExt.tablewidgets(k, v)
			end
			if count == 0 then
				MOAIImGui.TextColored(grey, "<empty>")
			end
			MOAIImGui.TreePop()
		end
	elseif type(obj) == "userdata" then
		local open = MOAIImGui.TreeNode(tostring(lable))
		MOAIImGui.SameLine()
		MOAIImGui.TextColored(grey, tostring(obj))
		if open then
			-- todo text colored right here
			if obj.getClassTable then
				local open = MOAIImGui.TreeNode(tostring(lable).." class")
				MOAIImGui.SameLine()
				MOAIImGui.TextColored(grey, tostring(obj:getClassTable()))
				if open then
					local count = 0
					for k, v in pairs(obj:getClassTable()) do
						count = count + 1
						ImGuiExt.tablewidgets(k, v)
					end
					if count == 0 then
						MOAIImGui.TextColored(grey, "<empty>")
					end
					MOAIImGui.TreePop()
				end
			end
			if obj.getMemberTable then
				local open = MOAIImGui.TreeNode(tostring(lable).." member")
				MOAIImGui.SameLine()
				MOAIImGui.TextColored(grey, tostring(obj:getMemberTable()))
				if open then
					local count = 0
					for k, v in pairs(obj:getMemberTable()) do
						count = count + 1
						ImGuiExt.tablewidgets(k, v)
					end
					if count == 0 then
						MOAIImGui.TextColored(grey, "<empty>")
					end
					MOAIImGui.TreePop()
				end
			end
			if obj.getRefTable then
				local open = MOAIImGui.TreeNode(tostring(lable).." ref")
				MOAIImGui.SameLine()
				MOAIImGui.TextColored(grey, tostring(obj:getRefTable()))
				if open then
					local count = 0
					for k, v in pairs(obj:getRefTable()) do
						count = count + 1
						ImGuiExt.tablewidgets(k, v)
					end
					if count == 0 then
						MOAIImGui.TextColored(grey, "<empty>")
					end
					MOAIImGui.TreePop()
				end
			end

			MOAIImGui.TreePop()
		end
	elseif type(obj) == "function" then
		MOAIImGui.Text(tostring(lable)..":")
		MOAIImGui.SameLine()
		MOAIImGui.TextColored(grey, tostring(obj))
	else
		MOAIImGui.Text(tostring(lable)..": "..tostring(obj))
		MOAIImGui.SameLine()
		MOAIImGui.TextColored(grey, "<"..type(obj)..">")
	end
end


function ImGuiExt.window(lable, obj, open)
	if type(open) == "nil" then
		open = true
	end

	if open then
		_, open = MOAIImGui.Begin(lable, open)
		if open then
			ImGuiExt.tablewidgets(lable, obj)
		end
		MOAIImGui.End()
	end

	return open
end

return ImGuiExt

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

local TableExt = require("draggin/tableext")

local SaveSystem = {}

--- Create a new SaveSystem.
-- Wraps saving and loading of a lua table. You probably should keep it simple
-- and avoid MOAI objects, I never even tested saving those. When loading, you
-- can optionally send a table full of defaults.
-- @param _filename the name of the save file. or "savedata.lua" if it's nil
-- @return the new SaveSystem instance
function SaveSystem.new(_filename)
	_filename = _filename or "savedata.lua"
	local sys = {}
	local data = {}

	local serializer = MOAISerializer.new()

	--- Save the current table.
	-- Always uses the filename.
	function sys:save()
		serializer:serializeToFile(_filename, data)
		-- serializer:exportToFile(_filename)
	end

	--- Load the save table.
	-- Copies the _default, then overrites values with the ones loaded from the
	-- file.
	-- @param _default a table with default values.
	-- @return a reference to the data table, KEEP THIS! It's the table that gets saved when you call save()
	function sys:load(_default)
		-- load using defaults
		-- keep in mind that this can prabably only deal with basic types and MOAIObjects
		data = TableExt.deepcopy(_default)

		print("save load", data.sound, _default.sound)

		if MOAIFileSystem.checkFileExists(_filename) then

			local filedata = dofile(_filename)
			TableExt.merge(data, filedata)
		end

		print("save load", data.sound, _default.sound)
		-- save it out right away
		self:save()

		-- return a reference to the table, any changes should be saved later
		return data
	end

	return sys
end

return SaveSystem

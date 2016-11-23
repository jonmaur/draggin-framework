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

local random = math.random

--- A group of functions for tables that aren't in the table library.
local TableExt = {}

--- Is the table empty.
-- @return true if the table is empty, false if it's not
function TableExt.empty(t)
	for _, _ in pairs(t) do
		return false
	end
	return true
end

--- Creates a deep copy of the table.
-- Doesn't handle circular references, but thinks like tables as keys "should" work.
-- @param _orig the lua object to copy
-- @return a copy of the _orig lua object
local function deepcopy(_orig)
	--print(_orig)
	local copy
	if type(_orig) == 'table' then
		copy = {}
		for orig_key, orig_value in next, _orig, nil do
			--print(orig_key, orig_value)
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(_orig)))
	else -- number, string, boolean, etc
		copy = _orig
	end
	--print(copy)
	return copy
end
TableExt.deepcopy = deepcopy

--- Print the contents of the table.
-- @param t the table to print
-- @param _indent the number of leading tabs to print
local function printtable(t, _indent)
	_indent = _indent or 1

	local tabs = ""
	for i = 1, _indent do
		tabs = tabs.."\t"
	end

	for k, v in pairs(t) do
		print(tabs.."["..tostring(k).."] = ", tostring(v))
		if type(v) == "table" then
			printtable(v, _indent + 1)
		end
	end
end
TableExt.print = printtable

--- Print the contents of the table to a string
-- @param t the table to print out to a string
-- @param _indent, optional, the number of leading tabs to print
-- @param _str, optional, the _str used in recursion
local function tabletostring(t, _indent, _str)
	_indent = _indent or 1
	_str = _str or ""

	local tabs = ""
	for i = 1, _indent do
		tabs = tabs.." "
	end

	for k, v in pairs(t) do
		_str = _str..tabs.."["..tostring(k).."] = "..tostring(v).."\n"
		if type(v) == "table" then
			_str = _str..tabletostring(v, _indent + 1, _str)
		end
	end

	return _str
end
TableExt.tostring = tabletostring

--- Merge tables in place.
-- @param t1 the table to accept the merge with t2
-- @param t2 the table to merge into t1, remains unchanged
-- @return t1 after merge
local function merge(t1, t2)
	for k,v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				merge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end
TableExt.merge = merge

--- Grab a random entry from the table. Table must be an array.
-- @param t the table to choose from
local function randomentry(t)
	return t[random(1, #t)]
end
TableExt.randomentry = randomentry

return TableExt

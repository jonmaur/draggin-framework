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

local SpriteManager = {}
local spriteData = {}

-- TODO: Figure out a better way to do this so filtering can be set per sprite, maybe
local defultFilter = MOAITexture.GL_LINEAR_MIPMAP_LINEAR

function SpriteManager.setDefaultFilter(_filter)
	defultFilter = _filter
end

--- Get the entire sprite data table.
-- BE CAREFUL! This table should really be read only.
-- Usefull for queries and tracking.
function SpriteManager.getSpriteDataTable()
	return spriteData
end

--- Get sprite data.
-- Keeps track of assets so you only load them once.
-- @param _strSpriteData the name of the sprite data to get.
-- @return the sprite data
function SpriteManager.getSpriteData(_strSpriteData)

	assert(type(_strSpriteData) == "string", "_strSpriteData type is "..type(_strSpriteData))

	local data


	if spriteData[_strSpriteData] == nil then
		-- load the sheet
		print("Creating new spritesheet:", _strSpriteData, defultFilter)

		data = dofile("res/sprites/".._strSpriteData..".lua")
		spriteData[_strSpriteData] = data

		data.name = _strSpriteData
		data.texture:setFilter(defultFilter)

	else
		data = spriteData[_strSpriteData]
	end

	return data
end

--- Clear the sprite data from the SpriteManager.
-- it doesn't matter if there are sprites still using it, lua will gc it later
-- BUT this does mean the sprite data will be re-loaded if asked for again, regardless of
-- whether or not some other sprite is using the same data
-- @param _strSpriteData the name of the sprite data to clear from the SpriteManager
function SpriteManager.clearSpriteData(_strSpriteData)
	spriteData[_strSpriteData] = nil
end


return SpriteManager

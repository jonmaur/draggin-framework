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


local Draggin = require "draggin/draggin"
local Display = require "draggin/display"

local TileMap = {}
local count = {}


--- Create a new TileMap instance.
-- Sets up the TileMap for proper rendering using the bleed edge technique.
-- @param _name the name of the TileMap to load
-- @param _viewport optional, the viewport to use for rendering
-- @param _camera optional, the camera to use for rendering
-- @param _xParallax optional, the x scrolling scale
-- @param _yParallax optional, the y scrolling scale
-- @return the new TileMap instance
function TileMap.new(_name, _viewport, _camera, _xParallax, _yParallax)

	local tilemap = {}

	if (count[_name] == nil) then
		count[_name] = 1
	else
		count[_name] = count[_name] + 1
	end

	local data = loadfile("res/tilemaps/".._name..".lua")()

	local bleedWidth = data.tilesetWidth--/data.tileWidth * (data.tileWidth+2)
	local bleedHeight = data.tilesetHeight--/data.tileHeight * (data.tileHeight+2)

	local mapdata = data.data

	local grid = MOAIGrid.new()

	tilemap.grid = grid

	grid:setSize(data.mapWidthInTiles, data.mapHeightInTiles, data.tileWidth, data.tileHeight)

	for y = 1, data.mapHeightInTiles do

		local row = {}
		for x = 1, data.mapWidthInTiles do
			row[x] = mapdata[((y-1)*data.mapWidthInTiles + (x-1))+1]
			if row[x] == 1 then
				row[x] = 0
			end
		end

		grid:setRow(y, unpack(row))
	end

	local tileDeck = MOAITileDeck2D.new()
	tilemap.tileDeck = tileDeck
	local tex = MOAITexture.new()
	tex:load("res/tilemaps/"..data.tileset)
	tex:setFilter(MOAITexture.GL_NEAREST)
	tileDeck:setTexture(tex)
	tileDeck:setSize(data.tilesetWidth/(data.tileWidth+2), data.tilesetHeight/(data.tileHeight+2),
		(data.tileWidth+2)/bleedWidth, (data.tileHeight+2)/bleedHeight,
		1/bleedWidth, 1/bleedHeight,
		(data.tileWidth)/bleedWidth, (data.tileHeight)/bleedHeight)
	-- NOTE: this is the magic that makes the tiles render properly when you are trying to do the origin at top left
	tileDeck:setUVRect(-0.5, 0.5, 0.5, -0.5)

	-- if there's a viewport then go ahead and make some layers for this tilemap and put a prop in them
	if _viewport then

		print("tilemap has a viewport", _name)

		local virtualWidth = Display.virtualWidth
		local virtualHeight = Display.virtualHeight

		local prop = MOAIProp2D.new()
		tilemap.prop = prop
		prop:setDeck(tileDeck)
		prop:setGrid(grid)
		prop:setColor(1, 1, 1, 1)
		prop:setLoc(0, 0)


		local layer = MOAILayer2D.new()
		layer:setViewport(_viewport)


		if _camera then
			layer:setCamera(_camera)
		else
			layer:setCamera(MOAICamera2D.new())
		end

		_xParallax = _xParallax or 1
		_yParallax = _yParallax or 1
		layer:setParallax(_xParallax, _yParallax)

		layer:insertProp(prop)
		prop:setBlendMode(MOAIProp.BLEND_NORMAL)

		tilemap.layer = layer
	end

	return tilemap
end

return TileMap

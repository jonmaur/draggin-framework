#!/usr/bin/python

# Copyright (c) 2014 Jon Maur

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


################################################################
# tilemapcompiler.py
# Generates tilemaps for use with MOAI with Draggin.

from PIL import Image
import sys
import math
from math import ceil, log
from fnmatch import fnmatch
import os
import os.path


# matches anything in the list
def fnmatchList(_name, _filters):

	for filter in _filters:
		if fnmatch(_name, filter):
			# found one match so get out of here
			return True

	# no matches
	return False


# loop through all the params and grab the image filenames
def gatherFiles(_sequence, _filters):

	print "Gathering filenames..."
	global outFilename

	filenames = []

	for i in _sequence:

		if os.path.isdir(i):
			print("\t"+i+":")
			os.listdir(i)
			outFilename = i
			print "outFilename: "+outFilename
			for root, dirs, files in os.walk(i):
				for name in files:
					if fnmatchList(name , _filters):
						filenames.append(os.path.join(i, name))
						print("\t\t"+name)
						#print getAnimationAndFrameFromFilename(name)
		else:
			if fnmatchList(i , _filters):
				filenames.append(i)
				#print("\t"+i)
				#print getAnimationAndFrameFromFilename(i)
	return filenames


class Tile:
	def __init__(self):
		self.image = None

class TileMap:
	def __init__(self, _imgFile, _tileWidth, _tileHeight):

		# open the image and convert it
		self.mapImage = Image.open(_imgFile)
		self.mapImage.draft("RGBA", self.mapImage.size)
		self.mapImage = self.mapImage.convert("RGBA")

		# tile size
		self.tileWidth = _tileWidth
		self.tileHeight = _tileHeight

		# the array of tiles
		self.tiles = []

		self.mapWidthInTiles = self.mapImage.size[0] / self.tileWidth
		self.mapHeightInTiles = self.mapImage.size[1] / self.tileHeight

		# the map data, an array of tile indices
		self.mapData = []

		# make a blank tile for number 0
		blankTile = Image.new("RGBA", (self.tileWidth, self.tileHeight), (0,0,0,0))
		self.tiles.append(blankTile)

		for y in range(self.mapHeightInTiles):
			for x in range(self.mapWidthInTiles):
				box = self.tileWidth * x, self.tileHeight * y, self.tileWidth * (x+1), self.tileHeight * (y+1)
				tile = self.mapImage.crop(box)

				self.mapData.append(self.findTile(tile))

	# look for the tile in the list of tiles, if not found then add it
	def findTile(self, tile):
		i = 0
		tileStr = tile.tobytes()
		for t in self.tiles:
			if t.tobytes() == tileStr:
				return i
			i += 1

		self.tiles.append(tile)
		return i


	def saveMoaiLua(self, outFilename):
		print "Num tiles: ", len(self.tiles)
		#print "MapData: ", self.mapData

		# this equation totally falls apart for 3, so I'll just special case that
		if len(self.tiles) != 3:
			resultWidth = int(math.ceil(math.sqrt(len(self.tiles))) * (self.tileWidth+2))
			resultHeight = int(math.ceil(math.sqrt(len(self.tiles))) * (self.tileHeight+2))
		else:
			resultWidth = 2 * (self.tileWidth+2)
			resultHeight = 2 * (self.tileHeight+2)

		tilesetImg = Image.new("RGBA", (resultWidth, resultHeight))

		x = 0
		y = 0
		offsetX = 0
		offsetY = 0
		rowX = 0 #tilesetImg.size[0]
		rowY = 0 #tilesetImg.size[1]

		for t in self.tiles:
			offsetX = ((self.tileWidth+2) - t.size[0]) / 2
			offsetY = ((self.tileHeight+2) - t.size[1]) / 2

			x = rowX + offsetX
			y = rowY + offsetY


			# super cheesy way to "bleed" the tile out
			tilesetImg.paste(t, (x-1, y-1))
			tilesetImg.paste(t, (x+1, y+1))
			tilesetImg.paste(t, (x-1, y+1))
			tilesetImg.paste(t, (x+1, y-1))

			tilesetImg.paste(t, (x-1, y))
			tilesetImg.paste(t, (x+1, y))
			tilesetImg.paste(t, (x, y+1))
			tilesetImg.paste(t, (x, y-1))

			# finally paste it in
			tilesetImg.paste(t, (x, y))


			rowX = rowX + (self.tileWidth+2)
			if rowX > tilesetImg.size[0] - (self.tileWidth+2):
				rowX = 0
				rowY = rowY + (self.tileHeight+2)


		print("Saving: "+outFilename+"_tileset.png")
		tilesetImg.save(outFilename+"_tileset.png")

		# write out the .lua file
		luaFile = open(outFilename+".lua", "w")
		luaFile.write('-- Generated by tilemapcompiler.py for Moai\n\n')
		luaFile.write('return {\n')
		luaFile.write('\ttileset = "'+str(os.path.basename(outFilename))+'_tileset.png",\n')
		luaFile.write('\ttilesetWidth = '+str(tilesetImg.size[0])+',\n')
		luaFile.write('\ttilesetHeight = '+str(tilesetImg.size[1])+',\n')

		luaFile.write('\tmapWidthInTiles = '+str(self.mapWidthInTiles)+',\n')
		luaFile.write('\tmapHeightInTiles = '+str(self.mapHeightInTiles)+',\n')
		luaFile.write('\ttileWidth = '+str(self.tileWidth)+',\n')
		luaFile.write('\ttileHeight = '+str(self.tileHeight)+',\n')
		luaFile.write('\tdata = {')
		for y in range(self.mapHeightInTiles):
			luaFile.write('\n\t\t')
			for x in range(self.mapWidthInTiles):
				luaFile.write(str(self.mapData[y*self.mapWidthInTiles + x]+1)+', ')
		luaFile.write('\n\t}\n')
		luaFile.write('}\n')
		print("Saving: "+outFilename+".lua")


# run the code here if it's not a module
if __name__ == "__main__":
	print("Bucket Tilemap Compiler:")

	if (len(sys.argv) == 1):
		print("No arguments found.")
		print("Commandline usage: tilemapcompiler [space separated list of files and/or folders]")
	else:
		imageFilenames = gatherFiles(sys.argv[1:], ("*.png", "*.bmp"))

	tm = TileMap(imageFilenames[0], 16, 16)
	tm.saveMoaiLua(os.path.splitext(imageFilenames[0])[0])

	print "Done."

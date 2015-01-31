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


from PIL import Image
import rect.rect as Rect
import rect.packer as Packer
import sys
import math
from math import ceil, log
from fnmatch import fnmatch
import os
import os.path
import re
from PIL import ImageChops
import easygui


FRAME_DURATION = (1.0/15.0)*1000.0
PADDING = 4
MIN_SHEET_SIZE = 64
MAX_SHEET_SIZE = 2048

# Globals
outFilename = "sprite"


class Frame:
	def __init__(self):
		global FRAME_DURATION
		self.duration = FRAME_DURATION
		self.u = 0
		self.v = 0
		self.w = 0
		self.h = 0
		self.cropOffset = [0, 0]
		self.image = None
		self.croppedImage = None
		self.imageName = ""

	def createCroppedImage(self):
		r, g, b, a = self.image.split()
	 	x1 = 0
	 	y1 = 0
	 	x2 = 1
	 	y2 = 1
	 	if a.getbbox() != None:
	 		x1, y1, x2, y2 = a.getbbox()
	 	self.croppedImage = self.image.crop((x1, y1, x2, y2))
	 	self.croppedImage.load()
	 	self.cropOffset[0] = x1
	 	self.cropOffset[1] = y1


	def setImage(self, _img):
		self.image = _img


class Animation:
	def __init__(self):
		self.frames = list()
		self.length = 0
		self.scale = 1
		self.refPoint = [0, 0]


class Success( Exception ):
    """
    Used to break out of a nested loop
    """
    pass

# function defs #####################################################

def log2(n):
    """
    return the log base 2 of n
    """
    return log(n)/log(2)


def pow2( start, stop ):
    """
    generate the powers of 2 in sequence
    from 2^start till 2^stop
    """
    while start <= stop:
      yield pow(2,start)
      start += 1


# compares 2 images
def compareImages(_img1, _img2):
    return ImageChops.difference(_img1, _img2).getbbox() is None


# returns the animation name and frame number from a filename
# (animation, frame)
def getAnimationAndFrameFromFilename(_filename):

	animation = ""
	frame = 0
	filename = os.path.basename(_filename)

	m = re.match(r"([A-Za-z0-9]*)(?:[_\-\.]*)(\d+)", filename)
	# did we fine something like "walking_001.png"
	if m:
		animation = m.group(1)
		frame = int(m.group(2))
	else:
		m = re.match(r"(\w+)", filename)
		animation = m.group(1)
		frame = 1

	# this is a case where the filenames are only numbers, 1.png 2.png... so make the animation name the same as the sprite
	if (not animation):
		animation = os.path.basename(os.path.dirname(_filename))

	return (animation, frame)


# compare function that uses animation name and frame numbers from the
# filenames
def imageFilenameCmp(a, b):
	animA, frameA = getAnimationAndFrameFromFilename(str(a))
	animB, frameB = getAnimationAndFrameFromFilename(str(b))

	if (animA == animB):
		# I don't really care about the == case
		if (frameA < frameB):
			return -1
		else:
			return 1
	if (animA < animB):
		return -1

	return 1


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

# is there only one non-zero alpha pixel in this image?
def hasOnlyOnePixel(_img):
	imageW = _img.size[0]
	imageH = _img.size[1]
	pixels = _img.getdata()

	numPixels = 0

	for y in range(0, imageH):
		for x in range(0, imageW):
			# non-zero alpha?
			if pixels[y*imageW + x][3] != 0:
				numPixels += 1

				if numPixels > 1:
					return False

	if numPixels == 1:
		return True

	return False


class Sprite:

	def __init__(self):
		self.animations = dict()
		self.allFrames = dict()
		#self.packedRects
		self.sheetSize = [0, 0]

	def importImages(self, _imageFiles):

		global FRAME_DURATION

		print "Importing images..."
		# Sort all the images by animation and frame numbers
		_imageFiles.sort(imageFilenameCmp)


		# Start creating the animation objects
		self.animations = dict()

		for filename in _imageFiles:
			#print "filename in _imageFiles", filename
			filename = str(filename)
			animName, frameNum = getAnimationAndFrameFromFilename(filename)

			if animName in self.animations:
				anim = self.animations[animName]
			else:
				anim = Animation()

			# open the image so we can compare it
			img = Image.open(filename)
			img.draft("RGBA", img.size)
			img = img.convert("RGBA")

			# are there even any images to compare?
			#print len(anim.frames)
			if len(anim.frames) > 0 and compareImages(img, anim.frames[-1].image):
				# same image, just increase the duration
				#print "Same image, increasing the duration"
				anim.frames[-1].duration += FRAME_DURATION
			else:
				# new image so add it to the animation
				#print "new image"
				newFrame = Frame()
				newFrame.image = img
				newFrame.imageName = filename
				newFrame.duration = FRAME_DURATION
				newFrame.createCroppedImage()
				anim.frames.append(newFrame)
				self.allFrames[filename] = newFrame

			self.animations[animName] = anim

		#print "animations:"
		#print self.animations

		# Figure out the refpoints
		# loop through all the animations
		for k, v in self.animations.items():

			# default refpoints should be in the middle of frame
			v.refPoint[0] = int(v.frames[0].image.size[0] / 2)
			v.refPoint[1] = int(v.frames[0].image.size[1] / 2)
			try:
				# if the animation has more than 1 frame
				if len(v.frames) > 1:
					# if the last frame has a duration of the default, then it's probably ok
					if v.frames[-1].duration == FRAME_DURATION:
						# check if there's only 1 non-zero alpha pixel
						if hasOnlyOnePixel(v.frames[-1].image):

							imageW = v.frames[-1].image.size[0]
							imageH = v.frames[-1].image.size[1]
							pixels = v.frames[-1].image.getdata()

							for y in range(0, imageH):
								for x in range(0, imageW):
									# non-zero alpha?
									if pixels[y*imageW + x][3] != 0:
										v.refPoint[0] = x
										v.refPoint[1] = y
										# clean it out of the animation
										del v.frames[-1]
										raise Success

			except Success:
				print "Found a refpoint for "+k+" : "+str(v.refPoint)
				pass

	def packFast(self, _padding):
		pass

	def packTight(self, _padding):

		print "Packing texture sheet..."
		# use Packer() algorithm
		global MIN_SHEET_SIZE
		global MAX_SHEET_SIZE

		# gather the rects to send to the packer
		rects = []
		for a in self.animations.values():
			for f in a.frames:
				rects.append( Rect.Rect( f.croppedImage.size, f.imageName ) )

		packed = False
		self.packedRects = None
		self.sheetSize = [0, 0]

		try:
			for out_x in pow2( log2(MIN_SHEET_SIZE), log2(MAX_SHEET_SIZE) ):
				# first try half height
				out_y = out_x / 2
				big_rect = Rect.Rect( (out_x, out_y) )

				try:
					packed_rects = Packer.pack( big_rect, rects, _padding )
					packed = True
					self.sheetSize = [int(out_x), int(out_y)]
					raise Success
				except ValueError:
					pass

				# then try full square
				out_y = out_x
				big_rect = Rect.Rect( (out_x, out_y) )

				try:
					packed_rects = Packer.pack( big_rect, rects, _padding )
					packed = True
					self.sheetSize = [int(out_x), int(out_y)]
					raise Success
				except ValueError:
					pass

		except Success:
			print "Packed into a sheet of "+str(big_rect)
			pass

		if (not packed):
			print('Could not pack frames into a sheet of '+str(MAX_SHEET_SIZE)+' * '+str(MAX_SHEET_SIZE))
			sys.exit(1)

		self.packedRects = packed_rects
		return packed_rects


	def saveLoveLua(self, _filename):
		print "Saving sprite as love .lua file..."

		# Finally write out the sheet
		sheet = Image.new("RGBA", self.sheetSize)

		for pr in self.packedRects:
			box = ( int(pr.bottomleft[0]), int(pr.bottomleft[1]), int(pr.topright[0]), int(pr.topright[1] ) )

			frame = self.allFrames[pr.name]
			sheet.paste(frame.croppedImage, box)

			frame.u = box[0]
			frame.v = box[1]
			frame.w = box[2] - box[0]
			frame.h = box[3] - box[1]


		# TODO: That alpha border thing that makes filtering not bleed
		print "Saving texture sheet..."
		sheetFilename = _filename+".png"
		print sheetFilename
		sheet.save( sheetFilename )


		sheetFilename = _filename[_filename.rfind('\\', 0, -2)+1:]
		if sheetFilename == '':
			sheetFilename = _filename
		sheetFilename += ".png"

		# write out the .lua file
		luaFile = open(_filename+".lua", "w")
		luaFile.write('-- Generated by spritecompiler.py for use with Love2D\n\n')
		luaFile.write('local path = ...\n')
		luaFile.write('local data = {}\n')
		luaFile.write('if type(path) ~= "string" then\n')
		luaFile.write('\tpath = "."\n')
		luaFile.write('end\n\n')
		luaFile.write('data.image = love.graphics.newImage(path.."/'+sheetFilename+'")\n')
		luaFile.write('data.image:setFilter("nearest", "nearest")\n')
		luaFile.write('data.animations = {}\n')

		# loop through all the animations
		for k, v in self.animations.items():
			luaFile.write('\ndata.animations.'+k+'={}\n')
			luaFile.write('local '+k+' = data.animations.'+k+'\n')
			luaFile.write(k+'.scale = '+str(v.scale)+'\n')

			# Loop through all the frames
			for f in v.frames:
				# Skip over duration of 0 frames, they shouldn't be part of the animation (how did they even get here...)
				if f.duration > 0:
					offsetX = v.refPoint[0] - f.cropOffset[0]
					offsetY = v.refPoint[1] - f.cropOffset[1]
					luaFile.write('table.insert('+k+', {u='+str(f.u)+', v='+str(f.v)+', w='+str(f.w)+', h='+str(f.h))
					luaFile.write(', offsetX='+str(offsetX)+', offsetY='+str(offsetY)+', duration='+str(float(f.duration)/1000.0)+'})\n')

			#table.insert(alleoop, {u=0, v=0, w=34, h=34, offsetX=18, offsetY=33, duration=0.0333333})

		luaFile.write('\ndata.quad = love.graphics.newQuad(0, 0, 1, 1, data.image:getWidth(), data.image:getHeight())\n\n')
		luaFile.write('return data\n')
		luaFile.flush()

	def saveMoaiLua(self, _filename):
		print "Saving sprite as moai .lua file..."

		# Finally write out the sheet
		sheet = Image.new("RGBA", self.sheetSize)

		for pr in self.packedRects:
			box = ( int(pr.bottomleft[0]), int(pr.bottomleft[1]), int(pr.topright[0]), int(pr.topright[1] ) )

			frame = self.allFrames[pr.name]
			sheet.paste(frame.croppedImage, box)

			frame.u = box[0]
			frame.v = box[1]
			frame.w = box[2] - box[0]
			frame.h = box[3] - box[1]


		# TODO: That alpha border thing that makes filtering not bleed
		print "Saving texture sheet..."
		sheetFilename = _filename+".png"
		print sheetFilename
		sheet.save( sheetFilename )


		sheetFilename = os.path.basename(sheetFilename)

		# write out the .lua file
		luaFile = open(_filename+".lua", "w")
		luaFile.write('-- Generated by spritecompiler.py for use with the Draggin Framework for MOAI\n\n')
		luaFile.write('local spriteData = {}\n\n')
		luaFile.write('local tex = MOAITexture.new()\n')
		luaFile.write('tex:load("res/sprites/'+sheetFilename+'")\n')
		luaFile.write('tex:setFilter(MOAITexture.GL_NEAREST)\n')
		luaFile.write('local deck = MOAIGfxQuadDeck2D.new()\n')
		luaFile.write('deck:setTexture(tex)\n\n')


		totalFrames = 0
		for a in self.animations.values():
			totalFrames += len(a.frames)

		luaFile.write('deck:reserve('+str(totalFrames)+')\n')

		luaFile.write('spriteData.bounds = {}\n')
		luaFile.write('spriteData.curves = {}\n')
		luaFile.write('spriteData.deckIndex = {}\n')
		luaFile.write('spriteData.originalWidths = {}\n')
		luaFile.write('local curve\n\n')
		frameIndex = 1

		for k, v in self.animations.items():

			luaFile.write('spriteData.deckIndex.'+k+' = '+str(frameIndex)+'\n')
			luaFile.write('curve = MOAIAnimCurve.new()\n')
			luaFile.write('curve:reserveKeys('+str(len(v.frames)+1)+')\n')

			curveIndex = 1
			timeline = 0
			orgWidth = 0

			for f in v.frames:
				orgWidth = f.image.size[0]
				offsetX = v.refPoint[0] - f.cropOffset[0]
				offsetY = v.refPoint[1] - f.cropOffset[1]
				luaFile.write('deck:setRect('+str(frameIndex)+', '+str(-offsetX)+', '+str(offsetY)+', '+str(f.w-offsetX)+', '+str(-(f.h-offsetY))+')\n')
				sheetW = float(self.sheetSize[0])
				sheetH = float(self.sheetSize[1])
				luaFile.write('deck:setUVRect('+str(frameIndex)+', ')
				luaFile.write(str(float(f.u)/sheetW)+', '+str(float(f.v)/sheetH)+', ')
				luaFile.write(str(float(f.u+f.w)/sheetW)+', '+str(float(f.v+f.h)/sheetH)+')\n')
				luaFile.write('curve:setKey('+str(curveIndex)+', '+str(float(timeline)/1000.0)+', '+str(frameIndex)+', MOAIEaseType.FLAT)\n')

				frameIndex+=1
				curveIndex+=1
				timeline+=f.duration

			# duplicate the last frame or it doesn't loop right :(
			luaFile.write('curve:setKey('+str(curveIndex)+', '+str(float(timeline)/1000.0)+', 1, MOAIEaseType.FLAT)\n')
			luaFile.write('spriteData.curves.'+k+' = curve\n')

			# write out the bounding box of this animation
			bx = -(v.refPoint[0] - v.frames[0].cropOffset[0])
			by = -(v.refPoint[1] - v.frames[0].cropOffset[1])
			luaFile.write('spriteData.bounds.'+k+' = {'+str(bx)+', '+str(by)+', '+str(v.frames[0].w+bx)+', '+str(v.frames[0].h+by)+'}\n')

			# write out the original width of the original un-cropped image, used mostly to help with RUBE import scales
			luaFile.write('spriteData.originalWidths.'+k+' = '+str(orgWidth)+'\n\n\n')


		luaFile.write('spriteData.texture = tex\n')
		luaFile.write('spriteData.deck = deck\n\n')
		luaFile.write('return spriteData\n')


	def saveXml(self, _filename):
		pass


# run the code here if it's not a module
if __name__ == "__main__":
	print("Draggin Sprite Compiler:")

	if (len(sys.argv) == 1):
		print("No arguments found.")
		print("Commandline usage: spriteCompiler [space separated list of files and/or folders]")
		print("Using a dialog box to get a folder.")
		folder = easygui.diropenbox("Choose a folder to create a sprite from", "Draggin Sprite Compiler", default=None)
		if (folder == None):
			print("You choose poorly, exiting.")
			sys.exit()
		imageFilenames = gatherFiles([folder], ("*.png", "*.bmp"))
	else:
		imageFilenames = gatherFiles(sys.argv[1:], ("*.png", "*.bmp"))

	spr = Sprite()
	spr.importImages(imageFilenames)
	spr.packTight(PADDING)
	spr.saveMoaiLua(outFilename)
	#spr.saveLoveLua(outFilename)

	print "Done."
	s = raw_input("Press Enter to continue...")

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


import sys
import math
from math import ceil, log
from fnmatch import fnmatch
import os
import os.path
import xml.dom.minidom
import re


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
		else:
			if fnmatchList(i , _filters):
				filenames.append(i)
				#print("\t"+i)
	return filenames

class Path:

	def __init__(self, _path):
		self.points = []
		self.closed = False
		_path = _path.replace('\n', ' ')
		#_path = re.sub(r'([A-Za-z])([0-9]|\-)', ' ', _path)
		_path = _path.replace(',', ' ')
		_path = re.sub(r'\s+', ' ', _path)
		tokens = re.split(' ', _path)

		command = ''
		pt = [0.0, 0.0]
		i = 0
		for token in tokens:
			if token == 'm' or token == 'M' or token == 'l' or token == 'L' or token == 'z' or token == 'Z':
				command = token
			else:
				if 'e' in token:
					token = 0
				if command == 'z' or command == 'Z':
					self.closed = True
					break
				if command == 'm' or command == 'l':
					pt[i] += float(token)
				else:
					pt[i] = float(token)
				i += 1
				if i > 1:
					if command == 'm':
						command = 'l'
					self.points.append([pt[0], pt[1]])
					i = 0

class Rect:
	def __init__(self):
		self.x = 0
		self.y = 0
		self.w = 0
		self.h = 0
		self.r = 0.0

class Circle:
	def __init__(self):
		self.x = 0.0
		self.y = 0.0
		self.r = 0.0

class World:
	def __init__(self, _svgFile):

		self.rects = []
		self.circles = []
		self.chains = []

		svg = xml.dom.minidom.parse(_svgFile)
		print("svg: "+_svgFile)
		layers = svg.getElementsByTagName("g")
		for layer in layers:
			name = layer.getAttribute("inkscape:label")
			print("name: "+name)

			if ("Box2D" in name):
				rects = layer.getElementsByTagName("rect")
				for rect in rects:
					obj = Rect()
					obj.x = int(float(rect.getAttribute("x")))
					obj.y = int(float(rect.getAttribute("y")))
					obj.w = int(float(rect.getAttribute("width")))
					obj.h = int(float(rect.getAttribute("height")))

					transform = rect.getAttribute("transform")
					if ("matrix" in transform):
						print transform
						# fancy regex from the internets, grabs numbers in any format from strings
						trans = re.findall(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", transform)
						if (float(trans[0]) == float(trans[3]) and float(trans[1]) == -float(trans[2])):
							# seems like a pure rotational transformation
							obj.r = -math.degrees(math.acos(float(trans[0])))

							print obj.r
					self.rects.append(obj)

				paths = layer.getElementsByTagName("path")
				for path in paths:
					if path.getAttribute("sodipodi:type") == "arc":
						# if it's an arc let's hope it's a circle
						d = path.getAttribute("d")
						if ("m" in d):
							print d
							# fancy regex from the internets, grabs numbers in any format from strings
							values = re.findall(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", d)

						t = path.getAttribute("transform")
						if ("translate" in t):
							print t
							# fancy regex from the internets, grabs numbers in any format from strings
							trans = re.findall(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", t)

						c = Circle()
						c.x = float(values[0]) + float(trans[0]) - float(values[2])
						c.y = float(values[1]) + float(trans[1])
						c.r = float(values[2])

						self.circles.append(c)

					else:
						# probably a chain
						d = path.getAttribute("d")
						# if ("m" in d):
						# 	print d
						# 	# fancy regex from the internets, grabs numbers in any format from strings
						# 	points = re.findall(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", d)

						path = Path(d)
						print path.points
						self.chains.append(path.points)


	def saveMoaiLua(self, _baseFilename):
		print("Box2D save MOAI")

		# write out the .lua file
		luaFile = open(_baseFilename+".lua", "w")
		luaFile.write('-- Generated by box2dcompiler.py for Moai\n\n')
		luaFile.write('local args = {...}\n')
		luaFile.write('local phys = args[1]\n\n')

		for rect in self.rects:
			# stuff
			luaFile.write('phys:addRect(MOAIBox2DBody.STATIC, '+str(rect.x)+', '+str(rect.y)+', '+str(rect.w)+', '+str(rect.h)+', '+str(rect.r)+')\n')

		# do the circles
		for circle in self.circles:
			luaFile.write('phys:addCircle(MOAIBox2DBody.STATIC, '+str(circle.x)+', '+str(circle.y)+', '+str(circle.r)+')\n')

		# do the chains
		for chain in self.chains:
			luaFile.write('phys:addChain({')

			# this is fun, the first point is in world space, all others are relative to the previous
			for point in chain:
				luaFile.write(str(point[0])+', '+str(point[1])+', ')

			# TODO: properly support closing the loop
			luaFile.write('}, true)\n')

# run the code here if it's not a module
if __name__ == "__main__":
	print("Draggin Box2D Compiler:")

	if (len(sys.argv) == 1):
		print("No arguments found.")
		print("Commandline usage: box2dcompiler [space separated list of files and/or folders]")
	else:
		svgFilenames = gatherFiles(sys.argv[1:], ("*.svg"))

	w = World(svgFilenames[0])
	w.saveMoaiLua(os.path.splitext(svgFilenames[0])[0])

	print("Done.")

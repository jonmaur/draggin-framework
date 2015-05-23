import os
import os.path
import glob
import shutil
import subprocess
from fnmatch import fnmatch

MOAI_BIN = os.environ["MOAI_BIN"]
DRAGGIN_FRAMEWORK = os.environ["DRAGGIN_FRAMEWORK"]

PROJECT_NAME = "draggin"
if 'PROJECT_NAME' in ARGUMENTS:
	PROJECT_NAME = ARGUMENTS["PROJECT_NAME"]

env = Environment(tools = [])

#the full path to this SConscript file
this_sconscript_file = (lambda x:x).func_code.co_filename

# matches anything in the list
def fnmatchList(_name, _filters):

	for f in _filters:
		if fnmatch(_name, f):
			# found one match so get out of here
			return True

	# no matches
	return False

###################################################################################################
# copy files
copyfiles = []
def copyAction( target, source, env ):
	print "copyAction"
	print "Copying "+str(target[0])
	try:
		shutil.copyfile(str(source[0]), str(target[0]))
	except (IOError, os.error), why:
		#easygui.exceptionbox(str(source[0])+", "+str(target[0])+" FAILED")
		raw_input(str(source[0])+", "+str(target[0])+" FAILED: "+str(why))

copyBuilder = Builder(action = copyAction)
env.Append(BUILDERS = {'copyComplier' : copyBuilder})

for root, dirs, files in os.walk("main"):
	for f in files:
		copyfile = ""
		filename = os.path.join(root, f)
		
		pattern_check = fnmatchList(filename, ["*.png", "*.ttf", "*.fnt", "*.wav", "*.mp3", "*.json"])
		if pattern_check:
			# print filename
			copyfile = str(filename)
				
		# print "directory "+str(root)
		
		if copyfile != "":
			outputfiles = []
			outputfiles.append(str("package/windows/" + copyfile[len("main/"):]))
			copyfiles.append(env.copyComplier(outputfiles, copyfile))

# the exe
outputfiles = []
outputfiles.append(str("package/windows/" + PROJECT_NAME + ".exe"))
executable = MOAI_BIN + "/sledge.exe"
if not os.path.exists(executable):
	executable = MOAI_BIN + "/moai.exe"

copyfiles.append(env.copyComplier(outputfiles, executable))

if len(copyfiles) > 0:
	Default(copyfiles)


###################################################################################################
# compile lua files
luafiles = []
def luaAction( target, source, env ):
	print "luaAction"
	print "compiling "+str(target[0])
	args = [os.path.join(DRAGGIN_FRAMEWORK, 'tools/luajitcompiler/luajit'), '-b', str(source[0]), str(target[0])]
	try:
		p = subprocess.Popen(args)
	except (IOError, os.error), why:
		#easygui.exceptionbox(str(source[0])+", "+str(target[0])+" FAILED")
		raw_input(str(source[0])+", "+str(target[0])+" FAILED: "+str(why))

luaBuilder = Builder(action = luaAction)
env.Append(BUILDERS = {'luaComplier' : luaBuilder})

# draggin files!!!!
dragginsrc = os.path.join(DRAGGIN_FRAMEWORK, 'src')
for root, dirs, files in os.walk(dragginsrc):
	for f in files:
		copyfile = ""
		filename = os.path.join(root, f)
		
		pattern_check = fnmatch(filename, "*.lua")
		if pattern_check:
			# print filename
			copyfile = str(filename)
				
		# print "directory "+str(root)
		
		if copyfile != "":
			outputfiles = []
			outputfiles.append(str("package/windows/" + copyfile[len(dragginsrc):]))
			luafiles.append(env.luaComplier(outputfiles, copyfile))

# game files
for root, dirs, files in os.walk("main"):
	for f in files:
		copyfile = ""
		filename = os.path.join(root, f)
		
		pattern_check = fnmatch(filename, "*.lua") and not fnmatch(filename, "*savedata.lua")
		if pattern_check:
			# print filename
			copyfile = str(filename)
				
		# print "directory "+str(root)
		
		if copyfile != "":
			outputfiles = []
			outputfiles.append(str("package/windows/" + copyfile[len("main/"):]))
			luafiles.append(env.luaComplier(outputfiles, copyfile))

if len(luafiles) > 0:
	Default(luafiles)

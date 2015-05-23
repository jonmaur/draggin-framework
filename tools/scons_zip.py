import os
import os.path
import glob
import shutil
from fnmatch import fnmatch

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
zipfiles = []
def zipAction( target, source, env ):
	print "zipAction"
	fpair = os.path.splitext(str(target[0]))
	print "Zipping "+fpair[0]
	try:
		shutil.make_archive(fpair[0], "zip", "package/windows")

	except (IOError, os.error), why:
		#easygui.exceptionbox(str(source[0])+", "+str(target[0])+" FAILED")
		raw_input(str(source[0])+", "+str(target[0])+" FAILED: "+str(why))

copyBuilder = Builder(action = zipAction)
env.Append(BUILDERS = {'zipComplier' : copyBuilder})

inputfiles = []

for root, dirs, files in os.walk("package/windows"):
	for f in files:
		filename = os.path.join(root, f)
		inputfiles.append(str(filename))

# the exe
outputfiles = []
outputfiles.append(str("package/" + PROJECT_NAME + "_windows.zip"))
zipfiles.append(env.zipComplier(outputfiles, inputfiles))


if len(zipfiles) > 0:
	Default(zipfiles)

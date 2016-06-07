#!/bin/bash

# You'll need the following os environment vars setup:
# The folder with the MOAI executable 'moai' which should be something like
# export MOAI_BIN="<path to moai-dev>/release/linux/host-glut/x64/bin"
# And the path to the draggin-framework:
# export DRAGGIN_FRAMEWORK="<path to draggin-framework>"

# Verify paths
if [ ! -f "$MOAI_BIN/moai" ]; then
    echo "---------------------------------------------------------------------------"
    echo "Error: The MOAI_BIN environment variable doesn't exist or its pointing to an"
    echo "invalid path.  Please point it at a folder containing a moai executable"
    echo "---------------------------------------------------------------------------"
    exit 1
fi

if [ ! -f "$DRAGGIN_FRAMEWORK/draggin-config.lua" ]; then
    echo "---------------------------------------------------------------------------"
    echo "WARNING: The DRAGGIN_FRAMEWORK environment variable either doesn't exist or it's"
    echo "pointing to an invalid path.  Please point it the draggin-framework folder"
    echo "---------------------------------------------------------------------------"
    exit 1
fi

cd `dirname $0`
cd main
$MOAI_BIN/moai $DRAGGIN_FRAMEWORK/draggin-config.lua main.lua

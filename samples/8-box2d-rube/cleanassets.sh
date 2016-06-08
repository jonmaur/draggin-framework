#!/bin/bash
scons -c -f $DRAGGIN_FRAMEWORK/tools/SConstruct ASSETS_DIR="assets" RES_DIR="main/res" --warn=no-all --include-dir=$DRAGGIN_FRAMEWORK/tools/spritecompiler/ --include-dir=$DRAGGIN_FRAMEWORK/tools/tilemapcompiler/ --include-dir=$DRAGGIN_FRAMEWORK/tools/box2dcompiler/

cd `dirname $0`
rm -rf main/res

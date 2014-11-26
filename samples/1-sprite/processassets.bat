:: ASSETS_DIR is the directory with all the raw assets
:: RES_DIR is where the processed assets end up, the res directory where the program can find and load them
cd %~dp0
scons -f %DRAGGIN_FRAMEWORK%/tools/SConstruct ASSETS_DIR="assets" RES_DIR="main/res" --warn=no-all --include-dir=%DRAGGIN_FRAMEWORK%/tools/spritecompiler/ --include-dir=%DRAGGIN_FRAMEWORK%/tools/tilemapcompiler/ --include-dir=%DRAGGIN_FRAMEWORK%/tools/box2dcompiler/

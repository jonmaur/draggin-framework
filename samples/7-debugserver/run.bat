:: You'll need the following os environment vars setup:
:: The folder with the MOAI executable 'moai' which should be something like
:: export MOAI_BIN="<path to moai-dev>/release/linux/host-glut/x64/bin"
:: And the path to the draggin-framework:
:: export DRAGGIN_FRAMEWORK="<path to draggin-framework>"

echo off
:: verify paths
if not exist "%MOAI_BIN%\moai.exe" (
    echo.
    echo --------------------------------------------------------------------------------
    echo ERROR: The MOAI_BIN environment variable either doesn't exist or it's pointing
    echo to an invalid path. Please point it at a folder containing moai.exe.
    echo --------------------------------------------------------------------------------
    echo.
    goto end
)

if not exist "%DRAGGIN_FRAMEWORK%\draggin-config.lua" (
    echo.
    echo -------------------------------------------------------------------------------
    echo WARNING: The DRAGGIN_FRAMEWORK environment variable either doesn't exist or it's 
    echo pointing to an invalid path. Please point it at the draggin-framework folder.
    echo -------------------------------------------------------------------------------
    echo.
)


:: run moai
cd %~dp0
cd main
"%MOAI_BIN%\moai" "%DRAGGIN_FRAMEWORK%\draggin-config.lua" "main.lua" -console

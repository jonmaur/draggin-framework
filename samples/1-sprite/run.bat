:: You'll need the following os environment vars setup:
:: The folder with the MOAI executable 'moai' which should be something like
:: export MOAI_BIN="<path to moai-dev>/release/linux/host-glut/x64/bin"
:: And the path to the draggin-framework:
:: export DRAGGIN_FRAMEWORK="<path to draggin-framework>"

echo off
setlocal

:: verify paths
if not exist "%DRAGGIN_FRAMEWORK%\draggin-config.lua" (
    echo.
    echo -------------------------------------------------------------------------------
    echo ERROR: The DRAGGIN_FRAMEWORK environment variable either doesn't exist or it's 
    echo pointing to an invalid path. Please point it at the draggin-framework folder.
    echo -------------------------------------------------------------------------------
    echo.
    goto end
)

if exist "%MOAI_BIN%\sledge.exe" (
    :: run sledge
    set current=%cd%
    cd %~dp0\main
    "%MOAI_BIN%\sledge" "main.lua" -console
    cd %current%

    goto end
)
if exist "%MOAI_BIN%\moai.exe" (
    :: run moai
    set current=%cd%
    cd %~dp0\main
    "%MOAI_BIN%\moai" "%DRAGGIN_FRAMEWORK%\draggin-config.lua" "main.lua" -console
    cd %current%
    
    goto end
)

echo.
echo --------------------------------------------------------------------------------
echo ERROR: The MOAI_BIN environment variable either doesn't exist or it's pointing
echo to an invalid path. Please point it at a folder containing moai.exe or 
echo sledge.exe
echo --------------------------------------------------------------------------------
echo.

:end

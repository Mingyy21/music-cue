@echo off
REM dev.bat - one-shot env for music.cue development
REM Usage:  dev.bat          -> interactive shell with env ready
REM         dev.bat doctor   -> run octo doctor
REM         dev.bat run      -> start app headless on port 8141
REM         dev.bat shot     -> capture screenshot
REM         dev.bat check    -> run hub check
REM         dev.bat quit     -> stop the running app

set "WS=E:\software2"
set "REPO=%WS%\OctoScript-App-Design-Flow"
set "APP=%WS%\apps\music-cue"
set "OCTO_HUB=%WS%\OctoSense-App-Hub\target\release\hub.exe"
set "OCTO_CARD_HOST=%WS%\OctoSense-App-Hub\target\release\card-host.exe"
set "OCTOSENSE_APP_HUB=%WS%\OctoSense-App-Hub"
set "PORT=8141"

if "%~1"=="" goto shell
if /I "%~1"=="doctor" goto doctor
if /I "%~1"=="run"    goto run
if /I "%~1"=="shot"   goto shot
if /I "%~1"=="check"  goto check
if /I "%~1"=="quit"   goto quit
goto shell

:doctor
cd /d "%REPO%"
python tools\octo doctor
goto :eof

:run
cd /d "%REPO%"
python tools\octo run "%APP%\bundle" --port %PORT% --hidden --detach
goto :eof

:shot
cd /d "%REPO%"
python tools\octo shot %PORT% "%APP%\bundle\screenshots\01-main.png"
goto :eof

:check
cd /d "%REPO%"
python tools\octo check "%APP%\bundle"
goto :eof

:quit
curl -s http://127.0.0.1:%PORT%/quit
echo quit sent
goto :eof

:shell
cd /d "%REPO%"
echo env ready:  OCTO_HUB / OCTO_CARD_HOST / OCTOSENSE_APP_HUB
echo try:  python tools\octo doctor
cmd /k

@echo off
rem workbuddy-proxy - manage the local WorkBuddy OpenAI/Anthropic compatible proxy
rem Pure cmd launcher delegating to the upstream submodule at refs/workbuddy-openai-proxy.
rem Keep this file ASCII-only and CRLF (see .gitattributes).
setlocal

set "PROXY_DIR=%~dp0refs\workbuddy-openai-proxy"

if not exist "%PROXY_DIR%\server.mjs" (
  echo workbuddy-proxy: submodule not found: %PROXY_DIR% 1>&2
  echo workbuddy-proxy: provision it with: 1>&2
  echo   git submodule update --init refs/workbuddy-openai-proxy 1>&2
  exit /b 1
)

cd /d "%PROXY_DIR%"

if "%~1"=="" goto start
if /i "%~1"=="start"   goto start
if /i "%~1"=="stop"    goto stop
if /i "%~1"=="restart" goto restart
if /i "%~1"=="login"   goto login
if /i "%~1"=="status"  goto status
if /i "%~1"=="console" goto console
if /i "%~1"=="ask"     goto ask

echo Usage: workbuddy-proxy [start ^| stop ^| restart ^| login ^| status ^| console ^| ask] 1>&2
exit /b 1

:start
echo Starting WorkBuddy proxy (hidden) on http://127.0.0.1:8788 ...
echo Console: http://127.0.0.1:8788/console  (first run: workbuddy-proxy login)
start "" wscript "%PROXY_DIR%\start-hidden.vbs"
exit /b 0

:stop
node "%PROXY_DIR%\stop.mjs"
exit /b 0

:restart
node "%PROXY_DIR%\stop.mjs"
timeout /t 2 >nul
start "" wscript "%PROXY_DIR%\start-hidden.vbs"
exit /b 0

:login
node "%PROXY_DIR%\login.mjs" %2 %3 %4 %5 %6 %7 %8 %9
exit /b 0

:status
node "%PROXY_DIR%\status.mjs" %2 %3 %4 %5 %6 %7 %8 %9
exit /b 0

:console
node "%PROXY_DIR%\console-open.mjs"
exit /b 0

:ask
shift
node "%PROXY_DIR%\ask.mjs" %*
exit /b 0

@echo off
setlocal

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

if defined HVIGOR_BIN if exist "%HVIGOR_BIN%" (
    call "%HVIGOR_BIN%" %*
    exit /b %ERRORLEVEL%
)

if defined DEVECO_STUDIO_HOME (
    if exist "%DEVECO_STUDIO_HOME%\tools\hvigor\bin\hvigorw.js" (
        call :run_deveco "%DEVECO_STUDIO_HOME%" %*
        exit /b %ERRORLEVEL%
    )
)

for %%D in ("%LOCALAPPDATA%\Programs\DevEco Studio" "%ProgramFiles%\Huawei\DevEco Studio") do (
    if exist "%%~fD\tools\hvigor\bin\hvigorw.js" (
        call :run_deveco "%%~fD" %*
        exit /b %ERRORLEVEL%
    )
)

where hvigor >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    hvigor %*
    exit /b %ERRORLEVEL%
)

if exist "%PROJECT_DIR%oh_modules\@ohos\hvigor\bin\hvigor.js" (
    call :run_local "%PROJECT_DIR%oh_modules\@ohos\hvigor\bin\hvigor.js" %*
    exit /b %ERRORLEVEL%
)

if exist "%PROJECT_DIR%node_modules\@ohos\hvigor\bin\hvigor.js" (
    call :run_local "%PROJECT_DIR%node_modules\@ohos\hvigor\bin\hvigor.js" %*
    exit /b %ERRORLEVEL%
)

echo Error: unable to find a usable HarmonyOS hvigor toolchain. 1>&2
echo Set DEVECO_STUDIO_HOME to your DevEco Studio directory, or put hvigor on PATH. 1>&2
exit /b 1

:run_deveco
set "STUDIO_HOME=%~1"
if exist "%STUDIO_HOME%\tools\node\node.exe" (
    set "NODE_EXE=%STUDIO_HOME%\tools\node\node.exe"
) else if exist "%STUDIO_HOME%\tools\node\bin\node.exe" (
    set "NODE_EXE=%STUDIO_HOME%\tools\node\bin\node.exe"
) else (
    exit /b 1
)
if not exist "%STUDIO_HOME%\tools\hvigor\bin\hvigorw.js" exit /b 1
if not defined DEVECO_SDK_HOME if exist "%STUDIO_HOME%\sdk" set "DEVECO_SDK_HOME=%STUDIO_HOME%\sdk"
shift
"%NODE_EXE%" "%STUDIO_HOME%\tools\hvigor\bin\hvigorw.js" %*
exit /b %ERRORLEVEL%

:run_local
set "HVIGOR_JS=%~1"
shift
if defined NODE_BIN if exist "%NODE_BIN%" (
    "%NODE_BIN%" "%HVIGOR_JS%" %*
    exit /b %ERRORLEVEL%
)
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    node "%HVIGOR_JS%" %*
    exit /b %ERRORLEVEL%
)
exit /b 1

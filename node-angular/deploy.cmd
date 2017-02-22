@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.9
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
    SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)

echo "-----------------Variables---------------------------------"
echo "DEPLOYMENT_SOURCE = %DEPLOYMENT_SOURCE%"
echo "DEPLOYMENT_TARGET = %DEPLOYMENT_TARGET%"
echo "NEXT_MANIFEST_PATH = %NEXT_MANIFEST_PATH%"
echo "PREVIOUS_MANIFEST_PATH = %PREVIOUS_MANIFEST_PATH%"
echo "KUDU_SYNC_CMD = %appdata%\npm\kuduSync.cmd"
echo "-----------------Variables END ---------------------------------"
echo ""
echo ""

goto Deployment

:: Utility Functions
:: -----------------

:SelectNodeVersion

IF DEFINED KUDU_SELECT_NODE_VERSION_CMD (
  :: The following are done only on Windows Azure Websites environment
  call %KUDU_SELECT_NODE_VERSION_CMD% "%DEPLOYMENT_SOURCE%" "%DEPLOYMENT_TARGET%" "%DEPLOYMENT_TEMP%"
  IF !ERRORLEVEL! NEQ 0 goto error

  IF EXIST "%DEPLOYMENT_TEMP%\__nodeVersion.tmp" (
    SET /p NODE_EXE=<"%DEPLOYMENT_TEMP%\__nodeVersion.tmp"
    IF !ERRORLEVEL! NEQ 0 goto error
  )
  
  IF EXIST "%DEPLOYMENT_TEMP%\__npmVersion.tmp" (
    SET /p NPM_JS_PATH=<"%DEPLOYMENT_TEMP%\__npmVersion.tmp"
    IF !ERRORLEVEL! NEQ 0 goto error
  )

  IF NOT DEFINED NODE_EXE (
    SET NODE_EXE=node
  )

  SET NPM_CMD="!NODE_EXE!" "!NPM_JS_PATH!"
) ELSE (
  SET NPM_CMD=npm
  SET NODE_EXE=node
)

goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

:Deployment
echo Handling node.js deployment.

:: 1. Select node version
call :SelectNodeVersion


:: 2. Install npm devDependancy packages with explicit flag --only=dev at DEPLOYMENT_SOURCE instead of DEPLOYMENT_TARGET
echo =======  Installing npm  devDependancy packages: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_SOURCE%\package.json" (
  pushd "%DEPLOYMENT_SOURCE%"
  call :ExecuteCmd !NPM_CMD! install --only=dev
  IF !ERRORLEVEL! NEQ 0 goto error
  popd
)
echo =======  Installing npm dev packages: Finished at %TIME% ======= 


:: 3. Install bower packages at DEPLOYMENT_SOURCE instead of DEPLOYMENT_TARGET
echo =======  Installing bower: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_SOURCE%\bower.json" (
 pushd "%DEPLOYMENT_SOURCE%"
 call :ExecuteCmd ".\node_modules\.bin\bower.cmd" install
 IF !ERRORLEVEL! NEQ 0 goto error
 popd
 )
echo =======  Installing bower: Finished at %TIME% ======= 



:: 4 Execute Gulp tasks at DEPLOYMENT_SOURCE instead of DEPLOYMENT_TARGET
echo =======  Executing gulp task release: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_SOURCE%\gulpfile.js" (
  pushd "%DEPLOYMENT_SOURCE%"
  echo "Building web site using Gulp" 
  ::call :ExecuteCmd !GULP_CMD! release-uncompress
  call :ExecuteCmd ".\node_modules\.bin\gulp.cmd" build --env prod
  call :ExecuteCmd ".\node_modules\.bin\gulp.cmd" release
  
  IF !ERRORLEVEL! NEQ 0 goto error
  popd
)
echo =======  Executing Gulp task release: Finished at %TIME% ======= 



:: 5. Do KuduSync BEFORE INSTALLING PRODUCTION DEPENDANCIES
echo ======= Kudu Syncing: Starting at %TIME% ======= 
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.vscode;node_modules;src;typings;.bowerrc;.deployment;.gitignore;bower.json;deploy.cmd;gulpfile.js;tsconfig.json;tsd.json;.hg;.deployment;deploy.cmd;*.xml;*.yml"
  IF !ERRORLEVEL! NEQ 0 goto error
)
echo ======= Kudu Syncing: Finished at %TIME% ======= 



:: 6. Install npm packages at DEPLOYMENT_TARGET 
echo =======  Installing npm packages: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_TARGET%\package.json" (
  pushd "%DEPLOYMENT_TARGET%"
  call :ExecuteCmd !NPM_CMD! install --production
  IF !ERRORLEVEL! NEQ 0 goto error
  popd
)
echo =======  Installing npm packages: Finished at %TIME% ======= 



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
::echo Press any key to exit.
::pause
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.

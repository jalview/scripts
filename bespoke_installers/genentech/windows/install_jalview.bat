@ECHO OFF

REM This is the Jalview batch script wrapper to run the powershell script of the same name.
REM There is nothing specific to Jalview.

REM ******************************************************************************
REM If you need to set a full path to the PowerShell executable please do so here:
SET PWSHPATH=
REM ******************************************************************************

REM This is some DOS magic to substitute the extension in the full path of this batch script with .ps1
SET SCRIPTPATH=%~dpn0.ps1

REM PowerShell script isn't where it should be!
IF NOT EXIST %SCRIPTPATH% (
  ECHO Could not find PowerShell script %SCRIPTPATH%.  Is %~nx0 in the right folder?
  EXIT /B 1
)

REM Look for either pwsh.exe or powershell.exe if not set in PWSHPATH above.
REM pwsh.exe is preferred as it is likely to be a newer version.
SET PWSH=
IF DEFINED PWSHPATH (
  SET PWSH=%PWSHPATH%
)
FOR %%X IN (pwsh.exe powershell.exe) DO (
  IF NOT DEFINED PWSH ( 
    IF NOT "%%~$PATH:X" == "" (
      REM Found a PowerShell executable in the PATH
      SET PWSH=%%X
      GOTO end_looking
    )
  )
)
:end_looking

IF NOT DEFINED PWSH (
  REM No PowerShell executable found -- tell the user what to do.
  ECHO No PowerShell found in %%PATH%%. If PowerShell is installed either
  ECHO 1. add it to your PATH, or
  ECHO 2. edit the PWSHPATH value at the top of this file:
  ECHO    "%~dpnx0"
  ECHO.
  ECHO %~n0 on the command line requires PowerShell. To install PowerShell see
  ECHO https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell
  EXIT /B 2
)

REM Run the PowerShell script
%PWSH% -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTPATH%' %*";

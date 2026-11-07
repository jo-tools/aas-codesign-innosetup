@ECHO OFF
SETLOCAL

REM aas-codesign.bat | Parameter %1: file-to-be-signed.exe
REM ******************************************************
REM
REM This batch script can be used from InnoSetup to
REM CodeSign using Azure Artifact Signing.
REM
REM InnoSetup is running under wine.
REM We now want to execute a Linux command: aas-codesign.sh
REM
REM The issue is that cmd /c start /wait will run asychronous :(
REM This .bat needs to wait until CodeSigning is really finished.
REM We do this by waiting for a file to be written by
REM aas-codesign-wine.sh - which contains the exit code.
REM
REM The exit code is being returned to InnoSetup, so that
REM InnoSetup fails if codesigning has failed (or timed out).

REM File to be signed (without quotes)
SET "FILE=%*"
SET "FILE=%FILE:"=%"
SET "LookForFile=%FILE%.signed"

REM Timeout: wait at most 120 cycles of 1 second
REM Note: InnoSetup retries a failed Sign Tool command (SignToolRetryCount)
SET /A maxcycles=120
SET /A cntr=0

REM Check if result exists (from a previous run)
IF EXIST "%LookForFile%" DEL "%LookForFile%"

REM Launch aas-codesign on Linux (asynchronous)
cmd /c start /wait /unix /usr/local/bin/aas-codesign-wine.sh "%FILE%"

:CheckForFile
IF EXIST "%LookForFile%" GOTO FoundIt

REM If we get here, the file is not found.
REM so let's wait a second and check again.
SET /A cntr+=1
IF %cntr% GEQ %maxcycles% GOTO Timeout

REM wait 1 second: ping waits 1 second between 2 echo requests
ping 127.0.0.1 -n 2 -w 1000 >nul

GOTO CheckForFile

:FoundIt
REM read exit code and remove temporary file
SET "RESULT=1"
SET /P RESULT=<"%LookForFile%"
DEL "%LookForFile%"
IF "%RESULT%"=="0" EXIT /B 0
ECHO aas-codesign.bat: Error occurred during codesigning [ExitCode: %RESULT%]
EXIT /B %RESULT%

:Timeout
ECHO aas-codesign.bat: Timeout while waiting for codesigning
EXIT /B 1

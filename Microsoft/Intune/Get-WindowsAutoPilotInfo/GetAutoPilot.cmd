@ECHO OFF
echo Enabling WinRM
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command Enable-PSRemoting -SkipNetworkProfileCheck -Force

:Start

echo.
echo Which country will this computer primarily be located?
echo.
echo  1 - Sweden
echo  2 - Norway
echo  3 - Denmark
echo  4 - Finland
echo  5 - Deutschland
echo 00 - EXIT
echo 99 - Delete CSV
echo.

@set /p userinp=Type the number of your choice: 
@set userinp=%userinp:~0,2%
@if "%userinp%"=="1" goto 1
@if "%userinp%"=="2" goto 2
@if "%userinp%"=="3" goto 3
@if "%userinp%"=="4" goto 4
@if "%userinp%"=="5" goto 5
@if "%userinp%"=="00" goto 00
@if "%userinp%"=="99" goto 99


:1
set grouptag=Device-SE
goto end

:2
set grouptag=Device-NO
goto end

:3
set grouptag=Device-DK
goto end

:4
set grouptag=Device-FI
goto end

:5
set grouptag=Device-DE
goto end

:99
del compHash.csv
goto Start

:end
echo Gathering Azure AD Joined AutoPilot Hash
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command .\Get-WindowsAutoPilotInfo.ps1 -OutputFile .\compHash.csv -append -GroupTag %grouptag%
echo Done!

:shutdown
rem shutdown /s /t 5

:00
pause
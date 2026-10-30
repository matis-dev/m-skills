@echo off
rem m-skills - the Windows launcher for the Antigravity guard hooks. Ships as bash.cmd at
rem the plugin root.
rem
rem agy runs a hook command through `cmd /c` with the plugin folder as cwd, and cmd looks
rem in the cwd before PATH, so `bash` in hooks.json lands here first. Without this file it
rem lands on whatever PATH offers: nothing, WSL's System32\bash.exe, or a bash company
rem policy blocks. Each of those exits nonzero, and agy then blocks every file and shell
rem tool. On Linux and macOS agy uses `sh -c`, which never looks in the cwd, so this file
rem is inert there.
rem
rem Finds Git Bash and runs the adapter with it. Always exits 0: the decision travels on
rem stdout, and a guard that cannot start must step aside, not stop all work. The skip
rem is logged to the same guards.log the adapter uses.
setlocal
set "B=%M_SKILLS_BASH%"
if defined B set "B=%B:"=%"
if defined B if not exist "%B%" set "B="
for %%P in ("%ProgramW6432%\Git\bin\bash.exe" "%ProgramFiles%\Git\bin\bash.exe" "%ProgramFiles(x86)%\Git\bin\bash.exe" "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" "%USERPROFILE%\scoop\apps\git\current\bin\bash.exe") do (
  if not defined B if exist %%P set "B=%%~P"
)
if not defined B for /f "delims=" %%G in ('where git.exe 2^>nul') do (
  if not defined B if exist "%%~dpG..\bin\bash.exe" set "B=%%~dpG..\bin\bash.exe"
  if not defined B if exist "%%~dpG..\..\bin\bash.exe" set "B=%%~dpG..\..\bin\bash.exe"
  if not defined B if exist "%%~dpG..\usr\bin\bash.exe" set "B=%%~dpG..\usr\bin\bash.exe"
)
if not defined B (
  if not exist "%USERPROFILE%\.claude\m-skills" mkdir "%USERPROFILE%\.claude\m-skills" 2>nul
  >>"%USERPROFILE%\.claude\m-skills\guards.log" echo %DATE% %TIME%	bash.cmd	Git Bash not found; guards skipped. Install Git for Windows or set M_SKILLS_BASH to its bin\bash.exe
  exit /b 0
)
for %%D in ("%B%") do set "PATH=%%~dpD;%%~dpD..\usr\bin;%PATH%"
"%B%" %*
exit /b 0

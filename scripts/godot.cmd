@echo off
setlocal
set "exe=C:\Users\92394\GameDiscovery\Godot\Godot_v4.4.1-stable_win64.exe"
if not exist "%exe%" (
  echo Godot 4.4 executable not found at "%exe%".
  exit /b 1
)
"%exe%" %*
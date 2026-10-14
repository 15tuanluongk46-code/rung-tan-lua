@echo off
setlocal
set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
  echo Khong tim thay Godot 4.7.2. Xem HUONG-DAN-WINDOWS.md.
  pause
  exit /b 1
)
"%GODOT%" --path "%~dp0." --editor

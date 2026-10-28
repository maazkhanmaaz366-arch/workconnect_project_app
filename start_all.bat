@echo off
color 0B
echo ==================================================
echo       Starting WorkConnect Ecosystem
echo ==================================================
echo.

echo [1/3] Launching FastAPI Backend...
start "WorkConnect - FastAPI Server" cmd /k "color 0A && cd backend_app && title FastAPI Server && .\venv\Scripts\python main.py"
timeout /t 3 /nobreak >nul

echo [2/3] Launching React Admin Web Panel...
start "WorkConnect - React Admin Panel" cmd /k "color 0D && cd admin_app && title React Admin Panel && npm run dev"
timeout /t 2 /nobreak >nul

echo [3/3] Launching Flutter Mobile App (Forced to Chrome)...
start "WorkConnect - Flutter Mobile App" cmd /k "color 0E && cd flutter_app && title Flutter Mobile App && flutter run -d chrome"

echo.
echo ==================================================
echo  All services have been launched in separate windows!
echo  Check your taskbar for the new terminal windows.
echo ==================================================
pause

@echo off
color 0B
echo ==================================================
echo   Starting WorkConnect Ecosystem (IDE Background)
echo ==================================================
echo.

echo [1/3] Starting FastAPI Backend on Port 8000...
start /B cmd /c "cd backend_app && .\venv\Scripts\python main.py"
timeout /t 3 /nobreak >nul

echo [2/3] Starting React Admin Web Panel...
start /B cmd /c "cd admin_app && npm run dev"
timeout /t 2 /nobreak >nul

echo [3/3] Starting Flutter Mobile App (Forced to Chrome)...
start /B cmd /c "cd flutter_app && flutter run -d chrome"

echo.
echo ==================================================
echo  All services are running in this terminal!
echo  Logs will appear here. Press Ctrl+C to stop.
echo ==================================================

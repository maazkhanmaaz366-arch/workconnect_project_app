@echo off
color 0B
echo ==================================================
echo       WorkConnect Ecosystem Setup ^& Start
echo ==================================================
echo.
echo This script will install all necessary dependencies
echo for the Backend, Admin Panel, and Flutter App,
echo and then start all the services.
echo.
echo ==================================================
echo [1/3] Setting up FastAPI Backend...
echo ==================================================
cd backend_app
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)
echo Installing Python requirements...
call venv\Scripts\activate.bat
pip install -r requirements.txt
call deactivate
cd ..
echo.

echo ==================================================
echo [2/3] Setting up React Admin Web Panel...
echo ==================================================
cd admin_app
echo Installing NPM dependencies (this might take a minute)...
call npm install
cd ..
echo.

echo ==================================================
echo [3/3] Setting up Flutter Mobile App...
echo ==================================================
cd flutter_app
echo Getting Flutter packages...
call flutter pub get
cd ..
echo.

echo ==================================================
echo Setup Complete! Starting services...
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

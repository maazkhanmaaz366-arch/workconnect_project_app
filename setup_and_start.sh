#!/bin/bash

# Define colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}      WorkConnect Ecosystem Setup & Start${NC}"
echo -e "${CYAN}==================================================${NC}"
echo
echo "This script will install all necessary dependencies"
echo "for the Backend, Admin Panel, and Flutter App,"
echo "and then start all the services."
echo
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}[1/3] Setting up FastAPI Backend...${NC}"
echo -e "${CYAN}==================================================${NC}"
cd backend_app || exit
if [ ! -f "venv/bin/activate" ]; then
    echo "Creating virtual environment for Mac..."
    rm -rf venv
    python3 -m venv venv
fi
echo "Installing Python requirements..."
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..
echo

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}[2/3] Setting up React Admin Web Panel...${NC}"
echo -e "${CYAN}==================================================${NC}"
cd admin_app || exit
echo "Installing NPM dependencies (this might take a minute)..."
npm install
cd ..
echo

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}[3/3] Setting up Flutter Mobile App...${NC}"
echo -e "${CYAN}==================================================${NC}"
cd flutter_app || exit
echo "Getting Flutter packages..."
flutter pub get
cd ..
echo

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}Setup Complete! Starting services...${NC}"
echo -e "${CYAN}==================================================${NC}"
echo

# Get absolute path for AppleScript
BASE_DIR=$(pwd)

echo -e "${GREEN}[1/3] Launching FastAPI Backend...${NC}"
osascript -e 'tell app "Terminal" to do script "cd \"'"$BASE_DIR"'/backend_app\" && source venv/bin/activate && python3 main.py"'
sleep 3

echo -e "${PURPLE}[2/3] Launching React Admin Web Panel...${NC}"
osascript -e 'tell app "Terminal" to do script "cd \"'"$BASE_DIR"'/admin_app\" && npm run dev"'
sleep 2

echo -e "${YELLOW}[3/3] Launching Flutter Mobile App (Forced to Chrome)...${NC}"
osascript -e 'tell app "Terminal" to do script "cd \"'"$BASE_DIR"'/flutter_app\" && flutter run -d chrome"'

echo
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN} All services have been launched in separate windows!${NC}"
echo -e "${CYAN} Check your Dock for the new terminal windows.${NC}"
echo -e "${CYAN}==================================================${NC}"
read -p "Press any key to continue..." -n1 -s
echo

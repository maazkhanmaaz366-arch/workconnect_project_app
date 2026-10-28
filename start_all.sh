#!/bin/bash

# Define colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}       Starting WorkConnect Ecosystem${NC}"
echo -e "${CYAN}==================================================${NC}"
echo

# Get current directory path
BASE_DIR=$(pwd)

echo -e "${GREEN}[1/3] Launching FastAPI Backend...${NC}"
osascript -e 'tell app "Terminal" to do script "cd \"'"$BASE_DIR"'/backend_app\" && venv/bin/python main.py"'
sleep 3

echo -e "${PURPLE}[2/3] Launching React Admin Web Panel...${NC}"
osascript -e 'tell app "Terminal" to do script "cd \"'"$BASE_DIR"'/admin_app\" && npm run dev"'
sleep 2

echo -e "${YELLOW}[3/3] Launching Flutter Mobile App (Forced to Chrome)...${NC}"
osascript -e 'tell app "Terminal" to do script "cd \"'"$BASE_DIR"'/flutter_app\" && flutter run -d chrome"'

echo
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN} All services have been launched in separate windows!${NC}"
echo -e "${CYAN} Check your dock for the new terminal windows.${NC}"
echo -e "${CYAN}==================================================${NC}"
read -p "Press any key to continue..." -n1 -s
echo

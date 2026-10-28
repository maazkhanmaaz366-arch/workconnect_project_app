#!/bin/bash

# Define colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}   Starting WorkConnect Ecosystem (IDE Background)${NC}"
echo -e "${CYAN}==================================================${NC}"
echo

# We will use trap to kill background processes if script is interrupted (Ctrl+C)
trap 'echo -e "\nStopping all services..."; kill $(jobs -p); exit' SIGINT SIGTERM

echo -e "${GREEN}[1/3] Starting FastAPI Backend on Port 8000...${NC}"
(cd backend_app && venv/bin/python main.py) &
sleep 3

echo -e "${PURPLE}[2/3] Starting React Admin Web Panel...${NC}"
(cd admin_app && npm run dev) &
sleep 2

echo -e "${YELLOW}[3/3] Starting Flutter Mobile App (Forced to Chrome)...${NC}"
(cd flutter_app && flutter run -d chrome) &

echo
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN} All services are running in this terminal!${NC}"
echo -e "${CYAN} Logs will appear here. Press Ctrl+C to stop.${NC}"
echo -e "${CYAN}==================================================${NC}"

# Wait for all background processes to keep script running
wait

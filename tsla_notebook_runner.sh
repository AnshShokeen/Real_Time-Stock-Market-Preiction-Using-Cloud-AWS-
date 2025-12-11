#!/bin/bash

# Tesla Stock Real-Time Monitor
# Automated script to fetch and display Tesla stock prices every 5 seconds

# Colors for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INTERVAL=5  # seconds between updates
TICKER="TSLA"
LOG_FILE="tesla_stock_log.txt"

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   Tesla Stock Real-Time Monitor${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}Ticker: ${TICKER}${NC}"
    echo -e "${YELLOW}Update Interval: ${INTERVAL} seconds${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Function to check if Python is installed
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: Python3 is not installed${NC}"
        exit 1
    fi
}

# Function to check and install required packages
check_packages() {
    echo -e "${YELLOW}Checking required packages...${NC}"
    python3 << EOF
import sys
try:
    import yfinance
    import pandas
    import numpy
    print("All required packages are installed!")
except ImportError as e:
    print(f"Missing package: {e}")
    print("\nInstalling required packages...")
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "yfinance", "pandas", "numpy"])
EOF
}

# Function to fetch stock price using yfinance
get_stock_price() {
    python3 << EOF
import yfinance as yf
import datetime
import sys

try:
    ticker = yf.Ticker("${TICKER}")
    data = ticker.history(period="1d", interval="1m")
    
    if not data.empty:
        current_price = data['Close'].iloc[-1]
        open_price = data['Open'].iloc[0]
        high_price = data['High'].max()
        low_price = data['Low'].min()
        volume = data['Volume'].sum()
        change = current_price - open_price
        change_percent = (change / open_price) * 100
        
        print(f"{current_price:.2f}|{open_price:.2f}|{high_price:.2f}|{low_price:.2f}|{volume}|{change:.2f}|{change_percent:.2f}")
    else:
        print("ERROR|Unable to fetch data")
        sys.exit(1)
except Exception as e:
    print(f"ERROR|{str(e)}")
    sys.exit(1)
EOF
}

# Function to display stock information
display_stock_info() {
    local data=$1
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    IFS='|' read -r price open high low volume change change_pct <<< "$data"
    
    # Determine color based on price change
    if [[ "$change" == -* ]]; then
        PRICE_COLOR=$RED
        ARROW="↓"
    else
        PRICE_COLOR=$GREEN
        ARROW="↑"
    fi
    
    echo -e "${BLUE}Timestamp: ${NC}${timestamp}"
    echo -e "${PRICE_COLOR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PRICE_COLOR}Current Price:  $${price} ${ARROW}${NC}"
    echo -e "${PRICE_COLOR}Change:         $${change} (${change_pct}%)${NC}"
    echo -e "${NC}Open:           $${open}${NC}"
    echo -e "${NC}High:           $${high}${NC}"
    echo -e "${NC}Low:            $${low}${NC}"
    echo -e "${NC}Volume:         ${volume}${NC}"
    echo -e "${PRICE_COLOR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Log to file
    echo "$timestamp|$price|$open|$high|$low|$volume|$change|$change_pct" >> "$LOG_FILE"
}

# Function to show recent history
show_history() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}Recent Price History (Last 5 updates):${NC}"
        tail -n 5 "$LOG_FILE" | while IFS='|' read -r ts price open high low vol change chg_pct; do
            if [[ "$change" == -* ]]; then
                echo -e "${RED}$ts - ${price} (${chg_pct}%)${NC}"
            else
                echo -e "${GREEN}$ts - ${price} (${chg_pct}%)${NC}"
            fi
        done
        echo ""
    fi
}

# Main function
main() {
    # Initial checks
    check_python
    check_packages
    
    echo -e "${GREEN}Starting Tesla Stock Monitor...${NC}"
    sleep 2
    
    # Main loop
    while true; do
        display_header
        
        # Fetch stock data
        stock_data=$(get_stock_price)
        
        if [[ $stock_data == ERROR* ]]; then
            echo -e "${RED}Error fetching data: ${stock_data#ERROR|}${NC}"
            echo -e "${YELLOW}Retrying in ${INTERVAL} seconds...${NC}"
        else
            display_stock_info "$stock_data"
            show_history
        fi
        
        echo -e "${YELLOW}Next update in ${INTERVAL} seconds... (Press Ctrl+C to stop)${NC}"
        sleep $INTERVAL
    done
}

# Trap Ctrl+C for clean exit
trap ctrl_c INT

ctrl_c() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}Stock monitor stopped.${NC}"
    echo -e "${GREEN}Log saved to: ${LOG_FILE}${NC}"
    echo -e "${CYAN}========================================${NC}"
    exit 0
}

# Run the main function
main

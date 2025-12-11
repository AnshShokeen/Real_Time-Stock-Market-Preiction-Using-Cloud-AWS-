import yfinance as yf
from datetime import datetime
import time
import pandas as pd
import os

def clear_screen():
    os.system('clear')

def print_header():
    print("\n" + "="*70)
    print("             TESLA STOCK REAL-TIME MONITORING SYSTEM")
    print("="*70)

def print_stock_data(current, predicted, sma_5, sma_10, trend, change, change_pct):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # Determine colors
    if change >= 0:
        color_start = '\033[92m'  # Green
        arrow = '▲'
    else:
        color_start = '\033[91m'  # Red
        arrow = '▼'
    color_end = '\033[0m'
    
    print(f"\n┌{'─'*68}┐")
    print(f"│ Timestamp: {timestamp:<54}│")
    print(f"├{'─'*68}┤")
    print(f"│                      CURRENT MARKET DATA                           │")
    print(f"├{'─'*68}┤")
    print(f"│ Current Price:              ${current:>10.2f}                      │")
    print(f"│ 5-Day Moving Average:       ${sma_5:>10.2f}                      │")
    print(f"│ 10-Day Moving Average:      ${sma_10:>10.2f}                      │")
    print(f"├{'─'*68}┤")
    print(f"│                    PREDICTION & ANALYSIS                           │")
    print(f"├{'─'*68}┤")
    print(f"│ Predicted Next Price:       ${predicted:>10.2f}                      │")
    print(f"│ Expected Change:            {color_start}${change:>+10.2f} ({change_pct:>+6.2f}%) {arrow}{color_end}     │")
    print(f"│ Market Trend:               {trend:<36}│")
    print(f"└{'─'*68}┘")

print_header()
print("\n[STATUS] Initializing monitoring system...")
print("[STATUS] Fetching market data...")

while True:
    try:
        # Get last 30 days
        data = yf.download('TSLA', period='30d', progress=False, auto_adjust=True)
        
        if not data.empty and len(data) > 10:
            # Current price
            prices = data['Close']
            current = float(prices.iloc[-1])
            
            # Calculate simple moving averages
            sma_5 = float(prices.tail(5).mean())
            sma_10 = float(prices.tail(10).mean())
            
            # Simple trend prediction
            recent_changes = prices.pct_change().tail(5)
            avg_change = float(recent_changes.mean())
            predicted = current * (1 + avg_change)
            
            # Calculate change
            change = predicted - current
            change_pct = (change / current) * 100
            
            # Determine trend
            if sma_5 > sma_10:
                trend = "BULLISH 📈"
            else:
                trend = "BEARISH 📉"
            
            # Display
            clear_screen()
            print_header()
            print_stock_data(current, predicted, sma_5, sma_10, trend, change, change_pct)
            print(f"\n[INFO] Next update in 5 seconds... (Press Ctrl+C to stop)")
        else:
            print(f"[WARNING] {datetime.now().strftime('%H:%M:%S')} - Waiting for sufficient data...")
        
    except KeyboardInterrupt:
        print("\n\n[SYSTEM] Monitor stopped by user. Goodbye!")
        break
    except Exception as e:
        print(f"[ERROR] {datetime.now().strftime('%H:%M:%S')} - {str(e)}")
    
    time.sleep(5)
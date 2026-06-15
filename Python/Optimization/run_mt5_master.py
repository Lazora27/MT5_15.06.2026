import os
import subprocess
import time
import json
import shutil
import argparse
from datetime import datetime

# Konfiguration
TERMINAL_EXE = r"C:\Program Files\MetaTrader 5 IC Markets EU\terminal64.exe"
INI_PATH = r"D:\2_Trading\MT5_Project\Config\master_tester.ini"
RESULTS_BASE_DIR = r"D:\2_Trading\MT5_Project\Results"
COMMON_FILES_DIR = r"C:\Users\golde\AppData\Roaming\MetaQuotes\Terminal\Common\Files"
JSON_GRID_PATH = r"C:\Users\golde\Documents\cAlgo\Parameter\optimized_Fixed_Exit\csharp_optimization_grid.json"

LOGIN = "52916915"
SERVER = "ICMarketsEU-Demo"
PASSWORD = "6BA4$AlL6YEstr"

def get_category_for_symbol(symbol):
    s = symbol.upper()
    if any(x in s for x in ["BTC", "ETH", "LTC", "XRP"]): return "Crypto"
    if any(x in s for x in ["XAU", "XAG", "BRENT", "WTI"]): return "Metal"
    if any(x in s for x in ["US30", "DAX", "GER", "UK", "JAP"]): return "Indizes"
    return "Forex"

def load_grid_params(strategy_name):
    if not os.path.exists(JSON_GRID_PATH):
        print(f"Error: Could not find JSON grid at {JSON_GRID_PATH}")
        return None
        
    with open(JSON_GRID_PATH, 'r') as f:
        data = json.load(f)
        
    if strategy_name in data:
        return data[strategy_name]["params"]
    return None

def generate_ini_content(strategy, symbol, timeframe, params, tp_max, sl_max):
    lines = [
        "[Tester]",
        f"Expert={strategy}",
        f"Symbol={symbol}",
        f"Period={timeframe}",
        f"Login={LOGIN}",
        f"Server={SERVER}",
        f"Password={PASSWORD}",
        "Deposit=100000",
        "Currency=USD",
        "Leverage=500",
        "ExecutionMode=0",
        "Optimization=2",
        "Model=1",
        "FromDate=2024.01.01",
        "ToDate=2026.06.01",
        "ReplaceReport=1",
        "ShutdownTerminal=1",
        "",
        "[TesterInputs]"
    ]
    
    # Custom Strategy Params
    if params:
        for p_name, p_data in params.items():
            start = p_data.get("start", 1)
            end = p_data.get("end", 10)
            num_steps = p_data.get("num_steps", 2)
            
            # Berechne linearen Step (MT5 benötigt linearen Step)
            if num_steps > 1:
                step = (end - start) / (num_steps - 1)
            else:
                step = 1
                
            # Wenn ints, dann runde
            if isinstance(start, int) and isinstance(end, int):
                step = max(1, int(round(step)))
            else:
                step = round(step, 4)
                
            lines.append(f"{p_name}={start}||{start}||{step}||{end}||Y")
            
    # Standard Params (TP, SL, Volume)
    lines.append(f"TpIndex=19||1||1||{tp_max}||Y")
    lines.append(f"SlIndex=10||1||1||{sl_max}||Y")
    lines.append("VolumeLots=0.01||0.01||0.01||2.0||N")
    
    return "\n".join(lines)

def run_optimization(strategy, symbol, timeframe):
    print(f"\n--- Starting Optimization for {strategy} on {symbol} ({timeframe}) ---")
    
    category = get_category_for_symbol(symbol)
    tp_sl_max = 45 if category == "Forex" else 67
    
    params = load_grid_params(strategy)
    if not params:
        print(f"Warning: No parameters found in JSON grid for {strategy}. Using defaults.")
        
    ini_content = generate_ini_content(strategy, symbol, timeframe, params, tp_sl_max, tp_sl_max)
    
    os.makedirs(os.path.dirname(INI_PATH), exist_ok=True)
    with open(INI_PATH, "w", encoding="utf-8") as f:
        f.write(ini_content)
        
    # Delete old raw CSV from MT5 Common Files
    raw_csv_name = f"{strategy.replace('_', '')}_Results.csv"
    raw_csv_path = os.path.join(COMMON_FILES_DIR, raw_csv_name)
    if os.path.exists(raw_csv_path):
        os.remove(raw_csv_path)
        
    print(f"Executing MT5 Headless...")
    cmd = [TERMINAL_EXE, f"/config:{INI_PATH}"]
    start_time = time.time()
    
    try:
        process = subprocess.Popen(cmd)
        while process.poll() is None:
            time.sleep(2)
    except Exception as e:
        print(f"Execution failed: {e}")
        return

    elapsed = time.time() - start_time
    print(f"MT5 Optimization completed in {elapsed:.1f} seconds.")
    
    # Process Results
    if os.path.exists(raw_csv_path):
        print(f"Raw CSV found. Processing results...")
        process_raw_csv(raw_csv_path, strategy, category, symbol, timeframe)
    else:
        print(f"ERROR: No raw CSV found at {raw_csv_path}. Optimization may have failed.")

def process_raw_csv(raw_csv_path, strategy, category, symbol, timeframe):
    target_dir = os.path.join(RESULTS_BASE_DIR, strategy, category, symbol, timeframe)
    os.makedirs(target_dir, exist_ok=True)
    
    date_str = datetime.now().strftime("%d-%m-%Y")
    base_name = f"{strategy}_{symbol}_{timeframe}_Start_{date_str}_optimized"
    
    target_csv = os.path.join(target_dir, f"{base_name}.csv")
    target_json = os.path.join(target_dir, f"{base_name}.json")
    target_html = os.path.join(target_dir, f"{base_name}.html")
    
    # 1. Format CSV
    results = []
    with open(raw_csv_path, 'r') as f:
        lines = f.readlines()
        
    if not lines:
        print("Raw CSV is empty.")
        return
        
    # For now, just copy it over, but ideally we'd map it to the exact cTrader columns
    # We will expand this parsing in the next iterations
    with open(target_csv, 'w') as f:
        f.writelines(lines)
        
    # TODO: Write JSON and HTML conversions here later.
    # Currently just copying raw MT5 format.
    print(f"Saved optimized results to: {target_csv}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MT5 Master Orchestrator")
    parser.add_argument("--strategy", type=str, help="Specific strategy to run. If omitted, runs ALL from grid.")
    parser.add_argument("--symbol", type=str, default="EURUSD", help="Symbol to test")
    parser.add_argument("--timeframe", type=str, default="H1", help="Timeframe (e.g., M15, H1, D1)")
    args = parser.parse_args()
    
    if args.strategy:
        run_optimization(args.strategy, args.symbol, args.timeframe)
    else:
        # Run all
        if os.path.exists(JSON_GRID_PATH):
            with open(JSON_GRID_PATH, 'r') as f:
                grid = json.load(f)
            for strat in grid.keys():
                run_optimization(strat, args.symbol, args.timeframe)
        else:
            print("Cannot run ALL, grid file not found.")

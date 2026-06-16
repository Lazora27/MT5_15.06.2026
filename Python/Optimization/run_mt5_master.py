import os
import json
import time
import subprocess
import shutil

# --- CONFIGURATION (Dynamic for Cross-Platform) ---

# Get Repo Base Directory
BASE_DIR = os.path.abspath(os.path.join(__file__, "../../../"))

# Locate MT5 Terminal Executable (Windows natively vs Wine default)
WINE_MT5 = r"C:\Program Files\MetaTrader 5\terminal64.exe"
WIN_MT5 = r"C:\Program Files\MetaTrader 5 IC Markets EU\terminal64.exe"
if os.path.exists(WIN_MT5):
    TERMINAL_PATH = WIN_MT5
elif os.path.exists(WINE_MT5):
    TERMINAL_PATH = WINE_MT5
else:
    raise Exception("MT5 terminal64.exe not found!")

# Dynamically locate MT5 Data Directories via AppData roaming
APPDATA_DIR = os.environ.get("APPDATA")
TERMINAL_BASE = os.path.join(APPDATA_DIR, "MetaQuotes", "Terminal")
data_dirs = [d for d in os.listdir(TERMINAL_BASE) if len(d) == 32] # 32-char MD5 hashes
if not data_dirs:
    raise Exception("No MetaTrader 5 data directory found in AppData!")
MT5_DATA_DIR = os.path.join(TERMINAL_BASE, data_dirs[0])
COMMON_FILES_DIR = os.path.join(TERMINAL_BASE, "Common", "Files")

# Result Base Directory (inside MT5 repo)
RESULTS_BASE_DIR = os.path.join(BASE_DIR, "Results")

# Locate parameter mapping JSON (cTrader repo location varies)
ct_linux = os.path.join(BASE_DIR, "cTrader_15.06.26")
ct_win = r"C:\Users\golde\Documents\cAlgo"
if os.path.exists(ct_linux):
    CTRADER_DIR = ct_linux
elif os.path.exists(ct_win):
    CTRADER_DIR = ct_win
else:
    raise Exception("cTrader repository/directory not found for parameters!")
JSON_MAPPING = os.path.join(CTRADER_DIR, "Parameter", "optimized_Fixed_Exit", "CSharp", "parameter_mapping.json")

# --- STRATEGIES & CONFIG ---
STRATEGIES = [
    "Accelerator_Oscillator", "ADX", "Autoencoder_Compression", "Boosting_Cascade", "CCI",
    "Consensus_Aggregator", "DMI", "Effective_Tick_Size", "ElderRay", "Hasbrouck_Info_Share",
    "JMA", "Meta_Learning", "Nonlinear_Prediction", "Predictive_Pattern_Engine", "PSAR",
    "Random_Forest_Ensemble", "RangeBound", "Realized_Vol_Signature", "Seasonal_Decomposition",
    "Trend_Vigor", "Ultimate_Convergence_Master", "VAR_Forecast", "Vortex"
]
SYMBOLS = ["EURUSD", "BTCUSD"]
TIMEFRAMES = ["H1", "M15"]
TF_MAP = {"M1": "M1", "M5": "M5", "M15": "M15", "M30": "M30", "H1": "H1", "H4": "H4", "D1": "D1"}

def load_params():
    with open(JSON_MAPPING, "r", encoding="utf-8") as f:
        return json.load(f)

def get_tester_inputs(params_dict):
    lines = ["[TesterInputs]"]
    for param_name, data in params_dict.items():
        mt5_param_name = "InpPeriod" if param_name == "Period" else param_name
        
        if param_name == "TpIndex":
            default = data['default']
            lines.append(f"{mt5_param_name}={default}||19||1||20||Y")
        else:
            default = data['default']
            lines.append(f"{mt5_param_name}={default}||{default}||0||0||0||N")
    return "\n".join(lines)

def get_category(symbol):
    s = symbol.upper()
    if any(x in s for x in ["BTC", "ETH", "LTC", "XRP"]): return "Crypto"
    if any(x in s for x in ["XAU", "XAG", "BRENT", "WTI"]): return "Metal"
    if any(x in s for x in ["US30", "DAX", "GER", "UK", "JAP"]): return "Indizes"
    return "Forex"

def clean_common_files():
    if not os.path.exists(COMMON_FILES_DIR): return
    for f in os.listdir(COMMON_FILES_DIR):
        if f.endswith(".csv"):
            try:
                os.remove(os.path.join(COMMON_FILES_DIR, f))
            except:
                pass

def find_result_csv():
    if not os.path.exists(COMMON_FILES_DIR): return None
    csvs = [f for f in os.listdir(COMMON_FILES_DIR) if f.endswith(".csv")]
    if not csvs:
        return None
    csvs.sort(key=lambda x: os.path.getmtime(os.path.join(COMMON_FILES_DIR, x)), reverse=True)
    return os.path.join(COMMON_FILES_DIR, csvs[0])

def check_csv_ready(filepath, timeout=20):
    start = time.time()
    last_size = -1
    stable_count = 0
    while time.time() - start < timeout:
        if os.path.exists(filepath):
            size = os.path.getsize(filepath)
            if size > 100 and size == last_size:
                stable_count += 1
                if stable_count >= 2: # Stable for 2 checks
                    try:
                        with open(filepath, "a"): pass
                        return True
                    except IOError:
                        pass
            else:
                stable_count = 0
            last_size = size
        time.sleep(1)
    return False

def run_backtest(strategy_key, strategy_data, symbol, tf):
    print(f"--- Starting {strategy_key} on {symbol} {tf} ---")
    
    # Ensure tester directory exists
    os.makedirs(os.path.join(MT5_DATA_DIR, "Tester"), exist_ok=True)
    ini_filepath = os.path.join(MT5_DATA_DIR, "Tester", "tester.ini")
    tester_inputs = get_tester_inputs(strategy_data['params'])
    
    ini_content = f"""[Tester]
Expert={strategy_key}
Symbol={symbol}
Period={TF_MAP[tf]}
Optimization=2
Model=0
Deposit=1000000
Currency=USD
Leverage=100
FromDate=2026.06.01
ToDate=2026.06.10
ForwardMode=0
Report={strategy_key}_Report
ReplaceReport=1
ShutdownTerminal=1

{tester_inputs}
"""
    with open(ini_filepath, "w", encoding="utf-16") as f:
        f.write(ini_content)
        
    clean_common_files()
    
    # Kill any hanging terminal instances
    os.system("taskkill /f /im terminal64.exe >nul 2>&1")
    
    cmd = [TERMINAL_PATH, f"/config:{ini_filepath}"]
    start_time = time.time()
    
    process = subprocess.Popen(cmd)
    process.wait()
    
    elapsed = time.time() - start_time
    
    # After terminal exits, the CSV should be there
    csv_path = find_result_csv()
    if csv_path and check_csv_ready(csv_path):
        cat = get_category(symbol)
        dest_folder = os.path.join(RESULTS_BASE_DIR, strategy_key, cat, symbol, tf)
        os.makedirs(dest_folder, exist_ok=True)
        
        dest_path = os.path.join(dest_folder, os.path.basename(csv_path))
        shutil.move(csv_path, dest_path)
        print(f"SUCCESS: {strategy_key} [{symbol} {tf}] completed in {elapsed:.1f}s -> {dest_path}")
        return True, elapsed
    else:
        print(f"FAILED: {strategy_key} [{symbol} {tf}] - No CSV report found.")
        return False, elapsed

def main():
    print(f"[*] Running with MT5 Path: {TERMINAL_PATH}")
    print(f"[*] AppData Directory: {MT5_DATA_DIR}")
    print(f"[*] Parameters from: {CTRADER_DIR}")
    
    param_map = load_params()
    results_summary = []
    
    for strat in STRATEGIES:
        strat_data = None
        for k, v in param_map.items():
            if v["folder"] == strat or k == strat:
                strat_data = v
                break
                
        if not strat_data:
            print(f"Warning: Config for {strat} not found.")
            continue
            
        for sym in SYMBOLS:
            for tf in TIMEFRAMES:
                success, t = run_backtest(strat, strat_data, sym, tf)
                results_summary.append({"Strategy": strat, "Symbol": sym, "TF": tf, "Success": success, "Time": t})
                
    print("\n\n" + "="*50)
    print("BACKTESTING SUMMARY")
    print("="*50)
    for r in results_summary:
        status = "OK" if r["Success"] else "FAIL"
        print(f"[{status}] {r['Strategy']} | {r['Symbol']} | {r['TF']} ({r['Time']:.1f}s)")

if __name__ == "__main__":
    main()

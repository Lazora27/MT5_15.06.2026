import os
import json

base_dir = r"D:\2_Trading\MT5_Project\Results"
json_grid = r"C:\Users\golde\Documents\cAlgo\Parameter\optimized_Fixed_Exit\csharp_optimization_grid.json"

symbols_categories = {
    "EURUSD": "Forex",
    "GBPUSD": "Forex",
    "USDJPY": "Forex",
    "USDCAD": "Forex",
    "AUDUSD": "Forex",
    "USDCHF": "Forex",
    "US30": "Indizes",
    "DAX": "Indizes",
    "UK100": "Indizes",
    "XAUUSD": "Metal",
    "XAGUSD": "Metal",
    "BTCUSD": "Crypto",
    "ETHUSD": "Crypto"
}

timeframes = ["M1", "M5", "M15", "M30", "H1", "H4", "D1"]

def get_strategies():
    if os.path.exists(json_grid):
        with open(json_grid, 'r') as f:
            data = json.load(f)
            return list(data.keys())
    return [
        "ADX", "Accelerator_Oscillator", "Autoencoder_Compression", "Boosting_Cascade",
        "CCI", "Consensus_Aggregator", "DMI", "Effective_Tick_Size", "ElderRay",
        "Hasbrouck_Info_Share", "JMA", "Meta_Learning", "Nonlinear_Prediction",
        "PSAR", "Predictive_Pattern_Engine", "Random_Forest_Ensemble", "RangeBound",
        "Realized_Vol_Signature", "Seasonal_Decomposition", "Trend_Vigor",
        "Ultimate_Convergence_Master", "VAR_Forecast", "Vortex"
    ]

strategies = get_strategies()

created_count = 0
for strat in strategies:
    for symbol, category in symbols_categories.items():
        for tf in timeframes:
            # Create: Results / Strategie / Kategorie / Symbol / Timeframe
            path = os.path.join(base_dir, strat, category, symbol, tf)
            if not os.path.exists(path):
                os.makedirs(path)
                created_count += 1

print(f"Erfolgreich {created_count} einheitliche Ordner-Strukturen generiert in {base_dir}")

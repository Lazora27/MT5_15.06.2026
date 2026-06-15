import os
import subprocess
import time

def run_mt5_optimization():
    print("--- MT5 Fully Automated Optimization Engine ---")
    
    symbol = "EURUSD"
    
    terminal_exe = r"C:\Program Files\MetaTrader 5 IC Markets EU\terminal64.exe"
    ini_path = r"D:\2_Trading\MT5_Project\Config\tester.ini"
    report_path = r"D:\2_Trading\MT5_Project\Results\Accelerator_EURUSD_M15_Opt"
    
    if os.path.exists(report_path + ".xml"):
        os.remove(report_path + ".xml")

    # Standard string writing, MT5 parses plain ascii / utf-8 perfectly fine.
    ini_content = f"""[Tester]
Expert=Accelerator_Oscillator
Symbol={symbol}
Period=M15
Login=52916915
Server=ICMarketsEU-Demo
Password=6BA4$AlL6YEstr
Deposit=1000000
Currency=USD
Leverage=500
ExecutionMode=0
Optimization=2
Model=1
FromDate=2024.01.01
ToDate=2026.06.01
Report={report_path}
ReplaceReport=1
ShutdownTerminal=1

[TesterInputs]
VolPeriod=3||3||2||20||Y
TpIndex=19||1||1||45||Y
SlIndex=10||1||1||45||Y
VolumeLots=0.01||0.01||0.01||2.0||N
"""

    with open(ini_path, "w", encoding="utf-8") as f:
        f.write(ini_content)
        
    print(f"Generated INI Config at: {ini_path}")
    print("Starting MetaTrader 5 Headless Tester...")
    
    start_time = time.time()
    
    cmd = [terminal_exe, f"/config:{ini_path}"]
    
    try:
        process = subprocess.Popen(cmd)
        
        print("Waiting for MT5 to complete optimization...")
        while process.poll() is None:
            time.sleep(2)
            
        print(f"MT5 Process finished with exit code {process.returncode}.")
        
    except Exception as e:
        print(f"Failed to run MT5: {e}")
        return

    elapsed = time.time() - start_time
    print(f"\nOptimization Completed in {elapsed:.1f} seconds!")
    
    if os.path.exists(report_path + ".xml"):
        print(f"SUCCESS: Report generated at {report_path}.xml")
    else:
        print("WARNING: MT5 closed, but no XML report was found.")

if __name__ == "__main__":
    run_mt5_optimization()

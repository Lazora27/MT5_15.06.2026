#!/bin/bash
set -e

echo "================================================="
echo " Starte MT5 Headless Backtest (via Xvfb & Wine)  "
echo "================================================="

# Pfade anpassen (abhängig davon, wo die Repos geklont wurden)
MT5_REPO="$HOME/MT5_Project"
PYTHON_SCRIPT="$MT5_REPO/Python/Optimization/run_mt5_master.py"

# Überprüfen, ob das Repo existiert
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Fehler: Das Python-Skript wurde nicht gefunden: $PYTHON_SCRIPT"
    echo "Hast du die Repositories geklont?"
    exit 1
fi

# Virtuellen Bildschirm starten (Display :99)
echo "[*] Starte virtuellen X-Server (Xvfb) auf Display :99..."
Xvfb :99 -screen 0 1024x768x24 &
XVFB_PID=$!
sleep 3 # Warten, bis Xvfb bereit ist

# Display Variable setzen, damit Wine/MT5 es nutzen
export DISPLAY=:99

echo "[*] Führe Python Backtest-Skript in Wine aus..."
# Führt die Windows-Python-Installation aus, die wiederum MT5 über das MetaTrader5 Paket ansteuert
wine python "$PYTHON_SCRIPT"

echo "[*] Beende virtuellen X-Server..."
kill $XVFB_PID

echo "================================================="
echo " Backtest abgeschlossen! "
echo " Die Ergebnisse sollten sich im Results Ordner befinden."
echo "================================================="

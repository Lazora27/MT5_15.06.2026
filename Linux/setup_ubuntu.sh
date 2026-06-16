#!/bin/bash
set -e

echo "================================================="
echo " Start: MT5 Headless Setup auf Ubuntu 22.04 LTS  "
echo "================================================="

# 1. System updaten & Architektur hinzufügen
sudo dpkg --add-architecture i386
sudo apt update && sudo apt upgrade -y

# 2. Xvfb (Virtual Framebuffer) & Tools installieren
echo "[*] Installiere Xvfb, wget und Abhängigkeiten..."
sudo apt install -y xvfb x11-utils wget cabextract winbind git

# 3. WineHQ installieren (Wine 9.0 / Stable)
echo "[*] Installiere WineHQ..."
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
sudo apt update
sudo apt install --install-recommends winehq-stable -y

# 4. Wine Prefix konfigurieren (Windows 10 Mode)
export WINEPREFIX=~/.wine
export WINEARCH=win64
echo "[*] Initialisiere Wine..."
winecfg /v win10
sleep 5 # Warten bis winecfg abgeschlossen ist

# 5. Windows Python in Wine installieren
echo "[*] Lade Windows Python 3.11.8 herunter..."
wget https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe -O python_installer.exe
echo "[*] Installiere Windows Python in Wine (Silent)..."
wine python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
rm python_installer.exe

# 6. MetaTrader 5 installieren
echo "[*] Lade MetaTrader 5 Setup herunter..."
wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O mt5setup.exe
echo "[*] Installiere MT5 (kann einen Moment dauern)..."
wine mt5setup.exe /auto
rm mt5setup.exe
sleep 10

# 7. Python Pakete in Wine installieren (pandas, MetaTrader5)
echo "[*] Installiere Python-Module (pandas, MetaTrader5) in Wine..."
wine python -m pip install --upgrade pip
wine python -m pip install pandas MetaTrader5

# 8. Repositories Klonen (Erfordert GitHub PAT)
echo "[*] Erstelle Projekt-Ordner..."
mkdir -p ~/Trading
cd ~/Trading

echo "================================================="
echo " SETUP ABGESCHLOSSEN! "
echo " WICHTIG: Füge deinen GitHub PAT Token ein und klone die Repos."
echo " git clone https://<TOKEN>@github.com/Lazora27/MT5_15.06.2026.git"
echo " git clone https://<TOKEN>@github.com/Lazora27/cTrader_15.06.26.git"
echo "================================================="
